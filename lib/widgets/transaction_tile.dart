// lib/widgets/transaction_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel item;
  final VoidCallback onDelete;

  const TransactionTile(
      {super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // ── Icon ──────────────────────────────────────────────────────
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),

          // ── Info ───────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description.isNotEmpty
                      ? item.description
                      : item.categoryName,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.primary.withOpacity(0.5)),
                      ),
                      child: Text(item.categoryName,
                          style: const TextStyle(
                              color: AppTheme.primaryLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMM').format(item.date),
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Amount + delete ────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-₹${item.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close,
                    color: AppTheme.textMuted, size: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
