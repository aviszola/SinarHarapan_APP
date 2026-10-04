import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '../../../lib/prisma';
import { ReservationService } from '../../../lib/services/reservation.service';
import { CheckInSchema } from '../../../lib/validators';

/**
 * POST /api/reservations
 * BUG-BE-02: Invoice number atomik persisten via database
 * BUG-BE-03: Repeat guest didukung penuh (cari NIK dulu, update data, reuse guest.id)
 */
export async function POST(request: NextRequest) {
  try {
    const userId = request.headers.get('x-user-id');
    const body = await request.json();

    const validation = CheckInSchema.safeParse(body);
    if (!validation.success) {
      return NextResponse.json(
        {
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: validation.error.issues[0].message,
            fields: validation.error.issues,
          },
        },
        { status: 400 }
      );
    }

    // Ambil harga kamar jika tidak dikirim
    let roomRate = body.roomRate;
    if (!roomRate) {
      const room = await prisma.room.findUnique({
        where: { id: validation.data.roomId },
      });
      if (room) {
        roomRate = Number(room.basePricePerNight);
      } else {
        return NextResponse.json(
          { success: false, error: { code: 'NOT_FOUND', message: 'Kamar tidak ditemukan' } },
          { status: 404 }
        );
      }
    }

    const checkInDto = {
      ...validation.data,
      roomRate,
      receptionistUserId: userId || undefined,
    };

    const result = await ReservationService.checkIn(prisma, checkInDto);

    return NextResponse.json(
      {
        success: true,
        data: result,
      },
      { status: 201 }
    );
  } catch (err: any) {
    if (err.message.startsWith('CONFLICT')) {
      return NextResponse.json(
        { success: false, error: { code: 'CONFLICT', message: err.message.replace('CONFLICT: ', '') } },
        { status: 409 }
      );
    }
    if (err.message.startsWith('NOT_FOUND')) {
      return NextResponse.json(
        { success: false, error: { code: 'NOT_FOUND', message: err.message.replace('NOT_FOUND: ', '') } },
        { status: 404 }
      );
    }
    console.error('[POST /api/reservations] Error:', err);
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: err.message } },
      { status: 500 }
    );
  }
}

/**
 * GET /api/reservations
 */
export async function GET(request: NextRequest) {
  try {
    const searchParams = request.nextUrl.searchParams;
    const status = searchParams.get('status');
    const page = searchParams.get('page') ? Number(searchParams.get('page')) : 1;
    const limit = Math.min(searchParams.get('limit') ? Number(searchParams.get('limit')) : 50, 100);
    const skip = (page - 1) * limit;

    const where: any = {};
    if (status === 'ACTIVE') {
      where.actualCheckOutTime = null;
    } else if (status === 'COMPLETED') {
      where.actualCheckOutTime = { not: null };
    }

    const [reservations, total] = await Promise.all([
      prisma.reservation.findMany({
        where,
        include: {
          guest: true,
          room: true,
          receptionist: {
            select: { id: true, fullName: true, username: true },
          },
        },
        orderBy: { checkInTime: 'desc' },
        skip,
        take: limit,
      }),
      prisma.reservation.count({ where }),
    ]);

    return NextResponse.json({
      success: true,
      data: reservations,
      pagination: {
        page,
        limit,
        totalItems: total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (err: any) {
    console.error('[GET /api/reservations] Error:', err);
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: err.message } },
      { status: 500 }
    );
  }
}
