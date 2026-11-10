import 'package:flutter/material.dart';

import '../../../core/services/admin_portal_service.dart';
import '../../../design_system/themes/six_mobile_color_scheme.dart';
import '../../../l10n/admin_password_reset_texts.dart';

Future<bool?> showSixMobilePasswordResetSheet({
  required BuildContext context,
  required String userName,
  required String userId,
  required Future<void> Function() onConfirm,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: false,
  enableDrag: false,
  backgroundColor: context.sixMobileColors.surface,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
  builder: (_) => _PasswordResetSheet(userName: userName, userId: userId, onConfirm: onConfirm),
);

enum _Phase { review, processing, success, error }

class _PasswordResetSheet extends StatefulWidget {
  const _PasswordResetSheet({required this.userName, required this.userId, required this.onConfirm});
  final String userName;
  final String userId;
  final Future<void> Function() onConfirm;

  @override
  State<_PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends State<_PasswordResetSheet> {
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
    final colors = context.sixMobileColors;
    final success = _phase == _Phase.success;
    return PopScope(
      canPop: !_busy,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(success ? Icons.check_circle_rounded : Icons.lock_reset_rounded,
                color: success ? colors.accent : colors.error, size: 32),
              const SizedBox(height: 16),
              Semantics(namesRoute: true, liveRegion: true,
                child: Text(adminPasswordResetText(context, success ? 'success' : 'title'),
                  style: TextStyle(color: colors.titleText, fontSize: 20, fontWeight: FontWeight.w800))),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: colors.softSurface, borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.userName, style: TextStyle(color: colors.titleText, fontWeight: FontWeight.w700)),
                  Text(widget.userId, style: TextStyle(color: colors.mutedText)),
                ]),
              ),
              const SizedBox(height: 16),
              if (!success) Text(adminPasswordResetText(context, 'message'), style: TextStyle(color: colors.titleText)),
              if (_phase == _Phase.processing) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(color: colors.accent),
                const SizedBox(height: 12),
                Semantics(liveRegion: true, child: Text(adminPasswordResetText(context, 'processing'), style: TextStyle(color: colors.titleText))),
              ],
              if (_phase == _Phase.error) ...[
                const SizedBox(height: 16),
                Semantics(liveRegion: true, child: Text(adminPasswordResetText(context, _error), style: TextStyle(color: colors.error))),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: colors.accent, foregroundColor: colors.onAccent, minimumSize: const Size.fromHeight(48)),
                onPressed: _busy ? null : _confirm,
                icon: const Icon(Icons.lock_reset_rounded),
                label: Text(adminPasswordResetText(context, _phase == _Phase.error ? 'retry' : 'confirm')),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: colors.titleText, backgroundColor: colors.softSurface, minimumSize: const Size.fromHeight(48)),
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                child: Text(adminPasswordResetText(context, 'cancel')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
