import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'sinar-harapan-pms-secret-key-2026';

export interface TokenPayload {
  userId: string;
  username: string;
  role: 'RECEPTIONIST' | 'MANAGER';
  jti?: string;
  iat?: number;
  exp?: number;
}

/**
 * AuthService: Sinar Harapan PMS
 * Menghandle otentikasi JWT, penerbitan token, dan denylist / pencabutan token saat logout (BUG-BE-01)
 */
export class AuthService {
  /**
   * Menerbitkan token JWT dengan jti unik
   */
  static issueToken(user: { id: string; username: string; role: 'RECEPTIONIST' | 'MANAGER' }): { token: string; expiresIn: number } {
    const jti = `${user.id}-${Date.now()}-${Math.random().toString(36).substring(2, 9)}`;
    const expiresIn = 43200; // 12 jam (dalam detik)

    const payload: TokenPayload = {
      userId: user.id,
      username: user.username,
      role: user.role,
      jti,
    };

    const token = jwt.sign(payload, JWT_SECRET, {
      expiresIn,
    });

    return { token, expiresIn };
  }

  /**
   * BUG-BE-01 FIX: Logout dan masukkan token ke tabel revoked_tokens (denylist)
   */
  static async revokeToken(prismaClient: any, token: string): Promise<{ success: boolean; message: string }> {
    try {
      // Decode token tanpa throw error walau sudah expired
      const decoded = jwt.decode(token) as TokenPayload | null;
      if (!decoded) {
        return { success: false, message: 'Format token tidak valid' };
      }

      const jti = decoded.jti || token.slice(-32); // Fallback ke signature jika jti tidak ada
      const expiresAt = decoded.exp ? new Date(decoded.exp * 1000) : new Date(Date.now() + 43200 * 1000);

      if (prismaClient && prismaClient.revokedToken) {
        await prismaClient.revokedToken.upsert({
          where: { tokenJti: jti },
          create: {
            tokenJti: jti,
            userId: decoded.userId || null,
            expiresAt,
          },
          update: {},
        });
      }

      return { success: true, message: 'Berhasil logout, token telah dibatalkan' };
    } catch (err: any) {
      console.error('[AuthService.revokeToken] Error revoking token:', err);
      return { success: false, message: 'Gagal membatalkan token' };
    }
  }

  /**
   * BUG-BE-01 FIX: Validasi token apakah masih berlaku dan TIDAK ADA di denylist (revoked_tokens)
   */
  static async verifyToken(prismaClient: any, token: string): Promise<{ valid: boolean; payload?: TokenPayload; reason?: string }> {
    try {
      // 1. Verifikasi cryptographic signature JWT
      const payload = jwt.verify(token, JWT_SECRET) as TokenPayload;

      // 2. Cek apakah token sudah dicabut (ada di database revoked_tokens)
      const jti = payload.jti || token.slice(-32);
      if (prismaClient && prismaClient.revokedToken) {
        const revoked = await prismaClient.revokedToken.findUnique({
          where: { tokenJti: jti },
        });

        if (revoked) {
          return {
            valid: false,
            reason: 'TOKEN_REVOKED: Token ini telah logout dan tidak dapat digunakan lagi (401 Unauthorized)',
          };
        }
      }

      return { valid: true, payload };
    } catch (err: any) {
      if (err.name === 'TokenExpiredError') {
        return { valid: false, reason: 'TOKEN_EXPIRED: Masa berlaku token telah habis' };
      }
      return { valid: false, reason: 'TOKEN_INVALID: Signature atau format token tidak valid' };
    }
  }
}
