// lib/widgets/add_category_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../providers/budget_provider.dart';
import '../services/app_theme.dart';
import '../services/snackbar_service.dart';

class AddCategoryDialog extends ConsumerStatefulWidget {
  final String monthKey;
  final CategoryModel? existing;

  const AddCategoryDialog({super.key, required this.monthKey, this.existing});

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  final _nameCtrl   = TextEditingController();
  final _budgetCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text   = widget.existing!.name;
      _budgetCtrl.text = widget.existing!.budget.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameCtrl.text.trim();
    final budgetText = _budgetCtrl.text.trim();

    if (name.isEmpty || budgetText.isEmpty) {
      SnackbarService.show(context, 'Please fill in all fields.',
          type: SnackType.warning);
      return;
    }
    final budget = double.tryParse(budgetText) ?? 0;
    if (budget <= 0) {
      SnackbarService.show(context, 'Budget must be greater than 0.',
          type: SnackType.warning);
      return;
    }

    final notifier = ref.read(categoriesProvider.notifier);
    if (widget.existing != null) {
      widget.existing!.name   = name;
      widget.existing!.budget = budget;
      // color stays as default purple value
      await notifier.updateCategory(widget.existing!);
    } else {
      await notifier.addCategory(
        name: name,
        budget: budget,
        colorValue: AppTheme.primary.value, // always purple, no picker needed
        monthKey: widget.monthKey,
      );
    }

    if (mounted) {
      Navigator.pop(context);
      SnackbarService.show(context,
          widget.existing != null
              ? 'Category updated successfully!'
              : 'Category "$name" added!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.category_outlined,
                color: AppTheme.primaryLight, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            widget.existing != null ? 'Edit Category' : 'Add Category',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Category Name',
              prefixIcon: Icon(Icons.label_outline,
                  color: AppTheme.primaryLight, size: 18),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _budgetCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Monthly Budget (₹)',
              prefixIcon: Icon(Icons.currency_rupee,
                  color: AppTheme.primaryLight, size: 18),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textMuted)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
