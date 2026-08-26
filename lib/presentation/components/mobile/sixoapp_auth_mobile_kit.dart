import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';

class SixoAppAuthMobileScaffold extends StatefulWidget {
  const SixoAppAuthMobileScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
    this.onBack,
    this.backSemanticLabel,
    this.featureLabels = const <String>[],
    this.compactHeader = false,
    this.minimumSurfaceHeight = 0,
  });

  final String title;
  final String subtitle;
  final Widget body;
  final VoidCallback? onBack;
  final String? backSemanticLabel;
  final List<String> featureLabels;
  final bool compactHeader;
  final double minimumSurfaceHeight;

  @override
  State<SixoAppAuthMobileScaffold> createState() =>
      _SixoAppAuthMobileScaffoldState();
}

class _SixoAppAuthMobileScaffoldState
    extends State<SixoAppAuthMobileScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
    if (reduceMotion == _reduceMotion) return;

    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _ambientController
        ..stop()
        ..value = 0.38;
    } else if (!_ambientController.isAnimating) {
      _ambientController.repeat();
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: SixMobilePalette.brandNavyDeep,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: SixMobilePalette.brandNavyDeep,
        resizeToAvoidBottomInset: true,
        body: AnimatedBuilder(
          animation: _ambientController,
          builder: (BuildContext context, Widget? child) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.58),
                      radius: 1.18,
                      colors: <Color>[
                        SixMobilePalette.brandNavyBright,
                        SixMobilePalette.brandNavy,
                        SixMobilePalette.brandNavyDeep,
                      ],
                      stops: <double>[0, 0.50, 1],
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: CustomPaint(
                    painter: _SixoAppAuthBackgroundPainter(
                      progress: _ambientController.value,
                      reduceMotion: _reduceMotion,
                    ),
                  ),
                ),
                child!,
              ],
            );
          },
          child: SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool short = constraints.maxHeight < 690;
                final double horizontalPadding = 20;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _SixoAppAuthTopBar(
                            onBack: widget.onBack,
                            backSemanticLabel: widget.backSemanticLabel,
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              widget.compactHeader || short ? 2 : 12,
                              horizontalPadding,
                              widget.compactHeader ? 18 : 26,
                            ),
                            child: _SixoAppAuthHero(
                              title: widget.title,
                              subtitle: widget.subtitle,
                              compact: widget.compactHeader || short,
                              animation: _ambientController,
                              reduceMotion: _reduceMotion,
                              featureLabels: widget.featureLabels,
                            ),
                          ),
                          const Spacer(),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: widget.minimumSurfaceHeight,
                            ),
                            child: _SixoAppAuthSurface(child: widget.body),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SixoAppAuthTopBar extends StatelessWidget {
  const _SixoAppAuthTopBar({
    required this.onBack,
    required this.backSemanticLabel,
  });

  final VoidCallback? onBack;
  final String? backSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: onBack == null ? 24 : 52,
      child: onBack == null
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  tooltip: backSemanticLabel,
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: SixMobilePalette.onPrimary,
                  iconSize: 20,
                  style: IconButton.styleFrom(
                    backgroundColor: SixMobilePalette.onPrimary.withValues(
                      alpha: 0.08,
                    ),
                    side: BorderSide(
                      color: SixMobilePalette.onPrimary.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _SixoAppAuthHero extends StatelessWidget {
  const _SixoAppAuthHero({
    required this.title,
    required this.subtitle,
    required this.compact,
    required this.animation,
    required this.reduceMotion,
    required this.featureLabels,
  });

  final String title;
  final String subtitle;
  final bool compact;
  final Animation<double> animation;
  final bool reduceMotion;
  final List<String> featureLabels;

  @override
  Widget build(BuildContext context) {
    final double symbolSize = compact ? 72 : 108;

    return Column(
      children: <Widget>[
        Semantics(
          image: true,
          label: 'SixoApp',
          child: AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double progress = animation.value;
              return Transform.scale(
                scale: reduceMotion
                    ? 1
                    : 1 + math.sin(progress * math.pi * 2) * 0.008,
                child: _SixoAppAuthSymbol(
                  size: symbolSize,
                  progress: progress,
                  reduceMotion: reduceMotion,
                ),
              );
            },
          ),
        ),
        SizedBox(height: compact ? 8 : 12),
        const Text(
          'SixoApp',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SixMobilePalette.onPrimary,
            fontSize: 22,
            height: 1,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: compact ? 18 : 26),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SixMobilePalette.onPrimary,
            fontSize: compact ? 26 : 32,
            height: 1.08,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            subtitle,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SixMobilePalette.brandSupportingText,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (featureLabels.isNotEmpty) ...<Widget>[
          SizedBox(height: compact ? 16 : 22),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: featureLabels
                .map((String label) => _SixoAppAuthFeaturePill(label: label))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class _SixoAppAuthSymbol extends StatelessWidget {
  const _SixoAppAuthSymbol({
    required this.size,
    required this.progress,
    required this.reduceMotion,
  });

  final double size;
  final double progress;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  SixMobilePalette.brandCyan.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
                stops: const <double>[0, 0.74],
              ),
            ),
          ),
          Image.asset(
            'assets/images/sixoapp_splash_symbol.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          if (!reduceMotion)
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect bounds) {
                final double center = -1.45 + progress * 2.9;
                return LinearGradient(
                  begin: Alignment(center - 0.45, -1),
                  end: Alignment(center + 0.45, 1),
                  colors: const <Color>[
                    Colors.transparent,
                    Color(0xD9FFFFFF),
                    Colors.transparent,
                  ],
                  stops: const <double>[0.36, 0.5, 0.64],
                ).createShader(bounds);
              },
              child: Image.asset(
                'assets/images/sixoapp_splash_symbol.png',
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}

class _SixoAppAuthFeaturePill extends StatelessWidget {
  const _SixoAppAuthFeaturePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SixMobilePalette.onPrimary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: SixMobilePalette.brandCyan.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: SixMobilePalette.brandSupportingText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SixoAppAuthSurface extends StatelessWidget {
  const _SixoAppAuthSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: SixMobilePalette.brandCyan.withValues(alpha: 0.16),
          ),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 34,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SixoAppAuthField extends StatelessWidget {
  const SixoAppAuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.enableSuggestions = true,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final bool enableSuggestions;
  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      cursorColor: SixMobilePalette.brandBlue,
      style: TextStyle(
        color: colors.titleText,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: colors.mutedText, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: colors.softSurface,
        labelStyle: TextStyle(
          color: colors.mutedText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: SixMobilePalette.brandBlue,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: colors.mutedText, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: SixMobilePalette.brandBlue,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class SixoAppAuthPrimaryButton extends StatelessWidget {
  const SixoAppAuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(17),
        gradient: const LinearGradient(
          colors: <Color>[
            SixMobilePalette.brandCyan,
            SixMobilePalette.brandBlue,
          ],
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: SixMobilePalette.brandBlue.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: SixMobilePalette.onPrimary,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  color: SixMobilePalette.onPrimary,
                  strokeWidth: 2.4,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 19),
                    const SizedBox(width: 9),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class SixoAppAuthSecondaryButton extends StatelessWidget {
  const SixoAppAuthSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.softSurface,
          foregroundColor: colors.titleText,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (leading != null) ...<Widget>[
              leading!,
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SixoAppAuthDivider extends StatelessWidget {
  const SixoAppAuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final SixMobileColorScheme colors = context.sixMobileColors;
    return Row(
      children: <Widget>[
        Expanded(child: Divider(color: colors.border)),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.mutedText,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(child: Divider(color: colors.border)),
      ],
    );
  }
}

class _SixoAppAuthBackgroundPainter extends CustomPainter {
  const _SixoAppAuthBackgroundPainter({
    required this.progress,
    required this.reduceMotion,
  });

  final double progress;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final double phase = reduceMotion ? 0.38 : progress;
    final Paint arcPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = SixMobilePalette.brandBlue.withValues(alpha: 0.13);

    final Path upperArc =
        Path()
          ..moveTo(-size.width * 0.18, size.height * 0.28)
          ..quadraticBezierTo(
            size.width * 0.42,
            -size.height * 0.12,
            size.width * 1.12,
            size.height * 0.18,
          );
    canvas.drawPath(upperArc, arcPaint);

    for (int index = 0; index < 4; index++) {
      final double y = size.height * (0.52 + index * 0.035);
      final double amplitude = size.height * (0.020 + index * 0.004);
      final double drift =
          math.sin((phase + index * 0.17) * math.pi * 2) * 7;
      final Path wave =
          Path()
            ..moveTo(-size.width * 0.10, y + drift)
            ..cubicTo(
              size.width * 0.18,
              y - amplitude,
              size.width * 0.34,
              y + amplitude,
              size.width * 0.53,
              y,
            )
            ..cubicTo(
              size.width * 0.72,
              y - amplitude,
              size.width * 0.84,
              y + amplitude,
              size.width * 1.10,
              y - amplitude * 0.35,
            );
      canvas.drawPath(
        wave,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = index == 0 ? 1.1 : 0.7
          ..color = SixMobilePalette.brandCyan.withValues(
            alpha: index == 0 ? 0.22 : 0.09,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SixoAppAuthBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.reduceMotion != reduceMotion;
  }
}
