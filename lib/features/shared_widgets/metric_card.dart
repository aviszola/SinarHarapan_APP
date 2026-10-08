import 'package:flutter/material.dart';
import 'kpi_tile.dart';

/// Kompatibilitas untuk kode yang masih mengimpor MetricCard.
/// Mengarahkan ke format KpiTile bersih tanpa ikon tren palsu dan tanpa teks filler.
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? trendText;
  final bool isTrendPositive;
  final Widget? trailing;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.trendText,
    this.isTrendPositive = true,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return KpiTile(
      label: title.toUpperCase(),
      value: value,
      subtitle: trendText,
      trailing: trailing,
    );
  }
}
