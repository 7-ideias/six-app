import 'package:flutter/material.dart';

class ZebraListItem extends StatelessWidget {
  final Widget child;
  final int index;
  final Color? evenColor;
  final Color? oddColor;

  const ZebraListItem({
    Key? key,
    required this.child,
    required this.index,
    this.evenColor,
    this.oddColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultEvenColor =
        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final defaultOddColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final backgroundColor =
        index.isEven
            ? (evenColor ?? defaultEvenColor)
            : (oddColor ?? defaultOddColor);

    return Container(color: backgroundColor, child: child);
  }
}
