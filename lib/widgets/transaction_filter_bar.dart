// lib/widgets/transaction_filter_bar.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../services/app_theme.dart';

class TransactionFilter {
  final CategoryModel? category;
  final DateTime? date;
  final double? minAmount;
  final double? maxAmount;

  const TransactionFilter({
    this.category,
    this.date,
    this.minAmount,
    this.maxAmount,
  });

  bool get hasAny =>
      category != null || date != null || minAmount != null || maxAmount != null;

  TransactionFilter copyWith({
    Object? category = _sentinel,
    Object? date = _sentinel,
    Object? minAmount = _sentinel,
    Object? maxAmount = _sentinel,
  }) {
    return TransactionFilter(
      category:  category  == _sentinel ? this.category  : category  as CategoryModel?,
      date:      date      == _sentinel ? this.date      : date      as DateTime?,
      minAmount: minAmount == _sentinel ? this.minAmount : minAmount as double?,
      maxAmount: maxAmount == _sentinel ? this.maxAmount : maxAmount as double?,
    );
  }
}

// Sentinel value for copyWith
const _sentinel = Object();

class TransactionFilterBar extends StatelessWidget {
  final TransactionFilter filter;
  final List<CategoryModel> categories;
  final void Function(TransactionFilter) onChanged;

  const TransactionFilterBar({
    super.key,
    required this.filter,
    required this.categories,
    required this.onChanged,
  });

  // ── Category picker ──────────────────────────────────────────────────────────
  void _pickCategory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Filter by Category',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 8),
            // All categories option
            ListTile(
              leading: Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              title: const Text('All Categories',
                  style: TextStyle(color: AppTheme.textSecondary)),
              trailing: filter.category == null
                  ? const Icon(Icons.check, color: AppTheme.primaryLight, size: 18)
                  : null,
              onTap: () {
                onChanged(filter.copyWith(category: null));
                Navigator.pop(context);
              },
            ),
            ...categories.map((cat) => ListTile(
                  leading: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(cat.name,
                      style: const TextStyle(color: AppTheme.textPrimary)),
                  trailing: filter.category?.id == cat.id
                      ? const Icon(Icons.check,
                          color: AppTheme.primaryLight, size: 18)
                      : null,
                  onTap: () {
                    onChanged(filter.copyWith(category: cat));
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  // ── Date picker ──────────────────────────────────────────────────────────────
  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: filter.date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      onChanged(filter.copyWith(date: picked));
    }
  }

  // ── Amount range picker ──────────────────────────────────────────────────────
  void _pickAmountRange(BuildContext context) {
    final minCtrl = TextEditingController(
        text: filter.minAmount?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(
        text: filter.maxAmount?.toStringAsFixed(0) ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Filter by Amount Range',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Min Amount (₹)',
                        prefixIcon: Icon(Icons.currency_rupee,
                            color: AppTheme.primaryLight, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Max Amount (₹)',
                        prefixIcon: Icon(Icons.currency_rupee,
                            color: AppTheme.primaryLight, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        onChanged(filter.copyWith(
                            minAmount: null, maxAmount: null));
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderColor),
                      ),
                      child: const Text('Clear',
                          style: TextStyle(color: AppTheme.textMuted)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final min = double.tryParse(minCtrl.text.trim());
                        final max = double.tryParse(maxCtrl.text.trim());
                        onChanged(filter.copyWith(
                            minAmount: min, maxAmount: max));
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary),
                      child: const Text('Apply',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.sectionBg,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter chips row ───────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Filter:',
                    style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),

                // Category chip
                _FilterChip(
                  icon: Icons.category_outlined,
                  label: filter.category?.name ?? 'Category',
                  isActive: filter.category != null,
                  onTap: () => _pickCategory(context),
                  onClear: filter.category != null
                      ? () => onChanged(filter.copyWith(category: null))
                      : null,
                ),
                const SizedBox(width: 6),

                // Date chip
                _FilterChip(
                  icon: Icons.calendar_today_outlined,
                  label: filter.date != null
                      ? DateFormat('dd MMM yyyy').format(filter.date!)
                      : 'Date',
                  isActive: filter.date != null,
                  onTap: () => _pickDate(context),
                  onClear: filter.date != null
                      ? () => onChanged(filter.copyWith(date: null))
                      : null,
                ),
                const SizedBox(width: 6),

                // Amount chip
                _FilterChip(
                  icon: Icons.currency_rupee,
                  label: _amountLabel(),
                  isActive: filter.minAmount != null || filter.maxAmount != null,
                  onTap: () => _pickAmountRange(context),
                  onClear: filter.minAmount != null || filter.maxAmount != null
                      ? () => onChanged(
                          filter.copyWith(minAmount: null, maxAmount: null))
                      : null,
                ),

                // Clear all
                if (filter.hasAny) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => onChanged(const TransactionFilter()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.accentRed.withOpacity(0.5)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.clear_all,
                              color: AppTheme.accentRed, size: 13),
                          SizedBox(width: 4),
                          Text('Clear All',
                              style: TextStyle(
                                  color: AppTheme.accentRed, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Active filter summary ──────────────────────────────────────────
          if (filter.hasAny) ...[
            const SizedBox(height: 6),
            Text(
              _summaryText(),
              style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  String _amountLabel() {
    if (filter.minAmount != null && filter.maxAmount != null) {
      return '₹${filter.minAmount!.toStringAsFixed(0)} – ₹${filter.maxAmount!.toStringAsFixed(0)}';
    }
    if (filter.minAmount != null) return '≥ ₹${filter.minAmount!.toStringAsFixed(0)}';
    if (filter.maxAmount != null) return '≤ ₹${filter.maxAmount!.toStringAsFixed(0)}';
    return 'Amount';
  }

  String _summaryText() {
    final parts = <String>[];
    if (filter.category != null) parts.add('Category: ${filter.category!.name}');
    if (filter.date != null)
      parts.add('Date: ${DateFormat('dd MMM yyyy').format(filter.date!)}');
    if (filter.minAmount != null || filter.maxAmount != null)
      parts.add('Amount: ${_amountLabel()}');
    return 'Showing: ${parts.join('  •  ')}';
  }
}

// ─── Single filter chip ────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withOpacity(0.2)
              : AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primary : AppTheme.borderColor,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: isActive
                    ? AppTheme.primaryLight
                    : AppTheme.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? AppTheme.primaryLight
                    : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 13, color: AppTheme.primaryLight),
              ),
            ],
          ],
        ),
      ),
    );
  }
}