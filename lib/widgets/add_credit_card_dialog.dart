import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/category_model.dart';
import '../providers/budget_provider.dart';
import '../services/snackbar_service.dart';

class AddCreditCardDialog extends ConsumerStatefulWidget {
  final String monthKey;

  const AddCreditCardDialog({super.key, required this.monthKey});

  @override
  ConsumerState<AddCreditCardDialog> createState() =>
      _AddCreditCardDialogState();
}

class _AddCreditCardDialogState extends ConsumerState<AddCreditCardDialog> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  CategoryModel? _selectedCategory; // NEW

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF6A0DAD)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      SnackbarService.show(
        context,
        'Please enter a title.',
        type: SnackType.warning,
      );
      return;
    }
    if (_amountCtrl.text.trim().isEmpty) {
      SnackbarService.show(
        context,
        'Please enter an amount.',
        type: SnackType.warning,
      );
      return;
    }
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      SnackbarService.show(
        context,
        'Amount must be greater than 0.',
        type: SnackType.warning,
      );
      return;
    }

    await ref
        .read(creditCardsProvider.notifier)
        .addCreditCard(
          title: _titleCtrl.text.trim(),
          amount: amount,
          date: _selectedDate,
          monthKey: widget.monthKey,
          categoryId: _selectedCategory?.id, // NEW
          categoryName: _selectedCategory?.name, // NEW
        );
    if (mounted) {
      Navigator.pop(context);
      final catMsg = _selectedCategory != null
          ? ' under ${_selectedCategory!.name}'
          : '';
      SnackbarService.show(
        context,
        'CC spend of ₹${amount.toStringAsFixed(0)}$catMsg added!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider); // NEW

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: const Text(
        'Add Credit Card Spend',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title / Description',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Amount (₹)'),
            ),
            const SizedBox(height: 12),

            // ── Category Dropdown (optional) ── NEW ──────────────────────────
            DropdownButtonFormField<CategoryModel>(
              value: _selectedCategory,
              dropdownColor: const Color(0xFF2A2A2A),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Category (optional)',
                suffixIcon: _selectedCategory != null
                    ? GestureDetector(
                        onTap: () => setState(() => _selectedCategory = null),
                        child: const Icon(
                          Icons.clear,
                          color: Colors.white38,
                          size: 18,
                        ),
                      )
                    : null,
              ),
              items: [
                ...categories.map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Color(c.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(c.name),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedCategory = val),
              hint: const Text(
                'No category',
                style: TextStyle(color: Colors.white38),
              ),
            ),

            // ─────────────────────────────────────────────────────────────────
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.white54,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A0DAD),
          ),
          child: const Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
