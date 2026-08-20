import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/utils/pdf_download.dart';
import '../../data/models/documento_models.dart';
import '../../domain/services/documento/documento_service.dart';
import '../theme/web_theme_tokens.dart';
import 'documento_editor_web_page.dart';
import 'documento_web_i18n.dart';

class DocumentosPersonalizadosWebContent extends StatefulWidget {
  const DocumentosPersonalizadosWebContent({super.key, this.servico});

  final DocumentoService? servico;

  @override
  State<DocumentosPersonalizadosWebContent> createState() =>
      _DocumentosPersonalizadosWebContentState();
}

class _DocumentosPersonalizadosWebContentState
    extends State<DocumentosPersonalizadosWebContent> {
  late final DocumentoService _servico;
  List<ModeloDocumento> _modelos = const <ModeloDocumento>[];
  List<ModeloPadraoDocumento> _padroes = const <ModeloPadraoDocumento>[];
  bool _carregando = true;
  bool _permitido = false;
  String? _idProcessando;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _servico = widget.servico ?? DocumentoService();
    _carregar();
  }

  String _t(String key, String pt, String en, String es) =>
      documentoTr(context, key, pt: pt, en: en, es: es);

  Future<void> _carregar() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final bool permitido = await _servico.buscarAcesso();
      if (!permitido) {
        if (!mounted) return;
        setState(() {
          _permitido = false;
          _modelos = const <ModeloDocumento>[];
          _padroes = const <ModeloPadraoDocumento>[];
        });
        return;
      }
      final List<Object> dados = await Future.wait<Object>(<Future<Object>>[
        _servico.listarModelos(),
        _servico.listarPadroes(),
      ]);
      if (!mounted) return;
      setState(() {
        _permitido = true;
        _modelos = dados[0] as List<ModeloDocumento>;
        _padroes = dados[1] as List<ModeloPadraoDocumento>;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erro = _t(
          'documents.loadError',
          'Não foi possível carregar os modelos de documento.',
          'Could not load document templates.',
          'No se pudieron cargar los modelos de documento.',
        );
      });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const SizedBox(
        height: 320,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_permitido && _erro == null) return _semPermissao();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _cabecalhoModulo(),
        if (_erro != null) ...<Widget>[
          const SizedBox(height: 14),
          _avisoErro(),
        ],
        const SizedBox(height: 18),
        _resumoAplicacao(),
        const SizedBox(height: 18),
        if (_modelos.isEmpty) _estadoVazio() else _gradeModelos(),
      ],
    );
  }

  Widget _cabecalhoModulo() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: <Widget>[
          SizedBox(
            width: 670,
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: tokens.info.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: tokens.info,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _t(
                          'documents.title',
                          'Cabeçalhos e rodapés de documentos',
                          'Document headers and footers',
                          'Encabezados y pies de documentos',
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: tokens.primaryText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _t(
                          'documents.subtitle',
                          'Crie modelos reutilizáveis e defina qual será aplicado aos relatórios e comprovantes em PDF.',
                          'Create reusable templates and choose which one is applied to PDF reports and receipts.',
                          'Crea modelos reutilizables y define cuál se aplica a informes y comprobantes PDF.',
                        ),
                        style: TextStyle(color: tokens.secondaryText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<PerfilPaginaDocumento>(
            tooltip: _t(
              'documents.new',
              'Novo modelo',
              'New template',
              'Nuevo modelo',
            ),
            onSelected: (PerfilPaginaDocumento perfil) =>
                _abrirEditor(perfil: perfil),
            itemBuilder: (BuildContext context) => PerfilPaginaDocumento.values
                .map(
                  (PerfilPaginaDocumento perfil) => PopupMenuItem(
                    value: perfil,
                    child: Text(_rotuloPerfil(perfil)),
                  ),
                )
                .toList(growable: false),
            child: IgnorePointer(
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  _t(
                    'documents.new',
                    'Novo modelo',
                    'New template',
                    'Nuevo modelo',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumoAplicacao() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.info.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.info.withValues(alpha: 0.22)),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 14,
        children: <Widget>[
          _itemResumo(
            Icons.inventory_2_outlined,
            _t(
              'documents.target.products',
              'Relatório de produtos',
              'Product report',
              'Informe de productos',
            ),
            PerfilPaginaDocumento.a4Paisagem,
            TipoDocumentoPdf.relatorioProdutos,
          ),
          _itemResumo(
            Icons.receipt_long_outlined,
            _t(
              'documents.target.receiptA4',
              'Comprovante A4',
              'A4 receipt',
              'Comprobante A4',
            ),
            PerfilPaginaDocumento.a4Retrato,
            TipoDocumentoPdf.comprovanteOperacao,
          ),
          _itemResumo(
            Icons.receipt_outlined,
            _t(
              'documents.target.receiptThermal',
              'Cupom térmico 80 mm',
              '80 mm thermal receipt',
              'Comprobante térmico 80 mm',
            ),
            PerfilPaginaDocumento.cupomTermico80mm,
            TipoDocumentoPdf.comprovanteOperacao,
          ),
        ],
      ),
    );
  }

  Widget _itemResumo(
    IconData icone,
    String titulo,
    PerfilPaginaDocumento perfil,
    TipoDocumentoPdf tipo,
  ) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final ModeloPadraoDocumento? padrao = _buscarPadrao(tipo, perfil);
    final ModeloDocumento? modelo = padrao == null
        ? null
        : _modelos
              .where(
                (ModeloDocumento item) => item.id == padrao.idModeloDocumento,
              )
              .firstOrNull;
    return SizedBox(
      width: 300,
      child: Row(
        children: <Widget>[
          Icon(icone, color: tokens.info),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  titulo,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  modelo?.nome ??
                      _t(
                        'documents.default.legacy',
                        'Layout atual do sistema',
                        'Current system layout',
                        'Diseño actual del sistema',
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: tokens.secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeModelos() => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final int colunas = constraints.maxWidth >= 1040
          ? 3
          : constraints.maxWidth >= 680
          ? 2
          : 1;
      const double espacamento = 16;
      final double largura =
          (constraints.maxWidth - (colunas - 1) * espacamento) / colunas;
      return Wrap(
        spacing: espacamento,
        runSpacing: espacamento,
        children: _modelos
            .map(
              (ModeloDocumento modelo) =>
                  SizedBox(width: largura, child: _cartaoModelo(modelo)),
            )
            .toList(growable: false),
      );
    },
  );

  Widget _cartaoModelo(ModeloDocumento modelo) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool processando = _idProcessando == modelo.id;
    final List<ModeloPadraoDocumento> usos = _padroes
        .where(
          (ModeloPadraoDocumento item) => item.idModeloDocumento == modelo.id,
        )
        .toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: usos.isEmpty ? tokens.cardBorder : tokens.selectedBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.info.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  modelo.perfilPagina.termico
                      ? Icons.receipt_outlined
                      : Icons.description_outlined,
                  color: tokens.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      modelo.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.primaryText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      _rotuloPerfil(modelo.perfilPagina),
                      style: TextStyle(
                        color: tokens.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (processando)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                PopupMenuButton<_AcaoModelo>(
                  onSelected: (_AcaoModelo acao) => _executarAcao(modelo, acao),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<_AcaoModelo>>[
                        PopupMenuItem(
                          value: _AcaoModelo.editar,
                          child: Text(_rotuloAcao(_AcaoModelo.editar)),
                        ),
                        PopupMenuItem(
                          value: _AcaoModelo.previa,
                          child: Text(_rotuloAcao(_AcaoModelo.previa)),
                        ),
                        PopupMenuItem(
                          value: _AcaoModelo.tornarPadrao,
                          child: Text(_rotuloAcao(_AcaoModelo.tornarPadrao)),
                        ),
                        PopupMenuItem(
                          value: _AcaoModelo.duplicar,
                          child: Text(_rotuloAcao(_AcaoModelo.duplicar)),
                        ),
                        PopupMenuItem(
                          value: _AcaoModelo.excluir,
                          child: Text(_rotuloAcao(_AcaoModelo.excluir)),
                        ),
                      ],
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            modelo.descricao.isEmpty
                ? _t(
                    'documents.noDescription',
                    'Sem descrição.',
                    'No description.',
                    'Sin descripción.',
                  )
                : modelo.descricao,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: tokens.secondaryText, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _selo(
                '${_t('documents.header', 'Cabeçalho', 'Header', 'Encabezado')}: '
                '${modelo.cabecalho.elementos.length}',
                tokens,
              ),
              _selo(
                '${_t('documents.footer', 'Rodapé', 'Footer', 'Pie')}: '
                '${modelo.rodape.elementos.length}',
                tokens,
              ),
              ...usos.map(
                (ModeloPadraoDocumento uso) =>
                    _selo(_rotuloUso(uso), tokens, destaque: true),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: processando ? null : () => _gerarPrevia(modelo),
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(
                    _t(
                      'documents.preview',
                      'Gerar prévia',
                      'Generate preview',
                      'Generar vista previa',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filledTonal(
                onPressed: processando
                    ? null
                    : () => _abrirEditor(modelo: modelo),
                tooltip: _rotuloAcao(_AcaoModelo.editar),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _selo(String texto, WebThemeTokens tokens, {bool destaque = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: (destaque ? tokens.info : tokens.surfaceMuted).withValues(
            alpha: destaque ? 0.10 : 0.80,
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          texto,
          style: TextStyle(
            color: destaque ? tokens.info : tokens.secondaryText,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _estadoVazio() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 46),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.dashboard_customize_outlined,
            size: 54,
            color: tokens.info,
          ),
          const SizedBox(height: 14),
          Text(
            _t(
              'documents.empty.title',
              'Crie o primeiro modelo',
              'Create the first template',
              'Crea el primer modelo',
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            _t(
              'documents.empty.subtitle',
              'Você poderá visualizar o PDF no servidor antes de torná-lo padrão.',
              'You can preview the server-generated PDF before making it the default.',
              'Podrás previsualizar el PDF del servidor antes de definirlo como predeterminado.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens.secondaryText),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () =>
                _abrirEditor(perfil: PerfilPaginaDocumento.a4Retrato),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              _t(
                'documents.empty.action',
                'Criar modelo A4',
                'Create A4 template',
                'Crear modelo A4',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _semPermissao() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.lock_outline_rounded,
            size: 48,
            color: tokens.secondaryText,
          ),
          const SizedBox(height: 12),
          Text(
            _t(
              'documents.permission.title',
              'Personalização de documentos indisponível',
              'Document customization unavailable',
              'Personalización de documentos no disponible',
            ),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            _t(
              'documents.permission.subtitle',
              'Solicite a permissão DOCUMENTOS_PERSONALIZAR ao administrador da empresa.',
              'Ask the company administrator for the DOCUMENTOS_PERSONALIZAR permission.',
              'Solicita al administrador el permiso DOCUMENTOS_PERSONALIZAR.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _avisoErro() {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.error_outline_rounded, color: tokens.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(_erro!)),
          TextButton(
            onPressed: _carregar,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirEditor({
    ModeloDocumento? modelo,
    PerfilPaginaDocumento? perfil,
  }) async {
    final ModeloDocumento inicial =
        modelo ?? _novoModelo(perfil ?? PerfilPaginaDocumento.a4Retrato);
    final ModeloDocumento? salvo = await showDialog<ModeloDocumento>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final Size tela = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.all(22),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: tela.width * 0.94,
            height: tela.height * 0.92,
            child: DocumentoEditorWebPage(
              modeloInicial: inicial,
              novoModelo: modelo == null,
              aoSalvar: _servico.salvarModelo,
              aoFechar: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        );
      },
    );
    if (salvo == null || !mounted) return;
    await _carregar();
    if (!mounted) return;
    _mensagem(
      _t(
        'documents.saved',
        'Modelo salvo com sucesso.',
        'Template saved successfully.',
        'Modelo guardado correctamente.',
      ),
    );
  }

  Future<void> _executarAcao(ModeloDocumento modelo, _AcaoModelo acao) async {
    switch (acao) {
      case _AcaoModelo.editar:
        await _abrirEditor(modelo: modelo);
        break;
      case _AcaoModelo.previa:
        await _gerarPrevia(modelo);
        break;
      case _AcaoModelo.tornarPadrao:
        await _tornarPadrao(modelo);
        break;
      case _AcaoModelo.duplicar:
        await _duplicar(modelo);
        break;
      case _AcaoModelo.excluir:
        await _excluir(modelo);
        break;
    }
  }

  Future<void> _gerarPrevia(ModeloDocumento modelo) async {
    final String id = modelo.id ?? '';
    if (id.isEmpty) return;
    _iniciarProcessamento(id);
    try {
      final DocumentoPdfResponse pdf = await _servico.gerarPrevia(
        idModelo: id,
        tipoDocumento: _tipoCompativel(modelo.perfilPagina),
      );
      final Uint8List bytes = base64Decode(pdf.arquivoBase64);
      final bool iniciou = iniciarDownloadPdf(
        bytes: bytes,
        nomeArquivo: pdf.nomeArquivo,
        mimeType: pdf.mimeType,
      );
      if (!mounted) return;
      _mensagem(
        iniciou
            ? _t(
                'documents.preview.started',
                'Prévia gerada e download iniciado.',
                'Preview generated and download started.',
                'Vista previa generada y descarga iniciada.',
              )
            : _t(
                'documents.preview.unavailable',
                'A prévia foi gerada, mas o navegador bloqueou o download.',
                'The preview was generated, but the browser blocked the download.',
                'La vista previa fue generada, pero el navegador bloqueó la descarga.',
              ),
      );
    } catch (_) {
      if (mounted) {
        _mensagem(
          _t(
            'documents.preview.error',
            'Não foi possível gerar a prévia do PDF.',
            'Could not generate the PDF preview.',
            'No se pudo generar la vista previa del PDF.',
          ),
          erro: true,
        );
      }
    } finally {
      _encerrarProcessamento();
    }
  }

  Future<void> _tornarPadrao(ModeloDocumento modelo) async {
    final String id = modelo.id ?? '';
    if (id.isEmpty) return;
    final TipoDocumentoPdf tipo = _tipoCompativel(modelo.perfilPagina);
    _iniciarProcessamento(id);
    try {
      await _servico.definirPadrao(
        ModeloPadraoDocumento(
          tipoDocumento: tipo,
          perfilPagina: modelo.perfilPagina,
          idModeloDocumento: id,
        ),
      );
      await _carregar();
      if (!mounted) return;
      _mensagem(
        _t(
          'documents.default.saved',
          'Modelo definido como padrão.',
          'Template set as default.',
          'Modelo definido como predeterminado.',
        ),
      );
    } catch (_) {
      if (mounted) {
        _mensagem(
          _t(
            'documents.default.error',
            'Não foi possível definir o modelo padrão.',
            'Could not set the default template.',
            'No se pudo definir el modelo predeterminado.',
          ),
          erro: true,
        );
      }
    } finally {
      _encerrarProcessamento();
    }
  }

  Future<void> _duplicar(ModeloDocumento modelo) async {
    final String id = modelo.id ?? '';
    if (id.isEmpty) return;
    _iniciarProcessamento(id);
    try {
      final ModeloDocumento copia = await _servico.duplicarModelo(id);
      await _carregar();
      if (!mounted) return;
      await _abrirEditor(modelo: copia);
    } catch (_) {
      if (mounted) {
        _mensagem(
          _t(
            'documents.duplicate.error',
            'Não foi possível duplicar o modelo.',
            'Could not duplicate the template.',
            'No se pudo duplicar el modelo.',
          ),
          erro: true,
        );
      }
    } finally {
      _encerrarProcessamento();
    }
  }

  Future<void> _excluir(ModeloDocumento modelo) async {
    final bool confirmar =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(
              _t(
                'documents.delete.title',
                'Excluir modelo?',
                'Delete template?',
                '¿Eliminar modelo?',
              ),
            ),
            content: Text(
              _t(
                'documents.delete.message',
                'Esta ação não poderá ser desfeita. Modelos definidos como padrão precisam ser substituídos antes.',
                'This action cannot be undone. Default templates must be replaced first.',
                'Esta acción no se puede deshacer. Los modelos predeterminados deben reemplazarse antes.',
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  _t('common.cancel', 'Cancelar', 'Cancel', 'Cancelar'),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  _t('common.delete', 'Excluir', 'Delete', 'Eliminar'),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmar) return;
    final String id = modelo.id ?? '';
    if (id.isEmpty) return;
    _iniciarProcessamento(id);
    try {
      await _servico.excluirModelo(id);
      await _carregar();
      if (!mounted) return;
      _mensagem(
        _t(
          'documents.deleted',
          'Modelo excluído.',
          'Template deleted.',
          'Modelo eliminado.',
        ),
      );
    } catch (_) {
      if (mounted) {
        _mensagem(
          _t(
            'documents.delete.error',
            'Não foi possível excluir. Verifique se o modelo ainda é o padrão.',
            'Could not delete it. Check whether the template is still the default.',
            'No se pudo eliminar. Verifica si el modelo sigue siendo el predeterminado.',
          ),
          erro: true,
        );
      }
    } finally {
      _encerrarProcessamento();
    }
  }

  void _iniciarProcessamento(String id) {
    if (mounted) setState(() => _idProcessando = id);
  }

  void _encerrarProcessamento() {
    if (mounted) setState(() => _idProcessando = null);
  }

  void _mensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: erro ? WebThemeTokens.of(context).danger : null,
      ),
    );
  }

  ModeloPadraoDocumento? _buscarPadrao(
    TipoDocumentoPdf tipo,
    PerfilPaginaDocumento perfil,
  ) => _padroes
      .where(
        (ModeloPadraoDocumento item) =>
            item.tipoDocumento == tipo && item.perfilPagina == perfil,
      )
      .firstOrNull;

  TipoDocumentoPdf _tipoCompativel(PerfilPaginaDocumento perfil) =>
      perfil == PerfilPaginaDocumento.a4Paisagem
      ? TipoDocumentoPdf.relatorioProdutos
      : TipoDocumentoPdf.comprovanteOperacao;

  ModeloDocumento _novoModelo(PerfilPaginaDocumento perfil) =>
      ModeloDocumento.novo(
        perfil,
        nomeA4: _t(
          'documents.new.defaultNameA4',
          'Documento personalizado',
          'Custom document',
          'Documento personalizado',
        ),
        nomeCupom: _t(
          'documents.new.defaultNameThermal',
          'Cupom personalizado 80 mm',
          'Custom 80 mm receipt',
          'Comprobante personalizado de 80 mm',
        ),
        textoRodape: _t(
          'documents.new.defaultFooter',
          'Obrigado pela preferência.',
          'Thank you for your business.',
          'Gracias por su preferencia.',
        ),
      );

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

  String _rotuloUso(ModeloPadraoDocumento uso) => switch (uso.perfilPagina) {
    PerfilPaginaDocumento.a4Paisagem => _t(
      'documents.target.products.short',
      'Padrão: produtos',
      'Default: products',
      'Predeterminado: productos',
    ),
    PerfilPaginaDocumento.a4Retrato => _t(
      'documents.target.receiptA4.short',
      'Padrão: comprovante A4',
      'Default: A4 receipt',
      'Predeterminado: comprobante A4',
    ),
    PerfilPaginaDocumento.cupomTermico80mm => _t(
      'documents.target.receiptThermal.short',
      'Padrão: cupom 80 mm',
      'Default: 80 mm receipt',
      'Predeterminado: comprobante 80 mm',
    ),
  };

  String _rotuloAcao(_AcaoModelo acao) => switch (acao) {
    _AcaoModelo.editar => _t('common.edit', 'Editar', 'Edit', 'Editar'),
    _AcaoModelo.previa => _t(
      'documents.preview.short',
      'Prévia PDF',
      'PDF preview',
      'Vista previa PDF',
    ),
    _AcaoModelo.tornarPadrao => _t(
      'documents.default.action',
      'Tornar padrão',
      'Make default',
      'Definir como predeterminado',
    ),
    _AcaoModelo.duplicar => _t(
      'common.duplicate',
      'Duplicar',
      'Duplicate',
      'Duplicar',
    ),
    _AcaoModelo.excluir => _t('common.delete', 'Excluir', 'Delete', 'Eliminar'),
  };
}

enum _AcaoModelo { editar, previa, tornarPadrao, duplicar, excluir }
