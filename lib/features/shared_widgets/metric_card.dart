import 'package:flutter/material.dart';
import '../../app/theme.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isCompact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.roundedLg,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: AppTypography.overline.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.display.copyWith(
                color: AppColors.navy900,
                fontSize: isCompact ? 28 : 34,
              ),
            ),
          ),
          if (trendText != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  isTrendPositive ? Icons.trending_up : Icons.trending_down,
                  size: 16,
                  color: isTrendPositive ? AppColors.orange600 : AppColors.statusOccupied,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    trendText!,
                    style: AppTypography.caption.copyWith(
                      color: isTrendPositive ? AppColors.orange600 : AppColors.statusOccupied,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
