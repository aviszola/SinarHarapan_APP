import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';

enum ChartMetricType { revenue, occupancy, guests }

enum ChartPeriod {
  week('Mingguan', '7 Hari'),
  month('Bulanan', '30 Hari'),
  year('Tahunan', '12 Bulan');

  final String label;
  final String sublabel;
  const ChartPeriod(this.label, this.sublabel);
}

class ExecutiveTrendChart extends StatefulWidget {
  final NumberFormat currencyFormatter;

  const ExecutiveTrendChart({super.key, required this.currencyFormatter});

  @override
  State<ExecutiveTrendChart> createState() => _ExecutiveTrendChartState();
}

class _ExecutiveTrendChartState extends State<ExecutiveTrendChart> {
  ChartMetricType _selectedMetric = ChartMetricType.revenue;
  ChartPeriod _selectedPeriod = ChartPeriod.month;
  bool _showPastPeriod = true;

  // ── 1. MONTH DATA (30 Days sampled every 2 days) ─────────────────────────
  static const List<double> _monthDays = [
    2,
    4,
    6,
    8,
    10,
    12,
    14,
    16,
    18,
    20,
    22,
    24,
    26,
    28,
    30,
  ];
  static const List<double> _monthCurrentRevenue = [
    1.2,
    1.5,
    1.8,
    2.1,
    1.9,
    2.4,
    3.1,
    2.8,
    3.2,
    2.7,
    3.5,
    3.8,
    3.2,
    4.1,
    3.9,
  ];
  static const List<double> _monthPastRevenue = [
    1.0,
    1.2,
    1.4,
    1.8,
    1.6,
    1.9,
    2.2,
    2.0,
    2.5,
    2.1,
    2.7,
    2.9,
    2.5,
    3.0,
    3.1,
  ];
  static const List<double> _monthCurrentOccupancy = [
    50,
    57,
    64,
    71,
    64,
    78,
    92,
    85,
    93,
    78,
    95,
    100,
    85,
    100,
    93,
  ];
  static const List<double> _monthPastOccupancy = [
    42,
    48,
    50,
    60,
    55,
    62,
    70,
    65,
    75,
    68,
    80,
    82,
    72,
    85,
    82,
  ];
  static const List<double> _monthCurrentGuests = [
    5,
    6,
    8,
    9,
    8,
    10,
    14,
    12,
    15,
    11,
    16,
    17,
    13,
    18,
    16,
  ];
  static const List<double> _monthPastGuests = [
    4,
    5,
    6,
    7,
    6,
    8,
    10,
    9,
    11,
    9,
    12,
    13,
    10,
    13,
    14,
  ];

  // ── 2. WEEK DATA (7 Days: Senin - Minggu) ─────────────────────────────────
  static const List<double> _weekDays = [1, 2, 3, 4, 5, 6, 7];
  static const List<double> _weekCurrentRevenue = [
    1.8,
    2.4,
    2.8,
    3.2,
    3.8,
    4.1,
    3.9,
  ];
  static const List<double> _weekPastRevenue = [
    1.5,
    2.0,
    2.4,
    2.7,
    3.1,
    3.5,
    3.3,
  ];
  static const List<double> _weekCurrentOccupancy = [
    64,
    78,
    85,
    92,
    95,
    100,
    93,
  ];
  static const List<double> _weekPastOccupancy = [55, 68, 72, 78, 82, 88, 80];
  static const List<double> _weekCurrentGuests = [8, 10, 12, 14, 16, 18, 16];
  static const List<double> _weekPastGuests = [6, 8, 10, 12, 13, 15, 14];

  // ── 3. YEAR DATA (12 Months: Jan - Des) ──────────────────────────────────
  static const List<double> _yearMonths = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
  ];
  static const List<double> _yearCurrentRevenue = [
    38.0,
    42.0,
    45.0,
    52.0,
    48.0,
    55.0,
    58.0,
    50.0,
    48.75,
    53.0,
    56.0,
    62.0,
  ];
  static const List<double> _yearPastRevenue = [
    32.0,
    36.0,
    39.0,
    45.0,
    41.0,
    48.0,
    50.0,
    44.0,
    41.25,
    46.0,
    49.0,
    54.0,
  ];
  static const List<double> _yearCurrentOccupancy = [
    68,
    72,
    75,
    82,
    78,
    88,
    91,
    80,
    79.2,
    84,
    87,
    94,
  ];
  static const List<double> _yearPastOccupancy = [
    60,
    64,
    66,
    72,
    69,
    77,
    80,
    71,
    65.4,
    74,
    76,
    83,
  ];
  static const List<double> _yearCurrentGuests = [
    140,
    155,
    168,
    195,
    180,
    210,
    225,
    190,
    182,
    200,
    215,
    240,
  ];
  static const List<double> _yearPastGuests = [
    120,
    135,
    145,
    170,
    155,
    180,
    195,
    165,
    151,
    175,
    185,
    205,
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Timeframe + Metric Switchers
          _buildHeader(),
          const SizedBox(height: AppSpacing.lg),

          // High-level KPI comparisons
          _buildComparisonSummary(),
          const SizedBox(height: AppSpacing.lg),

          // The Interactive Line Chart
          SizedBox(
            height: isMobile ? 260 : 320,
            child: LineChart(_buildChartData(isMobile: isMobile)),
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
        final isCompact = constraints.maxWidth < 840;

        final badgeText = switch (_selectedPeriod) {
          ChartPeriod.week => '+18.9% vs Minggu Lalu',
          ChartPeriod.month => '+18.2% vs Bulan Lalu',
          ChartPeriod.year => '+16.9% vs Tahun Lalu',
        };

        final titleContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.orange500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'KOMPARASI HISTORIS',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.orange600,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.availableBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        size: 14,
                        color: AppColors.statusAvailable,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.availableText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tren Pendapatan & Okupansi',
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Perbandingan performa operasional periode berjalan terhadap periode sebelumnya.',
              style: AppTypography.bodySm.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );

        final controls = Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // ── Timeframe Selector (Week / Month / Year) ───────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.navy50,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPeriodPill(
                      ChartPeriod.week,
                      Icons.view_week_outlined,
                    ),
                    _buildPeriodPill(
                      ChartPeriod.month,
                      Icons.calendar_view_month_outlined,
                    ),
                    _buildPeriodPill(
                      ChartPeriod.year,
                      Icons.calendar_today_outlined,
                    ),
                  ],
                ),
              ),
            ),

            // ── Metric Selector ───────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 6,
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

  Widget _buildPeriodPill(ChartPeriod period, IconData icon) {
    final isSelected = _selectedPeriod == period;
    return InkWell(
      onTap: () => setState(() => _selectedPeriod = period),
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy900 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.navy900.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.navy700,
            ),
            const SizedBox(width: 4),
            Text(
              period.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.navy700,
              ),
            ),
          ],
        ),
      ),
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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
                size: 14,
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
    String currentPeriodTitle;
    String pastPeriodTitle;
    String currentSummary;
    String pastSummary;
    String delta;

    switch (_selectedPeriod) {
      case ChartPeriod.week:
        currentPeriodTitle = 'Periode Sekarang (Minggu Ini: 18 - 24 Sep 2026)';
        pastPeriodTitle = 'Periode Masa Lalu (Minggu Lalu: 11 - 17 Sep 2026)';
        switch (_selectedMetric) {
          case ChartMetricType.revenue:
            currentSummary = widget.currencyFormatter.format(22000000);
            pastSummary = widget.currencyFormatter.format(18500000);
            delta = '+Rp 3.500.000 (+18.9%)';
            break;
          case ChartMetricType.occupancy:
            currentSummary = '86.7%';
            pastSummary = '72.1%';
            delta = '+14.6% pts';
            break;
          case ChartMetricType.guests:
            currentSummary = '94 Tamu';
            pastSummary = '78 Tamu';
            delta = '+16 Check-In (+20.5%)';
            break;
        }
        break;

      case ChartPeriod.month:
        currentPeriodTitle = 'Periode Sekarang (September 2026)';
        pastPeriodTitle = 'Periode Masa Lalu (Agustus 2026)';
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
        break;

      case ChartPeriod.year:
        currentPeriodTitle = 'Periode Sekarang (Tahun Berjalan 2026)';
        pastPeriodTitle = 'Periode Masa Lalu (Tahun Lalu 2025)';
        switch (_selectedMetric) {
          case ChartMetricType.revenue:
            currentSummary = widget.currencyFormatter.format(608750000);
            pastSummary = widget.currencyFormatter.format(520250000);
            delta = '+Rp 88.500.000 (+16.9%)';
            break;
          case ChartMetricType.occupancy:
            currentSummary = '81.5%';
            pastSummary = '71.2%';
            delta = '+10.3% pts';
            break;
          case ChartMetricType.guests:
            currentSummary = '2.302 Tamu';
            pastSummary = '1.981 Tamu';
            delta = '+321 Check-In (+16.2%)';
            break;
        }
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
                    currentPeriodTitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.availableBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          delta,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.availableText,
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
                    pastPeriodTitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
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
            color: _showPastPeriod
                ? AppColors.navy900
                : AppColors.textSecondary,
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

  LineChartData _buildChartData({bool isMobile = false}) {
    List<double> curData;
    List<double> pastData;
    List<double> xPoints;
    double minX;
    double maxX;
    double maxY;

    switch (_selectedPeriod) {
      case ChartPeriod.week:
        xPoints = _weekDays;
        minX = 0.5;
        maxX = 7.5;
        switch (_selectedMetric) {
          case ChartMetricType.revenue:
            curData = _weekCurrentRevenue;
            pastData = _weekPastRevenue;
            maxY = 5.0; // Million IDR
            break;
          case ChartMetricType.occupancy:
            curData = _weekCurrentOccupancy;
            pastData = _weekPastOccupancy;
            maxY = 110.0; // %
            break;
          case ChartMetricType.guests:
            curData = _weekCurrentGuests;
            pastData = _weekPastGuests;
            maxY = 22.0; // Guests
            break;
        }
        break;

      case ChartPeriod.month:
        xPoints = _monthDays;
        minX = 1;
        maxX = 31;
        switch (_selectedMetric) {
          case ChartMetricType.revenue:
            curData = _monthCurrentRevenue;
            pastData = _monthPastRevenue;
            maxY = 5.0; // Million IDR
            break;
          case ChartMetricType.occupancy:
            curData = _monthCurrentOccupancy;
            pastData = _monthPastOccupancy;
            maxY = 110.0; // %
            break;
          case ChartMetricType.guests:
            curData = _monthCurrentGuests;
            pastData = _monthPastGuests;
            maxY = 22.0; // Guests
            break;
        }
        break;

      case ChartPeriod.year:
        xPoints = _yearMonths;
        minX = 0.5;
        maxX = 12.5;
        switch (_selectedMetric) {
          case ChartMetricType.revenue:
            curData = _yearCurrentRevenue;
            pastData = _yearPastRevenue;
            maxY = 70.0; // Million IDR
            break;
          case ChartMetricType.occupancy:
            curData = _yearCurrentOccupancy;
            pastData = _yearPastOccupancy;
            maxY = 110.0; // %
            break;
          case ChartMetricType.guests:
            curData = _yearCurrentGuests;
            pastData = _yearPastGuests;
            maxY = 260.0; // Guests
            break;
        }
        break;
    }

    final currentSpots = <FlSpot>[];
    final pastSpots = <FlSpot>[];

    for (int i = 0; i < xPoints.length; i++) {
      currentSpots.add(FlSpot(xPoints[i], curData[i]));
      pastSpots.add(FlSpot(xPoints[i], pastData[i]));
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: maxY / 5,
        verticalInterval: _selectedPeriod == ChartPeriod.month ? 5 : 1,
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              switch (_selectedPeriod) {
                case ChartPeriod.week:
                  const daysOfWeek = [
                    'Sen',
                    'Sel',
                    'Rab',
                    'Kam',
                    'Jum',
                    'Sab',
                    'Min',
                  ];
                  if (idx >= 1 && idx <= 7) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        daysOfWeek[idx - 1],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();

                case ChartPeriod.month:
                  if (idx % 4 == 0 || idx == 2 || idx == 30) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Tgl $idx',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();

                case ChartPeriod.year:
                  const months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'Mei',
                    'Jun',
                    'Jul',
                    'Ags',
                    'Sep',
                    'Okt',
                    'Nov',
                    'Des',
                  ];
                  if (idx >= 1 && idx <= 12) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        months[idx - 1],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
              }
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: maxY / 5,
            reservedSize: _selectedMetric == ChartMetricType.revenue
                ? (isMobile ? 54 : 68)
                : (isMobile ? 38 : 45),
            getTitlesWidget: (value, meta) {
              if (value < 0) return const SizedBox();
              String text;
              switch (_selectedMetric) {
                case ChartMetricType.revenue:
                  text = _selectedPeriod == ChartPeriod.year
                      ? 'Rp ${value.toInt()}Jt'
                      : 'Rp ${value.toStringAsFixed(1)}Jt';
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
                  style: const TextStyle(
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
        border: const Border(
          bottom: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.border),
          top: BorderSide.none,
          right: BorderSide.none,
        ),
      ),
      minX: minX,
      maxX: maxX,
      minY: 0,
      maxY: maxY,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) =>
              AppColors.navy900.withValues(alpha: 0.95),
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final isCurrent = barSpot.barIndex == 0;
              final idx = barSpot.x.toInt();
              String headerTime;
              String periodName;

              switch (_selectedPeriod) {
                case ChartPeriod.week:
                  const fullDays = [
                    'Senin',
                    'Selasa',
                    'Rabu',
                    'Kamis',
                    'Jumat',
                    'Sabtu',
                    'Minggu',
                  ];
                  headerTime = (idx >= 1 && idx <= 7)
                      ? fullDays[idx - 1]
                      : 'Hari $idx';
                  periodName = isCurrent ? 'Minggu Ini' : 'Minggu Lalu';
                  break;
                case ChartPeriod.month:
                  headerTime = 'Tgl $idx Sep';
                  periodName = isCurrent
                      ? 'September (Kini)'
                      : 'Agustus (Lalu)';
                  break;
                case ChartPeriod.year:
                  const fullMonths = [
                    'Januari',
                    'Februari',
                    'Maret',
                    'April',
                    'Mei',
                    'Juni',
                    'Juli',
                    'Agustus',
                    'September',
                    'Oktober',
                    'November',
                    'Desember',
                  ];
                  headerTime = (idx >= 1 && idx <= 12)
                      ? fullMonths[idx - 1]
                      : 'Bulan $idx';
                  periodName = isCurrent ? 'Tahun 2026' : 'Tahun 2025';
                  break;
              }

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

              return LineTooltipItem(
                '$headerTime\n$periodName: $valStr',
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
    String currentLegend;
    String pastLegend;
    String peakInsight;

    switch (_selectedPeriod) {
      case ChartPeriod.week:
        currentLegend = 'Periode Sekarang (Minggu Ini)';
        pastLegend = 'Periode Masa Lalu (Minggu Lalu)';
        switch (_selectedMetric) {
          case ChartMetricType.revenue:
            peakInsight = 'Puncak: Sabtu (Rp 4.100.000)';
            break;
          case ChartMetricType.occupancy:
            peakInsight = 'Puncak: Sabtu (Okupansi 100%)';
            break;
          case ChartMetricType.guests:
            peakInsight = 'Puncak: Sabtu (18 Check-In)';
            break;
        }
        break;

      case ChartPeriod.month:
        currentLegend = 'Periode Sekarang (Sep 2026)';
        pastLegend = 'Periode Masa Lalu (Ags 2026)';
        switch (_selectedMetric) {
          case ChartMetricType.revenue:
            peakInsight = 'Puncak: 24 Sep (Okupansi 100% - Rp 4.100.000)';
            break;
          case ChartMetricType.occupancy:
            peakInsight = 'Puncak: 24 Sep (Okupansi 100%)';
            break;
          case ChartMetricType.guests:
            peakInsight = 'Puncak: 24 Sep (18 Check-In)';
            break;
        }
        break;

      case ChartPeriod.year:
        currentLegend = 'Periode Sekarang (Tahun 2026)';
        pastLegend = 'Periode Masa Lalu (Tahun 2025)';
        switch (_selectedMetric) {
          case ChartMetricType.revenue:
            peakInsight = 'Puncak: Desember (Proyeksi Rp 62.000.000)';
            break;
          case ChartMetricType.occupancy:
            peakInsight = 'Puncak: Desember (Okupansi 94%)';
            break;
          case ChartMetricType.guests:
            peakInsight = 'Puncak: Desember (240 Check-In)';
            break;
        }
        break;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
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
                currentLegend,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy900,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Past Legend
          if (_showPastPeriod) ...[
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
                  pastLegend,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],

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
                const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: AppColors.orange500,
                ),
                const SizedBox(width: 6),
                Text(
                  peakInsight,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
