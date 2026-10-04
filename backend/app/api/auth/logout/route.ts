import { NextRequest, NextResponse } from 'next/server';
import { AuthService } from '../../../lib/services/auth.service';
import { prisma } from '../../../lib/prisma';

/**
 * POST /api/auth/logout
 * BUG-BE-01 FIX: Token dimasukkan ke denylist (tabel revoked_tokens) sebelum menghapus di client.
 * Setelah logout, token yang sama tidak bisa lagi dipakai akses endpoint manapun.
 */
export async function POST(request: NextRequest) {
  const authHeader = request.headers.get('authorization');

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return NextResponse.json(
      {
        success: false,
        error: { code: 'UNAUTHORIZED', message: 'Token tidak ditemukan di header Authorization' },
      },
      { status: 401 }
    );
  }

  const token = authHeader.substring(7).trim();
  const result = await AuthService.revokeToken(prisma, token);

  if (!result.success) {
    return NextResponse.json(
      {
        success: false,
        error: { code: 'BAD_REQUEST', message: result.message },
      },
      { status: 400 }
    );
  }

  return NextResponse.json(
    {
      success: true,
      data: { message: result.message },
    },
    { status: 200 }
  );
}
