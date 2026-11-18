import 'package:flutter/material.dart';
import 'package:sixpos/presentation/components/marca_financeira_avatar.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

/// Cartão compacto do painel Web; não é reaproveitado na composição Mobile.
class ConfiguracaoFinanceiraMarcaCard extends StatefulWidget {
  const ConfiguracaoFinanceiraMarcaCard({
    super.key,
    required this.nome,
    required this.descricao,
    required this.ativo,
    required this.tipo,
    required this.onEdit,
    required this.textoStatus,
    required this.tooltipEditar,
    this.detalhe,
    this.logotipoUrl,
  });

  final String nome;
  final String descricao;
  final String? detalhe;
  final bool ativo;
  final String tipo;
  final String textoStatus;
  final String tooltipEditar;
  final String? logotipoUrl;
  final VoidCallback onEdit;

  @override
  State<ConfiguracaoFinanceiraMarcaCard> createState() =>
      _ConfiguracaoFinanceiraMarcaCardState();
}

class _ConfiguracaoFinanceiraMarcaCardState
    extends State<ConfiguracaoFinanceiraMarcaCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    final colors = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _hover ? tokens.hoverBackground : tokens.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hover
                ? tokens.info.withValues(alpha: 0.5)
                : tokens.cardBorder,
          ),
          boxShadow: _hover
              ? [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.11),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onEdit,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14,
              ),
              child: Row(
                children: [
                  MarcaFinanceiraAvatar(
                    nome: widget.descricao,
                    tipo: widget.tipo,
                    logotipoUrl: widget.logotipoUrl,
                    size: 50,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.nome,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: tokens.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.descricao,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: tokens.secondaryText,
                          ),
                        ),
                        if (widget.detalhe != null && widget.detalhe!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.detalhe!,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (MediaQuery.sizeOf(context).width >= 540)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: widget.ativo
                            ? tokens.success.withValues(alpha: 0.1)
                            : tokens.surfaceMuted,
                      ),
                      child: Text(
                        widget.textoStatus,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: widget.ativo ? tokens.success : tokens.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: widget.tooltipEditar,
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 19),
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
