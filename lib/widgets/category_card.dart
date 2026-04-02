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
    final remaining   = category.budget - spent;
    final isOver      = remaining < 0;
    final progress    = (spent / category.budget).clamp(0.0, 1.0);
    final progressColor = isOver
        ? AppTheme.accentRed
        : progress > 0.8
            ? AppTheme.accentAmber
            : AppTheme.accentGreen;

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppTheme.cardGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.category_outlined,
                      color: Colors.white, size: 16),
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
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(Icons.edit_outlined,
                      color: AppTheme.textMuted, size: 14),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(Icons.delete_outline,
                      color: AppTheme.textMuted, size: 14),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Amounts ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Stat(label: 'Budget', value: '₹${_fmt(category.budget)}',
                    color: AppTheme.textSecondary),
                _Stat(label: 'Spent', value: '₹${_fmt(spent)}',
                    color: AppTheme.primaryLight),
                _Stat(
                  label: isOver ? 'Over' : 'Left',
                  value: '₹${_fmt(remaining.abs())}',
                  color: progressColor,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Progress bar ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppTheme.borderColor,
                valueColor:
                    AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.textMuted, fontSize: 9, letterSpacing: 0.5)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
