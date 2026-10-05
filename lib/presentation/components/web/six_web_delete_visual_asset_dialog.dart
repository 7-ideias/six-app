import 'package:flutter/material.dart';
import '../../admin/admin_visual_asset_settings_texts.dart';
import '../../theme/web_theme_tokens.dart';
import 'six_web_animated_dialog.dart';

Future<bool> showSixWebDeleteVisualAssetDialog({
  required BuildContext context,
  required String title,
  required String target,
  required Future<void> Function() onConfirm,
}) async =>
    await showSixWebAnimatedDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: AdminVisualAssetSettingsTexts(context).delete,
      builder:
          (_) => SixWebDeleteVisualAssetDialog(
            title: title,
            target: target,
            onConfirm: onConfirm,
          ),
    ) ??
    false;

enum _DeleteState { review, processing, success, error }

class SixWebDeleteVisualAssetDialog extends StatefulWidget {
  const SixWebDeleteVisualAssetDialog({
    super.key,
    required this.title,
    required this.target,
    required this.onConfirm,
  });
  final String title, target;
  final Future<void> Function() onConfirm;
  @override
  State<SixWebDeleteVisualAssetDialog> createState() =>
      _SixWebDeleteVisualAssetDialogState();
}

class _SixWebDeleteVisualAssetDialogState
    extends State<SixWebDeleteVisualAssetDialog> {
  _DeleteState _state = _DeleteState.review;
  bool _missingDefault = false;
  bool get _busy =>
      _state == _DeleteState.processing || _state == _DeleteState.success;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _state = _DeleteState.processing);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      setState(() => _state = _DeleteState.success);
      await Future<void>.delayed(const Duration(milliseconds: 750));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _missingDefault = error.toString().contains(
            'ASSET_PADRAO_GLOBAL_OBRIGATORIO',
          );
          _state = _DeleteState.error;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AdminVisualAssetSettingsTexts(context);
    final tokens = WebThemeTokens.of(context);
    final success = _state == _DeleteState.success;
    return PopScope(
      canPop: !_busy,
      child: Semantics(
        namesRoute: true,
        label: t.delete,
        child: Dialog(
          backgroundColor: tokens.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.9, end: 1),
                    duration: Duration(
                      milliseconds:
                          MediaQuery.disableAnimationsOf(context) ? 1 : 600,
                    ),
                    builder:
                        (_, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                    child: Icon(
                      success
                          ? Icons.check_circle_outline
                          : Icons.delete_outline,
                      color: success ? tokens.success : tokens.warning,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    success ? t.deleted : t.delete,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(widget.target),
                  const SizedBox(height: 12),
                  Text(t.consequence),
                  if (_state == _DeleteState.processing) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                    Text(t.deleting),
                  ],
                  if (_state == _DeleteState.error) ...[
                    const SizedBox(height: 16),
                    Text(
                      _missingDefault ? t.globalRequired : t.error,
                      style: TextStyle(color: tokens.danger),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _busy
                                ? null
                                : () => Navigator.of(context).pop(false),
                        child: Text(t.cancel),
                      ),
                      FilledButton(
                        onPressed: _busy ? null : _confirm,
                        child: Text(
                          _state == _DeleteState.error ? t.retry : t.delete,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
