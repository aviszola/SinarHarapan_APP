import { WhatsAppService } from '../services/whatsapp.service';

/**
 * Cron Job: Checkout Reminder Scheduler
 * Runs every 10 minutes (FR-WA-01, FR-WA-02)
 */
export async function runCheckoutReminderJob(prismaClient: any) {
  const now = new Date();
  const sixtyMinutesLater = new Date(now.getTime() + 60 * 60 * 1000);

  // 1. Query reservations nearing check-out (within next 60 minutes) that have not been sent WA
  const activeReservations = await prismaClient.reservation.findMany({
    where: {
      actualCheckOutTime: null,
      expectedCheckOutTime: {
        gte: now,
        lte: sixtyMinutesLater,
      },
      waReminderSentAt: null,
    },
    include: {
      guest: true,
      room: true,
    },
  });

  console.log(`[Cron] Found ${activeReservations.length} reservations nearing check-out.`);

  for (const reservation of activeReservations) {
    const checkOutTimeStr = reservation.expectedCheckOutTime.toLocaleTimeString('id-ID', {
      hour: '2-digit',
      minute: '2-digit',
    });

    const result = await WhatsAppService.sendCheckOutReminder({
      recipientPhone: reservation.guest.phoneWhatsapp,
      guestName: reservation.guest.fullName,
      roomNumber: reservation.room.roomNumber,
      checkOutTimeStr: `${checkOutTimeStr} WIB`,
    });

    if (result.success) {
      await prismaClient.reservation.update({
        where: { id: reservation.id },
        data: {
          waReminderSentAt: new Date(),
          waDeliveryStatus: result.status,
        },
      });

      // Audit log
      await prismaClient.activityLog.create({
        data: {
          actionType: 'WA_REMINDER_SENT',
          resourceType: 'reservation',
          resourceId: reservation.id,
          details: {
            phone: reservation.guest.phoneWhatsapp,
            roomNumber: reservation.room.roomNumber,
            messageId: result.messageId,
          },
        },
      });
    } else {
      await prismaClient.activityLog.create({
        data: {
          actionType: 'WA_REMINDER_FAILED',
          resourceType: 'reservation',
          resourceId: reservation.id,
          details: {
            error: 'Gagal mengirim notifikasi WhatsApp otomatis',
            phone: reservation.guest.phoneWhatsapp,
          },
        },
      });
    }
  }
}
