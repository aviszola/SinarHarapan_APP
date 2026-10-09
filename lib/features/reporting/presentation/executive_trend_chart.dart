import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../shared_widgets/empty_state.dart';

enum ChartMetric { revenue, occupancy }
enum ChartPeriod { week, month }

/// Grafik Tren Manajer — Bersih, Terbaca Jelas, Tanpa Label Menumpuk.
/// Menampilkan kurva harian yang proporsional, gridline presisi, dan tooltip interaktif.
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

  /// Membangun deret waktu harian berkelanjutan (continuous timeline)
  /// agar rentang 7 hari / 30 hari ditampilkan secara proporsional tanpa loncat tanggal
  List<Map<String, dynamic>> _deriveSeries(
    List<Map<String, dynamic>> transactions,
    int daysCount,
    ChartMetric metric,
  ) {
    if (transactions.isEmpty) return [];

    final Map<String, double> revenueByDate = {};
    final Map<String, int> countByDate = {};
    final List<DateTime> validDates = [];

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

      final normalizedDt = DateTime(dt.year, dt.month, dt.day);
      validDates.add(normalizedDt);
      final key = DateFormat('yyyy-MM-dd').format(normalizedDt);

      final rawAmt =
          tx['totalAmount'] ?? tx['total_amount'] ?? tx['amount'] ?? 0;
      final amt = (rawAmt is num)
          ? rawAmt.toDouble()
          : (double.tryParse(rawAmt.toString()) ?? 0.0);

      revenueByDate[key] = (revenueByDate[key] ?? 0.0) + amt;
      countByDate[key] = (countByDate[key] ?? 0) + 1;
    }

    if (validDates.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    validDates.sort();
    final firstTxDate = validDates.first;
    final lastTxDate = validDates.last;

    // Tentukan tanggal jangkar (ujung kanan grafik)
    DateTime anchorDate = today;
    if (lastTxDate.isAfter(today)) {
      anchorDate = lastTxDate;
    } else if (today.difference(lastTxDate).inDays > 3) {
      anchorDate = lastTxDate;
    } else {
      // Pastikan transaksi terdekat tidak terpotong dari jendela grafik
      final windowStart = anchorDate.subtract(Duration(days: daysCount - 1));
      if (firstTxDate.isBefore(windowStart) &&
          lastTxDate.difference(firstTxDate).inDays < daysCount) {
        anchorDate = lastTxDate;
      }
    }

    final startDate = anchorDate.subtract(Duration(days: daysCount - 1));
    final List<Map<String, dynamic>> series = [];

    for (int i = 0; i < daysCount; i++) {
      final cur = startDate.add(Duration(days: i));
      final k = DateFormat('yyyy-MM-dd').format(cur);
      final rev = revenueByDate[k] ?? 0.0;
      final cnt = countByDate[k] ?? 0;
      final label = DateFormat('d MMM', 'id').format(cur);

      series.add({
        'index': i,
        'date': k,
        'dateTime': cur,
        'label': label,
        'value': metric == ChartMetric.revenue ? rev : cnt.toDouble(),
        'revenue': rev,
        'count': cnt,
      });
    }

    return series;
  }

  String _formatCompactRupiah(double value) {
    if (value <= 0) return '0';
    if (value >= 1000000) {
      final jt = value / 1000000;
      return jt == jt.roundToDouble()
          ? '${jt.toInt()} jt'
          : '${jt.toStringAsFixed(1)} jt';
    }
    if (value >= 1000) {
      return '${(value / 1000).toInt()} rb';
    }
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final rawData = widget.realTimeseriesData ?? [];
    final daysCount = _selectedPeriod == ChartPeriod.week ? 7 : 30;

    final chartData = _deriveSeries(rawData, daysCount, _selectedMetric);
    final hasData = chartData.isNotEmpty;

    // Hitung total nilai pada periode yang dipilih
    double totalPeriodValue = 0;
    if (hasData) {
      for (final item in chartData) {
        totalPeriodValue += (item['value'] as num?)?.toDouble() ?? 0.0;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Kontrol & Ringkasan Cepat
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedMetric == ChartMetric.revenue
                            ? 'Pendapatan Harian'
                            : 'Kedatangan Tamu Harian',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (hasData) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFCBD5E1), width: 0.8),
                          ),
                          child: Text(
                            _selectedMetric == ChartMetric.revenue
                                ? 'Total: ${widget.currencyFormatter.format(totalPeriodValue)}'
                                : 'Total: ${totalPeriodValue.toInt()} Tamu',
                            style: AppTextStyles.caption.copyWith(
                              color: const Color(0xFF334155),
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedPeriod == ChartPeriod.week
                        ? 'Rentang 7 hari aktif'
                        : 'Rentang 30 hari aktif',
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
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
                      (ChartMetric.occupancy, 'Kedatangan'),
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

          const SizedBox(height: 24),

          // Area Grafik atau Empty State
          SizedBox(
            height: 230,
            child: hasData
                ? _buildCleanLineChart(chartData)
                : EmptyStateWidget(
                    icon: Icons.show_chart_rounded,
                    title: 'Data Belum Tersedia',
                    message:
                        'Belum ada transaksi pada periode yang dipilih. Data transaksi baru akan langsung otomatis muncul di grafik ini.',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanLineChart(List<Map<String, dynamic>> data) {
    final spots = <FlSpot>[];
    double maxVal = 0;

    for (int i = 0; i < data.length; i++) {
      final val = (data[i]['value'] as num?)?.toDouble() ?? 0.0;
      if (val > maxVal) maxVal = val;
      spots.add(FlSpot(i.toDouble(), val));
    }

    // Hitung maxY dan yInterval yang teratur dan nyaman dibaca manusia
    double maxY;
    double yInterval;

    if (_selectedMetric == ChartMetric.revenue) {
      if (maxVal <= 0) {
        maxY = 1000000;
        yInterval = 250000;
      } else if (maxVal <= 500000) {
        maxY = 500000;
        yInterval = 125000;
      } else if (maxVal <= 1000000) {
        maxY = 1000000;
        yInterval = 250000;
      } else if (maxVal <= 2000000) {
        maxY = 2000000;
        yInterval = 500000;
      } else if (maxVal <= 3000000) {
        maxY = 3000000;
        yInterval = 750000;
      } else if (maxVal <= 5000000) {
        maxY = 5000000;
        yInterval = 1000000;
      } else {
        const step = 1000000.0;
        maxY = ((maxVal * 1.2) / step).ceil() * step;
        yInterval = maxY / 4;
      }
    } else {
      // Metrik Kedatangan Tamu
      if (maxVal <= 4) {
        maxY = 4;
        yInterval = 1;
      } else if (maxVal <= 10) {
        maxY = ((maxVal + 2) / 2).ceil() * 2.0;
        yInterval = maxY / 4;
      } else {
        maxY = ((maxVal * 1.25) / 5).ceil() * 5.0;
        yInterval = maxY / 5;
      }
    }

    final double maxX = math.max((data.length - 1).toDouble(), 1.0);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF0F172A),
            tooltipRoundedRadius: 8,
            tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.x.round();
                if (idx < 0 || idx >= data.length) return null;
                final d = data[idx];
                final dateLabel = d['label']?.toString() ?? '';
                final val = spot.y;
                final formatted = _selectedMetric == ChartMetric.revenue
                    ? widget.currencyFormatter.format(val)
                    : '${val.toInt()} Tamu Check-in';

                return LineTooltipItem(
                  '$dateLabel\n',
                  const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: formatted,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFFF1F5F9),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1.0, // Mencegah duplikasi teks tanggal
              getTitlesWidget: (value, meta) {
                final idx = value.round();
                // Lewati nilai pecahan untuk mencegah label bertumpukan
                if ((value - idx).abs() > 0.05) {
                  return const SizedBox.shrink();
                }
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }

                // Untuk 30 hari, tampilkan per interval 5 hari agar tidak padat
                if (data.length > 10) {
                  final isKeyPoint =
                      (idx % 5 == 0) || (idx == data.length - 1);
                  if (!isKeyPoint) return const SizedBox.shrink();
                }

                final label = data[idx]['label']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 58,
              interval: yInterval, // Sinkron dengan garis kisi
              getTitlesWidget: (value, meta) {
                final remainder = (value % yInterval).abs();
                if (remainder > 1.0 && (yInterval - remainder).abs() > 1.0) {
                  return const SizedBox.shrink();
                }

                String label;
                if (_selectedMetric == ChartMetric.revenue) {
                  label = _formatCompactRupiah(value);
                } else {
                  label = '${value.toInt()} Tamu';
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    label,
                    style: AppTextStyles.numberSmall.copyWith(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            left: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.18,
            color: const Color(0xFF1E3A8A), // Navy elegan
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isPeak = spot.y > 0;
                return FlDotCirclePainter(
                  radius: isPeak ? 4.5 : 2.5,
                  color: isPeak
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFFCBD5E1),
                  strokeWidth: isPeak ? 2 : 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E3A8A).withValues(alpha: 0.14),
                  const Color(0xFF1E3A8A).withValues(alpha: 0.00),
                ],
              ),
            ),
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
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = opt.$1 == value;
          return InkWell(
            onTap: () => onChanged(opt.$1),
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ]
                    : null,
              ),
              child: Text(
                opt.$2,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
