/**
 * InvoiceService: Sinar Harapan PMS
 * Menghandle generasi nomor faktur resmi dan kalkulasi denda keterlambatan check-out.
 */
export class InvoiceService {
  private static dailySequence = 1;
  private static lastDateStr = '';

  /**
   * Generates formatted invoice number: INV/SH/YYYYMMDD/XXXX
   * BUG-BE-02 FIX: Menggunakan tabel database `invoice_counters` dengan atomik upsert / increment.
   * Tidak akan hilang / reset ke 0001 saat server backend restart di Railway / containerized environment.
   */
  static async generatePersistentInvoiceNumber(prismaClient: any, date: Date = new Date()): Promise<string> {
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    const currentDateStr = `${yyyy}${mm}${dd}`;

    if (!prismaClient || !prismaClient.invoiceCounter) {
      // Fallback in-memory jika client database tidak tersedia (misal di lingkungan test murni tanpa DB)
      return this.generateInvoiceNumber(date);
    }

    // Atomic upsert pada database PostgreSQL / Supabase
    const counter = await prismaClient.invoiceCounter.upsert({
      where: { dateStr: currentDateStr },
      create: {
        dateStr: currentDateStr,
        lastSequence: 1,
      },
      update: {
        lastSequence: {
          increment: 1,
        },
      },
    });

    const seqStr = String(counter.lastSequence).padStart(4, '0');
    return `INV/SH/${currentDateStr}/${seqStr}`;
  }

  /**
   * Generates formatted invoice number in-memory (Legacy / Unit Testing Fallback)
   * Sequence resets daily per Arsitektur.md §4.3
   */
  static generateInvoiceNumber(date: Date = new Date()): string {
    const yyyy = date.getFullYear();
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const dd = String(date.getDate()).padStart(2, '0');
    const currentDateStr = `${yyyy}${mm}${dd}`;

    if (this.lastDateStr !== currentDateStr) {
      this.lastDateStr = currentDateStr;
      this.dailySequence = 1;
    }

    const seqStr = String(this.dailySequence++).padStart(4, '0');
    return `INV/SH/${currentDateStr}/${seqStr}`;
  }

  /**
   * BUG-BE-06: Verifikasi Single Source of Truth Formula Denda Telat Check-out
   * Standar kebijakan Hotel Sinar Harapan: Rp 50.000 / jam flat (bukan 10% per jam).
   * Standard checkout time: 12:00 WIB
   */
  static calculateLateFee(
    expectedCheckOut: Date,
    actualCheckOut: Date,
    hourlyRate: number = 50000
  ): { isLate: boolean; lateHours: number; fee: number } {
    if (actualCheckOut <= expectedCheckOut) {
      return { isLate: false, lateHours: 0, fee: 0 };
    }

    const diffMs = actualCheckOut.getTime() - expectedCheckOut.getTime();
    const hours = Math.ceil(diffMs / (1000 * 60 * 60));
    return {
      isLate: true,
      lateHours: hours,
      fee: hours * hourlyRate,
    };
  }
}
