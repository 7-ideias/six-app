import 'package:sixpos/data/models/categoria_catalogo_model.dart';
import 'package:sixpos/data/models/produto_imagem_model.dart';
import 'package:sixpos/data/models/produto_model.dart';

class ProdutoCadastroNumberFormat {
  const ProdutoCadastroNumberFormat({
    required this.decimalSeparator,
    required this.thousandSeparator,
  });

  final String decimalSeparator;
  final String thousandSeparator;
}

class ProdutoCadastroFormData {
  const ProdutoCadastroFormData({
    required this.id,
    required this.ativo,
    required this.favorito,
    required this.disponivelParaCatalogo,
    required this.codigoDeBarras,
    required this.nomeProduto,
    required this.tipoProduto,
    required this.categoriaSelecionadaId,
    required this.categoriaSelecionadaNome,
    required this.categoriaSelecionada,
    required this.grupoProduto,
    required this.tempoGarantia,
    required this.podeAlterarValorNaHora,
    required this.modeloProduto,
    required this.estoqueMaximo,
    required this.estoqueMinimo,
    required this.precoVenda,
    required this.produtoTemComissaoEspecial,
    required this.valorComissao,
    required this.quantidadeEntrada,
    required this.valorCusto,
    required this.valorVendaEntrada,
    required this.imagens,
    required this.numberFormat,
    this.tipoCadastro = 'RESUMIDO',
    this.descricao = '',
    this.codigoInterno = '',
    this.marca = '',
    this.fabricante = '',
    this.categoriaUnidadeMedida = 'UNIDADE',
    this.unidadeMedida = 'UN',
    this.controlaEstoque = true,
    this.permiteVendaFracionada = false,
    this.permiteEstoqueNegativo = false,
    this.quantidadeMinimaVenda = '',
    this.ncm = '',
    this.cest = '',
    this.cfop = '',
    this.origemMercadoria = '',
    this.cstIcms = '',
    this.csosn = '',
    this.cstPis = '',
    this.cstCofins = '',
    this.usarPrecoVendaComoValorEntradaQuandoVazio = false,
  });

  final String? id;
  final bool ativo;
  final bool favorito;
  final bool disponivelParaCatalogo;
  final String codigoDeBarras;
  final String nomeProduto;
  final String tipoProduto;
  final String? categoriaSelecionadaId;
  final String? categoriaSelecionadaNome;
  final CategoriaCatalogoModel? categoriaSelecionada;
  final String grupoProduto;
  final String tempoGarantia;
  final bool podeAlterarValorNaHora;
  final String modeloProduto;
  final String estoqueMaximo;
  final String estoqueMinimo;
  final String precoVenda;
  final bool produtoTemComissaoEspecial;
  final String valorComissao;
  final String quantidadeEntrada;
  final String valorCusto;
  final String valorVendaEntrada;
  final List<ProdutoImagemModel> imagens;
  final ProdutoCadastroNumberFormat numberFormat;
  final String tipoCadastro;
  final String descricao;
  final String codigoInterno;
  final String marca;
  final String fabricante;
  final String categoriaUnidadeMedida;
  final String unidadeMedida;
  final bool controlaEstoque;
  final bool permiteVendaFracionada;
  final bool permiteEstoqueNegativo;
  final String quantidadeMinimaVenda;
  final String ncm;
  final String cest;
  final String cfop;
  final String origemMercadoria;
  final String cstIcms;
  final String csosn;
  final String cstPis;
  final String cstCofins;
  final bool usarPrecoVendaComoValorEntradaQuandoVazio;
}

class ProdutoCadastroFormUtils {
  ProdutoCadastroFormUtils._();

  static const String tipoProduto = 'PRODUTO';
  static const String tipoServico = 'SERVICO';
  static const String modeloPadrao = 'UNIDADE';

  // Campos opcionais devem seguir vazios no payload; labels de ausência são
  // resolvidas na apresentação conforme o idioma ativo.
  static const String grupoPadrao = '';
  static const String garantiaPadrao = '';

  static String normalizarTipo(String value) {
    final tipo = value.trim().toUpperCase();
    if (tipo == tipoServico || tipo == 'SERVIÇO') {
      return tipoServico;
    }
    return tipoProduto;
  }

  static bool categoriaCompativelComTipo(
    CategoriaCatalogoModel categoria,
    String tipo,
  ) {
    return categoria.tipo == 'AMBOS' || categoria.tipo == normalizarTipo(tipo);
  }

  static CategoriaCatalogoModel? encontrarCategoriaPorId(
    List<CategoriaCatalogoModel> categorias,
    String? id,
  ) {
    final String? idNormalizado = id?.trim();
    if (idNormalizado == null || idNormalizado.isEmpty) return null;

    for (final CategoriaCatalogoModel categoria in categorias) {
      if (categoria.id == idNormalizado) return categoria;
    }

    return null;
  }

  static ObjCategoria? montarObjCategoria({
    required String? categoriaSelecionadaId,
    required String? categoriaSelecionadaNome,
    required CategoriaCatalogoModel? categoriaSelecionada,
  }) {
    final String? id = categoriaSelecionadaId?.trim();
    if (id == null || id.isEmpty) return null;

    return ObjCategoria(
      idCategoria: id,
      nomeCategoria:
          categoriaSelecionada?.nome ?? categoriaSelecionadaNome?.trim() ?? '',
    );
  }

  static ProdutoModel montarProduto(ProdutoCadastroFormData data) {
    final double precoVenda = parseDecimal(
      data.precoVenda,
      numberFormat: data.numberFormat,
    );
    final String valorVendaEntradaText = data.valorVendaEntrada.trim();
    final double valorVendaEntrada =
        valorVendaEntradaText.isEmpty &&
            data.usarPrecoVendaComoValorEntradaQuandoVazio
        ? precoVenda
        : parseDecimal(valorVendaEntradaText, numberFormat: data.numberFormat);

    return ProdutoModel(
      id: data.id,
      ativo: data.ativo,
      favorito: data.favorito,
      disponivelParaCatalogo: data.disponivelParaCatalogo,
      codigoDeBarras: data.codigoDeBarras.trim(),
      nomeProduto: data.nomeProduto.trim(),
      tipoProduto: normalizarTipo(data.tipoProduto),
      objCategoria: montarObjCategoria(
        categoriaSelecionadaId: data.categoriaSelecionadaId,
        categoriaSelecionadaNome: data.categoriaSelecionadaNome,
        categoriaSelecionada: data.categoriaSelecionada,
      ),
      objAgrupamento: ObjAgrupamento(
        grupoDoProduto: data.grupoProduto.trim().isEmpty
            ? grupoPadrao
            : data.grupoProduto.trim(),
      ),
      objetoServico: ObjetoServico(
        tempoDaGarantia: data.tempoGarantia.trim().isEmpty
            ? garantiaPadrao
            : data.tempoGarantia.trim(),
        podeAlterarOValorNaHora: data.podeAlterarValorNaHora,
      ),
      modeloProduto: data.modeloProduto.trim().isEmpty
          ? modeloPadrao
          : data.modeloProduto.trim(),
      estoqueMaximo: parseInteger(
        data.estoqueMaximo,
        numberFormat: data.numberFormat,
      ),
      estoqueMinimo: parseInteger(
        data.estoqueMinimo,
        numberFormat: data.numberFormat,
      ),
      precoVenda: precoVenda,
      objComissao: ObjComissao(
        produtoTemComissaoEspecial: data.produtoTemComissaoEspecial,
        valorFixoDeComissaoParaEsseProduto: parseDecimal(
          data.valorComissao,
          numberFormat: data.numberFormat,
        ),
      ),
      objEntradaSaidaProduto: <ObjEntradaSaidaProduto>[
        ObjEntradaSaidaProduto(
          quantidade: parseDecimal(
            data.quantidadeEntrada,
            numberFormat: data.numberFormat,
          ),
          valorCusto: parseDecimal(
            data.valorCusto,
            numberFormat: data.numberFormat,
          ),
          valorDaVenda: valorVendaEntrada,
        ),
      ],
      imagens: data.imagens,
      tipoCadastro: data.tipoCadastro.trim().toUpperCase() == 'COMPLETO'
          ? 'COMPLETO'
          : 'RESUMIDO',
      detalhes: ProdutoDetalhesModel(
        descricao: data.descricao.trim(),
        codigoInterno: data.codigoInterno.trim(),
        marca: data.marca.trim(),
        fabricante: data.fabricante.trim(),
      ),
      regrasOperacionais: ProdutoRegrasOperacionaisModel(
        categoriaUnidadeMedida: data.categoriaUnidadeMedida.trim().isEmpty
            ? 'UNIDADE'
            : data.categoriaUnidadeMedida.trim().toUpperCase(),
        unidadeMedida: data.unidadeMedida.trim().isEmpty
            ? 'UN'
            : data.unidadeMedida.trim().toUpperCase(),
        controlaEstoque: data.controlaEstoque,
        permiteVendaFracionada: data.permiteVendaFracionada,
        permiteEstoqueNegativo: data.permiteEstoqueNegativo,
        quantidadeMinimaVenda: parseDecimal(
          data.quantidadeMinimaVenda,
          numberFormat: data.numberFormat,
        ),
      ),
      dadosFiscais: ProdutoDadosFiscaisModel(
        ncm: data.ncm.trim(),
        cest: data.cest.trim(),
        cfop: data.cfop.trim(),
        origemMercadoria: data.origemMercadoria.trim(),
        cstIcms: data.cstIcms.trim(),
        csosn: data.csosn.trim(),
        cstPis: data.cstPis.trim(),
        cstCofins: data.cstCofins.trim(),
      ),
    );
  }

  static double parseDecimal(
    String value, {
    required ProdutoCadastroNumberFormat numberFormat,
  }) {
    final String decimalSeparator = numberFormat.decimalSeparator.trim();
    final String thousandSeparator = numberFormat.thousandSeparator.trim();
    String normalized = value.trim().replaceAll(RegExp(r'\s+'), '');
    if (normalized.isEmpty) return 0;

    if (thousandSeparator.isNotEmpty && thousandSeparator != decimalSeparator) {
      normalized = normalized.replaceAll(thousandSeparator, '');
    }
    if (decimalSeparator.isNotEmpty && decimalSeparator != '.') {
      normalized = normalized.replaceAll(decimalSeparator, '.');
    }

    normalized = normalized.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (normalized.isEmpty || normalized == '-' || normalized == '.') {
      return 0;
    }

    final int firstDot = normalized.indexOf('.');
    if (firstDot != -1) {
      normalized =
          normalized.substring(0, firstDot + 1) +
          normalized.substring(firstDot + 1).replaceAll('.', '');
    }

    return double.tryParse(normalized) ?? 0;
  }

  static int parseInteger(
    String value, {
    required ProdutoCadastroNumberFormat numberFormat,
  }) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) return 0;

    final int? integer = int.tryParse(trimmed);
    if (integer != null) return integer;

    return parseDecimal(trimmed, numberFormat: numberFormat).toInt();
  }
}
