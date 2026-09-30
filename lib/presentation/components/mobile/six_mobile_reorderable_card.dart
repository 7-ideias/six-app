import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);

    return DragTarget<T>(
      onWillAcceptWithDetails:
          (DragTargetDetails<T> details) => details.data != value,
      onAcceptWithDetails: (DragTargetDetails<T> details) {
        onReorder(details.data, value);
      },
      builder: (
        BuildContext context,
        List<T?> candidateData,
        List<dynamic> rejectedData,
      ) {
        final bool isDestino = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color:
                  isDestino ? handleColor.withAlpha(125) : Colors.transparent,
              width: 1.4,
            ),
          ),
          child: AnimatedScale(
            scale: isDestino ? 1.018 : 1,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: LongPressDraggable<T>(
              data: value,
              dragAnchorStrategy: childDragAnchorStrategy,
              maxSimultaneousDrags: 1,
              onDragStarted: HapticFeedback.selectionClick,
              feedback: _SixMobileReorderableCardFeedback(
                width: feedbackWidth,
                height: feedbackHeight,
                accentColor: handleColor,
                reduceMotion: reduceMotion,
                child: _buildCardWithHandle(isFeedback: true),
              ),
              childWhenDragging: Opacity(
                opacity: 0.38,
                child: Transform.scale(scale: 0.985, child: card),
              ),
              child: card,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardWithHandle({bool isFeedback = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        SizedBox(width: double.infinity, child: cardBuilder()),
        Positioned(
          top: 7,
          left: handleOnLeft ? 7 : null,
          right: handleOnLeft ? null : 7,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 18,
                color: handleColor.withAlpha(isFeedback ? 220 : 170),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SixMobileReorderableCardFeedback extends StatelessWidget {
  const _SixMobileReorderableCardFeedback({
    required this.width,
    required this.height,
    required this.accentColor,
    required this.reduceMotion,
    required this.child,
  });

  final double width;
  final double height;
  final Color accentColor;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Widget feedbackCard = Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withAlpha(34),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: accentColor.withAlpha(32),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(width: width, height: height, child: child),
      ),
    );

    if (reduceMotion) {
      return Transform.scale(scale: 1.018, child: feedbackCard);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: feedbackCard,
      builder: (BuildContext context, double value, Widget? child) {
        return Transform.translate(
          offset: Offset(0, -5 * value),
          child: Transform.scale(
            scale: 1 + (0.018 * value),
            child: Opacity(opacity: 0.92 + (0.08 * value), child: child),
          ),
        );
      },
    );
  }
}
