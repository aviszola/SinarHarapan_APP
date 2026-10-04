import { NextRequest, NextResponse } from 'next/server';
import bcrypt from 'bcryptjs';
import { prisma } from '../../../lib/prisma';
import { LoginSchema } from '../../../lib/validators';
import { AuthService } from '../../../lib/services/auth.service';
import { RateLimiterService } from '../../../lib/services/rate-limiter.service';

/**
 * POST /api/auth/login
 * BUG-BE-10 FIX: Rate limiting 5x per menit per IP (Arsitektur §3.3 & security.md §4.3)
 */
export async function POST(request: NextRequest) {
  try {
    // 1. Ekstrak Client IP untuk penegakan Rate Limiting (BUG-BE-10)
    const forwarded = request.headers.get('x-forwarded-for');
    const realIp = request.headers.get('x-real-ip');
    const clientIp = forwarded ? forwarded.split(',')[0].trim() : (realIp || '127.0.0.1');

    // 2. Cek apakah IP ini sudah terblokir oleh rate limiter
    const rateCheck = RateLimiterService.checkRateLimit(clientIp, 5, 60000);
    if (rateCheck.isLimited) {
      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'RATE_LIMITED',
            message: `Terlalu banyak percobaan login. Batas maksimal 5 kali per menit per alamat IP (429 RATE_LIMITED). Silakan coba lagi dalam ${rateCheck.resetInSec} detik.`,
          },
        },
        {
          status: 429,
          headers: {
            'Retry-After': String(rateCheck.resetInSec),
            'X-RateLimit-Limit': '5',
            'X-RateLimit-Remaining': '0',
            'X-RateLimit-Reset': String(rateCheck.resetInSec),
          },
        }
      );
    }

    const body = await request.json();
    const validation = LoginSchema.safeParse(body);

    if (!validation.success) {
      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: validation.error.issues[0].message,
          },
        },
        { status: 400 }
      );
    }

    const { username, password } = validation.data;

    // Cari user di database
    const user = await prisma.user.findUnique({
      where: { username },
    });

    if (!user || !user.isActive) {
      // Catat percobaan gagal dan rekam ke rate limiter
      const attempt = RateLimiterService.recordAttempt(clientIp, 5, 60000);
      try {
        await prisma.activityLog.create({
          data: {
            userId: user?.id || null,
            actionType: 'LOGIN_FAILED',
            resourceType: 'user',
            resourceId: user?.id || 'unknown',
            details: { username, clientIp, attemptCount: attempt.currentCount, reason: 'USER_NOT_FOUND_OR_INACTIVE' },
          },
        });
      } catch (logErr) {
        console.error('[RateLimit/AuditLog] Failed to log LOGIN_FAILED:', logErr);
      }

      if (attempt.isLimited) {
        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'RATE_LIMITED',
              message: `Batas percobaan login terlampaui (5x/menit). Akun/IP dibatasi sementara (429 RATE_LIMITED). Coba lagi dalam ${attempt.resetInSec} detik.`,
            },
          },
          { status: 429, headers: { 'Retry-After': String(attempt.resetInSec) } }
        );
      }

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'UNAUTHORIZED',
            message: 'Username atau password salah',
          },
        },
        { status: 401 }
      );
    }

    // Verifikasi password hash
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      // Catat percobaan gagal dan rekam ke rate limiter
      const attempt = RateLimiterService.recordAttempt(clientIp, 5, 60000);
      try {
        await prisma.activityLog.create({
          data: {
            userId: user.id,
            actionType: 'LOGIN_FAILED',
            resourceType: 'user',
            resourceId: user.id,
            details: { username: user.username, clientIp, attemptCount: attempt.currentCount, reason: 'INVALID_PASSWORD' },
          },
        });
      } catch (logErr) {
        console.error('[RateLimit/AuditLog] Failed to log LOGIN_FAILED:', logErr);
      }

      if (attempt.isLimited) {
        return NextResponse.json(
          {
            success: false,
            error: {
              code: 'RATE_LIMITED',
              message: `Batas percobaan login terlampaui (5x/menit). Akun/IP dibatasi sementara (429 RATE_LIMITED). Coba lagi dalam ${attempt.resetInSec} detik.`,
            },
          },
          { status: 429, headers: { 'Retry-After': String(attempt.resetInSec) } }
        );
      }

      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'UNAUTHORIZED',
            message: 'Username atau password salah',
          },
        },
        { status: 401 }
      );
    }

    // Login sukses: reset counter rate limiter untuk IP ini
    RateLimiterService.reset(clientIp);

    // Terbitkan JWT
    const { token, expiresIn } = AuthService.issueToken({
      id: user.id,
      username: user.username,
      role: user.role,
    });

    // Catat ke audit log
    await prisma.activityLog.create({
      data: {
        userId: user.id,
        actionType: 'LOGIN',
        resourceType: 'user',
        resourceId: user.id,
        details: { username: user.username, role: user.role, clientIp },
      },
    });

    return NextResponse.json({
      success: true,
      data: {
        token,
        expiresIn,
        user: {
          id: user.id,
          fullName: user.fullName,
          role: user.role,
        },
      },
    });
  } catch (err: any) {
    console.error('[POST /api/auth/login] Error:', err);
    return NextResponse.json(
      {
        success: false,
        error: { code: 'INTERNAL_ERROR', message: 'Terjadi kesalahan internal pada server' },
      },
      { status: 500 }
    );
  }
}

