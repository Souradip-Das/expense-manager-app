// lib/widgets/balance_card.dart
import 'package:flutter/material.dart';
import '../services/app_theme.dart';

class BalanceCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final VoidCallback? onEdit;
  final bool isReadOnly;
  final bool fullWidth;
  final bool isNegative; // red accent for spend cards

  const BalanceCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    this.onEdit,
    this.isReadOnly = false,
    this.fullWidth = false,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = isNegative ? AppTheme.accentRed : AppTheme.primary;
    final iconBgColor = isNegative
        ? AppTheme.accentRed.withOpacity(0.15)
        : AppTheme.primary.withOpacity(0.15);
    final iconColor = isNegative ? AppTheme.accentRed : AppTheme.primaryLight;
    final amountColor = isNegative ? AppTheme.accentRed : AppTheme.textPrimary;

    final card = Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          // ── Icon ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),

          // ── Label + Amount ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3)),
                const SizedBox(height: 4),
                Text(
                  '₹${_format(amount)}',
                  style: TextStyle(
                      color: amountColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // ── Action icon ────────────────────────────────────────────────────
          if (!isReadOnly)
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: AppTheme.primaryLight, size: 16),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.auto_graph,
                  color: isNegative
                      ? AppTheme.accentRed.withOpacity(0.6)
                      : AppTheme.textMuted,
                  size: 16),
            ),
        ],
      ),
    );

    if (fullWidth) return SizedBox(width: double.infinity, child: card);
    return Expanded(child: card);
  }

  String _format(double val) {
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000)   return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }
}