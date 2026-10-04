import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '../../../../../lib/prisma';
import { ReservationService } from '../../../../../lib/services/reservation.service';
import { CheckOutSchema } from '../../../../../lib/validators';

/**
 * POST /api/reservations/[id]/checkout
 * BUG-BE-08 FIX: additionalCharges menerima null dari client tanpa melempar validation error
 * BUG-BE-06 FIX: Formula late check-out konsisten Rp 50.000/jam flat
 */
export async function POST(request: NextRequest, { params }: { params: { id: string } }) {
  try {
    const userId = request.headers.get('x-user-id');
    let body = {};

    try {
      body = await request.json();
    } catch {
      // Body kosong diperbolehkan jika tidak ada biaya tambahan
      body = {};
    }

    const validation = CheckOutSchema.safeParse(body);
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

    const { additionalCharges, additionalChargesDetail } = validation.data;

    const result = await ReservationService.checkOut(prisma, params.id, {
      additionalCharges,
      additionalChargesDetail,
      receptionistUserId: userId || undefined,
    });

    return NextResponse.json({
      success: true,
      data: result,
    });
  } catch (err: any) {
    if (err.message.startsWith('NOT_FOUND')) {
      return NextResponse.json(
        { success: false, error: { code: 'NOT_FOUND', message: err.message.replace('NOT_FOUND: ', '') } },
        { status: 404 }
      );
    }
    if (err.message.startsWith('CONFLICT')) {
      return NextResponse.json(
        { success: false, error: { code: 'CONFLICT', message: err.message.replace('CONFLICT: ', '') } },
        { status: 409 }
      );
    }
    console.error('[POST /api/reservations/[id]/checkout] Error:', err);
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: err.message } },
      { status: 500 }
    );
  }
}
