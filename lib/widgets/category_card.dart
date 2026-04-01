// lib/widgets/category_card.dart
import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/app_theme.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final double spent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    required this.spent,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = category.budget - spent;
    final isOverBudget = remaining < 0;
    final progress = (spent / category.budget).clamp(0.0, 1.0);
    final progressColor = isOverBudget
        ? AppTheme.accentRed
        : progress > 0.8
            ? AppTheme.accentAmber
            : AppTheme.accentGreen;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: AppTheme.primary, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(
              children: [
                // Category icon
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.category_outlined,
                      color: AppTheme.primaryLight, size: 14),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Actions
                GestureDetector(
                    onTap: onEdit,
                    child: const Icon(Icons.edit_outlined,
                        color: AppTheme.textMuted, size: 15)),
                const SizedBox(width: 8),
                GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline,
                        color: AppTheme.textMuted, size: 15)),
              ],
            ),

            const SizedBox(height: 8),

            // ── Budget row ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoChip(
                  label: 'Budget',
                  value: '₹${_fmt(category.budget)}',
                  color: AppTheme.textSecondary,
                ),
                _InfoChip(
                  label: 'Spent',
                  value: '₹${_fmt(spent)}',
                  color: AppTheme.primaryLight,
                ),
                _InfoChip(
                  label: isOverBudget ? 'Over' : 'Left',
                  value: '₹${_fmt(remaining.abs())}',
                  color: progressColor,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Progress bar ───────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppTheme.borderColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double val) {
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000)   return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 9,
                letterSpacing: 0.5)),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
