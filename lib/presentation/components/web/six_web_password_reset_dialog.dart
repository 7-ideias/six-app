import 'package:flutter/material.dart';

import '../../../core/services/admin_portal_service.dart';
import '../../../l10n/admin_password_reset_texts.dart';
import '../../theme/web_theme_tokens.dart';
import 'six_web_animated_dialog.dart';

Future<bool?> showSixWebPasswordResetDialog({
  required BuildContext context,
  required String userName,
  required String userId,
  required Future<void> Function() onConfirm,
}) => showSixWebAnimatedDialog<bool>(
  context: context,
  barrierDismissible: false,
  barrierLabel: adminPasswordResetText(context, 'title'),
  builder: (_) => _PasswordResetDialog(
    userName: userName, userId: userId, onConfirm: onConfirm,
  ),
);

enum _Phase { review, processing, success, error }

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog({required this.userName, required this.userId, required this.onConfirm});
  final String userName;
  final String userId;
  final Future<void> Function() onConfirm;

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  _Phase _phase = _Phase.review;
  String _error = 'error';
  bool get _busy => _phase == _Phase.processing || _phase == _Phase.success;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _phase = _Phase.processing);
    try {
      await widget.onConfirm();
      if (!mounted) return;
      setState(() => _phase = _Phase.success);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is AdminPasswordResetException ? error.messageKey : 'error';
        _phase = _Phase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    final success = _phase == _Phase.success;
    final title = adminPasswordResetText(context, success ? 'success' : 'title');
    return PopScope(
      canPop: !_busy,
      child: Semantics(
        namesRoute: true,
        label: title,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Material(
            color: tokens.cardBackground,
            borderRadius: BorderRadius.circular(24),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 240),
                    child: Icon(success ? Icons.check_circle_rounded : Icons.lock_reset_rounded,
                      key: ValueKey(success), size: 36,
                      color: success ? tokens.success : tokens.warning),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: TextStyle(color: tokens.primaryText, fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Text(widget.userName, style: TextStyle(color: tokens.primaryText, fontWeight: FontWeight.w700)),
                  Text(widget.userId, style: TextStyle(color: tokens.mutedText)),
                  const SizedBox(height: 16),
                  if (!success) Text(adminPasswordResetText(context, 'message'), style: TextStyle(color: tokens.primaryText)),
                  if (_phase == _Phase.processing) ...[
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    Semantics(liveRegion: true, child: Text(adminPasswordResetText(context, 'processing'), style: TextStyle(color: tokens.primaryText))),
                  ],
                  if (_phase == _Phase.error) ...[
                    const SizedBox(height: 16),
                    Semantics(liveRegion: true, child: Text(adminPasswordResetText(context, _error), style: TextStyle(color: tokens.danger))),
                  ],
                  const SizedBox(height: 24),
                  Wrap(spacing: 12, runSpacing: 12, children: [
                    OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                      child: Text(adminPasswordResetText(context, 'cancel')),
                    ),
                    FilledButton.icon(
                      onPressed: _busy ? null : _confirm,
                      icon: const Icon(Icons.lock_reset_rounded),
                      label: Text(adminPasswordResetText(context, _phase == _Phase.error ? 'retry' : 'confirm')),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
