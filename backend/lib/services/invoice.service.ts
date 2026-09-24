export class InvoiceService {
  private static dailySequence = 1;
  private static lastDateStr = '';

  /**
   * Generates formatted invoice number: INV/SH/YYYYMMDD/XXXX
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
   * Calculates late check-out fee based on hourly policy
   * Standard checkout is 12:00 WIB
   */
  static calculateLateFee(expectedCheckOut: Date, actualCheckOut: Date, hourlyRate: number = 50000): { isLate: boolean; lateHours: number; fee: number } {
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
