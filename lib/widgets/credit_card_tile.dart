// lib/widgets/credit_card_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/credit_card_model.dart';
import '../services/app_theme.dart';

class CreditCardTile extends StatelessWidget {
  final CreditCardModel item;
  final VoidCallback onDelete;

  const CreditCardTile({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(color: AppTheme.primary, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.credit_card,
                  color: AppTheme.primaryLight, size: 18),
            ),
            const SizedBox(width: 12),

            // ── Title + date + category ────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(item.date),
                        style: const TextStyle(
                            color: AppTheme.textMuted, fontSize: 11),
                      ),
                      if (item.categoryName != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppTheme.primary.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.label_outline,
                                  color: AppTheme.primaryLight, size: 10),
                              const SizedBox(width: 3),
                              Text(item.categoryName!,
                                  style: const TextStyle(
                                      color: AppTheme.primaryLight,
                                      fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Amount ────────────────────────────────────────────────────
            Text(
              '-₹${item.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: AppTheme.accentRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const SizedBox(width: 8),

            // ── Delete ────────────────────────────────────────────────────
            GestureDetector(
              onTap: onDelete,
              child: const Icon(Icons.close,
                  color: AppTheme.textMuted, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
