import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
