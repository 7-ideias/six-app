import 'package:flutter/widgets.dart';

class MobileNavigationController extends ValueNotifier<int> {
  MobileNavigationController({int initialIndex = dashIndex})
    : super(initialIndex);

  static const int dashIndex = 0;
  static const int managementIndex = 1;
  static const int serviceIndex = 2;
  static const int firstIndex = dashIndex;
  static const int lastIndex = serviceIndex;

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
