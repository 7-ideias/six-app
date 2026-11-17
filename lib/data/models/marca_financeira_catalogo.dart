import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/data/models/instituicao_open_finance_model.dart';

/// Catálogo brasileiro curado de operadoras. A identidade não é inferida por
/// substring nem pela instituição que recebe o depósito da maquininha.
/// URLs só são usadas para marcas comprovadamente correspondentes ao ISPB.
class OperadoraMaquininha {
  const OperadoraMaquininha(this.codigo, this.nome, this.logotipoUrl);

  final String codigo;
  final String nome;
  final String? logotipoUrl;

  String get marcaId => 'OPERADORA:$codigo';

  InstituicaoOpenFinance paraSelecao() => InstituicaoOpenFinance(
    nome: nome,
    logotipoUrl: logotipoUrl ?? '',
    marcaOpenFinanceId: marcaId,
  );
}

abstract final class MarcaFinanceiraCatalogo {
  static const String _cdn =
      'https://cdn.jsdelivr.net/npm/logos-bancos-br@0/logos/svg/';

  static const List<OperadoraMaquininha> operadoras = [
    OperadoraMaquininha('STONE', 'Stone', '${_cdn}16501555.svg'),
    OperadoraMaquininha('CIELO', 'Cielo', '${_cdn}01027058.svg'),
    OperadoraMaquininha('GETNET', 'Getnet', '${_cdn}10440482.svg'),
    OperadoraMaquininha('PAGBANK', 'PagBank', '${_cdn}08561701.svg'),
    OperadoraMaquininha('MERCADO_PAGO', 'Mercado Pago', '${_cdn}10573521.svg'),
    OperadoraMaquininha('SUMUP', 'SumUp', '${_cdn}37241230.svg'),
    OperadoraMaquininha('INFINITEPAY', 'InfinitePay', '${_cdn}18189547.svg'),
    OperadoraMaquininha('REDE', 'Rede', null),
    OperadoraMaquininha('TON', 'Ton', null),
    OperadoraMaquininha('SAFRAPAY', 'SafraPay', null),
    OperadoraMaquininha('PAGARME', 'Pagar.me', null),
  ];

  static List<InstituicaoOpenFinance> operadorasParaSelecao() =>
      operadoras.map((item) => item.paraSelecao()).toList(growable: false);

  static OperadoraMaquininha? operadoraDe(String? id, String nome) {
    final normalizado = InstituicaoOpenFinance.normalizarNome(nome);
    if (id != null && id.startsWith('OPERADORA:')) {
      final codigo = id.substring('OPERADORA:'.length);
      for (final item in operadoras) {
        if (item.codigo == codigo &&
            (InstituicaoOpenFinance.normalizarNome(item.nome) == normalizado ||
                (codigo == 'PAGBANK' && normalizado == 'pagseguro'))) {
          return item;
        }
      }
      // Uma referência antiga divergente não pode mostrar a marca errada.
      return null;
    }
    for (final item in operadoras) {
      if (InstituicaoOpenFinance.normalizarNome(item.nome) == normalizado) {
        return item;
      }
    }
    // Aliases controlados. Não associar por semelhança ou substring.
    if (normalizado == 'pagseguro') {
      return operadoras.firstWhere((item) => item.codigo == 'PAGBANK');
    }
    return null;
  }

  static String? logoOperadora(
    String nome,
    String? marcaId, {
    required bool habilitadoBrasil,
  }) {
    if (!habilitadoBrasil) return null;
    return operadoraDe(marcaId, nome)?.logotipoUrl;
  }

  static String? logoConta(
    ConfiguracaoFinanceira item,
    CatalogoInstituicoesBrasil catalogo,
  ) {
    if (!catalogo.habilitado || item.tipo != 'BANCO') return null;
    final nome = item.instituicao.trim().isNotEmpty
        ? item.instituicao
        : _instituicaoLegada(item.nome);
    final id = item.marcaId?.startsWith('OF:') == true
        ? item.marcaId!.substring(3)
        : null;
    return catalogo.logotipoDe(nome, marcaOpenFinanceId: id);
  }

  static String _instituicaoLegada(String nomeConta) {
    final nome = InstituicaoOpenFinance.normalizarNome(nomeConta);
    if (const {
      'btg', 'btgpessoal', 'btgempresa', 'btgpactual',
    }.contains(nome)) return 'BTG Pactual';
    if (const {
      'itau', 'itaupessoal', 'itauempresa', 'itauunibanco',
    }.contains(nome)) return 'Itaú';
    if (const {
      'nubank', 'nubankpessoal', 'nubankempresa', 'nu',
    }.contains(nome)) return 'Nubank';
    return nomeConta;
  }

  static String? logoDaConfiguracao(
    ConfiguracaoFinanceira item,
    String grupo,
    CatalogoInstituicoesBrasil catalogo,
  ) {
    if (grupo == 'MAQUININHAS') {
      return logoOperadora(
        item.instituicao, item.marcaId,
        habilitadoBrasil: catalogo.habilitado,
      );
    }
    if (grupo == 'CONTAS') return logoConta(item, catalogo);
    return null;
  }
}
