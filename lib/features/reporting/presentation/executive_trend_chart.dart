import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';

enum ChartMetricType {
  revenue,
  occupancy,
  guests,
}

enum ChartPeriod {
  thisMonthVsLast,
  thisWeekVsLast,
}

class ExecutiveTrendChart extends StatefulWidget {
  final NumberFormat currencyFormatter;

  const ExecutiveTrendChart({
    super.key,
    required this.currencyFormatter,
  });

  @override
  State<ExecutiveTrendChart> createState() => _ExecutiveTrendChartState();
}

class _ExecutiveTrendChartState extends State<ExecutiveTrendChart> {
  ChartMetricType _selectedMetric = ChartMetricType.revenue;
  bool _showPastPeriod = true;

  // Sampled days across a 30-day month
  static const List<double> _days = [
    2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30
  ];

  // Revenue in millions IDR
  static const List<double> _currentRevenue = [
    1.2, 1.5, 1.8, 2.1, 1.9, 2.4, 3.1, 2.8, 3.2, 2.7, 3.5, 3.8, 3.2, 4.1, 3.9
  ];
  static const List<double> _pastRevenue = [
    1.0, 1.2, 1.4, 1.8, 1.6, 1.9, 2.2, 2.0, 2.5, 2.1, 2.7, 2.9, 2.5, 3.0, 3.1
  ];

  // Occupancy in percentage
  static const List<double> _currentOccupancy = [
    50, 57, 64, 71, 64, 78, 92, 85, 93, 78, 95, 100, 85, 100, 93
  ];
  static const List<double> _pastOccupancy = [
    42, 48, 50, 60, 55, 62, 70, 65, 75, 68, 80, 82, 72, 85, 82
  ];

  // Guest check-ins count
  static const List<double> _currentGuests = [
    5, 6, 8, 9, 8, 10, 14, 12, 15, 11, 16, 17, 13, 18, 16
  ];
  static const List<double> _pastGuests = [
    4, 5, 6, 7, 6, 8, 10, 9, 11, 9, 12, 13, 10, 13, 14
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Controls
          _buildHeader(),
          const SizedBox(height: AppSpacing.lg),

          // High-level KPI comparisons
          _buildComparisonSummary(),
          const SizedBox(height: AppSpacing.lg),

          // The Interactive Line Chart
          SizedBox(
            height: 320,
            child: LineChart(_buildChartData()),
          ),

          const SizedBox(height: AppSpacing.md),

          // Footer Legend & Insights
          _buildFooterLegend(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;
        final titleContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.orange500.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'KOMPARATIF HISTORIS & REALTIME',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.orange600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up, size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text(
                        '+18.2% vs Bulan Lalu',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tren Pertumbuhan & Performa Operasional Multi-Dimensi',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Analisis komparasi garis data berjalan (sekarang) versus data historis (masa lalu) untuk proyeksi bisnis hotel.',
              style: AppTypography.bodySm.copyWith(color: AppColors.textSecondary),
            ),
          ],
        );

        final controls = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMetricChip(
              icon: Icons.attach_money,
              label: 'Pendapatan',
              type: ChartMetricType.revenue,
            ),
            _buildMetricChip(
              icon: Icons.bed_outlined,
              label: 'Okupansi %',
              type: ChartMetricType.occupancy,
            ),
            _buildMetricChip(
              icon: Icons.people_outline,
              label: 'Volume Tamu',
              type: ChartMetricType.guests,
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleContent,
              const SizedBox(height: AppSpacing.md),
              controls,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: titleContent),
            const SizedBox(width: AppSpacing.md),
            controls,
          ],
        );
      },
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required ChartMetricType type,
  }) {
    final isSelected = _selectedMetric == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedMetric = type),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navy900 : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.navy900 : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonSummary() {
    String currentSummary;
    String pastSummary;
    String delta;

    switch (_selectedMetric) {
      case ChartMetricType.revenue:
        currentSummary = widget.currencyFormatter.format(48750000);
        pastSummary = widget.currencyFormatter.format(41250000);
        delta = '+Rp 7.500.000 (+18.2%)';
        break;
      case ChartMetricType.occupancy:
        currentSummary = '79.2%';
        pastSummary = '65.4%';
        delta = '+13.8% pts';
        break;
      case ChartMetricType.guests:
        currentSummary = '182 Tamu';
        pastSummary = '151 Tamu';
        delta = '+31 Check-In (+20.5%)';
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;

        final currentItem = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.orange500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Periode Sekarang (September 2026)',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        currentSummary,
                        style: AppTypography.h3.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          delta,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        final pastItem = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.navy700.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Periode Masa Lalu (Agustus 2026)',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pastSummary,
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final compareChip = FilterChip(
          selected: _showPastPeriod,
          label: const Text('Bandingkan Periode Lalu'),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _showPastPeriod ? AppColors.navy900 : AppColors.textSecondary,
          ),
          selectedColor: AppColors.orange500.withValues(alpha: 0.15),
          checkmarkColor: AppColors.orange600,
          onSelected: (val) => setState(() => _showPastPeriod = val),
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    currentItem,
                    const SizedBox(height: 12),
                    pastItem,
                    const SizedBox(height: 12),
                    compareChip,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: currentItem),
                    Container(
                      height: 32,
                      width: 1,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(child: pastItem),
                    const SizedBox(width: 16),
                    compareChip,
                  ],
                ),
        );
      },
    );
  }

  LineChartData _buildChartData() {
    List<double> curData;
    List<double> pastData;
    double maxY;

    switch (_selectedMetric) {
      case ChartMetricType.revenue:
        curData = _currentRevenue;
        pastData = _pastRevenue;
        maxY = 5.0; // Million IDR
        break;
      case ChartMetricType.occupancy:
        curData = _currentOccupancy;
        pastData = _pastOccupancy;
        maxY = 110.0; // %
        break;
      case ChartMetricType.guests:
        curData = _currentGuests;
        pastData = _pastGuests;
        maxY = 22.0; // Guests
        break;
    }

    final currentSpots = <FlSpot>[];
    final pastSpots = <FlSpot>[];

    for (int i = 0; i < _days.length; i++) {
      currentSpots.add(FlSpot(_days[i], curData[i]));
      pastSpots.add(FlSpot(_days[i], pastData[i]));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: maxY / 5,
        verticalInterval: 5,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.border.withValues(alpha: 0.6),
          strokeWidth: 1,
          dashArray: [4, 4],
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: AppColors.border.withValues(alpha: 0.3),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 2,
            getTitlesWidget: (value, meta) {
              final day = value.toInt();
              if (day % 4 == 0 || day == 2 || day == 30) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Tgl $day',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 5,
            reservedSize: _selectedMetric == ChartMetricType.revenue ? 68 : 45,
            getTitlesWidget: (value, meta) {
              if (value < 0) return const SizedBox();
              String text;
              switch (_selectedMetric) {
                case ChartMetricType.revenue:
                  text = 'Rp ${value.toStringAsFixed(1)}Jt';
                  break;
                case ChartMetricType.occupancy:
                  text = '${value.toInt()}%';
                  break;
                case ChartMetricType.guests:
                  text = '${value.toInt()} pax';
                  break;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Text(
                  text,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          top: BorderSide.none,
          right: BorderSide.none,
        ),
      ),
      minX: 1,
      maxX: 31,
      minY: 0,
      maxY: maxY,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => AppColors.navy900.withValues(alpha: 0.95),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final isCurrent = barSpot.barIndex == 0;
              final day = barSpot.x.toInt();
              String valStr;
              switch (_selectedMetric) {
                case ChartMetricType.revenue:
                  valStr = 'Rp ${(barSpot.y * 1000000).toInt()}';
                  break;
                case ChartMetricType.occupancy:
                  valStr = '${barSpot.y.toStringAsFixed(1)}%';
                  break;
                case ChartMetricType.guests:
                  valStr = '${barSpot.y.toInt()} Tamu';
                  break;
              }

              final periodName = isCurrent ? 'September (Kini)' : 'Agustus (Lalu)';
              return LineTooltipItem(
                'Tgl $day Sep\n$periodName: $valStr',
                TextStyle(
                  color: isCurrent ? AppColors.orange500 : Colors.white70,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        // 1. Current Period (Solid Orange with gradient area fill)
        LineChartBarData(
          spots: currentSpots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppColors.orange500,
          barWidth: 3.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2.5,
                strokeColor: AppColors.orange500,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.orange500.withValues(alpha: 0.28),
                AppColors.orange500.withValues(alpha: 0.02),
              ],
            ),
          ),
        ),

        // 2. Past Period (Dashed Navy/Slate with no heavy fill)
        if (_showPastPeriod)
          LineChartBarData(
            spots: pastSpots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.navy700.withValues(alpha: 0.45),
            barWidth: 2.2,
            dashArray: [6, 4],
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 2.5,
                  color: AppColors.navy700.withValues(alpha: 0.6),
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
      ],
    );
  }

  Widget _buildFooterLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Current Legend
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.orange500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Periode Sekarang (Sep 2026)',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.navy900,
              ),
            ),
          ],
        ),

        // Past Legend
        if (_showPastPeriod)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.navy700.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Periode Masa Lalu (Ags 2026)',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

        // High Peak Observation
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 14, color: AppColors.orange500),
              const SizedBox(width: 6),
              Text(
                'Puncak: 24 Sep (Okupansi 100% - Rp 4.100.000)',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
