import 'package:flutter/widgets.dart';

class MobileNavigationController extends ValueNotifier<int> {
  MobileNavigationController({int initialIndex = 1}) : super(initialIndex);

  static const int firstIndex = 0;
  static const int lastIndex = 2;

  void select(int index) {
    final bool isValid = index >= firstIndex && index <= lastIndex;
    if (!isValid || value == index) return;

    value = index;
  }
}

class MobileNavigationScope
    extends InheritedNotifier<MobileNavigationController> {
  const MobileNavigationScope({
    super.key,
    required MobileNavigationController controller,
    required super.child,
  }) : super(notifier: controller);

  static MobileNavigationController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MobileNavigationScope>()
        ?.notifier;
  }
}
