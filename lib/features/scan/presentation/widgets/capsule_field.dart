import 'package:flutter/material.dart';

/// Read-only "field" look for tappable values (e.g. a date picker): same
/// shape and colours as a text field from the app theme.
class CapsuleShell extends StatelessWidget {
  const CapsuleShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? null
            : Border.all(color: colorScheme.outline, width: 1.2),
      ),
      child: child,
    );
  }
}

/// Form text field styled by the app theme. [semanticLabel] is what screen
/// readers announce for the field (pair it with the visible [FieldLabel]).
class CapsuleField extends StatelessWidget {
  const CapsuleField({
    super.key,
    required this.controller,
    this.semanticLabel,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.minLines,
  });

  final TextEditingController controller;
  final String? semanticLabel;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      minLines: minLines,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
    return semanticLabel == null
        ? field
        : Semantics(label: semanticLabel, textField: true, child: field);
  }
}
