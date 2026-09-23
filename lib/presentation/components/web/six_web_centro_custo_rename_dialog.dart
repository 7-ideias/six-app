import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sixpos/data/models/agenda_financeira_lancamento_model.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

enum _RenameState { edit, review, processing, success, error }

Future<CentroCustoModel?> showSixWebCentroCustoRenameDialog({
  required BuildContext context,
  required CentroCustoModel centro,
  required Future<CentroCustoModel> Function(String nome) onConfirm,
}) {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  return showGeneralDialog<CentroCustoModel>(
    context: context,
    barrierDismissible: false,
    barrierLabel: context.t(
      'agenda.costCenter.rename.barrier',
      fallback: 'Revisar alteração do centro de custos',
    ),
    barrierColor: Colors.transparent,
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 300),
    pageBuilder: (BuildContext context, _, __) =>
        _CentroCustoRenameDialog(centro: centro, onConfirm: onConfirm),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

class _CentroCustoRenameDialog extends StatefulWidget {
  const _CentroCustoRenameDialog({
    required this.centro,
    required this.onConfirm,
  });

  final CentroCustoModel centro;
  final Future<CentroCustoModel> Function(String nome) onConfirm;

  @override
  State<_CentroCustoRenameDialog> createState() =>
      _CentroCustoRenameDialogState();
}

class _CentroCustoRenameDialogState extends State<_CentroCustoRenameDialog> {
  late final TextEditingController _nomeController;
  _RenameState _state = _RenameState.edit;
  String _novoNome = '';
  String _erro = '';

  bool get _busy =>
      _state == _RenameState.processing || _state == _RenameState.success;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.centro.nome);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _review() {
    final String nome = _nomeController.text.trim();
    if (nome.isEmpty || nome == widget.centro.nome.trim()) return;
    setState(() {
      _novoNome = nome;
      _state = _RenameState.review;
      _erro = '';
    });
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() {
      _state = _RenameState.processing;
      _erro = '';
    });
    try {
      final CentroCustoModel atualizado = await widget.onConfirm(_novoNome);
      if (!mounted) return;
      setState(() => _state = _RenameState.success);
      final bool reduceMotion = MediaQuery.of(context).disableAnimations;
      await Future<void>.delayed(
        Duration(milliseconds: reduceMotion ? 1 : 750),
      );
      if (mounted) Navigator.of(context).pop(atualizado);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _RenameState.error;
        _erro = context.t(
          'agenda.costCenter.rename.error',
          fallback: 'Não foi possível alterar o nome. Tente novamente.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return PopScope(
      canPop: !_busy,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(
                  key: const Key('centro-custo-rename-backdrop'),
                  color: const Color(0xC200163A),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Semantics(
                    namesRoute: true,
                    label: context.t(
                      'agenda.costCenter.rename.title',
                      fallback: 'Alterar nome do centro de custos',
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tokens.surfaceElevated,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: tokens.cardBorder),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x52020A18),
                              blurRadius: 44,
                              offset: Offset(0, 24),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Container(
                                height: 5,
                                color: _state == _RenameState.success
                                    ? tokens.success
                                    : tokens.warning,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(28),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _buildContent(tokens),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(WebThemeTokens tokens) {
    if (_state == _RenameState.processing) {
      return _feedback(
        key: const Key('centro-custo-rename-processing'),
        tokens: tokens,
        icon: Icons.sync_rounded,
        color: tokens.warning,
        title: context.t(
          'agenda.costCenter.rename.processing',
          fallback: 'Atualizando centro de custos...',
        ),
        body: context.t(
          'agenda.costCenter.rename.processingBody',
          fallback: 'Estamos mantendo os lançamentos vinculados consistentes.',
        ),
        progress: true,
      );
    }
    if (_state == _RenameState.success) {
      return _feedback(
        key: const Key('centro-custo-rename-success'),
        tokens: tokens,
        icon: Icons.check_circle_outline_rounded,
        color: tokens.success,
        title: context.t(
          'agenda.costCenter.rename.success',
          fallback: 'Nome atualizado',
        ),
        body: context.t(
          'agenda.costCenter.rename.successBody',
          fallback:
              'O histórico e os relatórios continuam vinculados ao mesmo centro.',
        ),
      );
    }
    return _state == _RenameState.edit
        ? _buildEdit(tokens)
        : _buildReview(tokens);
  }

  Widget _buildEdit(WebThemeTokens tokens) {
    return Column(
      key: const Key('centro-custo-rename-edit'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _header(
          tokens,
          title: context.t(
            'agenda.costCenter.rename.title',
            fallback: 'Alterar nome do centro de custos',
          ),
          body: context.t(
            'agenda.costCenter.rename.editBody',
            fallback:
                'Informe o novo nome. Antes de salvar, você poderá revisar o impacto.',
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          key: const Key('centro-custo-rename-name'),
          controller: _nomeController,
          autofocus: true,
          maxLength: 120,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _review(),
          decoration: InputDecoration(
            labelText: context.t('agenda.costCenter.name', fallback: 'Nome'),
            prefixIcon: const Icon(Icons.account_tree_outlined),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.t('common.cancel', fallback: 'Cancelar')),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              key: const Key('centro-custo-rename-review'),
              onPressed:
                  _nomeController.text.trim().isEmpty ||
                      _nomeController.text.trim() == widget.centro.nome.trim()
                  ? null
                  : _review,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(
                context.t(
                  'agenda.costCenter.rename.reviewAction',
                  fallback: 'Revisar alteração',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReview(WebThemeTokens tokens) {
    return Column(
      key: ValueKey<_RenameState>(_state),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _header(
          tokens,
          title: context.t(
            'agenda.costCenter.rename.confirmTitle',
            fallback: 'Confirmar alteração?',
          ),
          body: context.t(
            'agenda.costCenter.rename.confirmBody',
            fallback: 'Revise os nomes antes de confirmar.',
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _nameBlock(
                  tokens,
                  'agenda.costCenter.rename.current',
                  'Nome atual',
                  widget.centro.nome,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Icon(Icons.arrow_forward_rounded, color: tokens.warning),
              ),
              Expanded(
                child: _nameBlock(
                  tokens,
                  'agenda.costCenter.rename.new',
                  'Novo nome',
                  _novoNome,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tokens.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.warning.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.info_outline_rounded, color: tokens.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.t(
                    'agenda.costCenter.rename.impact',
                    fallback:
                        'Os lançamentos já vinculados passarão a exibir o novo nome. Valores, datas e vínculos não serão alterados.',
                  ),
                  style: TextStyle(color: tokens.primaryText, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        if (_state == _RenameState.error) ...<Widget>[
          const SizedBox(height: 12),
          Text(_erro, style: TextStyle(color: tokens.danger)),
        ],
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() => _state = _RenameState.edit),
              child: Text(context.t('common.back', fallback: 'Voltar')),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              key: const Key('centro-custo-rename-confirm'),
              onPressed: _busy ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: tokens.warning,
                foregroundColor: tokens.onWarning,
              ),
              icon: const Icon(Icons.check_rounded),
              label: Text(
                _state == _RenameState.error
                    ? context.t('common.tryAgain', fallback: 'Tentar novamente')
                    : context.t(
                        'agenda.costCenter.rename.confirmAction',
                        fallback: 'Confirmar alteração',
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _header(
    WebThemeTokens tokens, {
    required String title,
    required String body,
  }) {
    return Column(
      children: <Widget>[
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: tokens.warning.withValues(alpha: 0.13),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.drive_file_rename_outline_rounded,
            color: tokens.warning,
            size: 34,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: tokens.primaryText,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.secondaryText, height: 1.4),
        ),
      ],
    );
  }

  Widget _nameBlock(
    WebThemeTokens tokens,
    String key,
    String fallback,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.t(key, fallback: fallback),
          style: TextStyle(color: tokens.secondaryText, fontSize: 12),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: tokens.primaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _feedback({
    required Key key,
    required WebThemeTokens tokens,
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    bool progress = false,
  }) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: progress
              ? Padding(
                  padding: const EdgeInsets.all(22),
                  child: CircularProgressIndicator(
                    color: color,
                    strokeWidth: 3,
                  ),
                )
              : Icon(icon, color: color, size: 38),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: tokens.primaryText,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.secondaryText, height: 1.45),
        ),
      ],
    );
  }
}
