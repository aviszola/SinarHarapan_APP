import { ReportQuerySchema, AuditLogQuerySchema } from '../validators';

/**
 * ReportService: Sinar Harapan PMS
 * Menghandle ekspor laporan (BUG-BE-07) dan kueri audit log dengan pagination aman (BUG-BE-09)
 */
export class ReportService {
  /**
   * BUG-BE-07 FIX: Validasi rentang tanggal ekspor laporan (maksimal 90 hari)
   */
  static validateReportDateRange(query: { startDate: string; endDate: string }) {
    const parseResult = ReportQuerySchema.safeParse(query);
    if (!parseResult.success) {
      const firstIssue = parseResult.error.issues[0];
      throw new Error(`VALIDATION_ERROR: ${firstIssue.message}`);
    }
    return parseResult.data;
  }

  /**
   * BUG-BE-09 FIX: Query Audit Log dengan pembatasan parameter limit maksimal 100
   */
  static async getAuditLogs(prismaClient: any, query: any) {
    const parsed = AuditLogQuerySchema.safeParse(query);
    if (!parsed.success) {
      throw new Error(`VALIDATION_ERROR: ${parsed.error.issues[0].message}`);
    }

    const { page, limit, actionType, userId, startDate, endDate } = parsed.data;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (actionType) where.actionType = actionType;
    if (userId) where.userId = userId;
    if (startDate || endDate) {
      where.createdAt = {};
      if (startDate) where.createdAt.gte = new Date(startDate);
      if (endDate) {
        const end = new Date(endDate);
        end.setHours(23, 59, 59, 999);
        where.createdAt.lte = end;
      }
    }

    const [logs, total] = await Promise.all([
      prismaClient.activityLog.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit, // Dijamin <= 100
        include: {
          user: {
            select: { id: true, username: true, fullName: true, role: true },
          },
        },
      }),
      prismaClient.activityLog.count({ where }),
    ]);

    return {
      logs,
      pagination: {
        page,
        limit,
        totalItems: total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }
}
