import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/produto_imagem_model.dart';
import '../../../l10n/six_i18n.dart';
import '../../controllers/pdv_selecao_imagens_controller.dart';
import '../../theme/web_theme_tokens.dart';
import '../produto_web_image.dart';
import '../six_cached_network_image.dart';

class PdvSeletorItensWeb extends StatelessWidget {
  const PdvSeletorItensWeb({
    super.key,
    required this.tipo,
    required this.onTipo,
    required this.onAtualizar,
    required this.multipla,
    required this.revisando,
    required this.grade,
    required this.onRevisar,
    required this.onLimpar,
    required this.onConfirmar,
    required this.quantidade,
    required this.subtotal,
    required this.controles,
    required this.estado,
    required this.itemCount,
    required this.itemBuilder,
  });

  final String tipo, subtotal;
  final ValueChanged<String> onTipo;
  final VoidCallback onAtualizar, onRevisar, onLimpar, onConfirmar;
  final bool multipla, revisando, grade;
  final int quantidade, itemCount;
  final Widget? controles, estado;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return Material(
      color: tokens.surfaceElevated,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pad = constraints.maxWidth < 600 ? 14.0 : 24.0;
          final curto = constraints.maxHeight < 570 * scale;
          final cabecalho = Padding(
            padding: EdgeInsets.fromLTRB(pad, 10, pad, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (revisando)
                      IconButton(
                        tooltip: context.t('common.back'),
                        onPressed: onRevisar,
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      Icon(Icons.shopping_basket_outlined, color: tokens.info),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.t(
                          revisando
                              ? 'pdv.selection.review'
                              : multipla
                              ? 'produto.webList.selection.titleMany'
                              : 'produto.webList.selection.titleOne',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (revisando)
                      IconButton(
                        tooltip: context.t('common.clear'),
                        onPressed: onLimpar,
                        icon: const Icon(Icons.clear_all_rounded),
                      )
                    else
                      IconButton(
                        tooltip: context.t('common.refresh'),
                        onPressed: onAtualizar,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    IconButton(
                      tooltip: context.t('common.close'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                if (!revisando) ...[
                  const SizedBox(height: 6),
                  _AbasCategoria(tipo: tipo, onTipo: onTipo),
                  if (controles != null) ...[
                    const SizedBox(height: 12),
                    controles!,
                  ],
                ],
              ],
            ),
          );
          final children = SliverChildBuilderDelegate(
            itemBuilder,
            childCount: itemCount,
          );
          final largura = constraints.maxWidth - 2 * pad;
          final colunas = math.max(
            1,
            ((largura + 12) / (225 * math.max(1.0, scale) + 12)).floor(),
          );
          final resultados = CustomScrollView(
            key: ValueKey((tipo, revisando, grade)),
            primary: false,
            shrinkWrap: true,
            slivers: [
              if (curto) SliverToBoxAdapter(child: cabecalho),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 2, pad, 12),
                sliver:
                    estado != null
                        ? SliverToBoxAdapter(child: estado)
                        : grade
                        ? SliverGrid(
                          delegate: children,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: colunas,
                                mainAxisExtent:
                                    118 + 100 * math.max(1.0, scale),
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                              ),
                        )
                        : SliverList(delegate: children),
              ),
            ],
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!curto) cabecalho,
              Flexible(child: resultados),
              if (multipla && (controles != null || quantidade > 0))
                _rodape(context, pad, largura < 530 * scale),
            ],
          );
        },
      ),
    );
  }

  Widget _rodape(BuildContext context, double pad, bool compacto) {
    final tokens = WebThemeTokens.of(context);
    final selecionados = quantidade > 0;
    final resumo = TextButton.icon(
      onPressed: selecionados ? onRevisar : null,
      icon: Icon(revisando ? Icons.expand_less : Icons.expand_more, size: 18),
      label: Text(context.pdvSelectedItems(quantidade)),
    );
    final valor = Text(
      '${context.t('pdv.selection.subtotal')}  $subtotal',
      style: TextStyle(fontWeight: FontWeight.w700, color: tokens.primaryText),
    );
    final confirmar = FilledButton(
      onPressed: selecionados ? onConfirmar : null,
      child: Text(context.t('pdv.selection.addToSale')),
    );
    final dados = Wrap(
      spacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [resumo, if (selecionados) valor],
    );
    return Container(
      padding: EdgeInsets.symmetric(horizontal: pad, vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.cardBorder)),
      ),
      child:
          compacto
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [dados, confirmar],
              )
              : Row(children: [Expanded(child: dados), confirmar]),
    );
  }
}

class _AbasCategoria extends StatelessWidget {
  const _AbasCategoria({required this.tipo, required this.onTipo});
  final String tipo;
  final ValueChanged<String> onTipo;

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    final imagens = context.watch<PdvSelecaoImagensController?>();
    return Wrap(
      spacing: 6,
      children: [
        for (final categoria in ['PRODUTO', 'SERVICO'])
          Builder(
            builder: (context) {
              final produto = categoria == 'PRODUTO';
              final ativo = tipo == categoria;
              final url = imagens?.url(categoria);
              final icone = Icon(
                produto
                    ? Icons.inventory_2_outlined
                    : Icons.design_services_outlined,
                size: 18,
                color: ativo ? tokens.info : tokens.secondaryText,
              );
              return Semantics(
                selected: ativo,
                button: true,
                inMutuallyExclusiveGroup: true,
                child: InkWell(
                  key: ValueKey('pdv-categoria-$categoria'),
                  onTap: () => onTipo(categoria),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          width: 2,
                          color: ativo ? tokens.info : tokens.cardBorder,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 44,
                            height: 30,
                            child: ColoredBox(
                              color: tokens.surfaceMuted,
                              child:
                                  url == null
                                      ? icone
                                      : SixCachedNetworkImage(
                                        key: ValueKey(url),
                                        imageUrl: url,
                                        alignment: Alignment.centerRight,
                                        fit: BoxFit.cover,
                                        placeholder: icone,
                                        errorBuilder: (_, __, ___) => icone,
                                      ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          context.t(
                            produto
                                ? 'catalogHub.modules.products'
                                : 'catalogHub.modules.services',
                          ),
                          style: TextStyle(
                            color:
                                ativo
                                    ? tokens.primaryText
                                    : tokens.secondaryText,
                            fontWeight:
                                ativo ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class PdvBuscaWeb extends StatelessWidget {
  const PdvBuscaWeb({
    super.key,
    required this.busca,
    required this.modos,
    required this.filtros,
    required this.abertos,
    required this.ativos,
    required this.onFiltros,
  });
  final Widget busca, modos, filtros;
  final bool abertos;
  final int ativos;
  final VoidCallback onFiltros;

  @override
  Widget build(BuildContext context) {
    final label = context.t('pdv.selection.filters');
    final botao = OutlinedButton.icon(
      onPressed: onFiltros,
      icon: Icon(abertos ? Icons.expand_less : Icons.tune_rounded, size: 18),
      label: Text(ativos == 0 ? label : '$label ($ativos)'),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final modo = SizedBox(
          width: math.min(constraints.maxWidth, 196),
          child: modos,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (constraints.maxWidth >= 660)
              Row(
                children: [
                  Expanded(child: busca),
                  const SizedBox(width: 12),
                  botao,
                  const SizedBox(width: 10),
                  modo,
                ],
              )
            else ...[
              busca,
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [botao, modo],
              ),
            ],
            if (abertos) ...[const SizedBox(height: 8), filtros],
          ],
        );
      },
    );
  }
}

class PdvItemSelecaoWeb extends StatelessWidget {
  const PdvItemSelecaoWeb({
    super.key,
    required this.grade,
    required this.nome,
    required this.codigo,
    required this.preco,
    required this.imagem,
    required this.icone,
    required this.quantidade,
    required this.onSelecionar,
    required this.onEditar,
    required this.onQuantidade,
  });
  final bool grade;
  final String nome, codigo, preco;
  final ProdutoImagemModel? imagem;
  final IconData icone;
  final int quantidade;
  final VoidCallback onSelecionar, onEditar;
  final ValueChanged<int> onQuantidade;

  @override
  Widget build(BuildContext context) {
    final tokens = WebThemeTokens.of(context);
    final selecionado = quantidade > 0;
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final foto = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ColoredBox(
        color: tokens.surfaceMuted,
        child: ProdutoWebImage(
          image: imagem,
          preferThumbnail: true,
          fallback: Center(
            child: Icon(
              icone,
              size: grade ? 36 : 20,
              color: tokens.secondaryText,
            ),
          ),
        ),
      ),
    );
    final nomeCodigo = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nome,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: tokens.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          codigo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: tokens.secondaryText),
        ),
      ],
    );
    final valor = Text(
      preco,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontWeight: FontWeight.w700, color: tokens.primaryText),
    );
    final qtd = _acoes(context);
    return Material(
      color: selecionado ? tokens.selectedBackground : tokens.cardBackground,
      shape:
          grade
              ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      selecionado ? tokens.selectedBorder : tokens.cardBorder,
                ),
              )
              : Border(bottom: BorderSide(color: tokens.cardBorder)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: selecionado ? onEditar : onSelecionar,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child:
              grade
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: foto),
                      const SizedBox(height: 8),
                      nomeCodigo,
                      Row(children: [Expanded(child: valor), qtd]),
                    ],
                  )
                  : LayoutBuilder(
                    builder: (context, constraints) {
                      final estreito = constraints.maxWidth < 520 * scale;
                      return Row(
                        children: [
                          SizedBox.square(dimension: 40, child: foto),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [nomeCodigo, if (estreito) valor],
                            ),
                          ),
                          if (!estreito)
                            SizedBox(width: 132 * scale, child: valor),
                          SizedBox(
                            width: estreito ? null : 116,
                            child: Align(
                              alignment: Alignment.centerRight,
                              widthFactor: 1,
                              child: qtd,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
        ),
      ),
    );
  }

  Widget _acoes(BuildContext context) {
    Widget botao(IconData icone, String texto, VoidCallback acao) => IconButton(
      tooltip: '$texto · $nome',
      constraints: const BoxConstraints.tightFor(width: 34, height: 36),
      padding: EdgeInsets.zero,
      onPressed: acao,
      icon: Icon(icone, size: 18),
    );
    final aumentar = context.t('pdv.selection.increase');
    if (quantidade == 0) {
      return botao(
        Icons.add_rounded,
        context.t('procedimentos.addItem'),
        onSelecionar,
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        botao(
          Icons.remove_rounded,
          context.t('pdv.selection.decrease'),
          () => onQuantidade(-1),
        ),
        Tooltip(
          message: context.t('pdv.quantityEditor.tooltip'),
          child: InkWell(
            onTap: onEditar,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 30,
                maxWidth: 48,
                minHeight: 36,
              ),
              child: Center(
                widthFactor: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('$quantidade'),
                ),
              ),
            ),
          ),
        ),
        botao(Icons.add_rounded, aumentar, () => onQuantidade(1)),
      ],
    );
  }
}
