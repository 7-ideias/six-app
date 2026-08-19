import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/di/operacao_module.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/operacao_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/domain/services/operacao/operacao_service.dart';
import 'package:sixpos/l10n/app_localizations.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

Future<void> showRecebimentoPagamentoWebDialog({
  required BuildContext context,
  required bool somenteSelecao,
  required double valorTotalVenda,
  required List<Map<String, dynamic>> itensResumo,
  required String idColaborador,
  required String nomeColaborador,
  String? clienteNome,
  String? numeroVenda,
  OperacaoService? operacaoService,
  List<FormaPagamentoSelecionada> formasPagamentoIniciais =
      const <FormaPagamentoSelecionada>[],
  Map<String, String> descricoesFormasIniciais = const <String, String>{},
  ValueChanged<RecebimentoPagamentoSelecaoResultado>? onSelecaoConfirmada,
  VoidCallback? onSuccess,
}) async {
  final bool reduceMotion =
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    transitionDuration: Duration(milliseconds: reduceMotion ? 1 : 260),
    pageBuilder:
        (
          BuildContext routeContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return _RecebimentoPagamentoRouteSurface(
            animation: animation,
            reduceMotion: reduceMotion,
            child: RecebimentoPagamentoWeb(
              embedded: true,
              somenteSelecao: somenteSelecao,
              formasPagamentoIniciais: formasPagamentoIniciais,
              descricoesFormasIniciais: descricoesFormasIniciais,
              onBack: () => Navigator.of(routeContext).maybePop(),
              onSelecaoConfirmada: onSelecaoConfirmada,
              onSuccess: () {
                onSuccess?.call();
                Navigator.of(routeContext).maybePop();
              },
              valorTotalVenda: valorTotalVenda,
              itensResumo: itensResumo,
              clienteNome: clienteNome,
              numeroVenda: numeroVenda,
              idColaborador: idColaborador,
              nomeColaborador: nomeColaborador,
              operacaoService: operacaoService,
            ),
          );
        },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) => child,
  );
}

class RecebimentoPagamentoSelecaoResultado {
  const RecebimentoPagamentoSelecaoResultado({
    required this.formasPagamento,
    required this.descricaoPorCodigo,
  });

  final List<FormaPagamentoSelecionada> formasPagamento;
  final Map<String, String> descricaoPorCodigo;

  double get totalDistribuido => formasPagamento.fold<double>(
    0,
    (double soma, FormaPagamentoSelecionada forma) => soma + forma.valor,
  );
}

class RecebimentoPagamentoWeb extends StatefulWidget {
  const RecebimentoPagamentoWeb({
    super.key,
    required this.valorTotalVenda,
    required this.itensResumo,
    required this.idColaborador,
    required this.nomeColaborador,
    this.clienteNome,
    this.numeroVenda,
    this.operacaoService,
    this.embedded = false,
    this.onBack,
    this.onSuccess,
    this.somenteSelecao = false,
    this.formasPagamentoIniciais = const <FormaPagamentoSelecionada>[],
    this.descricoesFormasIniciais = const <String, String>{},
    this.onSelecaoConfirmada,
  });

  final double valorTotalVenda;
  final List<Map<String, dynamic>> itensResumo;
  final String idColaborador;
  final String nomeColaborador;
  final String? clienteNome;
  final String? numeroVenda;
  final OperacaoService? operacaoService;
  final bool embedded;
  final VoidCallback? onBack;
  final VoidCallback? onSuccess;
  final bool somenteSelecao;
  final List<FormaPagamentoSelecionada> formasPagamentoIniciais;
  final Map<String, String> descricoesFormasIniciais;
  final ValueChanged<RecebimentoPagamentoSelecaoResultado>? onSelecaoConfirmada;

  @override
  State<RecebimentoPagamentoWeb> createState() =>
      _RecebimentoPagamentoWebState();
}

enum _DecisaoImpressao { naoImprimir, imprimirA4, imprimirCupomTermico }

class _FormaPagamentoWeb {
  const _FormaPagamentoWeb({
    required this.codigo,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.selecionado,
    required this.valor,
  });

  final String codigo;
  final String titulo;
  final String descricao;
  final IconData icone;
  final bool selecionado;
  final double valor;

  _FormaPagamentoWeb copyWith({
    String? codigo,
    String? titulo,
    String? descricao,
    IconData? icone,
    bool? selecionado,
    double? valor,
  }) {
    return _FormaPagamentoWeb(
      codigo: codigo ?? this.codigo,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      icone: icone ?? this.icone,
      selecionado: selecionado ?? this.selecionado,
      valor: valor ?? this.valor,
    );
  }
}

class _RecebimentoPagamentoWebState extends State<RecebimentoPagamentoWeb>
    with SingleTickerProviderStateMixin {
  late final List<Map<String, dynamic>> _itensResumo;
  late final OperacaoService _operacaoService;
  final CaixaApiClient _caixaApiClient = HttpCaixaApiClient();
  final Map<String, TextEditingController> _valorControllers =
      <String, TextEditingController>{};

  late List<_FormaPagamentoWeb> _formasPagamento;
  bool _salvandoOperacao = false;
  bool _carregandoFormas = true;
  bool _estadoInicialAplicado = false;
  late final AnimationController _iconController;

  static const List<_FormaPagamentoWeb> _formasPagamentoFallback =
      <_FormaPagamentoWeb>[
        _FormaPagamentoWeb(
          codigo: 'TIPO1',
          titulo: 'Dinheiro',
          descricao: 'Recebimento no caixa com conferência imediata.',
          icone: Icons.payments_outlined,
          selecionado: false,
          valor: 0,
        ),
        _FormaPagamentoWeb(
          codigo: 'TIPO2',
          titulo: 'Pix',
          descricao: 'Confirmação rápida via chave, QR Code ou copia e cola.',
          icone: Icons.qr_code_2_outlined,
          selecionado: false,
          valor: 0,
        ),
        _FormaPagamentoWeb(
          codigo: 'TIPO3',
          titulo: 'Cartão de crédito',
          descricao: 'Recebimento parcelado ou à vista com operadora.',
          icone: Icons.credit_card_outlined,
          selecionado: false,
          valor: 0,
        ),
        _FormaPagamentoWeb(
          codigo: 'TIPO4',
          titulo: 'Cartão de débito',
          descricao: 'Liquidação imediata com confirmação de maquininha.',
          icone: Icons.point_of_sale_outlined,
          selecionado: false,
          valor: 0,
        ),
        _FormaPagamentoWeb(
          codigo: 'TIPO5',
          titulo: 'Boleto',
          descricao: 'Emissão para pagamento posterior com baixa futura.',
          icone: Icons.receipt_long_outlined,
          selecionado: false,
          valor: 0,
        ),
        _FormaPagamentoWeb(
          codigo: 'TIPO6',
          titulo: 'Fiado',
          descricao: 'Lançamento em aberto para cobrança posterior.',
          icone: Icons.history_toggle_off_outlined,
          selecionado: false,
          valor: 0,
        ),
        _FormaPagamentoWeb(
          codigo: 'TIPO7',
          titulo: 'Crediário',
          descricao: 'Lançamento com cobrança futura.',
          icone: Icons.event_note_outlined,
          selecionado: false,
          valor: 0,
        ),
        _FormaPagamentoWeb(
          codigo: 'TIPO8',
          titulo: 'Convênio',
          descricao: 'Pagamento via convênio da empresa.',
          icone: Icons.people_outline,
          selecionado: false,
          valor: 0,
        ),
        _FormaPagamentoWeb(
          codigo: 'TIPO9',
          titulo: 'Vale',
          descricao: 'Pagamento via voucher ou vale.',
          icone: Icons.confirmation_number_outlined,
          selecionado: false,
          valor: 0,
        ),
        _FormaPagamentoWeb(
          codigo: 'TIPO10',
          titulo: 'Outros',
          descricao: 'Outros tipos de recebimento.',
          icone: Icons.more_horiz_outlined,
          selecionado: false,
          valor: 0,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    _itensResumo = List<Map<String, dynamic>>.from(widget.itensResumo);
    _operacaoService = widget.operacaoService ?? OperacaoModule.operacaoService;
    _formasPagamento = _formasPagamentoFallback
        .map((forma) => forma.copyWith())
        .toList(growable: false);
    _carregarFormasPagamentoConfiguradas();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
        _iconController.value = 1;
      } else {
        _iconController.forward();
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    for (final TextEditingController controller in _valorControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarFormasPagamentoConfiguradas() async {
    try {
      final InformacoesBasicasCaixaResponse informacoes = await _caixaApiClient
          .getInformacoesBasicasDoCaixa();
      final List<_FormaPagamentoWeb> formas =
          _montarFormasPagamentoConfiguradas(informacoes.tiposRecebimento);
      if (!mounted) return;
      setState(() {
        if (formas.isNotEmpty) {
          _formasPagamento = formas;
        }
        _carregandoFormas = false;
      });
      _aplicarEstadoInicialSeNecessario();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregandoFormas = false;
      });
      _aplicarEstadoInicialSeNecessario();
    }
  }

  List<_FormaPagamentoWeb> _montarFormasPagamentoConfiguradas(
    List<TiposRecebimento> tipos,
  ) {
    final List<TiposRecebimento> ativos =
        tipos.where((TiposRecebimento tipo) => tipo.ativo).toList()..sort(
          (TiposRecebimento a, TiposRecebimento b) =>
              a.ordemExibicao.compareTo(b.ordemExibicao),
        );

    final Set<String> codigosAdicionados = <String>{};
    final List<_FormaPagamentoWeb> formas = <_FormaPagamentoWeb>[];
    for (final TiposRecebimento tipo in ativos) {
      final String codigo = tipo.codigoTipo.trim().toUpperCase();
      if (!_codigoTipoValido(codigo) || codigosAdicionados.contains(codigo)) {
        continue;
      }

      final String titulo = tipo.descricaoExibicao.trim().isNotEmpty
          ? tipo.descricaoExibicao.trim()
          : _descricaoPadraoPorCodigo(codigo);

      formas.add(
        _FormaPagamentoWeb(
          codigo: codigo,
          titulo: titulo,
          descricao: tipo.naturezaRecebimento.trim().isNotEmpty
              ? tipo.naturezaRecebimento.trim()
              : _descricaoPadraoPorCodigo(codigo),
          icone: _iconePorCodigo(codigo),
          selecionado: false,
          valor: 0,
        ),
      );
      codigosAdicionados.add(codigo);
    }
    return formas;
  }

  void _aplicarEstadoInicialSeNecessario() {
    if (_estadoInicialAplicado || !mounted) return;
    _estadoInicialAplicado = true;

    if (widget.formasPagamentoIniciais.isEmpty &&
        widget.descricoesFormasIniciais.isEmpty) {
      if (_formasPagamento.isEmpty) return;
      final String codigoInicial = _formasPagamento.first.codigo;
      setState(() {
        _formasPagamento = _formasPagamento
            .map(
              (_FormaPagamentoWeb forma) => forma.copyWith(
                selecionado: forma.codigo == codigoInicial,
                valor: forma.codigo == codigoInicial
                    ? widget.valorTotalVenda
                    : 0,
              ),
            )
            .toList(growable: false);
      });
      _controllerFor(_formasPagamento.first).text = widget.valorTotalVenda
          .toStringAsFixed(2);
      return;
    }

    final Map<String, FormaPagamentoSelecionada> formaInicialPorCodigo =
        <String, FormaPagamentoSelecionada>{
          for (final FormaPagamentoSelecionada forma
              in widget.formasPagamentoIniciais)
            forma.codigo.trim().toUpperCase(): forma,
        };

    setState(() {
      _formasPagamento = _formasPagamento
          .map((forma) {
            final FormaPagamentoSelecionada? inicial =
                formaInicialPorCodigo[forma.codigo];
            final String? descricaoInicial =
                widget.descricoesFormasIniciais[forma.codigo];
            return forma.copyWith(
              titulo: descricaoInicial?.trim().isNotEmpty == true
                  ? descricaoInicial!.trim()
                  : forma.titulo,
              selecionado: inicial != null && inicial.valor > 0,
              valor: inicial?.valor ?? 0,
            );
          })
          .toList(growable: false);
    });

    for (final _FormaPagamentoWeb forma in _formasPagamento) {
      if (forma.valor <= 0) {
        _valorControllers.remove(forma.codigo)?.dispose();
        continue;
      }
      _controllerFor(forma).text = forma.valor.toStringAsFixed(2);
    }
  }

  bool _codigoTipoValido(String codigo) {
    return RegExp(r'^TIPO(10|[1-9])$').hasMatch(codigo);
  }

  String _descricaoPadraoPorCodigo(String codigo) {
    switch (codigo) {
      case 'TIPO1':
        return 'Dinheiro';
      case 'TIPO2':
        return 'Pix';
      case 'TIPO3':
        return 'Cartão de crédito';
      case 'TIPO4':
        return 'Cartão de débito';
      case 'TIPO5':
        return 'Boleto';
      case 'TIPO6':
        return 'Fiado';
      case 'TIPO7':
        return 'Crediário';
      case 'TIPO8':
        return 'Convênio';
      case 'TIPO9':
        return 'Vale';
      case 'TIPO10':
        return 'Outros';
      default:
        return codigo;
    }
  }

  IconData _iconePorCodigo(String codigo) {
    switch (codigo) {
      case 'TIPO1':
        return Icons.payments_outlined;
      case 'TIPO2':
        return Icons.qr_code_2_outlined;
      case 'TIPO3':
        return Icons.credit_card_outlined;
      case 'TIPO4':
        return Icons.point_of_sale_outlined;
      case 'TIPO5':
        return Icons.receipt_long_outlined;
      case 'TIPO6':
        return Icons.history_toggle_off_outlined;
      case 'TIPO7':
        return Icons.event_note_outlined;
      case 'TIPO8':
        return Icons.people_outline;
      case 'TIPO9':
        return Icons.confirmation_number_outlined;
      default:
        return Icons.more_horiz_outlined;
    }
  }

  TextEditingController _controllerFor(_FormaPagamentoWeb forma) {
    return _valorControllers.putIfAbsent(
      forma.codigo,
      () => TextEditingController(
        text: forma.valor > 0 ? forma.valor.toStringAsFixed(2) : '',
      ),
    );
  }

  int _quantidadeFormasSelecionadas() {
    return _formasPagamento.where((forma) => forma.selecionado).length;
  }

  double _valorSelecionadoTotal() {
    return _formasPagamento.fold<double>(
      0,
      (double soma, _FormaPagamentoWeb forma) =>
          soma + (forma.selecionado ? forma.valor : 0),
    );
  }

  double _valorRestante() {
    return widget.valorTotalVenda - _valorSelecionadoTotal();
  }

  List<_FormaPagamentoWeb> _formasPagamentoVisiveis() {
    return _formasPagamento
        .where((forma) => forma.selecionado)
        .toList(growable: false);
  }

  List<FormaPagamentoSelecionada> _montarFormasSelecionadas() {
    return _formasPagamento
        .where((forma) => forma.selecionado && forma.valor > 0)
        .map(
          (forma) => FormaPagamentoSelecionada(
            codigo: forma.codigo,
            valor: forma.valor,
          ),
        )
        .toList(growable: false);
  }

  Map<String, String> _mapaDescricaoSelecionada() {
    return <String, String>{
      for (final _FormaPagamentoWeb forma in _formasPagamento)
        if (forma.selecionado && forma.valor > 0) forma.codigo: forma.titulo,
    };
  }

  List<ItemVendaAtual> _montarItensDaVenda() {
    return _itensResumo
        .map((item) {
          final String idProduto =
              (item['id'] ??
                      item['codigo'] ??
                      item['idSKU'] ??
                      item['idCodigoUnicoDoProduto'] ??
                      '')
                  .toString();

          return ItemVendaAtual(
            idProduto: idProduto,
            nome: (item['nome'] ?? '').toString(),
            quantidade: (item['quantidade'] ?? 1) as int,
            valorUnitario: ((item['valor'] ?? 0.0) as num).toDouble(),
            ehServico: (item['ehServico'] ?? false) == true,
          );
        })
        .toList(growable: false);
  }

  Future<void> _fecharTela() async {
    if (widget.embedded) {
      widget.onBack?.call();
      return;
    }

    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _alternarForma(_FormaPagamentoWeb forma, bool selecionado) {
    setState(() {
      _formasPagamento = _formasPagamento
          .map((item) {
            if (item.codigo != forma.codigo) {
              return item;
            }
            return item.copyWith(
              selecionado: selecionado,
              valor: selecionado ? item.valor : 0,
            );
          })
          .toList(growable: false);
    });

    if (!selecionado) {
      _valorControllers[forma.codigo]?.clear();
    }
  }

  void _alterarValorForma(_FormaPagamentoWeb forma, String value) {
    final double parsed = _parseValor(value);
    setState(() {
      _formasPagamento = _formasPagamento
          .map((item) {
            if (item.codigo != forma.codigo) {
              return item;
            }
            return item.copyWith(
              valor: parsed < 0 ? 0 : parsed,
              selecionado: parsed > 0 || item.selecionado,
            );
          })
          .toList(growable: false);
    });
  }

  void _preencherValorRestante(_FormaPagamentoWeb forma) {
    final double restante = _valorRestante();
    final double valorAtual = forma.valor;
    final double novoValor = (valorAtual + restante).clamp(
      0.0,
      double.infinity,
    );
    setState(() {
      _formasPagamento = _formasPagamento
          .map((item) {
            if (item.codigo != forma.codigo) {
              return item;
            }
            return item.copyWith(selecionado: true, valor: novoValor);
          })
          .toList(growable: false);
    });
    _controllerFor(forma).text = novoValor.toStringAsFixed(2);
  }

  void _adicionarForma() {
    _FormaPagamentoWeb? novaForma;
    for (final _FormaPagamentoWeb forma in _formasPagamento) {
      if (!forma.selecionado) {
        novaForma = forma;
        break;
      }
    }
    final _FormaPagamentoWeb? formaAdicionada = novaForma;
    if (formaAdicionada == null) return;

    final double valorInicial = _valorRestante()
        .clamp(0, double.infinity)
        .toDouble();
    setState(() {
      _formasPagamento = _formasPagamento
          .map(
            (_FormaPagamentoWeb forma) => forma.codigo == formaAdicionada.codigo
                ? forma.copyWith(selecionado: true, valor: valorInicial)
                : forma,
          )
          .toList(growable: false);
    });
    _controllerFor(formaAdicionada).text = valorInicial > 0
        ? valorInicial.toStringAsFixed(2)
        : '';
  }

  void _removerForma(_FormaPagamentoWeb forma) {
    if (_quantidadeFormasSelecionadas() <= 1) return;
    _alternarForma(forma, false);
  }

  void _substituirForma(_FormaPagamentoWeb formaAtual, String novoCodigo) {
    if (formaAtual.codigo == novoCodigo) return;
    _FormaPagamentoWeb? novaForma;
    for (final _FormaPagamentoWeb forma in _formasPagamento) {
      if (forma.codigo == novoCodigo) {
        novaForma = forma;
        break;
      }
    }
    final _FormaPagamentoWeb? formaSubstituta = novaForma;
    if (formaSubstituta == null || formaSubstituta.selecionado) return;

    final double valorAtual = formaAtual.valor;
    setState(() {
      _formasPagamento = _formasPagamento
          .map((_FormaPagamentoWeb forma) {
            if (forma.codigo == formaAtual.codigo) {
              return forma.copyWith(selecionado: false, valor: 0);
            }
            if (forma.codigo == formaSubstituta.codigo) {
              return forma.copyWith(selecionado: true, valor: valorAtual);
            }
            return forma;
          })
          .toList(growable: false);
    });

    _valorControllers[formaAtual.codigo]?.clear();
    _controllerFor(formaSubstituta).text = valorAtual > 0
        ? valorAtual.toStringAsFixed(2)
        : '';
  }

  Future<void> _mostrarDialogMensagem({
    required String titulo,
    required String mensagem,
    bool sucesso = false,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            sucesso ? Icons.check_circle_outline : Icons.info_outline,
            color: sucesso
                ? const Color(0xFF2E7D32)
                : Theme.of(context).colorScheme.primary,
            size: 34,
          ),
          title: Text(titulo),
          content: Text(mensagem),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)?.pdvWebClosePaymentAction ??
                    'Fechar',
              ),
            ),
          ],
        );
      },
    );
  }

  Future<_DecisaoImpressao> _perguntarImpressaoAposConclusao({
    required String uuidOperacao,
  }) async {
    final _DecisaoImpressao? resposta = await showDialog<_DecisaoImpressao>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            Icons.check_circle_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 34,
          ),
          title: const Text('Operação concluída'),
          content: Text(
            'Venda enviada com sucesso.\nUUID: $uuidOperacao\n\nDeseja imprimir o comprovante agora?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_DecisaoImpressao.naoImprimir);
              },
              child: const Text('Não imprimir'),
            ),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop(_DecisaoImpressao.imprimirA4);
              },
              child: const Text('Imprimir A4'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).pop(_DecisaoImpressao.imprimirCupomTermico);
              },
              child: const Text('Imprimir cupom'),
            ),
          ],
        );
      },
    );

    return resposta ?? _DecisaoImpressao.naoImprimir;
  }

  FormatoImpressaoOperacao? _mapearFormatoImpressao(_DecisaoImpressao decisao) {
    switch (decisao) {
      case _DecisaoImpressao.naoImprimir:
        return null;
      case _DecisaoImpressao.imprimirA4:
        return FormatoImpressaoOperacao.a4;
      case _DecisaoImpressao.imprimirCupomTermico:
        return FormatoImpressaoOperacao.cupomTermico;
    }
  }

  String _rotuloFormatoImpressao(FormatoImpressaoOperacao formato) {
    switch (formato) {
      case FormatoImpressaoOperacao.a4:
        return 'A4';
      case FormatoImpressaoOperacao.cupomTermico:
        return 'Cupom térmico';
    }
  }

  Future<void> _confirmarOperacao() async {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final List<FormaPagamentoSelecionada> formasSelecionadas =
        _montarFormasSelecionadas();

    if (formasSelecionadas.isEmpty) {
      await _mostrarDialogMensagem(
        titulo:
            l10n?.pdvWebSelectPaymentMethodTitle ??
            'Selecione uma forma de recebimento',
        mensagem:
            l10n?.pdvWebSelectPaymentMethodMessage ??
            'Escolha pelo menos uma forma e informe um valor para continuar.',
      );
      return;
    }

    final double diferenca = (_valorSelecionadoTotal() - widget.valorTotalVenda)
        .abs();
    if (diferenca > 0.009) {
      await _mostrarDialogMensagem(
        titulo: l10n?.pdvWebPaymentMismatchTitle ?? 'Revise a distribuição',
        mensagem:
            l10n?.pdvWebPaymentMismatchMessage ??
            'A soma das formas deve ser igual ao total da venda.',
      );
      return;
    }

    if (widget.somenteSelecao) {
      widget.onSelecaoConfirmada?.call(
        RecebimentoPagamentoSelecaoResultado(
          formasPagamento: formasSelecionadas,
          descricaoPorCodigo: _mapaDescricaoSelecionada(),
        ),
      );
      await _fecharTela();
      return;
    }

    final bool confirmar =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              icon: Icon(
                Icons.verified_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 34,
              ),
              title: Text(
                l10n?.pdvWebConfirmReceiveAction ?? 'Confirmar recebimento',
              ),
              content: Text(
                '${l10n?.pdvWebConfirmReceiveMessagePrefix ?? 'Deseja confirmar o recebimento no valor de'} ${_formatarValor(widget.valorTotalVenda)}?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n?.pdvWebBackAction ?? 'Voltar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    l10n?.pdvWebConfirmReceiveAction ?? 'Confirmar recebimento',
                  ),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmar) return;

    setState(() => _salvandoOperacao = true);

    try {
      final DateTime dataOperacao = DateTime.now();
      final OperacaoVendaInput input = OperacaoVendaInput(
        descricao:
            'Venda ${(widget.numeroVenda?.trim().isNotEmpty ?? false) ? widget.numeroVenda!.trim() : 'em andamento'}',
        idColaborador: widget.idColaborador,
        nomeColaborador: widget.nomeColaborador,
        itens: _montarItensDaVenda(),
        formasPagamento: formasSelecionadas,
        dataOperacao: dataOperacao,
      );

      final OperacaoInserirResponse response = await _operacaoService
          .finalizarVenda(input);

      if (!mounted) return;

      final String uuidOperacao = response.uuid.trim();
      if (uuidOperacao.isNotEmpty) {
        final _DecisaoImpressao decisao =
            await _perguntarImpressaoAposConclusao(uuidOperacao: uuidOperacao);

        if (!mounted) return;

        final FormatoImpressaoOperacao? formato = _mapearFormatoImpressao(
          decisao,
        );
        if (formato != null) {
          try {
            await _operacaoService.imprimirComprovanteDaOperacao(
              idOperacao: uuidOperacao,
              formato: formato,
              input: input,
            );

            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Solicitação de impressão enviada (${_rotuloFormatoImpressao(formato)}).',
                ),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            await _mostrarDialogMensagem(
              titulo: 'Operação salva, falha na impressão',
              mensagem: e.toString(),
            );
          }
        }
      }

      if (!mounted) return;
      if (widget.embedded) {
        widget.onSuccess?.call();
      } else {
        await _fecharTela();
      }
    } catch (e) {
      if (!mounted) return;
      await _mostrarDialogMensagem(
        titulo: 'Erro ao enviar operação',
        mensagem: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _salvandoOperacao = false);
      }
    }
  }

  String _txt(String key, String fallback) =>
      context.t(key, fallback: fallback);

  Widget _buildCabecalhoCompacto() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String cliente = widget.clienteNome?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildPaymentIcon(theme),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n?.pdvWebPaymentOverlayTitle ?? 'Recebimento',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${l10n?.pdvWebSaleTotalLabel ?? 'Total da venda'}: ${_formatarValor(widget.valorTotalVenda)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (cliente.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    cliente,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: l10n?.pdvWebClosePaymentAction ?? 'Fechar recebimento',
            onPressed: _salvandoOperacao ? null : _fecharTela,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIcon(ThemeData theme) {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (BuildContext context, Widget? child) {
        final double progress = Curves.easeOutBack.transform(
          _iconController.value,
        );
        return Transform.scale(
          scale: 0.82 + (progress * 0.18),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(
              Icons.payments_rounded,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumoDistribuicao() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final double totalDistribuido = _valorSelecionadoTotal();
    final double restante = _valorRestante();
    final bool completo = restante.abs() <= 0.009;
    final Color statusColor = completo ? tokens.success : tokens.warning;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _buildResumoItem(
                  l10n?.pdvWebSaleTotalLabel ?? 'Total da venda',
                  _formatarValor(widget.valorTotalVenda),
                  tokens.primaryText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResumoItem(
                  l10n?.pdvWebDistributedTotalLabel ?? 'Total distribuído',
                  _formatarValor(totalDistribuido),
                  tokens.primaryText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResumoItem(
                  l10n?.pdvWebRemainingAmountLabel ?? 'Valor restante',
                  _formatarValor(restante),
                  statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  completo
                      ? Icons.check_circle_rounded
                      : Icons.info_outline_rounded,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    completo
                        ? (l10n?.pdvWebPaymentDistributionReadyLabel ??
                              'Distribuição pronta para confirmação.')
                        : (l10n?.pdvWebPaymentDistributionReviewLabel ??
                              'Ajuste os valores para fechar o total da venda.'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoItem(String label, String value, Color valueColor) {
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: tokens.secondaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildPainelFormaPagamento(_FormaPagamentoWeb forma) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final TextEditingController controller = _controllerFor(forma);
    final List<_FormaPagamentoWeb> opcoes = _formasPagamento
        .where(
          (_FormaPagamentoWeb opcao) =>
              opcao.codigo == forma.codigo || !opcao.selecionado,
        )
        .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !_salvandoOperacao,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _txt('recebimento.valorForma', 'Valor da forma'),
                    prefixText: '${_currencyCode()} ',
                    suffixIcon: IconButton(
                      tooltip:
                          l10n?.pdvWebCompleteRemainingAction ??
                          'Completar restante',
                      onPressed: _salvandoOperacao
                          ? null
                          : () => _preencherValorRestante(forma),
                      icon: const Icon(Icons.auto_fix_high_rounded, size: 19),
                    ),
                    filled: true,
                    fillColor: tokens.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  onChanged: (String value) => _alterarValorForma(forma, value),
                ),
              ),
              if (_quantidadeFormasSelecionadas() > 1) ...<Widget>[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: _txt('recebimento.removerForma', 'Remover forma'),
                  onPressed: _salvandoOperacao
                      ? null
                      : () => _removerForma(forma),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: tokens.danger,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            key: ValueKey<String>('payment-method-${forma.codigo}'),
            initialValue: forma.codigo,
            isExpanded: true,
            dropdownColor: tokens.menuBackground,
            decoration: InputDecoration(
              labelText: _txt(
                'recebimento.tipoRecebimento',
                'Tipo de recebimento',
              ),
              filled: true,
              fillColor: tokens.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            items: opcoes
                .map(
                  (_FormaPagamentoWeb opcao) => DropdownMenuItem<String>(
                    value: opcao.codigo,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          opcao.icone,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            opcao.titulo,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.primaryText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _salvandoOperacao
                ? null
                : (String? codigo) {
                    if (codigo != null) _substituirForma(forma, codigo);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildPainelPrincipal() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final List<_FormaPagamentoWeb> formasVisiveis = _formasPagamentoVisiveis();
    final bool podeAdicionar = _formasPagamento.any(
      (_FormaPagamentoWeb forma) => !forma.selecionado,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildResumoDistribuicao(),
          const SizedBox(height: 22),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _txt(
                    'recebimento.formasRecebimento',
                    l10n?.pdvWebPaymentMethodsTitle ?? 'Formas de recebimento',
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '${_txt('recebimento.restante', 'Restante')}: ${_formatarValor(_valorRestante())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.secondaryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_carregandoFormas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Column(
                  children: <Widget>[
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(
                      _txt(
                        'recebimento.carregandoTipos',
                        'Carregando tipos de recebimento...',
                      ),
                      style: TextStyle(color: tokens.secondaryText),
                    ),
                  ],
                ),
              ),
            )
          else
            ...formasVisiveis.map(
              (_FormaPagamentoWeb forma) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPainelFormaPagamento(forma),
              ),
            ),
          if (!_carregandoFormas)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: podeAdicionar && !_salvandoOperacao
                    ? _adicionarForma
                    : null,
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  _txt('recebimento.adicionarForma', 'Adicionar forma'),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarraAcoes() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final bool distribuicaoValida =
        _montarFormasSelecionadas().isNotEmpty &&
        _valorRestante().abs() <= 0.009;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: tokens.surfaceElevated,
        border: Border(top: BorderSide(color: tokens.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          TextButton(
            onPressed: _salvandoOperacao ? null : _fecharTela,
            child: Text(_txt('common.cancel', 'Cancelar')),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: !_salvandoOperacao && distribuicaoValida
                ? _confirmarOperacao
                : null,
            icon: _salvandoOperacao
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_outline_rounded),
            label: Text(
              _salvandoOperacao
                  ? (l10n?.pdvWebProcessingReceiveAction ?? 'Processando...')
                  : (widget.somenteSelecao
                        ? (l10n?.pdvWebConfirmDistributionAction ??
                              'Confirmar distribuição')
                        : (l10n?.pdvWebConfirmReceiveAction ??
                              'Confirmar recebimento')),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatarValor(double valor) =>
      context.read<LocaleSettingsProvider>().formatCurrency(valor);

  String _currencyCode() => context.read<LocaleSettingsProvider>().currencyCode;

  double _parseValor(String value) {
    final String texto = value
        .trim()
        .replaceAll(_currencyCode(), '')
        .replaceAll('R\$', '')
        .trim();
    final String normalizado = texto.contains(',') && texto.contains('.')
        ? texto.replaceAll('.', '').replaceAll(',', '.')
        : texto.replaceAll(',', '.');
    return double.tryParse(normalizado) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final WebThemeTokens tokens = WebThemeTokens.of(context);
    final String routeLabel =
        AppLocalizations.of(context)?.pdvWebPaymentOverlayTitle ??
        'Recebimento';
    final Widget conteudo = PopScope(
      canPop: !_salvandoOperacao,
      child: Semantics(
        namesRoute: true,
        label: routeLabel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF020617).withValues(alpha: 0.30),
                blurRadius: 42,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: tokens.surfaceElevated,
              surfaceTintColor: Colors.transparent,
              child: Stack(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      _buildCabecalhoCompacto(),
                      Divider(height: 1, color: tokens.divider),
                      Expanded(child: _buildPainelPrincipal()),
                      _buildBarraAcoes(),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 3,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return conteudo;
    }

    return Scaffold(
      backgroundColor: tokens.workspaceBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680, maxHeight: 780),
              child: conteudo,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecebimentoPagamentoRouteSurface extends StatelessWidget {
  const _RecebimentoPagamentoRouteSurface({
    required this.animation,
    required this.reduceMotion,
    required this.child,
  });

  final Animation<double> animation;
  final bool reduceMotion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).maybePop();
        },
      },
      child: Focus(
        autofocus: true,
        child: AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? animatedChild) {
            final double progress = reduceMotion
                ? 1
                : Curves.easeOutCubic.transform(animation.value);
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                BackdropFilter(
                  filter: ui.ImageFilter.blur(
                    sigmaX: 4 * progress,
                    sigmaY: 4 * progress,
                  ),
                  child: ColoredBox(
                    color: const Color(
                      0xFF0F172A,
                    ).withValues(alpha: 0.58 * progress),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                              final double availableHeight =
                                  constraints.maxHeight;
                              final double dialogHeight = availableHeight > 780
                                  ? 780
                                  : availableHeight;
                              return Opacity(
                                opacity: progress,
                                child: Transform.translate(
                                  offset: Offset(0, 16 * (1 - progress)),
                                  child: Transform.scale(
                                    scale: 0.96 + (0.04 * progress),
                                    child: SizedBox(
                                      width: 680,
                                      height: dialogHeight,
                                      child: animatedChild,
                                    ),
                                  ),
                                ),
                              );
                            },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: child,
        ),
      ),
    );
  }
}
