import 'package:flutter/material.dart';

/// Visible label above a form field. Excluded from semantics: the field
/// itself carries the same text as its screen-reader label.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(bottom: 8, start: 2),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontSize: 13.5),
        ),
      ),
    );
  }
}
