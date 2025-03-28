import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OperacaoItem {
  final IconData icon;
  final String label;
  final String? description;
  final Color color;
  final VoidCallback onTap;

  OperacaoItem(
    this.icon,
    this.label,
    this.color,
    this.onTap, {
    this.description,
  });
}

class OperacaoCardGrid extends StatelessWidget {
  final List<OperacaoItem> operationList;
  final double? height;
  final double? cardHeight;

  const OperacaoCardGrid({
    super.key,
    required this.operationList,
    this.height,
    this.cardHeight,
  });

  @override
  Widget build(BuildContext context) {
    final grid =
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 1,
          childAspectRatio: 2.8,
          mainAxisSpacing: 20,
          children: operationList.map(_buildCard).toList(),
        ).animate().fade(duration: 600.ms).slideY();

    return height != null
        ? SizedBox(height: height, child: grid)
        : Expanded(child: Align(alignment: Alignment.center, child: grid));
  }

  Widget _buildCard(OperacaoItem item) {
    final card = Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        height: cardHeight,
        child: Container(
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: item.color, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: item.color,
                child: Icon(item.icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: item.color,
                      ),
                    ),
                    if (item.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOut);

    return GestureDetector(onTap: item.onTap, child: card);
  }
}
