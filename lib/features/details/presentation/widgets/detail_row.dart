import 'package:flutter/material.dart';

/// One labelled value inside the details card: tinted icon tile, small muted
/// label, value; hairline divider below unless [isLast].
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(value, style: textTheme.titleSmall?.copyWith(fontSize: 15)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 68, endIndent: 16, color: colorScheme.outlineVariant),
      ],
    );
  }
}
