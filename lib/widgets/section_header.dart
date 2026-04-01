// lib/widgets/section_header.dart
import 'package:flutter/material.dart';
import '../services/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;

  const SectionHeader({
    super.key,
    required this.title,
    required this.onAdd,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.sectionBg,
        border: Border(
          top:    BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.3),
          ),
          const Spacer(),
          if (onRemove != null)
            _ActionButton(icon: Icons.remove, onTap: onRemove!),
          const SizedBox(width: 6),
          _ActionButton(icon: Icons.add, onTap: onAdd),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
        ),
        child: Icon(icon, color: AppTheme.primaryLight, size: 15),
      ),
    );
  }
}
