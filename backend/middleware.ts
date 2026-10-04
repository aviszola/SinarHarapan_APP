import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { AuthService } from './lib/services/auth.service';
import { prisma } from './lib/prisma';

// Public endpoints that do not require authentication
const PUBLIC_PATHS = [
  '/api/auth/login',
  '/api/health',
  '/api-docs',
  '/api/docs',
];

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // 1. Skip public paths
  if (PUBLIC_PATHS.some((path) => pathname === path || pathname.startsWith(path + '/'))) {
    return NextResponse.next();
  }

  // 2. Only intercept /api routes
  if (!pathname.startsWith('/api')) {
    return NextResponse.next();
  }

  // 3. Extract Authorization header
  const authHeader = request.headers.get('authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return NextResponse.json(
      {
        success: false,
        error: {
          code: 'UNAUTHORIZED',
          message: 'Token otentikasi tidak ditemukan. Silakan login terlebih dahulu.',
        },
      },
      { status: 401 }
    );
  }

  const token = authHeader.substring(7).trim();

  // 4. BUG-BE-01 FIX: Verifikasi signature JWT dan cek denylist (revoked_tokens)
  const verification = await AuthService.verifyToken(prisma, token);
  if (!verification.valid) {
    return NextResponse.json(
      {
        success: false,
        error: {
          code: 'UNAUTHORIZED',
          message: verification.reason || 'Token otentikasi tidak valid atau telah logout',
        },
      },
      { status: 401 }
    );
  }

  // 5. Teruskan request dengan header kredensial pengguna
  const requestHeaders = new Headers(request.headers);
  if (verification.payload) {
    requestHeaders.set('x-user-id', verification.payload.userId);
    requestHeaders.set('x-user-role', verification.payload.role);
    requestHeaders.set('x-user-name', verification.payload.username);
  }

  return NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  });
}

export const config = {
  matcher: ['/api/:path*'],
};
