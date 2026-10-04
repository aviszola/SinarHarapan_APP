import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '../../../../lib/prisma';
import { ReportService } from '../../../../lib/services/report.service';

/**
 * GET /api/reports/export
 * BUG-BE-07 FIX: Validasi ketat selisih tanggal (maksimal 90 hari).
 * Mencegah pemanggilan rentang 8 bulan pada dataset besar yang memicu 504 Gateway Timeout.
 */
export async function GET(request: NextRequest) {
  try {
    const role = request.headers.get('x-user-role');
    if (role !== 'MANAGER') {
      return NextResponse.json(
        { success: false, error: { code: 'FORBIDDEN', message: 'Hanya MANAGER yang berhak mengunduh ekspor laporan' } },
        { status: 403 }
      );
    }

    const searchParams = request.nextUrl.searchParams;
    const startDate = searchParams.get('startDate');
    const endDate = searchParams.get('endDate');

    if (!startDate || !endDate) {
      return NextResponse.json(
        { success: false, error: { code: 'VALIDATION_ERROR', message: 'Parameter startDate dan endDate wajib diisi' } },
        { status: 400 }
      );
    }

    // Validasi rentang tanggal <= 90 hari (BUG-BE-07)
    ReportService.validateReportDateRange({ startDate, endDate });

    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    const reservations = await prisma.reservation.findMany({
      where: {
        checkInTime: {
          gte: start,
          lte: end,
        },
      },
      include: {
        guest: true,
        room: true,
      },
      orderBy: { checkInTime: 'asc' },
    });

    const summary = {
      period: { startDate, endDate },
      totalTransactions: reservations.length,
      totalRevenue: reservations.reduce((acc, curr) => acc + Number(curr.totalAmount), 0),
      items: reservations.map((r) => ({
        invoiceNumber: r.invoiceNumber,
        checkInTime: r.checkInTime,
        checkOutTime: r.actualCheckOutTime || r.expectedCheckOutTime,
        roomNumber: r.room.roomNumber,
        guestName: r.guest.fullName,
        bookingSource: r.bookingSource,
        totalAmount: Number(r.totalAmount),
        paymentMethod: r.paymentMethod,
      })),
    };

    return NextResponse.json({
      success: true,
      data: summary,
    });
  } catch (err: any) {
    if (err.message.startsWith('VALIDATION_ERROR')) {
      return NextResponse.json(
        { success: false, error: { code: 'VALIDATION_ERROR', message: err.message.replace('VALIDATION_ERROR: ', '') } },
        { status: 400 }
      );
    }
    console.error('[GET /api/reports/export] Error:', err);
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: err.message } },
      { status: 500 }
    );
  }
}
