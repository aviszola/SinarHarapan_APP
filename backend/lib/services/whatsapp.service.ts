export interface WhatsAppMessagePayload {
  recipientPhone: string;
  guestName: string;
  roomNumber: string;
  checkOutTimeStr: string;
}

export class WhatsAppService {
  private static readonly GATEWAY_URL = process.env.WA_GATEWAY_URL || 'https://api.fonnte.com/send';
  private static readonly API_KEY = process.env.WA_GATEWAY_API_KEY || 'mock-api-key';

  /**
   * Official PRD FR-WA-03 Reminder Message Template
   */
  static renderReminderTemplate(payload: WhatsAppMessagePayload): string {
    return (
      `Yth. Bpk/Ibu ${payload.guestName},\n\n` +
      `Terima kasih telah menginap di Hotel Sinar Harapan (Mitra RedDoorz).\n` +
      `Kami menginformasikan bahwa waktu check-out untuk Kamar ${payload.roomNumber}\n` +
      `adalah pukul ${payload.checkOutTimeStr} WIB (tersisa 1 jam lagi).\n\n` +
      `Mohon pastikan seluruh barang bawaan Anda tidak tertinggal. Jika Anda\n` +
      `memerlukan bantuan staf atau perpanjangan durasi menginap, silakan\n` +
      `hubungi meja resepsionis.\n\n` +
      `Salam hangat,\n` +
      `Manajemen Hotel Sinar Harapan`
    );
  }

  /**
   * Dispatches WhatsApp reminder with automatic retry logic (max 3x)
   */
  static async sendCheckOutReminder(payload: WhatsAppMessagePayload): Promise<{ success: boolean; messageId: string; status: string }> {
    const message = this.renderReminderTemplate(payload);

    let attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        // If live API key is configured, post to Fonnte/Wablas
        if (process.env.WA_GATEWAY_API_KEY) {
          const res = await fetch(this.GATEWAY_URL, {
            method: 'POST',
            headers: {
              'Authorization': this.API_KEY,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              target: payload.recipientPhone,
              message: message,
            }),
          });

          if (res.ok) {
            const data = await res.json();
            return {
              success: true,
              messageId: data.id || `msg-${Date.now()}`,
              status: 'SENT',
            };
          }
        } else {
          // Simulated mock delivery for staging/testing
          return {
            success: true,
            messageId: `mock-wa-${Date.now()}-${attempts}`,
            status: 'DELIVERED',
          };
        }
      } catch (err) {
        if (attempts >= maxAttempts) {
          return {
            success: false,
            messageId: `err-${Date.now()}`,
            status: 'FAILED',
          };
        }
        // Exponential backoff
        await new Promise((resolve) => setTimeout(resolve, 500 * Math.pow(2, attempts)));
      }
    }

    return { success: false, messageId: '', status: 'FAILED' };
  }

  /**
   * Official Digital Receipt Template for WhatsApp
   */
  static renderReceiptTemplate(payload: WhatsAppReceiptPayload): string {
    return (
      `*BUKTI PEMBAYARAN & STRUK KASIR RESMI*\n` +
      `*HOTEL SINAR HARAPAN (Mitra RedDoorz)*\n` +
      `----------------------------------------\n` +
      `No. Faktur    : *${payload.invoiceNumber}*\n` +
      `Nama Tamu     : ${payload.guestName}\n` +
      `Unit Kamar    : Kamar ${payload.roomNumber} (${payload.roomType})\n` +
      `Periode In    : ${payload.checkInDate}\n` +
      `Periode Out   : ${payload.checkOutDate}\n` +
      `----------------------------------------\n` +
      `Metode Bayar  : ${payload.paymentMethod}\n` +
      `*TOTAL LUNAS  : ${payload.grandTotalStr}*\n` +
      `Status        : *LUNAS (PAID)*\n` +
      `Kasir         : ${payload.receptionistName}\n` +
      `----------------------------------------\n` +
      `Terima kasih telah mempercayakan akomodasi Anda di Hotel Sinar Harapan. ` +
      `Semoga perjalanan Anda menyenangkan!\n\n` +
      `Unduh Faktur PDF Resmi:\n` +
      `${payload.pdfDownloadUrl || 'https://pms.sinarharapan.com/invoice/' + payload.invoiceNumber}`
    );
  }

  /**
   * Dispatches digital receipt/struk to guest WhatsApp
   */
  static async sendReceipt(payload: WhatsAppReceiptPayload): Promise<{ success: boolean; messageId: string; status: string }> {
    const message = this.renderReceiptTemplate(payload);

    let attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        if (process.env.WA_GATEWAY_API_KEY) {
          const res = await fetch(this.GATEWAY_URL, {
            method: 'POST',
            headers: {
              'Authorization': this.API_KEY,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              target: payload.recipientPhone,
              message: message,
            }),
          });

          if (res.ok) {
            const data = await res.json();
            return {
              success: true,
              messageId: data.id || `wa-inv-${Date.now()}`,
              status: 'SENT',
            };
          }
        } else {
          return {
            success: true,
            messageId: `mock-wa-inv-${Date.now()}`,
            status: 'DELIVERED',
          };
        }
      } catch (err) {
        if (attempts >= maxAttempts) {
          return {
            success: false,
            messageId: `err-${Date.now()}`,
            status: 'FAILED',
          };
        }
        await new Promise((resolve) => setTimeout(resolve, 500 * Math.pow(2, attempts)));
      }
    }

    return { success: false, messageId: '', status: 'FAILED' };
  }
}

export interface WhatsAppReceiptPayload {
  recipientPhone: string;
  guestName: string;
  invoiceNumber: string;
  roomNumber: string;
  roomType: string;
  checkInDate: string;
  checkOutDate: string;
  grandTotalStr: string;
  paymentMethod: string;
  receptionistName: string;
  pdfDownloadUrl?: string;
}

