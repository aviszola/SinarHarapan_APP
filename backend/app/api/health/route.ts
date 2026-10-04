import { NextResponse } from 'next/server';
import { prisma } from '../../../lib/prisma';

/**
 * GET /api/health
 * Endpoint status kesehatan server & koneksi database
 */
export async function GET() {
  try {
    // Test database connection
    await prisma.$queryRaw`SELECT 1`;

    return NextResponse.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'Sinar Harapan PMS Backend',
      database: 'connected',
      version: '1.0.0',
    });
  } catch (err: any) {
    return NextResponse.json(
      {
        status: 'error',
        timestamp: new Date().toISOString(),
        service: 'Sinar Harapan PMS Backend',
        database: 'disconnected',
        error: err.message,
      },
      { status: 503 }
    );
  }
}
