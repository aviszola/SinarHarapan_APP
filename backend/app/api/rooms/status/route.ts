import { NextResponse } from 'next/server';
import { prisma } from '../../../../lib/prisma';

/**
 * GET /api/rooms/status
 * Endpoint ringan khusus polling status grid kamar oleh frontend Flutter (tiap 15 detik)
 */
export async function GET() {
  try {
    const rooms = await prisma.room.findMany({
      where: { deletedAt: null },
      select: {
        id: true,
        roomNumber: true,
        status: true,
        updatedAt: true,
      },
      orderBy: [{ floor: 'asc' }, { roomNumber: 'asc' }],
    });

    return NextResponse.json({
      success: true,
      data: rooms,
    });
  } catch (err: any) {
    console.error('[GET /api/rooms/status] Error:', err);
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: err.message } },
      { status: 500 }
    );
  }
}
