import 'package:flutter/material.dart';

/// Hz Divider
typedef Widget ContextMenuDividerBuilder(BuildContext context);

class ContextMenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Divider(color: Colors.grey.shade600, height: .5),
    );
  }
}
