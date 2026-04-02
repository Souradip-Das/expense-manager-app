// lib/widgets/section_header.dart
import 'package:flutter/material.dart';
import '../services/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onAdd;
  final VoidCallback? onRemove;
  final String? subtitle;

  const SectionHeader({
    super.key,
    required this.title,
    required this.onAdd,
    this.onRemove,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          if (onRemove != null)
            _CircleBtn(icon: Icons.remove, onTap: onRemove!),
          const SizedBox(width: 8),
          _CircleBtn(icon: Icons.add, onTap: onAdd),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
