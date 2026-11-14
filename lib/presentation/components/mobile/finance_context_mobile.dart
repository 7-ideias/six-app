import 'package:flutter/material.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/l10n/six_i18n.dart';

Duration financeContextDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : const Duration(milliseconds: 350);

Color financeContextTopColor(BuildContext context, String space) =>
    space == 'PESSOAL'
    ? const Color(0xFF39352D)
    : context.sixMobileColors.primary;

class FinanceContextSelectorMobile extends StatelessWidget {
  const FinanceContextSelectorMobile({
    super.key,
    required this.space,
    this.onChanged,
  });
  final String space;
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) {
    final c = context.sixMobileColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = (space == 'PESSOAL')
        ? (dark ? const Color(0xFF594C32) : const Color(0xFFF4E8CC))
        : c.softAccentSurface;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedAlign(
                duration: financeContextDuration(context),
                curve: Curves.easeInOutCubic,
                alignment: (space == 'PESSOAL')
                    ? AlignmentDirectional.centerEnd
                    : AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: .5,
                  heightFactor: 1,
                  child: AnimatedContainer(
                    duration: financeContextDuration(context),
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final option in ['EMPRESA', 'PESSOAL'])
                  Expanded(
                    child: Semantics(
                      selected: space == option,
                      button: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onChanged == null
                            ? null
                            : () {
                                if (space != option) onChanged!(option);
                              },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  option == 'EMPRESA'
                                      ? Icons.storefront_outlined
                                      : Icons.person_outline,
                                  size: 19,
                                  color: c.titleText,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    context.t('space.$option'),
                                    style: TextStyle(
                                      color: c.titleText,
                                      fontSize: 14,
                                      fontWeight: space == option
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class FinanceContextBackgroundMobile extends StatelessWidget {
  const FinanceContextBackgroundMobile({
    super.key,
    required this.space,
    required this.child,
  });
  final String space;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = context.sixMobileColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final topColor = financeContextTopColor(context, space);
    return AnimatedContainer(
      duration: financeContextDuration(context),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0, .18, .44, .72, 1],
          colors: space == 'PESSOAL'
              ? [
                  topColor,
                  dark ? const Color(0xFF514730) : const Color(0xFFA99B7A),
                  dark ? const Color(0xFF302C23) : const Color(0xFFF0E5CD),
                  c.background,
                  c.background,
                ]
              : [
                  c.primary,
                  Color.lerp(c.primary, c.secondary, .5)!,
                  Color.lerp(c.secondary, c.background, .7)!,
                  c.background,
                  c.background,
                ],
        ),
      ),
      child: child,
    );
  }
}
