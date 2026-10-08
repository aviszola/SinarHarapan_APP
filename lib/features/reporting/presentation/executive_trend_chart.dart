import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_spacing.dart';
import '../../shared_widgets/empty_state.dart';

enum ChartMetric { revenue, occupancy }
enum ChartPeriod { week, month }

/// Grafik Tren Manajer — Bersih, Garis Tegas 2px, Tanpa Glow / Fake Spline.
/// Menampilkan data riil atau Empty State jujur jika data historis belum tersedia dari backend.
class ExecutiveTrendChart extends StatefulWidget {
  final NumberFormat currencyFormatter;
  final List<Map<String, dynamic>>? realTimeseriesData;

  const ExecutiveTrendChart({
    super.key,
    required this.currencyFormatter,
    this.realTimeseriesData,
  });

  @override
  State<ExecutiveTrendChart> createState() => _ExecutiveTrendChartState();
}

class _ExecutiveTrendChartState extends State<ExecutiveTrendChart> {
  ChartMetric _selectedMetric = ChartMetric.revenue;
  ChartPeriod _selectedPeriod = ChartPeriod.week;

  @override
  Widget build(BuildContext context) {
    // Hotel Sinar Harapan memiliki 3 kamar.
    // Jika tidak ada data time-series backend yang valid, tampilkan empty state jujur.
    final data = widget.realTimeseriesData;
    final hasRealData = data != null && data.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.rounded,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Kontrol: Sederhana (Satu periode, satu metrik)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedMetric == ChartMetric.revenue
                        ? 'Pendapatan Harian'
                        : 'Tingkat Hunian Harian',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.brandNavyDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedPeriod == ChartPeriod.week
                        ? '7 hari terakhir'
                        : '30 hari berjalan',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pilihan Metrik
                  _buildSegmentedControl<ChartMetric>(
                    value: _selectedMetric,
                    options: const [
                      (ChartMetric.revenue, 'Pendapatan'),
                      (ChartMetric.occupancy, 'Okupansi'),
                    ],
                    onChanged: (val) => setState(() => _selectedMetric = val),
                  ),
                  const SizedBox(width: 8),
                  // Pilihan Periode
                  _buildSegmentedControl<ChartPeriod>(
                    value: _selectedPeriod,
                    options: const [
                      (ChartPeriod.week, '7 Hari'),
                      (ChartPeriod.month, '30 Hari'),
                    ],
                    onChanged: (val) => setState(() => _selectedPeriod = val),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Area Grafik atau Empty State Jujur
          SizedBox(
            height: 220,
            child: hasRealData
                ? _buildCleanLineChart(data)
                : const EmptyStateWidget(
                    icon: Icons.show_chart_rounded,
                    title: 'Data Tren Belum Tersedia',
                    message:
                        'Backend belum mengembalikan log transaksi harian untuk rentang waktu ini. Laporan ringkasan tetap dapat dilihat pada kartu di atas.',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanLineChart(List<Map<String, dynamic>> data) {
    // Garis tegas 2px, tanpa gradient tebal, horizontal gridlines halus saja
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['value'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), val));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _selectedMetric == ChartMetric.revenue ? 500000 : 33.3,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                final label = data[idx]['label']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                if (_selectedMetric == ChartMetric.revenue) {
                  return Text(
                    '${(value / 1000).toInt()}k',
                    style: AppTextStyles.numberSmall,
                  );
                } else {
                  return Text(
                    '${value.toInt()}%',
                    style: AppTextStyles.numberSmall,
                  );
                }
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
            left: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false, // Garis tegas, bukan spline meliuk tidak wajar
            color: AppColors.brandNavy,
            barWidth: 2,
            isStrokeCapRound: false,
            dotData: const FlDotData(show: false), // Titik hanya saat hover/sentuh
            belowBarData: BarAreaData(show: false), // Tanpa gradient fill tebal
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl<T>({
    required T value,
    required List<(T, String)> options,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSubtle,
        borderRadius: AppRadius.roundedSm,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = opt.$1 == value;
          return InkWell(
            onTap: () => onChanged(opt.$1),
            borderRadius: AppRadius.roundedSm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.surface : Colors.transparent,
                borderRadius: AppRadius.roundedSm,
                border: isSelected ? Border.all(color: AppColors.border, width: 1) : null,
              ),
              child: Text(
                opt.$2,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.brandNavyDark : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
