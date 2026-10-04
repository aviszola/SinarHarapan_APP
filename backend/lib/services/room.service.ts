export interface CreateRoomDto {
  roomNumber: string;
  roomType: string;
  floor: number;
  basePricePerNight: number;
  facilities?: string[];
}

export interface UpdateRoomDto {
  roomType?: string;
  floor?: number;
  basePricePerNight?: number;
  facilities?: string[];
  status?: 'AVAILABLE' | 'OCCUPIED' | 'DIRTY' | 'MAINTENANCE';
}

/**
 * RoomService: Sinar Harapan PMS
 * Menghandle manajemen inventaris kamar dan soft-delete (BUG-BE-05)
 */
export class RoomService {
  /**
   * Mendapatkan daftar kamar aktif (BUG-BE-05: filter deletedAt IS NULL)
   */
  static async getRooms(prismaClient: any, filter?: { roomType?: string; floor?: number; status?: any; limit?: number; page?: number }) {
    const where: any = {
      deletedAt: null, // Hanya ambil kamar yang belum dihapus (soft-delete)
    };

    if (filter?.roomType) where.roomType = filter.roomType;
    if (filter?.floor) where.floor = filter.floor;
    if (filter?.status) where.status = filter.status;

    const limit = Math.min(filter?.limit || 50, 100); // Batasi max 100
    const page = filter?.page || 1;
    const skip = (page - 1) * limit;

    const [rooms, total] = await Promise.all([
      prismaClient.room.findMany({
        where,
        orderBy: [{ floor: 'asc' }, { roomNumber: 'asc' }],
        skip,
        take: limit,
      }),
      prismaClient.room.count({ where }),
    ]);

    return {
      rooms,
      pagination: {
        page,
        limit,
        totalItems: total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Mendapatkan detail satu kamar
   */
  static async getRoomById(prismaClient: any, id: string) {
    const room = await prismaClient.room.findFirst({
      where: {
        id,
        deletedAt: null,
      },
      include: {
        reservations: {
          where: { actualCheckOutTime: null },
          include: { guest: true },
          take: 1,
        },
      },
    });

    if (!room) {
      throw new Error('NOT_FOUND: Kamar tidak ditemukan atau telah dihapus');
    }

    return room;
  }

  /**
   * BUG-BE-05 FIX: Hapus Kamar dengan Riwayat Transaksi (Soft Delete)
   * Menggantikan prisma.room.delete() dengan update deletedAt = new Date().
   * Mencegah PostgreSQL P2003 Foreign Key Constraint Violation saat kamar memiliki riwayat reservasi lama.
   */
  static async removeRoom(prismaClient: any, id: string, managerUserId?: string): Promise<{ success: boolean; message: string }> {
    // 1. Cek keberadaan kamar
    const room = await prismaClient.room.findFirst({
      where: { id, deletedAt: null },
    });

    if (!room) {
      throw new Error('NOT_FOUND: Kamar tidak ditemukan atau sudah dihapus');
    }

    // 2. Cek apakah ada reservasi yang sedang AKTIF (tamu sedang menginap di kamar tersebut)
    const activeReservation = await prismaClient.reservation.findFirst({
      where: {
        roomId: id,
        actualCheckOutTime: null,
      },
    });

    if (activeReservation) {
      throw new Error('CONFLICT: Kamar sedang memiliki tamu aktif check-in, tidak dapat dihapus');
    }

    // 3. BUG-BE-05 FIX: Lakukan SOFT DELETE dengan mengisi timestamp deletedAt
    await prismaClient.room.update({
      where: { id },
      data: {
        deletedAt: new Date(),
      },
    });

    // 4. Catat ke audit log
    if (prismaClient.activityLog) {
      await prismaClient.activityLog.create({
        data: {
          userId: managerUserId || null,
          actionType: 'DELETE_ROOM',
          resourceType: 'room',
          resourceId: id,
          details: {
            roomNumber: room.roomNumber,
            deletedAt: new Date().toISOString(),
            method: 'SOFT_DELETE',
          },
        },
      });
    }

    return {
      success: true,
      message: `Kamar ${room.roomNumber} berhasil dihapus (soft-delete)`,
    };
  }
}
