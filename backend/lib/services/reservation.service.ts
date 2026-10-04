import { InvoiceService } from './invoice.service';

export interface CheckInDto {
  roomId: string;
  bookingSource: 'REDDOORZ' | 'WALK_IN';
  reddoorzBookingCode?: string | null;
  nik: string;
  fullName: string;
  phoneWhatsapp: string;
  address?: string | null;
  totalNights: number;
  roomRate: number;
  paymentMethod: 'CASH' | 'QRIS' | 'TRANSFER' | 'REDDOORZ_PREPAID';
  receptionistUserId?: string;
}

/**
 * ReservationService: Sinar Harapan PMS
 * Menghandle reservasi kamar, repeat guest logic (BUG-BE-03), dan invoice number persisten (BUG-BE-02)
 */
export class ReservationService {
  /**
   * BUG-BE-03 FIX: Tamu Lama (Repeat Guest) Check-in Ulang
   * Cari dulu apakah NIK sudah ada di database:
   * - Jika ada: gunakan guest.id yang sudah ada dan perbarui data profilnya jika ada pembaruan
   * - Jika belum ada: buat baris data guest baru
   */
  static async checkIn(prismaClient: any, dto: CheckInDto): Promise<any> {
    return await prismaClient.$transaction(async (tx: any) => {
      // 1. Cek ketersediaan kamar
      const room = await tx.room.findFirst({
        where: {
          id: dto.roomId,
          deletedAt: null, // Filter soft-deleted room (BUG-BE-05)
        },
      });

      if (!room) {
        throw new Error('NOT_FOUND: Kamar tidak ditemukan atau telah dihapus');
      }

      if (room.status !== 'AVAILABLE') {
        throw new Error('CONFLICT: Kamar sedang tidak tersedia (status saat ini: ' + room.status + ')');
      }

      // 2. Cek apakah NIK ini sedang aktif menginap di kamar lain (belum check-out)
      const activeRes = await tx.reservation.findFirst({
        where: {
          guest: { nik: dto.nik },
          actualCheckOutTime: null,
        },
        include: { room: true },
      });

      if (activeRes) {
        throw new Error(`CONFLICT: Tamu dengan NIK ${dto.nik} saat ini sedang aktif menginap di kamar ${activeRes.room.roomNumber}`);
      }

      // 3. BUG-BE-03 FIX: Cari data guest berdasarkan NIK (@unique)
      let guest = await tx.guest.findUnique({
        where: { nik: dto.nik },
      });

      if (guest) {
        // Tamu lama (Repeat Guest): update data kontak/nama jika ada perubahan dan pakai id yang sama
        guest = await tx.guest.update({
          where: { id: guest.id },
          data: {
            fullName: dto.fullName,
            phoneWhatsapp: dto.phoneWhatsapp,
            address: dto.address ?? guest.address,
          },
        });
      } else {
        // Tamu baru: buat baris baru di tabel guests
        guest = await tx.guest.create({
          data: {
            nik: dto.nik,
            fullName: dto.fullName,
            phoneWhatsapp: dto.phoneWhatsapp,
            address: dto.address ?? null,
          },
        });
      }

      // 4. BUG-BE-02 FIX: Generate nomor invoice atomik persisten dari database
      const invoiceNumber = await InvoiceService.generatePersistentInvoiceNumber(tx);

      const checkInTime = new Date();
      const expectedCheckOutTime = new Date(checkInTime.getTime() + dto.totalNights * 24 * 60 * 60 * 1000);
      expectedCheckOutTime.setHours(12, 0, 0, 0); // Standar checkout 12:00 WIB
      const totalAmount = dto.roomRate * dto.totalNights;

      // 5. Buat reservasi baru
      const reservation = await tx.reservation.create({
        data: {
          invoiceNumber,
          guestId: guest.id,
          roomId: room.id,
          bookingSource: dto.bookingSource,
          reddoorzBookingCode: dto.reddoorzBookingCode || null,
          checkInTime,
          expectedCheckOutTime,
          totalNights: dto.totalNights,
          roomRate: dto.roomRate,
          totalAmount,
          paymentMethod: dto.paymentMethod,
          paymentStatus: 'PAID',
          receptionistUserId: dto.receptionistUserId || null,
        },
      });

      // 6. Update status kamar menjadi OCCUPIED
      await tx.room.update({
        where: { id: room.id },
        data: { status: 'OCCUPIED' },
      });

      // 7. Catat audit log
      await tx.activityLog.create({
        data: {
          userId: dto.receptionistUserId || null,
          actionType: 'CHECK_IN',
          resourceType: 'reservation',
          resourceId: reservation.id,
          details: {
            invoiceNumber,
            roomNumber: room.roomNumber,
            guestName: guest.fullName,
            nik: guest.nik,
            isRepeatGuest: !!guest,
          },
        },
      });

      return {
        id: reservation.id,
        invoiceNumber,
        roomId: room.id,
        roomNumber: room.roomNumber,
        guestId: guest.id,
        guestName: guest.fullName,
        nik: guest.nik,
        totalAmount,
        status: 'OCCUPIED',
      };
    });
  }

  /**
   * Proses Check-out tamu
   */
  static async checkOut(
    prismaClient: any,
    reservationId: string,
    options?: { additionalCharges?: number; additionalChargesDetail?: any[]; receptionistUserId?: string }
  ): Promise<any> {
    return await prismaClient.$transaction(async (tx: any) => {
      const reservation = await tx.reservation.findUnique({
        where: { id: reservationId },
        include: { room: true, guest: true },
      });

      if (!reservation) {
        throw new Error('NOT_FOUND: Reservasi tidak ditemukan');
      }

      if (reservation.actualCheckOutTime !== null) {
        throw new Error('CONFLICT: Reservasi ini sudah selesai di-checkout sebelumnya');
      }

      const actualCheckOutTime = new Date();
      const extraCharges = options?.additionalCharges ?? 0;
      const extraDetail = options?.additionalChargesDetail ?? [];
      const updatedTotalAmount = Number(reservation.totalAmount) + extraCharges;

      // Update reservasi
      const updatedReservation = await tx.reservation.update({
        where: { id: reservationId },
        data: {
          actualCheckOutTime,
          additionalCharges: extraCharges,
          additionalChargesDetail: extraDetail,
          totalAmount: updatedTotalAmount,
        },
      });

      // Ubah status kamar jadi DIRTY (kuning, butuh dibersihkan)
      await tx.room.update({
        where: { id: reservation.roomId },
        data: { status: 'DIRTY' },
      });

      // Catat audit log
      await tx.activityLog.create({
        data: {
          userId: options?.receptionistUserId || null,
          actionType: 'CHECK_OUT',
          resourceType: 'reservation',
          resourceId: reservation.id,
          details: {
            invoiceNumber: reservation.invoiceNumber,
            roomNumber: reservation.room.roomNumber,
            guestName: reservation.guest.fullName,
            additionalCharges: extraCharges,
            grandTotal: updatedTotalAmount,
          },
        },
      });

      return {
        id: updatedReservation.id,
        invoiceNumber: updatedReservation.invoiceNumber,
        roomNumber: reservation.room.roomNumber,
        roomStatus: 'DIRTY',
        additionalCharges: extraCharges,
        grandTotal: updatedTotalAmount,
      };
    });
  }
}
