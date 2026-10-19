import 'package:flutter/material.dart';

/// Keeps admin content readable on wide browser windows while filling phones.
class AdminPageFrame extends StatelessWidget {
  const AdminPageFrame({required this.child, this.maxWidth = 1120, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth < maxWidth
            ? constraints.maxWidth
            : maxWidth;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : null;

        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: width, height: height, child: child),
          ),
        );
      },
    );
  }
}
