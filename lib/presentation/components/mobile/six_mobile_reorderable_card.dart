import 'package:flutter/material.dart';

typedef SixMobileReorderableCardBuilder = Widget Function();

class SixMobileReorderableCard<T extends Object> extends StatelessWidget {
  const SixMobileReorderableCard({
    super.key,
    required this.value,
    required this.onReorder,
    required this.cardBuilder,
    required this.feedbackWidth,
    required this.feedbackHeight,
    required this.handleColor,
    this.handleOnLeft = false,
  });

  final T value;
  final void Function(T movido, T destino) onReorder;
  final SixMobileReorderableCardBuilder cardBuilder;
  final double feedbackWidth;
  final double feedbackHeight;
  final Color handleColor;
  final bool handleOnLeft;

  @override
  Widget build(BuildContext context) {
    final Widget card = _buildCardWithHandle();

    return DragTarget<T>(
      onWillAcceptWithDetails: (DragTargetDetails<T> details) =>
          details.data != value,
      onAcceptWithDetails: (DragTargetDetails<T> details) {
        onReorder(details.data, value);
      },
      builder:
          (
            BuildContext context,
            List<T?> candidateData,
            List<dynamic> rejectedData,
          ) {
            final bool isDestino = candidateData.isNotEmpty;
            return AnimatedScale(
              scale: isDestino ? 1.018 : 1,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: LongPressDraggable<T>(
                data: value,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                maxSimultaneousDrags: 1,
                feedback: Material(
                  color: Colors.transparent,
                  child: Transform.scale(
                    scale: 1.018,
                    child: SizedBox(
                      width: feedbackWidth,
                      height: feedbackHeight,
                      child: _buildCardWithHandle(),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(opacity: 0.28, child: card),
                child: card,
              ),
            );
          },
    );
  }

  Widget _buildCardWithHandle() {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        cardBuilder(),
        Positioned(
          top: 7,
          left: handleOnLeft ? 7 : null,
          right: handleOnLeft ? null : 7,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: handleColor.withAlpha(150),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
