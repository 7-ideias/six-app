import 'package:flutter/material.dart';
import 'package:sixpos/core/di/operacao_module.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/operacao_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/domain/services/operacao/operacao_service.dart';
import 'package:sixpos/l10n/app_localizations.dart';
import 'package:sixpos/top_navigation_bar_web.dart';

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

class _RecebimentoPagamentoWebState extends State<RecebimentoPagamentoWeb> {
  late final List<Map<String, dynamic>> _itensResumo;
  late final OperacaoService _operacaoService;
  final CaixaApiClient _caixaApiClient = HttpCaixaApiClient();
  final Map<String, TextEditingController> _valorControllers =
      <String, TextEditingController>{};

  late List<_FormaPagamentoWeb> _formasPagamento;
  bool _salvandoOperacao = false;
  bool _carregandoFormas = true;
  bool _estadoInicialAplicado = false;

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
    _itensResumo = List<Map<String, dynamic>>.from(widget.itensResumo);
    _operacaoService = widget.operacaoService ?? OperacaoModule.operacaoService;
    _formasPagamento = _formasPagamentoFallback
        .map((forma) => forma.copyWith())
        .toList(growable: false);
    _carregarFormasPagamentoConfiguradas();
  }

  @override
  void dispose() {
    for (final TextEditingController controller in _valorControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarFormasPagamentoConfiguradas() async {
    try {
      final InformacoesBasicasCaixaResponse informacoes =
          await _caixaApiClient.getInformacoesBasicasDoCaixa();
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

      final String titulo =
          tipo.descricaoExibicao.trim().isNotEmpty
              ? tipo.descricaoExibicao.trim()
              : _descricaoPadraoPorCodigo(codigo);

      formas.add(
        _FormaPagamentoWeb(
          codigo: codigo,
          titulo: titulo,
          descricao:
              tipo.naturezaRecebimento.trim().isNotEmpty
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
              titulo:
                  descricaoInicial?.trim().isNotEmpty == true
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
      final TextEditingController? controller = _valorControllers.remove(
        forma.codigo,
      );
      controller?.dispose();
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
            color:
                sucesso
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

    final double diferenca =
        (_valorSelecionadoTotal() - widget.valorTotalVenda).abs();
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

  Widget _buildCabecalhoCompacto() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final bool temCliente = widget.clienteNome?.trim().isNotEmpty == true;
    final double restante = _valorRestante();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(
                  l10n?.pdvWebPaymentOverlayTitle ?? 'Recebimento',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                _buildInfoChip(
                  icon: Icons.attach_money_outlined,
                  text:
                      '${l10n?.pdvWebSaleTotalLabel ?? 'Total da venda'} ${_formatarValor(widget.valorTotalVenda)}',
                ),
                if (temCliente)
                  _buildInfoChip(
                    icon: Icons.person_outline,
                    text: widget.clienteNome!.trim(),
                  ),
                if (_quantidadeFormasSelecionadas() > 0)
                  _buildInfoChip(
                    icon: Icons.payments_outlined,
                    text:
                        '${_quantidadeFormasSelecionadas()} ${l10n?.pdvWebPaymentMethodsSelectedLabel ?? 'formas'}',
                  ),
                if (restante.abs() <= 0.009)
                  _buildInfoChip(
                    icon: Icons.verified_outlined,
                    text:
                        l10n?.pdvWebPaymentDefinedLabel ?? 'Pagamento definido',
                  ),
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

  Widget _buildInfoChip({required IconData icon, required String text}) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillForma(_FormaPagamentoWeb forma) {
    final ThemeData theme = Theme.of(context);
    return FilterChip(
      selected: forma.selecionado,
      onSelected:
          _salvandoOperacao
              ? null
              : (bool selected) => _alternarForma(forma, selected),
      avatar: Icon(
        forma.icone,
        size: 16,
        color:
            forma.selecionado
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.primary,
      ),
      label: Text(forma.titulo),
      labelStyle: TextStyle(
        color:
            forma.selecionado
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: theme.colorScheme.primary,
      checkmarkColor: theme.colorScheme.onPrimary,
      side: BorderSide(
        color:
            forma.selecionado
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  Widget _buildPainelFormaPagamento(_FormaPagamentoWeb forma) {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final TextEditingController controller = _controllerFor(forma);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              forma.selecionado
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Checkbox(
                value: forma.selecionado,
                onChanged:
                    _salvandoOperacao
                        ? null
                        : (bool? value) =>
                            _alternarForma(forma, value ?? false),
              ),
              const SizedBox(width: 6),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  forma.icone,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  forma.titulo,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _formatarValor(forma.valor),
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            forma.descricao,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: forma.selecionado && !_salvandoOperacao,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n?.pdvWebPaymentValueFieldLabel ?? 'Valor',
                    prefixText: 'R\$ ',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (String value) => _alterarValorForma(forma, value),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed:
                    _salvandoOperacao
                        ? null
                        : () => _preencherValorRestante(forma),
                icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                label: Text(
                  l10n?.pdvWebCompleteRemainingAction ?? 'Completar restante',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumoDistribuicao() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final double totalDistribuido = _valorSelecionadoTotal();
    final double restante = _valorRestante();

    final bool completo = restante.abs() <= 0.009;
    final Color statusBg =
        completo ? const Color(0xFFE9F6EC) : const Color(0xFFFFF4E5);
    final Color statusFg =
        completo ? const Color(0xFF2E7D32) : const Color(0xFFB26A00);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n?.pdvWebPaymentSummaryTitle ?? 'Resumo da distribuição',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _buildLinhaResumo(
            l10n?.pdvWebSaleTotalLabel ?? 'Total da venda',
            _formatarValor(widget.valorTotalVenda),
          ),
          _buildLinhaResumo(
            l10n?.pdvWebDistributedTotalLabel ?? 'Total distribuído',
            _formatarValor(totalDistribuido),
          ),
          _buildLinhaResumo(
            l10n?.pdvWebRemainingAmountLabel ?? 'Valor restante',
            _formatarValor(restante),
          ),
          _buildLinhaResumo(
            l10n?.pdvWebPaymentMethodsSelectedLabel ?? 'Formas selecionadas',
            _quantidadeFormasSelecionadas().toString(),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              completo
                  ? (l10n?.pdvWebPaymentDistributionReadyLabel ??
                      'Distribuição pronta para confirmação.')
                  : (l10n?.pdvWebPaymentDistributionReviewLabel ??
                      'Ajuste os valores para fechar o total da venda.'),
              style: TextStyle(color: statusFg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaResumo(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPainelPrincipal() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final List<_FormaPagamentoWeb> formasVisiveis = _formasPagamentoVisiveis();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxWidth < 980;

        final Widget listaFormas = Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n?.pdvWebPaymentMethodsTitle ?? 'Formas de recebimento',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _formasPagamento
                    .map(_buildPillForma)
                    .toList(growable: false),
              ),
              const SizedBox(height: 10),
              Expanded(
                child:
                    _carregandoFormas
                        ? Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        )
                        : (formasVisiveis.isEmpty
                            ? Center(
                              child: Text(
                                l10n?.pdvWebSelectPaymentMethodHint ??
                                    'Selecione uma forma para informar valores.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                            : SingleChildScrollView(
                              child: Column(
                                children: formasVisiveis
                                    .map(
                                      (_FormaPagamentoWeb forma) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: _buildPainelFormaPagamento(
                                          forma,
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            )),
              ),
            ],
          ),
        );

        if (compact) {
          return Column(
            children: <Widget>[
              Expanded(child: listaFormas),
              const SizedBox(height: 10),
              _buildResumoDistribuicao(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(flex: 7, child: listaFormas),
            const SizedBox(width: 10),
            Expanded(flex: 3, child: _buildResumoDistribuicao()),
          ],
        );
      },
    );
  }

  Widget _buildBarraAcoes() {
    final AppLocalizations? l10n = AppLocalizations.of(context);
    final ThemeData theme = Theme.of(context);
    final double restante = _valorRestante();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          OutlinedButton.icon(
            onPressed: _salvandoOperacao ? null : _fecharTela,
            icon: const Icon(Icons.arrow_back_outlined),
            label: Text(l10n?.pdvWebClosePaymentAction ?? 'Fechar recebimento'),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                '${l10n?.pdvWebRemainingAmountLabel ?? 'Valor restante'}: ${_formatarValor(restante)}',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              FilledButton.icon(
                onPressed: _salvandoOperacao ? null : _confirmarOperacao,
                icon:
                    _salvandoOperacao
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.check_circle_outline),
                label: Text(
                  _salvandoOperacao
                      ? (l10n?.pdvWebProcessingReceiveAction ??
                          'Processando...')
                      : (widget.somenteSelecao
                          ? (l10n?.pdvWebConfirmDistributionAction ??
                              'Confirmar distribuição')
                          : (l10n?.pdvWebConfirmReceiveAction ??
                              'Confirmar recebimento')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatarValor(double valor) => 'R\$ ${valor.toStringAsFixed(2)}';

  double _parseValor(String value) {
    final String texto = value.trim().replaceAll('R\$', '').trim();
    final String normalizado =
        texto.contains(',') && texto.contains('.')
            ? texto.replaceAll('.', '').replaceAll(',', '.')
            : texto.replaceAll(',', '.');
    return double.tryParse(normalizado) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final Widget conteudo = Column(
      children: <Widget>[
        _buildCabecalhoCompacto(),
        const SizedBox(height: 10),
        Expanded(child: _buildPainelPrincipal()),
        _buildBarraAcoes(),
      ],
    );

    if (widget.embedded) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: conteudo,
      );
    }

    return Scaffold(
      appBar: TopNavigationBarWeb(
        items: const <TopNavItemData>[
          TopNavItemData(
            title: 'Início',
            subItems: <String>[
              'Preferências do Sistema',
              'Painel Administrativo',
            ],
          ),
          TopNavItemData(
            title: 'Permitir',
            subItems: <String>['Gerenciar Permissões', 'Alterar Configurações'],
          ),
          TopNavItemData(
            title: 'Cadastros',
            subItems: <String>['Clientes', 'Produtos', 'Fornecedores'],
          ),
          TopNavItemData(
            title: 'Relatórios',
            subItems: <String>['Vendas', 'Estoque', 'Financeiro'],
          ),
          TopNavItemData(
            title: 'Executar',
            subItems: <String>['Processar Pagamentos', 'Fechar Caixa'],
          ),
          TopNavItemData(
            title: 'Configurações',
            subItems: <String>['Sistema', 'Usuários'],
          ),
          TopNavItemData(
            title: 'Automações',
            subItems: <String>['Tarefas Agendadas'],
          ),
          TopNavItemData(
            title: 'Ajuda',
            subItems: <String>['Suporte', 'Sobre'],
          ),
        ],
        onNotificationPressed: () {},
      ),
      body: Padding(padding: const EdgeInsets.all(16), child: conteudo),
    );
  }
}
