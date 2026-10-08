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

  List<Map<String, dynamic>> _deriveRevenueSeries(
      List<Map<String, dynamic>> transactions, int daysCount) {
    if (transactions.isEmpty) return [];

    final Map<String, double> revenueByDate = {};

    for (final tx in transactions) {
      final status = (tx['paymentStatus'] ?? tx['payment_status'] ?? '')
          .toString()
          .toUpperCase();
      if (status.isNotEmpty &&
          status != 'PAID' &&
          status != 'LUNAS' &&
          status != 'BERHASIL') {
        continue;
      }

      final rawDate = tx['createdAt'] ??
          tx['created_at'] ??
          tx['checkInTime'] ??
          tx['check_in_time'] ??
          tx['date'];
      if (rawDate == null) continue;

      DateTime? dt;
      if (rawDate is DateTime) {
        dt = rawDate;
      } else {
        dt = DateTime.tryParse(rawDate.toString());
      }
      if (dt == null) continue;

      final key = DateFormat('yyyy-MM-dd').format(dt);
      final rawAmt =
          tx['totalAmount'] ?? tx['total_amount'] ?? tx['amount'] ?? 0;
      final amt = (rawAmt is num)
          ? rawAmt.toDouble()
          : (double.tryParse(rawAmt.toString()) ?? 0.0);

      revenueByDate[key] = (revenueByDate[key] ?? 0.0) + amt;
    }

    if (revenueByDate.isEmpty) return [];

    final sortedKeys = revenueByDate.keys.toList()..sort();
    final selectedKeys = sortedKeys.length > daysCount
        ? sortedKeys.sublist(sortedKeys.length - daysCount)
        : sortedKeys;

    return selectedKeys.map((k) {
      final dt = DateTime.parse(k);
      final label = DateFormat('d MMM', 'id').format(dt);
      return {
        'label': label,
        'value': revenueByDate[k] ?? 0.0,
        'date': k,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rawData = widget.realTimeseriesData ?? [];
    final daysCount = _selectedPeriod == ChartPeriod.week ? 7 : 30;

    List<Map<String, dynamic>> chartData = [];
    bool hasData = false;
    String emptyMessage = '';

    if (_selectedMetric == ChartMetric.revenue) {
      chartData = _deriveRevenueSeries(rawData, daysCount);
      hasData = chartData.isNotEmpty;
      emptyMessage =
          'Belum ada transaksi pendapatan pada periode ${_selectedPeriod == ChartPeriod.week ? "7 hari terakhir" : "30 hari berjalan"}. Rekapitulasi dapat dilihat pada kartu di atas.';
    } else {
      hasData = false;
      emptyMessage =
          'Data histori tingkat hunian per hari membutuhkan agregasi snapshot harian dari backend. Rata-rata hunian bulan ini tetap dapat dipantau pada kartu ringkasan di atas.';
    }

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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
            child: hasData
                ? _buildCleanLineChart(chartData)
                : EmptyStateWidget(
                    icon: Icons.show_chart_rounded,
                    title: _selectedMetric == ChartMetric.revenue
                        ? 'Data Pendapatan Belum Ada'
                        : 'Histori Okupansi Belum Tersedia',
                    message: emptyMessage,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanLineChart(List<Map<String, dynamic>> data) {
    // Garis tegas 2px, tanpa gradient tebal, horizontal gridlines halus saja
    final spots = <FlSpot>[];
    double maxVal = 0;
    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['value'] as num?)?.toDouble() ?? 0.0;
      if (val > maxVal) maxVal = val;
      spots.add(FlSpot(i.toDouble(), val));
    }

    final maxY = maxVal > 0 ? (maxVal * 1.25) : 1000000.0;
    final chartSpots = spots.length == 1
        ? [spots[0], FlSpot(1, spots[0].y)]
        : spots;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _selectedMetric == ChartMetric.revenue ? (maxY / 4) : 25.0,
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
            spots: chartSpots,
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
