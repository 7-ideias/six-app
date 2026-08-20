import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sixpos/data/models/documento_models.dart';
import 'package:sixpos/presentation/components/web/six_web_select_field.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';

import 'documento_web_i18n.dart';

class DocumentoEditorWebPage extends StatefulWidget {
  const DocumentoEditorWebPage({
    super.key,
    this.modeloInicial,
    this.novoModelo = false,
    required this.aoSalvar,
    required this.aoFechar,
  });

  final ModeloDocumento? modeloInicial;
  final bool novoModelo;
  final Future<ModeloDocumento> Function(ModeloDocumento modelo) aoSalvar;
  final VoidCallback aoFechar;

  @override
  State<DocumentoEditorWebPage> createState() => _DocumentoEditorWebPageState();
}

class _DocumentoEditorWebPageState extends State<DocumentoEditorWebPage> {
  late ModeloDocumento _modelo;
  late final TextEditingController _nomeController;
  late final TextEditingController _descricaoController;
  bool _editandoCabecalho = true;
  String? _idElementoSelecionado;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _modelo =
        widget.modeloInicial ??
        ModeloDocumento.novo(PerfilPaginaDocumento.a4Retrato);
    _nomeController = TextEditingController(text: _modelo.nome);
    _descricaoController = TextEditingController(text: _modelo.descricao);
    _idElementoSelecionado = _zonaAtual.elementos.firstOrNull?.id;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  ZonaDocumento get _zonaAtual =>
      _editandoCabecalho ? _modelo.cabecalho : _modelo.rodape;

  ElementoDocumento? get _elementoSelecionado => _zonaAtual.elementos
      .where((ElementoDocumento item) => item.id == _idElementoSelecionado)
      .firstOrNull;

  String _t(String key, String pt, String en, String es) =>
      documentoTr(context, key, pt: pt, en: en, es: es);

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Material(
      color: tokens.workspaceBackground,
      child: Column(
        children: <Widget>[
          SixWebDashboardHeader(
            icon: Icons.dashboard_customize_outlined,
            title: widget.novoModelo || widget.modeloInicial == null
                ? _t(
                    'documents.editor.newTitle',
                    'Novo modelo de documento',
                    'New document template',
                    'Nuevo modelo de documento',
                  )
                : _t(
                    'documents.editor.editTitle',
                    'Editar modelo de documento',
                    'Edit document template',
                    'Editar modelo de documento',
                  ),
            subtitle: _t(
              'documents.editor.subtitle',
              'Personalize somente o cabeçalho e o rodapé. O conteúdo operacional permanece protegido.',
              'Customize only the header and footer. Operational content remains protected.',
              'Personaliza solo el encabezado y el pie. El contenido operativo permanece protegido.',
            ),
            onBack: widget.aoFechar,
            actions: <Widget>[
              FilledButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _salvando
                      ? _t(
                          'documents.editor.saving',
                          'Salvando...',
                          'Saving...',
                          'Guardando...',
                        )
                      : _t(
                          'documents.editor.save',
                          'Salvar modelo',
                          'Save template',
                          'Guardar modelo',
                        ),
                ),
              ),
            ],
          ),
          if (_erro != null)
            Container(
              width: double.infinity,
              color: tokens.danger.withValues(alpha: 0.09),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Text(
                _erro!,
                style: TextStyle(
                  color: tokens.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (constraints.maxWidth >= 1180) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(width: 310, child: _painelConfiguracao()),
                      Expanded(child: _painelPreview()),
                      SizedBox(width: 330, child: _painelPropriedades()),
                    ],
                  );
                }
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: <Widget>[
                      _painelConfiguracao(compacto: true),
                      const SizedBox(height: 18),
                      SizedBox(height: 620, child: _painelPreview()),
                      const SizedBox(height: 18),
                      _painelPropriedades(compacto: true),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _painelConfiguracao({bool compacto = false}) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      decoration: compacto
          ? _painelDecoration(tokens)
          : BoxDecoration(
              color: tokens.surfaceElevated,
              border: Border(right: BorderSide(color: tokens.cardBorder)),
            ),
      child: ListView(
        shrinkWrap: compacto,
        physics: compacto ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          _tituloPainel(
            Icons.tune_rounded,
            _t(
              'documents.editor.configuration',
              'Configuração',
              'Configuration',
              'Configuración',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nomeController,
            decoration: InputDecoration(
              labelText: _t(
                'documents.editor.name',
                'Nome do modelo',
                'Template name',
                'Nombre del modelo',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descricaoController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: _t(
                'documents.editor.description',
                'Descrição',
                'Description',
                'Descripción',
              ),
            ),
          ),
          const SizedBox(height: 14),
          SixWebSelectField(
            label: _t(
              'documents.editor.pageProfile',
              'Formato do documento',
              'Document format',
              'Formato del documento',
            ),
            value: _rotuloPerfil(_modelo.perfilPagina),
            items: PerfilPaginaDocumento.values
                .map(_rotuloPerfil)
                .toList(growable: false),
            onSelected: (String label) {
              final PerfilPaginaDocumento perfil = PerfilPaginaDocumento.values
                  .firstWhere(
                    (PerfilPaginaDocumento item) =>
                        _rotuloPerfil(item) == label,
                  );
              if (perfil == _modelo.perfilPagina) return;
              final ModeloDocumento novo = ModeloDocumento.novo(perfil);
              setState(() {
                _modelo = novo.copyWith(
                  id: _modelo.id,
                  nome: _nomeController.text,
                  descricao: _descricaoController.text,
                  revisao: _modelo.revisao,
                );
                _editandoCabecalho = true;
                _idElementoSelecionado = _modelo.cabecalho.elementos.first.id;
              });
            },
          ),
          const SizedBox(height: 18),
          SegmentedButton<bool>(
            segments: <ButtonSegment<bool>>[
              ButtonSegment<bool>(
                value: true,
                icon: const Icon(Icons.vertical_align_top_rounded),
                label: Text(
                  _t(
                    'documents.editor.header',
                    'Cabeçalho',
                    'Header',
                    'Encabezado',
                  ),
                ),
              ),
              ButtonSegment<bool>(
                value: false,
                icon: const Icon(Icons.vertical_align_bottom_rounded),
                label: Text(
                  _t('documents.editor.footer', 'Rodapé', 'Footer', 'Pie'),
                ),
              ),
            ],
            selected: <bool>{_editandoCabecalho},
            onSelectionChanged: (Set<bool> value) {
              setState(() {
                _editandoCabecalho = value.first;
                _idElementoSelecionado = _zonaAtual.elementos.firstOrNull?.id;
              });
            },
          ),
          const SizedBox(height: 14),
          _campoNumero(
            label: _t(
              'documents.editor.zoneHeight',
              'Altura da área (mm)',
              'Area height (mm)',
              'Altura del área (mm)',
            ),
            valor: _zonaAtual.alturaMm,
            aoAlterar: (double valor) {
              final double limite = _modelo.perfilPagina.termico
                  ? (_editandoCabecalho ? 60 : 45)
                  : (_editandoCabecalho ? 55 : 35);
              _atualizarZona(
                _zonaAtual.copyWith(
                  alturaMm: valor.clamp(5, limite).toDouble(),
                ),
              );
            },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _zonaAtual.exibir,
            title: Text(
              _t(
                'documents.editor.showArea',
                'Exibir esta área',
                'Show this area',
                'Mostrar esta área',
              ),
            ),
            onChanged: (bool valor) =>
                _atualizarZona(_zonaAtual.copyWith(exibir: valor)),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _t(
                    'documents.editor.elements',
                    'Elementos',
                    'Elements',
                    'Elementos',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              PopupMenuButton<TipoElementoDocumento>(
                tooltip: _t(
                  'documents.editor.addElement',
                  'Adicionar elemento',
                  'Add element',
                  'Agregar elemento',
                ),
                onSelected: _adicionarElemento,
                itemBuilder: (_) => TipoElementoDocumento.values
                    .where(
                      (TipoElementoDocumento tipo) =>
                          tipo != TipoElementoDocumento.qrCode,
                    )
                    .map(
                      (TipoElementoDocumento tipo) => PopupMenuItem(
                        value: tipo,
                        child: Row(
                          children: <Widget>[
                            Icon(_iconeTipo(tipo), size: 18),
                            const SizedBox(width: 10),
                            Text(_rotuloTipo(tipo)),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
                child: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._zonaAtual.elementos.map(_itemElemento),
        ],
      ),
    );
  }

  Widget _painelPreview() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      color: tokens.workspaceBackground,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _tituloPainel(
            Icons.preview_outlined,
            _t(
              'documents.editor.preview',
              'Pré-visualização proporcional',
              'Proportional preview',
              'Vista previa proporcional',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t(
              'documents.editor.previewHint',
              'Arraste os elementos dentro das áreas coloridas. O PDF de teste confirma o resultado final.',
              'Drag elements inside the colored areas. The test PDF confirms the final result.',
              'Arrastra los elementos dentro de las áreas coloreadas. El PDF de prueba confirma el resultado final.',
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: tokens.secondaryText),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double larguraMm = _modelo.perfilPagina.larguraUtilMm;
                  final double alturaMm = _modelo.perfilPagina.alturaPreviewMm;
                  final double escala = math.min(
                    constraints.maxWidth / larguraMm,
                    constraints.maxHeight / alturaMm,
                  );
                  final double largura = larguraMm * escala;
                  final double altura = alturaMm * escala;
                  return Container(
                    width: largura,
                    height: altura,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        _modelo.perfilPagina.termico ? 6 : 10,
                      ),
                      border: Border.all(color: tokens.cardBorder),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: _modelo.cabecalho.alturaMm * escala,
                          child: _canvasZona(_modelo.cabecalho, true, escala),
                        ),
                        Expanded(child: _corpoBloqueado()),
                        SizedBox(
                          height: _modelo.rodape.alturaMm * escala,
                          child: _canvasZona(_modelo.rodape, false, escala),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _canvasZona(ZonaDocumento zona, bool cabecalho, double escala) {
    final bool ativa = _editandoCabecalho == cabecalho;
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return GestureDetector(
      onTap: () {
        setState(() {
          _editandoCabecalho = cabecalho;
          _idElementoSelecionado = zona.elementos.firstOrNull?.id;
        });
      },
      child: Container(
        color: ativa
            ? tokens.info.withValues(alpha: 0.11)
            : tokens.surfaceMuted.withValues(alpha: 0.65),
        child: Stack(
          children: zona.elementos
              .map(
                (ElementoDocumento elemento) => Positioned(
                  left: elemento.xMm * escala,
                  top: elemento.yMm * escala,
                  width: elemento.larguraMm * escala,
                  height: elemento.alturaMm * escala,
                  child: _elementoCanvas(elemento, zona, escala, cabecalho),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }

  Widget _elementoCanvas(
    ElementoDocumento elemento,
    ZonaDocumento zona,
    double escala,
    bool cabecalho,
  ) {
    final bool selecionado =
        elemento.id == _idElementoSelecionado &&
        _editandoCabecalho == cabecalho;
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final double tamanhoFonte =
        (elemento.propriedades['tamanhoFonte'] as num?)?.toDouble() ?? 9;
    return GestureDetector(
      onTap: () {
        setState(() {
          _editandoCabecalho = cabecalho;
          _idElementoSelecionado = elemento.id;
        });
      },
      onPanUpdate: (DragUpdateDetails details) {
        final double novoX = (elemento.xMm + details.delta.dx / escala)
            .clamp(0, _modelo.perfilPagina.larguraUtilMm - elemento.larguraMm)
            .toDouble();
        final double novoY = (elemento.yMm + details.delta.dy / escala)
            .clamp(0, zona.alturaMm - elemento.alturaMm)
            .toDouble();
        _substituirElemento(
          elemento.copyWith(xMm: novoX, yMm: novoY),
          cabecalho: cabecalho,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selecionado ? tokens.info : Colors.transparent,
            width: selecionado ? 1.5 : 0.5,
          ),
          color: selecionado
              ? tokens.info.withValues(alpha: 0.06)
              : Colors.transparent,
        ),
        alignment: Alignment.centerLeft,
        child: switch (elemento.tipo) {
          TipoElementoDocumento.texto => Text(
            _valorPreview(elemento),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: _alinhamentoPreview(elemento),
            style: TextStyle(
              color: _corPreview(elemento),
              fontWeight: elemento.propriedades['negrito'] == true
                  ? FontWeight.w800
                  : FontWeight.w500,
              fontSize: math.max(7.0, tamanhoFonte * escala * 0.42),
            ),
          ),
          TipoElementoDocumento.logo => Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.info.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.business_rounded,
              color: tokens.info,
              size: math.min(24.0, elemento.alturaMm * escala * 0.7),
            ),
          ),
          TipoElementoDocumento.linha => Divider(
            height: 1,
            thickness: 1,
            color: _corPreview(elemento),
          ),
          TipoElementoDocumento.qrCode => Icon(
            Icons.qr_code_2_rounded,
            color: tokens.primaryText,
            size: math.min(
              elemento.larguraMm * escala,
              elemento.alturaMm * escala,
            ),
          ),
          TipoElementoDocumento.paginacao => Text(
            _t(
              'documents.preview.page',
              'Página 1 de 1',
              'Page 1 of 1',
              'Página 1 de 1',
            ),
            style: TextStyle(
              color: tokens.secondaryText,
              fontSize: math.max(7.0, tamanhoFonte * escala * 0.42),
            ),
          ),
        },
      ),
    );
  }

  Widget _corpoBloqueado() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      width: double.infinity,
      color: tokens.workspaceBackground.withValues(alpha: 0.42),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.lock_outline_rounded, color: tokens.mutedText),
          const SizedBox(height: 6),
          Text(
            _t(
              'documents.editor.protectedBody',
              'Corpo protegido do relatório',
              'Protected report body',
              'Cuerpo protegido del informe',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tokens.secondaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < 4; i++) ...<Widget>[
            Container(
              height: 7,
              width: i.isEven ? 220 : 170,
              color: tokens.cardBorder.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }

  Widget _painelPropriedades({bool compacto = false}) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final ElementoDocumento? elemento = _elementoSelecionado;
    return Container(
      decoration: compacto
          ? _painelDecoration(tokens)
          : BoxDecoration(
              color: tokens.surfaceElevated,
              border: Border(left: BorderSide(color: tokens.cardBorder)),
            ),
      child: ListView(
        shrinkWrap: compacto,
        physics: compacto ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          _tituloPainel(
            Icons.edit_attributes_outlined,
            _t(
              'documents.editor.properties',
              'Propriedades',
              'Properties',
              'Propiedades',
            ),
          ),
          const SizedBox(height: 16),
          if (elemento == null)
            Text(
              _t(
                'documents.editor.selectElement',
                'Selecione um elemento no modelo para editar.',
                'Select a template element to edit.',
                'Selecciona un elemento del modelo para editar.',
              ),
              style: TextStyle(color: tokens.secondaryText),
            )
          else ...<Widget>[
            Row(
              children: <Widget>[
                Icon(_iconeTipo(elemento.tipo), color: tokens.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _rotuloTipo(elemento.tipo),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _t(
                    'documents.editor.deleteElement',
                    'Excluir elemento',
                    'Delete element',
                    'Eliminar elemento',
                  ),
                  onPressed: _excluirElementoSelecionado,
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: tokens.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (elemento.tipo == TipoElementoDocumento.texto)
              SixWebSelectField(
                label: _t(
                  'documents.editor.dynamicField',
                  'Campo dinâmico',
                  'Dynamic field',
                  'Campo dinámico',
                ),
                value: _rotuloVinculo(elemento.chaveVinculo),
                items: ChaveVinculoDocumento.values
                    .where(
                      (ChaveVinculoDocumento item) =>
                          item != ChaveVinculoDocumento.paginacao &&
                          item != ChaveVinculoDocumento.urlValidacao,
                    )
                    .map(_rotuloVinculo)
                    .toList(growable: false),
                onSelected: (String label) {
                  final ChaveVinculoDocumento chave = ChaveVinculoDocumento
                      .values
                      .firstWhere(
                        (ChaveVinculoDocumento item) =>
                            _rotuloVinculo(item) == label,
                      );
                  _substituirElemento(elemento.copyWith(chaveVinculo: chave));
                },
              ),
            if (elemento.tipo == TipoElementoDocumento.texto &&
                elemento.chaveVinculo ==
                    ChaveVinculoDocumento.textoLivre) ...<Widget>[
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey<String>('texto-${elemento.id}'),
                initialValue: elemento.propriedades['texto']?.toString() ?? '',
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _t(
                    'documents.editor.freeText',
                    'Texto personalizado',
                    'Custom text',
                    'Texto personalizado',
                  ),
                ),
                onChanged: (String value) =>
                    _atualizarPropriedade(elemento, 'texto', value),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _campoDimensao(
                  _t('documents.editor.x', 'X (mm)', 'X (mm)', 'X (mm)'),
                  elemento.xMm,
                  (double value) => _substituirElemento(
                    elemento.copyWith(xMm: _limitarX(elemento, value)),
                  ),
                ),
                _campoDimensao(
                  _t('documents.editor.y', 'Y (mm)', 'Y (mm)', 'Y (mm)'),
                  elemento.yMm,
                  (double value) => _substituirElemento(
                    elemento.copyWith(yMm: _limitarY(elemento, value)),
                  ),
                ),
                _campoDimensao(
                  _t(
                    'documents.editor.width',
                    'Largura (mm)',
                    'Width (mm)',
                    'Ancho (mm)',
                  ),
                  elemento.larguraMm,
                  (double value) => _substituirElemento(
                    elemento.copyWith(
                      larguraMm: value
                          .clamp(
                            1,
                            _modelo.perfilPagina.larguraUtilMm - elemento.xMm,
                          )
                          .toDouble(),
                    ),
                  ),
                ),
                _campoDimensao(
                  _t(
                    'documents.editor.height',
                    'Altura (mm)',
                    'Height (mm)',
                    'Alto (mm)',
                  ),
                  elemento.alturaMm,
                  (double value) => _substituirElemento(
                    elemento.copyWith(
                      alturaMm: value
                          .clamp(1, _zonaAtual.alturaMm - elemento.yMm)
                          .toDouble(),
                    ),
                  ),
                ),
              ],
            ),
            if (elemento.tipo == TipoElementoDocumento.texto ||
                elemento.tipo == TipoElementoDocumento.paginacao) ...<Widget>[
              const SizedBox(height: 14),
              _campoNumero(
                label: _t(
                  'documents.editor.fontSize',
                  'Tamanho da fonte',
                  'Font size',
                  'Tamaño de fuente',
                ),
                valor:
                    (elemento.propriedades['tamanhoFonte'] as num?)
                        ?.toDouble() ??
                    9,
                aoAlterar: (double value) => _atualizarPropriedade(
                  elemento,
                  'tamanhoFonte',
                  value.clamp(5, 40),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: elemento.propriedades['negrito'] == true,
                title: Text(
                  _t(
                    'documents.editor.bold',
                    'Texto em negrito',
                    'Bold text',
                    'Texto en negrita',
                  ),
                ),
                onChanged: (bool value) =>
                    _atualizarPropriedade(elemento, 'negrito', value),
              ),
              const SizedBox(height: 8),
              SixWebSelectField(
                label: _t(
                  'documents.editor.alignment',
                  'Alinhamento',
                  'Alignment',
                  'Alineación',
                ),
                value: _rotuloAlinhamento(
                  elemento.propriedades['alinhamento']?.toString() ??
                      'ESQUERDA',
                ),
                items: <String>[
                  'ESQUERDA',
                  'CENTRO',
                  'DIREITA',
                ].map(_rotuloAlinhamento).toList(growable: false),
                onSelected: (String rotulo) {
                  final String codigo =
                      <String>['ESQUERDA', 'CENTRO', 'DIREITA'].firstWhere(
                        (String item) => _rotuloAlinhamento(item) == rotulo,
                      );
                  _atualizarPropriedade(elemento, 'alinhamento', codigo);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey<String>(
                  'cor-${elemento.id}-${elemento.propriedades['cor']}',
                ),
                initialValue:
                    elemento.propriedades['cor']?.toString() ?? '#334155',
                decoration: InputDecoration(
                  labelText: _t(
                    'documents.editor.color',
                    'Cor hexadecimal',
                    'Hex color',
                    'Color hexadecimal',
                  ),
                  hintText: '#334155',
                ),
                onFieldSubmitted: (String value) {
                  final String cor = value.trim().toUpperCase();
                  if (RegExp(r'^#[0-9A-F]{6}$').hasMatch(cor)) {
                    _atualizarPropriedade(elemento, 'cor', cor);
                  }
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _itemElemento(ElementoDocumento elemento) {
    final bool selected = elemento.id == _idElementoSelecionado;
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _idElementoSelecionado = elemento.id),
        child: AnimatedContainer(
          duration: WebThemeTokens.transitionDuration,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? tokens.info.withValues(alpha: 0.10)
                : tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? tokens.selectedBorder : tokens.cardBorder,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(_iconeTipo(elemento.tipo), size: 18, color: tokens.info),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  elemento.tipo == TipoElementoDocumento.texto
                      ? _rotuloVinculo(elemento.chaveVinculo)
                      : _rotuloTipo(elemento.tipo),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.primaryText,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tituloPainel(IconData icon, String titulo) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: tokens.info),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            titulo,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _painelDecoration(WebThemeTokens tokens) => BoxDecoration(
    color: tokens.surfaceElevated,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: tokens.cardBorder),
  );

  Widget _campoNumero({
    required String label,
    required double valor,
    required ValueChanged<double> aoAlterar,
  }) => TextFormField(
    key: ValueKey<String>('$label-${valor.toStringAsFixed(2)}'),
    initialValue: valor.toStringAsFixed(1),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    onChanged: (String value) {
      final double? parsed = double.tryParse(value.replaceAll(',', '.'));
      if (parsed != null) aoAlterar(parsed);
    },
  );

  Widget _campoDimensao(
    String label,
    double valor,
    ValueChanged<double> aoAlterar,
  ) => SizedBox(
    width: 136,
    child: _campoNumero(label: label, valor: valor, aoAlterar: aoAlterar),
  );

  void _atualizarZona(ZonaDocumento zona) {
    setState(() {
      _modelo = _editandoCabecalho
          ? _modelo.copyWith(cabecalho: zona)
          : _modelo.copyWith(rodape: zona);
    });
  }

  void _substituirElemento(ElementoDocumento atualizado, {bool? cabecalho}) {
    final bool noCabecalho = cabecalho ?? _editandoCabecalho;
    final ZonaDocumento zona = noCabecalho ? _modelo.cabecalho : _modelo.rodape;
    final ZonaDocumento novaZona = zona.copyWith(
      elementos: zona.elementos
          .map(
            (ElementoDocumento item) =>
                item.id == atualizado.id ? atualizado : item,
          )
          .toList(growable: false),
    );
    setState(() {
      _modelo = noCabecalho
          ? _modelo.copyWith(cabecalho: novaZona)
          : _modelo.copyWith(rodape: novaZona);
    });
  }

  void _atualizarPropriedade(
    ElementoDocumento elemento,
    String chave,
    dynamic valor,
  ) {
    _substituirElemento(
      elemento.copyWith(
        propriedades: <String, dynamic>{...elemento.propriedades, chave: valor},
      ),
    );
  }

  void _adicionarElemento(TipoElementoDocumento tipo) {
    final String id = 'elemento-${DateTime.now().microsecondsSinceEpoch}';
    final double larguraDisponivel = _modelo.perfilPagina.larguraUtilMm;
    final ElementoDocumento elemento = switch (tipo) {
      TipoElementoDocumento.texto => ElementoDocumento(
        id: id,
        tipo: tipo,
        chaveVinculo: ChaveVinculoDocumento.textoLivre,
        xMm: 2,
        yMm: 2,
        larguraMm: math.min(70.0, larguraDisponivel - 4.0),
        alturaMm: 8,
        propriedades: <String, dynamic>{
          'texto': _t(
            'documents.editor.newText',
            'Novo texto',
            'New text',
            'Nuevo texto',
          ),
          'tamanhoFonte': 9,
          'alinhamento': 'ESQUERDA',
          'cor': '#334155',
        },
      ),
      TipoElementoDocumento.logo => ElementoDocumento(
        id: id,
        tipo: tipo,
        chaveVinculo: ChaveVinculoDocumento.nomeFantasiaEmpresa,
        xMm: 2,
        yMm: 2,
        larguraMm: 24,
        alturaMm: math.min(16.0, _zonaAtual.alturaMm - 2.0),
      ),
      TipoElementoDocumento.linha => ElementoDocumento(
        id: id,
        tipo: tipo,
        chaveVinculo: ChaveVinculoDocumento.textoLivre,
        xMm: 0,
        yMm: math.max(0.0, _zonaAtual.alturaMm - 2.0),
        larguraMm: larguraDisponivel,
        alturaMm: 1,
        propriedades: const <String, dynamic>{'cor': '#CBD5E1'},
      ),
      TipoElementoDocumento.qrCode => ElementoDocumento(
        id: id,
        tipo: tipo,
        chaveVinculo: ChaveVinculoDocumento.urlValidacao,
        xMm: 2,
        yMm: 2,
        larguraMm: 16,
        alturaMm: 16,
      ),
      TipoElementoDocumento.paginacao => ElementoDocumento(
        id: id,
        tipo: tipo,
        chaveVinculo: ChaveVinculoDocumento.paginacao,
        xMm: math.max(0.0, larguraDisponivel - 42.0),
        yMm: 2,
        larguraMm: 40,
        alturaMm: 7,
        propriedades: const <String, dynamic>{
          'tamanhoFonte': 8,
          'alinhamento': 'DIREITA',
          'cor': '#64748B',
        },
      ),
    };
    _atualizarZona(
      _zonaAtual.copyWith(
        elementos: <ElementoDocumento>[..._zonaAtual.elementos, elemento],
      ),
    );
    setState(() => _idElementoSelecionado = id);
  }

  void _excluirElementoSelecionado() {
    final String? id = _idElementoSelecionado;
    if (id == null) return;
    final List<ElementoDocumento> restantes = _zonaAtual.elementos
        .where((ElementoDocumento item) => item.id != id)
        .toList(growable: false);
    _atualizarZona(_zonaAtual.copyWith(elementos: restantes));
    setState(() => _idElementoSelecionado = restantes.firstOrNull?.id);
  }

  double _limitarX(ElementoDocumento elemento, double valor) => valor
      .clamp(0, _modelo.perfilPagina.larguraUtilMm - elemento.larguraMm)
      .toDouble();

  double _limitarY(ElementoDocumento elemento, double valor) =>
      valor.clamp(0, _zonaAtual.alturaMm - elemento.alturaMm).toDouble();

  Future<void> _salvar() async {
    final String nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      setState(() {
        _erro = _t(
          'documents.editor.nameRequired',
          'Informe o nome do modelo.',
          'Enter the template name.',
          'Ingresa el nombre del modelo.',
        );
      });
      return;
    }
    if (_modelo.cabecalho.elementos.isEmpty &&
        _modelo.rodape.elementos.isEmpty) {
      setState(() {
        _erro = _t(
          'documents.editor.elementsRequired',
          'Adicione ao menos um elemento ao cabeçalho ou ao rodapé.',
          'Add at least one element to the header or footer.',
          'Agrega al menos un elemento al encabezado o al pie.',
        );
      });
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      final ModeloDocumento salvo = await widget.aoSalvar(
        _modelo.copyWith(
          nome: nome,
          descricao: _descricaoController.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(salvo);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = _t(
          'documents.editor.saveError',
          'Não foi possível salvar o modelo. Revise as dimensões e tente novamente.',
          'Could not save the template. Review the dimensions and try again.',
          'No se pudo guardar el modelo. Revisa las dimensiones e inténtalo de nuevo.',
        );
      });
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  String _rotuloPerfil(PerfilPaginaDocumento perfil) => switch (perfil) {
    PerfilPaginaDocumento.a4Retrato => _t(
      'documents.profile.a4Portrait',
      'A4 retrato',
      'A4 portrait',
      'A4 vertical',
    ),
    PerfilPaginaDocumento.a4Paisagem => _t(
      'documents.profile.a4Landscape',
      'A4 paisagem',
      'A4 landscape',
      'A4 horizontal',
    ),
    PerfilPaginaDocumento.cupomTermico80mm => _t(
      'documents.profile.thermal80',
      'Cupom térmico 80 mm',
      '80 mm thermal receipt',
      'Comprobante térmico de 80 mm',
    ),
  };

  String _rotuloTipo(TipoElementoDocumento tipo) => switch (tipo) {
    TipoElementoDocumento.texto => _t(
      'documents.element.text',
      'Texto',
      'Text',
      'Texto',
    ),
    TipoElementoDocumento.logo => _t(
      'documents.element.logo',
      'Logotipo',
      'Logo',
      'Logotipo',
    ),
    TipoElementoDocumento.linha => _t(
      'documents.element.line',
      'Linha',
      'Line',
      'Línea',
    ),
    TipoElementoDocumento.qrCode => _t(
      'documents.element.qr',
      'QR Code',
      'QR code',
      'Código QR',
    ),
    TipoElementoDocumento.paginacao => _t(
      'documents.element.pagination',
      'Paginação',
      'Pagination',
      'Paginación',
    ),
  };

  IconData _iconeTipo(TipoElementoDocumento tipo) => switch (tipo) {
    TipoElementoDocumento.texto => Icons.text_fields_rounded,
    TipoElementoDocumento.logo => Icons.image_outlined,
    TipoElementoDocumento.linha => Icons.horizontal_rule_rounded,
    TipoElementoDocumento.qrCode => Icons.qr_code_2_rounded,
    TipoElementoDocumento.paginacao => Icons.numbers_rounded,
  };

  String _rotuloVinculo(ChaveVinculoDocumento chave) => switch (chave) {
    ChaveVinculoDocumento.textoLivre => _t(
      'documents.binding.freeText',
      'Texto personalizado',
      'Custom text',
      'Texto personalizado',
    ),
    ChaveVinculoDocumento.nomeFantasiaEmpresa => _t(
      'documents.binding.tradeName',
      'Nome fantasia',
      'Trade name',
      'Nombre comercial',
    ),
    ChaveVinculoDocumento.razaoSocialEmpresa => _t(
      'documents.binding.legalName',
      'Razão social',
      'Legal name',
      'Razón social',
    ),
    ChaveVinculoDocumento.documentoEmpresa => _t(
      'documents.binding.taxId',
      'Documento da empresa',
      'Business tax ID',
      'Documento de la empresa',
    ),
    ChaveVinculoDocumento.telefoneEmpresa => _t(
      'documents.binding.phone',
      'Telefone',
      'Phone',
      'Teléfono',
    ),
    ChaveVinculoDocumento.emailEmpresa => _t(
      'documents.binding.email',
      'E-mail',
      'Email',
      'Email',
    ),
    ChaveVinculoDocumento.enderecoEmpresa => _t(
      'documents.binding.address',
      'Endereço',
      'Address',
      'Dirección',
    ),
    ChaveVinculoDocumento.siteEmpresa => _t(
      'documents.binding.site',
      'Site',
      'Website',
      'Sitio web',
    ),
    ChaveVinculoDocumento.tituloDocumento => _t(
      'documents.binding.documentTitle',
      'Título do documento',
      'Document title',
      'Título del documento',
    ),
    ChaveVinculoDocumento.numeroDocumento => _t(
      'documents.binding.documentNumber',
      'Número do documento',
      'Document number',
      'Número del documento',
    ),
    ChaveVinculoDocumento.dataGeracao => _t(
      'documents.binding.generatedAt',
      'Data de geração',
      'Generated at',
      'Fecha de generación',
    ),
    ChaveVinculoDocumento.paginacao => _t(
      'documents.binding.pagination',
      'Paginação',
      'Pagination',
      'Paginación',
    ),
    ChaveVinculoDocumento.urlValidacao => _t(
      'documents.binding.validationUrl',
      'URL de validação',
      'Validation URL',
      'URL de validación',
    ),
  };

  String _valorPreview(ElementoDocumento elemento) =>
      switch (elemento.chaveVinculo) {
        ChaveVinculoDocumento.textoLivre =>
          elemento.propriedades['texto']?.toString() ?? '',
        ChaveVinculoDocumento.nomeFantasiaEmpresa => _t(
          'documents.preview.companyName',
          'Sua empresa',
          'Your business',
          'Tu empresa',
        ),
        ChaveVinculoDocumento.razaoSocialEmpresa => _t(
          'documents.preview.legalName',
          'Sua Empresa Ltda.',
          'Your Business LLC',
          'Tu Empresa S.L.',
        ),
        ChaveVinculoDocumento.documentoEmpresa => '00.000.000/0001-00',
        ChaveVinculoDocumento.telefoneEmpresa => '(00) 00000-0000',
        ChaveVinculoDocumento.emailEmpresa => 'contato@suaempresa.com',
        ChaveVinculoDocumento.enderecoEmpresa => _t(
          'documents.preview.address',
          'Endereço da empresa',
          'Business address',
          'Dirección de la empresa',
        ),
        ChaveVinculoDocumento.siteEmpresa => 'www.suaempresa.com',
        ChaveVinculoDocumento.tituloDocumento => _t(
          'documents.preview.documentTitle',
          'Título do documento',
          'Document title',
          'Título del documento',
        ),
        ChaveVinculoDocumento.numeroDocumento => '000123',
        ChaveVinculoDocumento.dataGeracao => _t(
          'documents.preview.generatedAt',
          '20/08/2026 10:30',
          '08/20/2026 10:30 AM',
          '20/08/2026 10:30',
        ),
        ChaveVinculoDocumento.paginacao => _t(
          'documents.preview.page',
          'Página 1 de 1',
          'Page 1 of 1',
          'Página 1 de 1',
        ),
        ChaveVinculoDocumento.urlValidacao => _t(
          'documents.preview.validationUrl',
          'URL de validação',
          'Validation URL',
          'URL de validación',
        ),
      };

  String _rotuloAlinhamento(String codigo) => switch (codigo) {
    'CENTRO' => _t('documents.alignment.center', 'Centro', 'Center', 'Centro'),
    'DIREITA' => _t('documents.alignment.right', 'Direita', 'Right', 'Derecha'),
    _ => _t('documents.alignment.left', 'Esquerda', 'Left', 'Izquierda'),
  };

  TextAlign _alinhamentoPreview(ElementoDocumento elemento) =>
      switch (elemento.propriedades['alinhamento']) {
        'CENTRO' => TextAlign.center,
        'DIREITA' => TextAlign.right,
        _ => TextAlign.left,
      };

  Color _corPreview(ElementoDocumento elemento) {
    final String valor = elemento.propriedades['cor']?.toString() ?? '#334155';
    final int? hex = int.tryParse(valor.replaceFirst('#', ''), radix: 16);
    return hex == null ? const Color(0xFF334155) : Color(0xFF000000 | hex);
  }
}
