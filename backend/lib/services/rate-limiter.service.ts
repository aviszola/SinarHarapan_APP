/**
 * RateLimiterService: Sinar Harapan PMS
 * Menghandle rate limiting in-memory per alamat IP untuk mencegah serangan brute-force
 * Sesuai spesifikasi Arsitektur §3.3 & security.md §4.3 (Maks 5 percobaan per menit per IP)
 * BUG-BE-10 FIX
 */

interface RateLimitRecord {
  count: number;
  resetAt: number;
}

export class RateLimiterService {
  private static store = new Map<string, RateLimitRecord>();

  /**
   * Cek apakah IP/key melebihi batas request
   * @param key Identifier (misal: client IP)
   * @param maxAttempts Batas maksimal percobaan (default: 5)
   * @param windowMs Jendela waktu dalam milidetik (default: 60.000 ms = 1 menit)
   */
  static checkRateLimit(
    key: string,
    maxAttempts: number = 5,
    windowMs: number = 60000
  ): { isLimited: boolean; remaining: number; resetInSec: number; currentCount: number } {
    const now = Date.now();
    const record = this.store.get(key);

    if (!record || now > record.resetAt) {
      // Jendela baru dimulai
      return {
        isLimited: false,
        remaining: maxAttempts,
        resetInSec: Math.ceil(windowMs / 1000),
        currentCount: 0,
      };
    }

    const resetInSec = Math.max(1, Math.ceil((record.resetAt - now) / 1000));
    if (record.count >= maxAttempts) {
      return {
        isLimited: true,
        remaining: 0,
        resetInSec,
        currentCount: record.count,
      };
    }

    return {
      isLimited: false,
      remaining: maxAttempts - record.count,
      resetInSec,
      currentCount: record.count,
    };
  }

  /**
   * Catat satu kali percobaan (gagal atau request masuk)
   */
  static recordAttempt(
    key: string,
    maxAttempts: number = 5,
    windowMs: number = 60000
  ): { isLimited: boolean; currentCount: number; resetInSec: number } {
    const now = Date.now();
    const record = this.store.get(key);

    if (!record || now > record.resetAt) {
      this.store.set(key, { count: 1, resetAt: now + windowMs });
      return { isLimited: false, currentCount: 1, resetInSec: Math.ceil(windowMs / 1000) };
    }

    record.count += 1;
    const resetInSec = Math.max(1, Math.ceil((record.resetAt - now) / 1000));
    const isLimited = record.count > maxAttempts;

    return { isLimited, currentCount: record.count, resetInSec };
  }

  /**
   * Reset hitungan saat pengguna berhasil login dengan benar
   */
  static reset(key: string): void {
    this.store.delete(key);
  }

  /**
   * Bersihkan data yang sudah kedaluwarsa untuk mencegah memory leak
   */
  static cleanup(): void {
    const now = Date.now();
    for (const [key, record] of this.store.entries()) {
      if (now > record.resetAt) {
        this.store.delete(key);
      }
    }
  }

  /**
   * Bersihkan semua data (untuk unit testing)
   */
  static clearAll(): void {
    this.store.clear();
  }
}
