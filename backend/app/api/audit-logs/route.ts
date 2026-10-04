import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '../../../lib/prisma';
import { ReportService } from '../../../lib/services/report.service';

/**
 * GET /api/audit-logs
 * BUG-BE-09 FIX: Batas maksimal parameter limit adalah 100 data per request untuk mencegah query overload database.
 */
export async function GET(request: NextRequest) {
  try {
    const role = request.headers.get('x-user-role');
    if (role !== 'MANAGER') {
      return NextResponse.json(
        { success: false, error: { code: 'FORBIDDEN', message: 'Hanya MANAGER yang berhak melihat audit log sistem' } },
        { status: 403 }
      );
    }

    const searchParams = request.nextUrl.searchParams;
    const query = {
      page: searchParams.get('page') ? Number(searchParams.get('page')) : 1,
      limit: searchParams.get('limit') ? Number(searchParams.get('limit')) : 20,
      actionType: searchParams.get('actionType') || undefined,
      userId: searchParams.get('userId') || undefined,
      startDate: searchParams.get('startDate') || undefined,
      endDate: searchParams.get('endDate') || undefined,
    };

    const result = await ReportService.getAuditLogs(prisma, query);

    return NextResponse.json({
      success: true,
      data: result.logs,
      pagination: result.pagination,
    });
  } catch (err: any) {
    if (err.message.startsWith('VALIDATION_ERROR')) {
      return NextResponse.json(
        { success: false, error: { code: 'VALIDATION_ERROR', message: err.message.replace('VALIDATION_ERROR: ', '') } },
        { status: 400 }
      );
    }
    console.error('[GET /api/audit-logs] Error:', err);
    return NextResponse.json(
      { success: false, error: { code: 'INTERNAL_ERROR', message: err.message } },
      { status: 500 }
    );
  }
}
