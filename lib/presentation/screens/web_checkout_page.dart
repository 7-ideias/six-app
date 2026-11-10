import 'package:flutter/material.dart';

import 'subscription_web_page.dart';

/// Legacy public route now enters the authenticated commerce subscription flow.
class WebCheckoutPage extends StatelessWidget {
  const WebCheckoutPage({super.key, this.initialUri});
  final Uri? initialUri;
  @override
  Widget build(BuildContext context) =>
      SubscriptionWebPage(selection: initialUri);
}
