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
  final bool isNegative;

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
    final gradient =
        isNegative ? AppTheme.redGradient : AppTheme.cardGradient;
    final amountColor = Colors.white;

    final card = Container(
      margin: const EdgeInsets.all(4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isNegative
                    ? AppTheme.accentRed
                    : AppTheme.primary)
                .withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon badge
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              // Edit / auto badge
              if (!isReadOnly)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 14),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_graph,
                      color: Colors.white70, size: 14),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${_format(amount)}',
            style: TextStyle(
                color: amountColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5),
          ),
        ],
      ),
    );

    if (fullWidth) return SizedBox(width: double.infinity, child: card);
    return Expanded(child: card);
  }

  String _format(double val) {
    if (val >= 100000) return '${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '${(val / 1000).toStringAsFixed(1)}K';
    return val.toStringAsFixed(0);
  }
}
