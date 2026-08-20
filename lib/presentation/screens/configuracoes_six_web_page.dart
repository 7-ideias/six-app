import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/services/empresa_service.dart';
import '../../data/models/dominio_models.dart';
import '../../data/models/empresa_model.dart';
import '../../domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import '../../domain/models/regionalizacao_models.dart';
import '../../l10n/web_i18n_store.dart';
import '../../providers/locale_settings_provider.dart';

import '../../data/services/aparencia/aparencia_api_client.dart';
import '../../domain/models/aparencia_models.dart';
import '../../domain/services/aparencia/aparencia_service.dart';
import '../../design_system/helpers/six_theme_resolver.dart';
import '../components/six_backend_loading.dart';
import '../components/web/six_web_select_field.dart';
import '../components/web/six_web_settings_dialog.dart';
import '../theme/web_theme_tokens.dart';
import 'documentos_personalizados_web_content.dart';

void showConfiguracoesSixWebDialog(BuildContext context) {
  showSixWebSettingsDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      void fecharDialog() {
        final NavigatorState navigator = Navigator.of(dialogContext);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }

      return ConfiguracoesSixWebPage(embedded: true, onBack: fecharDialog);
    },
  );
}

class ConfiguracoesSixWebPage extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onBack;

  const ConfiguracoesSixWebPage({
    super.key,
    this.embedded = false,
    this.onBack,
  });

  @override
  State<ConfiguracoesSixWebPage> createState() =>
      _ConfiguracoesSixWebPageState();
}

enum SecaoConfiguracaoSix {
  geral,
  regionalizacao,
  aparencia,
  comunicacao,
  documentos,
  operacao,
  seguranca,
  preferenciasUsuario,
}

class _ConfiguracoesSixWebPageState extends State<ConfiguracoesSixWebPage> {
  static const int _maxLogoBytes = 1024 * 1024;
  static const List<String> _visibilidadesCatalogo = <String>[
    'Público com link',
    'Privado com aprovação',
    'Somente clientes cadastrados',
  ];
  static const List<String> _validadesCatalogo = <String>[
    'Sem expiração',
    '24 horas',
    '7 dias',
    '30 dias',
  ];
  static const List<String> _modosAtendimentoMesa = <String>[
    'Mesa e balcão',
    'Somente mesa',
    'Mesa, balcão e delivery',
    'Comanda individual',
  ];
  static const List<String> _diasSemanaAtendimento = <String>[
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];
  static const List<String> _statusMesa = <String>[
    'Livre',
    'Ocupada',
    'Aguardando pedido',
    'Em consumo',
    'Aguardando pagamento',
    'Fechada',
  ];
  static const List<String> _perfisCliente = <String>[
    'Cliente comum',
    'Cliente recorrente',
    'Cliente corporativo',
    'Cliente com análise de crédito',
  ];
  static const List<String> _politicasCredito = <String>[
    'Aprovação manual',
    'Aprovação automática por limite',
    'Sempre exigir aprovação',
    'Não permitir crédito',
  ];
  static const List<String> _prazosFiado = <String>[
    '7 dias',
    '15 dias',
    '30 dias',
    '45 dias',
    'Personalizado',
  ];
  static const List<String> _tiposDesconto = <String>[
    'Percentual e valor fixo',
    'Apenas percentual',
    'Apenas valor fixo',
    'Somente com permissão',
  ];
  static const List<String> _basesComissao = <String>[
    'Valor líquido da venda',
    'Valor bruto da venda',
    'Apenas serviços',
    'Apenas produtos',
  ];
  static const List<_ConfiguracaoChoiceOption>
  _atributosGradeDisponiveis = <_ConfiguracaoChoiceOption>[
    _ConfiguracaoChoiceOption(
      label: 'Cor',
      description:
          'Permite variações como preto, branco, azul e outras cores comerciais.',
      icon: Icons.palette_outlined,
    ),
    _ConfiguracaoChoiceOption(
      label: 'Tamanho',
      description:
          'Útil para acessórios, peças e produtos com medidas comerciais.',
      icon: Icons.photo_size_select_small_rounded,
    ),
    _ConfiguracaoChoiceOption(
      label: 'Voltagem',
      description: 'Diferencia itens 110V, 220V, bivolt ou padrões locais.',
      icon: Icons.bolt_outlined,
    ),
    _ConfiguracaoChoiceOption(
      label: 'Modelo',
      description: 'Organiza produtos por modelo, geração ou linha compatível.',
      icon: Icons.devices_other_rounded,
    ),
    _ConfiguracaoChoiceOption(
      label: 'Capacidade',
      description: 'Ajuda em variações como 64GB, 128GB, ml, kg ou pacote.',
      icon: Icons.data_usage_rounded,
    ),
    _ConfiguracaoChoiceOption(
      label: 'Condição',
      description: 'Separa novo, usado, recondicionado ou peça de reposição.',
      icon: Icons.verified_outlined,
    ),
  ];
  static const List<_ConfiguracaoChoiceOption> _unidadesDisponiveis =
      <_ConfiguracaoChoiceOption>[
        _ConfiguracaoChoiceOption(
          label: 'Unidade',
          description: 'Peças, acessórios e itens vendidos individualmente.',
          icon: Icons.inventory_2_outlined,
        ),
        _ConfiguracaoChoiceOption(
          label: 'Área',
          description: 'm², cm² e serviços medidos por superfície.',
          icon: Icons.crop_square_rounded,
        ),
        _ConfiguracaoChoiceOption(
          label: 'Distância',
          description: 'm, km e cobranças por deslocamento.',
          icon: Icons.straighten_rounded,
        ),
        _ConfiguracaoChoiceOption(
          label: 'Volume',
          description: 'ml, l e insumos medidos por capacidade.',
          icon: Icons.water_drop_outlined,
        ),
        _ConfiguracaoChoiceOption(
          label: 'Tempo',
          description: 'Hora técnica, diária, mensalidade e assinatura.',
          icon: Icons.schedule_rounded,
        ),
        _ConfiguracaoChoiceOption(
          label: 'Peso',
          description: 'g, kg e materiais vendidos por massa.',
          icon: Icons.scale_rounded,
        ),
        _ConfiguracaoChoiceOption(
          label: 'Moeda',
          description: 'Valores financeiros tratados como unidade de cobrança.',
          icon: Icons.paid_outlined,
        ),
      ];

  SecaoConfiguracaoSix _secaoAtual = SecaoConfiguracaoSix.geral;
  bool _possuiAlteracoesNaoSalvas = false;
  bool _possuiAlteracoesGerais = false;
  final ScrollController _conteudoScrollController = ScrollController();
  // ignore: unused_field — estado de loading da aparência (ainda não exibido na UI)
  bool _carregandoAparencia = false;
  bool _carregandoDadosEmpresa = false;
  bool _selecionandoLogo = false;
  bool _dadosEmpresaCarregados = false;
  bool _carregandoStatusAtendimento = false;
  bool _salvandoStatusAtendimento = false;
  bool _statusAtendimentoCarregado = false;
  bool _statusAtendimentoAlterado = false;
  String? _erroDadosEmpresa;
  String? _erroStatusAtendimento;
  String? _logoBase64;
  final ImagePicker _imagePicker = ImagePicker();
  late final EmpresaService _empresaService;
  late final AparenciaService _aparenciaService;
  late final AtendimentoTecnicoService _atendimentoTecnicoService;
  final Map<String, TextEditingController> _statusPtControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _statusEnControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> _statusEsControllers =
      <String, TextEditingController>{};
  List<DominioStatusAtendimentoCustomizacaoModel>
  _statusAtendimentoCustomizacoes =
      const <DominioStatusAtendimentoCustomizacaoModel>[];

  @override
  void initState() {
    super.initState();
    _empresaService = EmpresaService();
    _aparenciaService = AparenciaService(apiClient: HttpAparenciaApiClient());
    _atendimentoTecnicoService = AtendimentoTecnicoService();
    _carregarDadosDaEmpresa();
    _carregarAparencia();
    _carregarStatusAtendimentoCustomizacoes();
  }

  Future<void> _carregarAparencia() async {
    setState(() => _carregandoAparencia = true);
    try {
      final config = await _aparenciaService.buscarAparencia();
      if (!mounted) return;
      setState(() {
        _temaSelecionado = config.tema.label;
        _densidadeSelecionada = SixThemeResolver().densidade.label;
        _corPrimaria = config.paleta.primaria;
        _corSecundaria = config.paleta.secundaria;
        _corDestaque = config.paleta.destaque;
        _corAlerta = config.paleta.alerta;

        // Atualiza o resolver global para que outras partes do app possam usar
        SixThemeResolver().atualizarConfiguracao(config);
      });
    } catch (e) {
      debugPrint('Erro ao carregar aparência: $e');
    } finally {
      if (mounted) {
        setState(() => _carregandoAparencia = false);
      }
    }
  }

  Future<void> _carregarDadosDaEmpresa() async {
    setState(() {
      _carregandoDadosEmpresa = true;
      _erroDadosEmpresa = null;
    });

    try {
      final EmpresaModel empresa = await _empresaService.buscarDadosDaEmpresa();
      if (!mounted) return;
      setState(() {
        _aplicarDadosDaEmpresa(empresa);
        _dadosEmpresaCarregados = true;
        _possuiAlteracoesGerais = false;
        _carregandoDadosEmpresa = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados da empresa: $e');
      if (!mounted) return;
      setState(() {
        _dadosEmpresaCarregados = false;
        _erroDadosEmpresa = _i18n(
          'empresa.configuracao.loadError',
          'Não foi possível carregar os dados da empresa.',
        );
        _carregandoDadosEmpresa = false;
      });
    }
  }

  Future<void> _carregarStatusAtendimentoCustomizacoes() async {
    setState(() {
      _carregandoStatusAtendimento = true;
      _erroStatusAtendimento = null;
    });

    try {
      final List<DominioStatusAtendimentoCustomizacaoModel> status =
          await _atendimentoTecnicoService
              .listarCustomizacoesStatusAtendimento();
      if (!mounted) return;
      setState(() {
        _sincronizarStatusAtendimentoControllers(status);
        _statusAtendimentoCustomizacoes = status;
        _statusAtendimentoCarregado = true;
        _statusAtendimentoAlterado = false;
        _carregandoStatusAtendimento = false;
      });
    } catch (e) {
      debugPrint('Erro ao carregar customizações de status: $e');
      if (!mounted) return;
      setState(() {
        _statusAtendimentoCarregado = false;
        _erroStatusAtendimento =
            'Não foi possível carregar os nomes dos status.';
        _carregandoStatusAtendimento = false;
      });
    }
  }

  void _sincronizarStatusAtendimentoControllers(
    List<DominioStatusAtendimentoCustomizacaoModel> status,
  ) {
    for (final DominioStatusAtendimentoCustomizacaoModel item in status) {
      _statusPtControllers
          .putIfAbsent(item.statusCodigo, () => TextEditingController())
          .text = item.nomeAtualPtBr;
      _statusEnControllers
          .putIfAbsent(item.statusCodigo, () => TextEditingController())
          .text = item.nomeAtualEnUs;
      _statusEsControllers
          .putIfAbsent(item.statusCodigo, () => TextEditingController())
          .text = item.nomeAtualEsEs;
    }
  }

  void _aplicarDadosDaEmpresa(EmpresaModel empresa) {
    _nomeEmpresaController.text = _normalizarCampoEmpresa(empresa.nomeEmpresa);
    _nomeFantasiaController.text = _normalizarCampoEmpresa(
      empresa.nomeFantasia,
    );
    _documentoFiscalController.text = _normalizarCampoEmpresa(
      empresa.documentoNoBrasilCNPJ,
    );
    _telefoneController.text = _normalizarCampoEmpresa(empresa.telefone);
    _whatsAppController.text = _normalizarCampoEmpresa(empresa.whatsapp);
    _emailController.text = _normalizarCampoEmpresa(empresa.emailPrincipal);
    _siteController.text = _normalizarCampoEmpresa(empresa.siteEmpresa);
    _enderecoController.text = _normalizarCampoEmpresa(empresa.endereco);
    _logoBase64 = _normalizarLogoEmpresa(empresa.logoBase64);
    _horariosAtendimento = _normalizarHorariosAtendimento(
      empresa.horariosAtendimento,
    );
    _horariosAtendimentoConfiguradosNoBackend =
        empresa.horariosAtendimento.isNotEmpty;
    _horariosAtendimentoEditados = false;
  }

  Future<void> _salvarDadosDaEmpresa() async {
    final String nomeEmpresa = _nomeEmpresaController.text.trim();
    if (nomeEmpresa.isEmpty) {
      throw Exception(
        _i18n(
          'empresa.configuracao.requiredField',
          'Informe o nome da empresa.',
        ),
      );
    }
    final String? erroHorario = _validarHorariosAtendimento();
    if (erroHorario != null) {
      throw Exception(erroHorario);
    }

    final EmpresaModel empresa = EmpresaModel(
      nomeEmpresa: nomeEmpresa,
      nomeFantasia: _nomeFantasiaController.text.trim(),
      documentoNoBrasilCNPJ: _documentoFiscalController.text.trim(),
      telefone: _telefoneController.text.trim(),
      whatsapp: _whatsAppController.text.trim(),
      emailPrincipal: _emailController.text.trim(),
      siteEmpresa: _siteController.text.trim(),
      endereco: _enderecoController.text.trim(),
      logoBase64: _logoBase64,
      horariosAtendimento:
          _horariosAtendimentoConfiguradosNoBackend ||
                  _horariosAtendimentoEditados
              ? _horariosAtendimento
              : const <HorarioAtendimentoModel>[],
    );

    final EmpresaModel atualizada = await _empresaService
        .atualizarDadosDaEmpresa(empresa);
    if (!mounted) return;
    setState(() {
      _aplicarDadosDaEmpresa(atualizada);
      _dadosEmpresaCarregados = true;
      _possuiAlteracoesGerais = false;
      _erroDadosEmpresa = null;
    });
  }

  Future<void> _salvarStatusAtendimentoSeNecessario() async {
    if (!_statusAtendimentoCarregado || !_statusAtendimentoAlterado) {
      return;
    }

    setState(() => _salvandoStatusAtendimento = true);

    try {
      final List<Map<String, dynamic>> payload = _statusAtendimentoCustomizacoes
          .map((item) {
            return item.toCustomizacaoJson(
              nomePtBr:
                  _statusPtControllers[item.statusCodigo]?.text ??
                  item.nomeAtualPtBr,
              nomeEnUs:
                  _statusEnControllers[item.statusCodigo]?.text ??
                  item.nomeAtualEnUs,
              nomeEsEs:
                  _statusEsControllers[item.statusCodigo]?.text ??
                  item.nomeAtualEsEs,
            );
          })
          .toList(growable: false);

      final List<DominioStatusAtendimentoCustomizacaoModel> atualizados =
          await _atendimentoTecnicoService.salvarCustomizacoesStatusAtendimento(
            payload,
          );

      if (!mounted) return;
      setState(() {
        _sincronizarStatusAtendimentoControllers(atualizados);
        _statusAtendimentoCustomizacoes = atualizados;
        _statusAtendimentoAlterado = false;
      });
    } finally {
      if (mounted) {
        setState(() => _salvandoStatusAtendimento = false);
      }
    }
  }

  void _marcarAlteracaoStatusAtendimento() {
    if (!_statusAtendimentoAlterado) {
      setState(() => _statusAtendimentoAlterado = true);
    }
    _marcarAlteracao();
  }

  void _restaurarStatusAtendimentoPadrao() {
    if (_statusAtendimentoCustomizacoes.isEmpty) return;

    setState(() {
      for (final DominioStatusAtendimentoCustomizacaoModel item
          in _statusAtendimentoCustomizacoes) {
        _statusPtControllers[item.statusCodigo]?.text = item.nomePadraoPtBr;
        _statusEnControllers[item.statusCodigo]?.text = item.nomePadraoEnUs;
        _statusEsControllers[item.statusCodigo]?.text = item.nomePadraoEsEs;
      }
      _statusAtendimentoAlterado = true;
    });
    _marcarAlteracao();
    _mostrarSnackBarConfiguracoes(
      'Os nomes padrão dos status foram restaurados. Salve para aplicar.',
    );
  }

  Future<void> _selecionarLogoEmpresa() async {
    if (_carregandoDadosEmpresa || _selecionandoLogo) return;

    setState(() => _selecionandoLogo = true);

    try {
      final XFile? arquivo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 768,
        maxHeight: 768,
        imageQuality: 82,
      );

      if (!mounted) return;

      if (arquivo == null) {
        setState(() => _selecionandoLogo = false);
        return;
      }

      final Uint8List bytes = await arquivo.readAsBytes();
      if (!mounted) return;

      if (bytes.isEmpty) {
        throw FormatException(
          _i18n(
            'empresa.configuracao.logoLoadError',
            'Não foi possível carregar o logo.',
          ),
        );
      }

      if (bytes.length > _maxLogoBytes) {
        throw FormatException(
          _i18n(
            'empresa.configuracao.logoTooLarge',
            'Escolha uma imagem de até 1 MB.',
          ),
        );
      }

      final String mimeType =
          arquivo.mimeType ?? _mimeTypeFromName(arquivo.name) ?? 'image/jpeg';

      setState(() {
        _logoBase64 = 'data:$mimeType;base64,${base64Encode(bytes)}';
        _selecionandoLogo = false;
        _possuiAlteracoesGerais = true;
      });
      _marcarAlteracao();
    } catch (e) {
      debugPrint('Erro ao selecionar logo da empresa: $e');
      if (!mounted) return;
      setState(() => _selecionandoLogo = false);
      _mostrarSnackBarConfiguracoes(
        e is FormatException
            ? e.message
            : _i18n(
              'empresa.configuracao.logoLoadError',
              'Não foi possível carregar o logo.',
            ),
        erro: true,
      );
    }
  }

  void _removerLogoEmpresa() {
    setState(() {
      _logoBase64 = '';
      _possuiAlteracoesGerais = true;
    });
    _marcarAlteracao();
  }

  String _normalizarCampoEmpresa(String? value) {
    final String normalizado = (value ?? '').trim();
    return normalizado.toUpperCase() == 'NO DATA' ? '' : normalizado;
  }

  String _normalizarLogoEmpresa(String? value) {
    final String normalizado = (value ?? '').trim();
    return normalizado.toUpperCase() == 'NO DATA' ? '' : normalizado;
  }

  static List<HorarioAtendimentoModel> _horariosAtendimentoPadrao() {
    return _diasSemanaAtendimento
        .map((dia) {
          final bool fimDeSemana = dia == 'SATURDAY' || dia == 'SUNDAY';
          return HorarioAtendimentoModel(
            diaSemana: dia,
            fechado: fimDeSemana,
            inicio: fimDeSemana ? null : '08:00',
            fim: fimDeSemana ? null : '18:00',
          );
        })
        .toList(growable: false);
  }

  List<HorarioAtendimentoModel> _normalizarHorariosAtendimento(
    List<HorarioAtendimentoModel> horarios,
  ) {
    if (horarios.isEmpty) {
      return _horariosAtendimentoPadrao();
    }

    final Map<String, HorarioAtendimentoModel> porDia =
        <String, HorarioAtendimentoModel>{
          for (final horario in horarios)
            horario.diaSemana.trim().toUpperCase(): horario,
        };

    return _diasSemanaAtendimento
        .map((dia) {
          final HorarioAtendimentoModel? horario = porDia[dia];
          if (horario == null) {
            return HorarioAtendimentoModel(diaSemana: dia, fechado: true);
          }

          final String? inicio = _normalizarHora(horario.inicio);
          final String? fim = _normalizarHora(horario.fim);
          final bool fechado = horario.fechado || inicio == null || fim == null;
          return HorarioAtendimentoModel(
            diaSemana: dia,
            fechado: fechado,
            inicio: fechado ? null : inicio,
            fim: fechado ? null : fim,
          );
        })
        .toList(growable: false);
  }

  String? _validarHorariosAtendimento() {
    for (final horario in _horariosAtendimento) {
      if (horario.fechado) continue;

      final int? inicio = _horaEmMinutos(horario.inicio);
      final int? fim = _horaEmMinutos(horario.fim);
      if (inicio == null || fim == null) {
        return _i18n(
          'configuracoes.businessHoursInvalid',
          'Revise os horários de atendimento antes de salvar.',
        );
      }
      if (inicio >= fim) {
        return _i18n(
          'configuracoes.businessHoursStartBeforeEnd',
          'O horário inicial deve ser anterior ao horário final.',
        );
      }
    }
    return null;
  }

  void _aplicarHorarioDiasUteis() {
    setState(() {
      _horariosAtendimento = _diasSemanaAtendimento
          .map((dia) {
            final bool fimDeSemana = dia == 'SATURDAY' || dia == 'SUNDAY';
            return HorarioAtendimentoModel(
              diaSemana: dia,
              fechado: fimDeSemana,
              inicio: fimDeSemana ? null : '08:00',
              fim: fimDeSemana ? null : '18:00',
            );
          })
          .toList(growable: false);
      _horariosAtendimentoEditados = true;
      _possuiAlteracoesGerais = true;
    });
    _marcarAlteracao();
  }

  void _copiarSegundaParaDiasUteis() {
    final HorarioAtendimentoModel segunda = _horariosAtendimento.firstWhere(
      (horario) => horario.diaSemana == 'MONDAY',
      orElse:
          () => const HorarioAtendimentoModel(
            diaSemana: 'MONDAY',
            fechado: false,
            inicio: '08:00',
            fim: '18:00',
          ),
    );

    setState(() {
      _horariosAtendimento = _horariosAtendimento
          .map((horario) {
            final bool diaUtil = <String>{
              'MONDAY',
              'TUESDAY',
              'WEDNESDAY',
              'THURSDAY',
              'FRIDAY',
            }.contains(horario.diaSemana);
            if (!diaUtil) return horario;
            return HorarioAtendimentoModel(
              diaSemana: horario.diaSemana,
              fechado: segunda.fechado,
              inicio: segunda.fechado ? null : segunda.inicio,
              fim: segunda.fechado ? null : segunda.fim,
            );
          })
          .toList(growable: false);
      _horariosAtendimentoEditados = true;
      _possuiAlteracoesGerais = true;
    });
    _marcarAlteracao();
  }

  void _atualizarHorarioAtendimento(
    String diaSemana,
    HorarioAtendimentoModel novoHorario,
  ) {
    setState(() {
      _horariosAtendimento = _horariosAtendimento
          .map(
            (horario) => horario.diaSemana == diaSemana ? novoHorario : horario,
          )
          .toList(growable: false);
      _horariosAtendimentoEditados = true;
      _possuiAlteracoesGerais = true;
    });
    _marcarAlteracao();
  }

  void _alterarDiaAberto(HorarioAtendimentoModel horario, bool aberto) {
    _atualizarHorarioAtendimento(
      horario.diaSemana,
      HorarioAtendimentoModel(
        diaSemana: horario.diaSemana,
        fechado: !aberto,
        inicio: aberto ? (horario.inicio ?? '08:00') : null,
        fim: aberto ? (horario.fim ?? '18:00') : null,
      ),
    );
  }

  Future<void> _selecionarHorario(
    HorarioAtendimentoModel horario,
    bool inicio,
  ) async {
    final TimeOfDay? selecionado = await showTimePicker(
      context: context,
      initialTime:
          _parseHora(inicio ? horario.inicio : horario.fim) ??
          TimeOfDay(hour: inicio ? 8 : 18, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (selecionado == null || !mounted) return;

    final String valor = _formatarHora(selecionado);
    _atualizarHorarioAtendimento(
      horario.diaSemana,
      HorarioAtendimentoModel(
        diaSemana: horario.diaSemana,
        fechado: false,
        inicio: inicio ? valor : horario.inicio ?? '08:00',
        fim: inicio ? horario.fim ?? '18:00' : valor,
      ),
    );
  }

  String _labelDiaSemana(String diaSemana) {
    return switch (diaSemana.trim().toUpperCase()) {
      'MONDAY' => _i18n('common.weekday.monday', 'Segunda-feira'),
      'TUESDAY' => _i18n('common.weekday.tuesday', 'Terça-feira'),
      'WEDNESDAY' => _i18n('common.weekday.wednesday', 'Quarta-feira'),
      'THURSDAY' => _i18n('common.weekday.thursday', 'Quinta-feira'),
      'FRIDAY' => _i18n('common.weekday.friday', 'Sexta-feira'),
      'SATURDAY' => _i18n('common.weekday.saturday', 'Sábado'),
      'SUNDAY' => _i18n('common.weekday.sunday', 'Domingo'),
      _ => diaSemana,
    };
  }

  String? _normalizarHora(String? value) {
    final String normalizado = (value ?? '').trim();
    if (normalizado.length >= 5) {
      return normalizado.substring(0, 5);
    }
    return null;
  }

  TimeOfDay? _parseHora(String? value) {
    final String? normalizado = _normalizarHora(value);
    if (normalizado == null) return null;
    final List<String> partes = normalizado.split(':');
    if (partes.length != 2) return null;
    final int? hora = int.tryParse(partes[0]);
    final int? minuto = int.tryParse(partes[1]);
    if (hora == null || minuto == null) return null;
    if (hora < 0 || hora > 23 || minuto < 0 || minuto > 59) return null;
    return TimeOfDay(hour: hora, minute: minuto);
  }

  int? _horaEmMinutos(String? value) {
    final TimeOfDay? hora = _parseHora(value);
    if (hora == null) return null;
    return hora.hour * 60 + hora.minute;
  }

  String _formatarHora(TimeOfDay value) {
    final String hora = value.hour.toString().padLeft(2, '0');
    final String minuto = value.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  String? _mimeTypeFromName(String name) {
    final String lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return null;
  }

  // =========================
  // ESTADO DA TELA
  // =========================

  // Geral
  final TextEditingController _nomeEmpresaController = TextEditingController();
  final TextEditingController _nomeFantasiaController = TextEditingController();
  final TextEditingController _documentoFiscalController =
      TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _whatsAppController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _siteController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  List<HorarioAtendimentoModel> _horariosAtendimento =
      _horariosAtendimentoPadrao();
  bool _horariosAtendimentoConfiguradosNoBackend = false;
  bool _horariosAtendimentoEditados = false;

  // Regionalização
  String _idiomaSelecionado = 'Português (Brasil)';
  String _paisRegiaoSelecionado = 'Brasil';
  String _fusoSelecionado = 'America/Sao_Paulo';
  String _formatoDataSelecionado = 'dd/MM/yyyy';
  String _formatoHoraSelecionado = '24 horas';
  String _primeiroDiaSemanaSelecionado = 'Segunda-feira';
  String _formatoNumeroSelecionado = '1.234,56';

  // Financeiro / moeda
  String _moedaSelecionada = 'R\$ - Real Brasileiro';
  String _posicaoSimboloSelecionada = 'Antes do valor';
  String _casasDecimaisSelecionadas = '2';
  String _separadorDecimalSelecionado = 'Vírgula';
  String _separadorMilharSelecionado = 'Ponto';
  bool _permitirMultiplasMoedas = false;
  bool _aplicarArredondamentoFinanceiro = true;

  // Aparência
  String _temaSelecionado = 'Claro';
  String _densidadeSelecionada = 'Confortável';
  Color _corPrimaria = const Color(0xFF1F3C88);
  Color _corSecundaria = const Color(0xFF5E81F4);
  Color _corDestaque = const Color(0xFF0FA958);
  Color _corAlerta = const Color(0xFFF59E0B);

  // Comunicação
  bool _notificarPorEmail = true;
  bool _notificarPorWhatsApp = true;
  bool _notificarPorTelegram = false;
  bool _envioAutomaticoStatus = true;
  bool _envioManualPermitido = true;
  String _canalPreferencialCliente = 'WhatsApp';
  final TextEditingController
  _assinaturaMensagemController = TextEditingController(
    text:
        'Equipe Six agradece o seu contato. Qualquer dúvida, estamos à disposição.',
  );
  final TextEditingController _mensagemOrdemCriadaController =
      TextEditingController(
        text: 'Sua ordem de serviço foi criada com sucesso.',
      );
  final TextEditingController _mensagemProntoRetiradaController =
      TextEditingController(text: 'Seu equipamento está pronto para retirada.');

  // Operação
  bool _controlarEstoque = true;
  bool _exigirClienteNaVenda = false;
  bool _exigirSerialImei = true;
  bool _exigirTecnicoResponsavel = true;
  bool _abrirCaixaObrigatorio = true;
  bool _permitirVendaSemEstoque = false;
  bool _gerarComissaoColaborador = true;
  bool _permitirEdicaoAposFechamento = false;
  bool _descontoManualPermitido = true;
  double _limiteDesconto = 10;
  bool _permitirVendaCatalogoPorLink = true;
  bool _exigirClienteNoCatalogo = false;
  bool _permitirCompartilhamentoCatalogo = true;
  bool _cadastroGradeProdutos = true;
  bool _controlarEstoquePorVariacao = true;
  bool _exigirGradeParaProdutoVariavel = false;
  bool _vendaPorMesa = false;
  bool _mesaObrigatoria = true;
  bool _permitirTransferenciaMesa = true;
  bool _permitirJuntarMesas = true;
  bool _cobrarTaxaServicoMesa = true;
  bool _imprimirComandaMesa = true;
  bool _fecharMesaSomenteNoCaixa = true;
  bool _validarDocumentoCliente = true;
  bool _exigirTelefoneCliente = true;
  bool _exigirEnderecoClienteParaFiado = true;
  bool _exigirAceiteUsoDadosCliente = true;
  bool _permitirVendasFiado = false;
  bool _exigirAprovacaoCredito = true;
  bool _permitirLimiteCreditoCliente = true;
  bool _bloquearClienteInadimplente = true;
  bool _notificarVencimentoFiado = true;
  bool _permitirParcelamentoFiado = true;
  bool _exigirAnexoCadastroCliente = false;
  bool _produtoApenasComUnidadeMedida = true;
  bool _exigirJustificativaDesconto = true;
  bool _aplicarComissaoEmServicos = true;
  bool _aplicarComissaoEmProdutos = false;
  String _visibilidadeCatalogo = 'Público com link';
  String _validadeLinkCatalogo = 'Sem expiração';
  String _modoAtendimentoMesa = 'Mesa e balcão';
  String _statusInicialMesa = 'Livre';
  String _perfilPadraoCliente = 'Cliente comum';
  String _politicaCreditoSelecionada = 'Aprovação manual';
  String _prazoPadraoFiado = '30 dias';
  String _tipoDescontoSelecionado = 'Percentual e valor fixo';
  String _baseComissaoSelecionada = 'Valor líquido da venda';
  double _taxaServicoMesaPercentual = 10;
  double _limiteCreditoPadrao = 500;
  double _entradaMinimaFiadoPercentual = 0;
  double _percentualComissaoPadrao = 5;
  final TextEditingController _nomeCatalogoController = TextEditingController(
    text: 'Catálogo Six Repair',
  );
  final TextEditingController _slugCatalogoController = TextEditingController(
    text: 'six-repair-center',
  );
  final TextEditingController _prefixoMesaController = TextEditingController(
    text: 'Mesa',
  );
  final TextEditingController _quantidadeMesasController =
      TextEditingController(text: '20');
  final TextEditingController _diasBloqueioAtrasoController =
      TextEditingController(text: '7');
  final Set<String> _atributosGradeSelecionados = <String>{
    'Cor',
    'Tamanho',
    'Modelo',
  };
  final Set<String> _unidadesMedidaAutorizadas = <String>{
    'Unidade',
    'Área',
    'Distância',
    'Volume',
    'Tempo',
    'Peso',
  };

  final List<String> _statusAssistencia = [
    'Recebido',
    'Em análise',
    'Aguardando aprovação',
    'Aguardando peça',
    'Em reparo',
    'Pronto para retirada',
    'Entregue',
  ];

  // Segurança
  bool _mfaHabilitado = false;
  bool _encerrarSessoesInativas = true;
  String _tempoSessaoSelecionado = '8 horas';
  bool _permitirLoginMultiplo = true;
  bool _exigirTrocaSenhaPeriodica = false;

  // Preferências do usuário
  String _paginaInicialSelecionada = 'Painel administrativo';
  bool _receberSomNotificacao = true;
  bool _receberNotificacoesDesktop = true;
  bool _mostrarDicasContextuais = true;
  final List<String> _atalhosFavoritos = [
    'Nova venda',
    'Nova ordem de serviço',
    'Caixa',
    'Clientes',
  ];

  @override
  void dispose() {
    _nomeEmpresaController.dispose();
    _nomeFantasiaController.dispose();
    _documentoFiscalController.dispose();
    _telefoneController.dispose();
    _whatsAppController.dispose();
    _emailController.dispose();
    _siteController.dispose();
    _enderecoController.dispose();
    _assinaturaMensagemController.dispose();
    _mensagemOrdemCriadaController.dispose();
    _mensagemProntoRetiradaController.dispose();
    _nomeCatalogoController.dispose();
    _slugCatalogoController.dispose();
    _prefixoMesaController.dispose();
    _quantidadeMesasController.dispose();
    _diasBloqueioAtrasoController.dispose();
    for (final TextEditingController controller in <TextEditingController>[
      ..._statusPtControllers.values,
      ..._statusEnControllers.values,
      ..._statusEsControllers.values,
    ]) {
      controller.dispose();
    }
    _conteudoScrollController.dispose();
    super.dispose();
  }

  // =========================
  // AUXILIARES
  // =========================

  void _marcarAlteracao() {
    if (!_possuiAlteracoesNaoSalvas) {
      setState(() {
        _possuiAlteracoesNaoSalvas = true;
      });
    }
  }

  void _mostrarSnackBarConfiguracoes(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    final tokens = WebThemeTokens.of(context);
    if (erro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
          backgroundColor: tokens.danger,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.success,
      ),
    );
  }

  void _selecionarSecao(SecaoConfiguracaoSix secao) {
    if (_secaoAtual == secao) return;

    setState(() {
      _secaoAtual = secao;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_conteudoScrollController.hasClients) return;
      _conteudoScrollController.animateTo(
        0,
        duration: WebThemeTokens.transitionDuration,
        curve: WebThemeTokens.transitionCurve,
      );
    });
  }

  void _selecionarTemaVisual(String tema) {
    setState(() {
      _temaSelecionado = tema;
    });
    _aplicarAparenciaPreview();
    _marcarAlteracao();
  }

  void _aplicarAparenciaPreview() {
    final resolver = SixThemeResolver();
    final paletaAtual = resolver.paleta;
    resolver.atualizarConfiguracao(
      ConfiguracaoAparenciaSistema(
        tema: TemaSistema.fromLabel(_temaSelecionado),
        paleta: PaletaSistema(
          primaria: _corPrimaria,
          secundaria: _corSecundaria,
          destaque: _corDestaque,
          alerta: _corAlerta,
          fundo: paletaAtual.fundo,
          superficie: paletaAtual.superficie,
          textoPrimario: paletaAtual.textoPrimario,
          textoSecundario: paletaAtual.textoSecundario,
        ),
      ),
    );
    resolver.atualizarDensidade(
      DensidadeVisualSistema.fromLabel(_densidadeSelecionada),
    );
  }

  Future<void> _salvarConfiguracoes() async {
    if (_carregandoDadosEmpresa || _selecionandoLogo) {
      return;
    }

    final localeProvider = context.read<LocaleSettingsProvider>();

    setState(() {
      _carregandoAparencia = true;
    });

    try {
      if (_dadosEmpresaCarregados || _possuiAlteracoesGerais) {
        await _salvarDadosDaEmpresa();
      }

      await _salvarStatusAtendimentoSeNecessario();

      final locale = _mapIdiomaSelecionadoParaLocale(_idiomaSelecionado);

      final configuracaoRegionalizacao = localeProvider.companyConfig.copyWith(
        languageCode: locale.languageCode,
        countryCode:
            locale.countryCode ?? localeProvider.companyConfig.countryCode,
        formatting: AppRegionalFormatting(
          currencyCode: _mapMoedaSelecionadaParaCurrencyCode(_moedaSelecionada),
          timeZone: _fusoSelecionado,
          dateFormat: _formatoDataSelecionado,
          timeFormat: _formatoHoraSelecionado == '24 horas' ? '24h' : '12h',
          decimalSeparator:
              _separadorDecimalSelecionado == 'Vírgula' ? ',' : '.',
          thousandSeparator: _mapSeparadorMilhar(_separadorMilharSelecionado),
          firstDayOfWeek:
              _primeiroDiaSemanaSelecionado == 'Domingo' ? 'SUNDAY' : 'MONDAY',
          numberPattern:
              _formatoNumeroSelecionado == '1,234.56' ? '#,##0.00' : '#.##0,00',
          decimalPlaces: int.tryParse(_casasDecimaisSelecionadas) ?? 2,
          allowMultipleCurrencies: _permitirMultiplasMoedas,
          applyFinancialRounding: _aplicarArredondamentoFinanceiro,
        ),
      );

      await localeProvider.saveCompanyConfig(configuracaoRegionalizacao);
      await localeProvider.setUserLocale(locale);

      final configuracao = ConfiguracaoAparenciaSistema(
        tema: TemaSistema.fromLabel(_temaSelecionado),
        paleta: PaletaSistema(
          primaria: _corPrimaria,
          secundaria: _corSecundaria,
          destaque: _corDestaque,
          alerta: _corAlerta,
          fundo: SixThemeResolver().paleta.fundo,
          superficie: SixThemeResolver().paleta.superficie,
          textoPrimario: SixThemeResolver().paleta.textoPrimario,
          textoSecundario: SixThemeResolver().paleta.textoSecundario,
        ),
      );

      await _aparenciaService.salvarAparencia(configuracao);
      SixThemeResolver().atualizarConfiguracao(configuracao);
      SixThemeResolver().atualizarDensidade(
        DensidadeVisualSistema.fromLabel(_densidadeSelecionada),
      );

      setState(() {
        _possuiAlteracoesNaoSalvas = false;
      });

      if (mounted) {
        _mostrarSnackBarConfiguracoes(
          _i18n(
            'configuracoes.settingsSaved',
            'Configurações salvas com sucesso.',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBarConfiguracoes(
          '${_i18n('configuracoes.settingsSaveError', 'Erro ao salvar configurações')}: $e',
          erro: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregandoAparencia = false;
        });
      }
    }
  }

  void _restaurarPadraoDaSecao() {
    if (_secaoAtual == SecaoConfiguracaoSix.geral) {
      _carregarDadosDaEmpresa();
      return;
    }

    if (_secaoAtual == SecaoConfiguracaoSix.operacao &&
        _statusAtendimentoCarregado) {
      _restaurarStatusAtendimentoPadrao();
      return;
    }

    final tokens = WebThemeTokens.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Os valores padrão da seção "${_tituloSecao(_secaoAtual)}" foram restaurados.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: tokens.info,
      ),
    );
  }

  String _tituloSecao(SecaoConfiguracaoSix secao) {
    switch (secao) {
      case SecaoConfiguracaoSix.geral:
        return 'Geral';
      case SecaoConfiguracaoSix.regionalizacao:
        return 'Regionalização';
      case SecaoConfiguracaoSix.aparencia:
        return 'Aparência';
      case SecaoConfiguracaoSix.comunicacao:
        return 'Comunicação';
      case SecaoConfiguracaoSix.documentos:
        return 'Documentos';
      case SecaoConfiguracaoSix.operacao:
        return 'Regras operacionais';
      case SecaoConfiguracaoSix.seguranca:
        return 'Segurança';
      case SecaoConfiguracaoSix.preferenciasUsuario:
        return 'Preferências do usuário';
    }
  }

  String _descricaoSecao(SecaoConfiguracaoSix secao) {
    switch (secao) {
      case SecaoConfiguracaoSix.geral:
        return 'Dados institucionais, identidade do comércio e informações principais para documentos e comunicação.';
      case SecaoConfiguracaoSix.regionalizacao:
        return 'Idioma, país, moeda, fuso horário, formatos de data e padronização financeira da empresa.';
      case SecaoConfiguracaoSix.aparencia:
        return 'Tema, densidade visual, branding do sistema e personalização visual do Six.';
      case SecaoConfiguracaoSix.comunicacao:
        return 'Mensagens automáticas, canais de notificação e preferências de contato com clientes.';
      case SecaoConfiguracaoSix.documentos:
        return 'Templates, rodapés, termos e componentes visuais de PDFs e comprovantes.';
      case SecaoConfiguracaoSix.operacao:
        return 'Catálogo por link, grade de produtos, mesas, clientes, fiado, estoque, caixa, desconto, comissão e unidades de medida.';
      case SecaoConfiguracaoSix.seguranca:
        return 'Sessão, autenticação, acesso, políticas de proteção e gestão de segurança da conta.';
      case SecaoConfiguracaoSix.preferenciasUsuario:
        return 'Ajustes pessoais do operador para melhorar produtividade e experiência no dia a dia.';
    }
  }

  Color _paletteForeground(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
  }

  Widget _buildPaletteExperiencePreview() {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final String brandName =
        _nomeFantasiaController.text.trim().isEmpty
            ? 'Sua marca aqui'
            : _nomeFantasiaController.text.trim();
    final Color primaryFg = _paletteForeground(_corPrimaria);
    final Color secondaryFg = _paletteForeground(_corSecundaria);
    final Color successFg = _paletteForeground(_corDestaque);
    final Color warningFg = _paletteForeground(_corAlerta);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 920;

        return Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _corPrimaria,
                  border: Border(bottom: BorderSide(color: tokens.cardBorder)),
                ),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _corSecundaria,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primaryFg.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: secondaryFg,
                        size: 22,
                      ),
                    ),
                    SizedBox(
                      width: compact ? double.infinity : 300,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brandName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: primaryFg,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Balcão de venda • Hoje',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: primaryFg.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildPaletteNavChip(
                      label: 'Painel',
                      color: _corSecundaria,
                      foreground: secondaryFg,
                      selected: true,
                    ),
                    _buildPaletteNavChip(
                      label: 'Vendas',
                      color: primaryFg,
                      foreground: _corPrimaria,
                    ),
                    _buildPaletteNavChip(
                      label: 'Estoque',
                      color: primaryFg,
                      foreground: _corPrimaria,
                    ),
                    _buildPaletteHeaderStatus(
                      label: 'Caixa aberto',
                      color: _corDestaque,
                      foreground: successFg,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child:
                    compact
                        ? Column(
                          children: [
                            _buildPaletteDashboardPreview(),
                            const SizedBox(height: 16),
                            _buildPaletteOrderPreview(),
                          ],
                        )
                        : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildPaletteDashboardPreview()),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPaletteOrderPreview()),
                          ],
                        ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    _buildPaletteAlert(
                      icon: Icons.warning_amber_rounded,
                      title: '2 itens abaixo do mínimo',
                      subtitle:
                          'Estoque mínimo atingido em produtos de alto giro.',
                      color: _corAlerta,
                      foreground: warningFg,
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.tune_rounded, color: _corSecundaria),
                          label: const Text('Filtrar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: tokens.primaryText,
                            side: BorderSide(
                              color: _corSecundaria.withValues(alpha: 0.38),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.add_rounded, color: successFg),
                          label: const Text('Nova venda'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _corDestaque,
                            foregroundColor: successFg,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaletteDashboardPreview() {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Resumo do dia',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _buildPaletteTag('Meta 84%', _corDestaque),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPaletteMetric(
                icon: Icons.point_of_sale_rounded,
                label: 'Vendas',
                value: '28',
                color: _corPrimaria,
              ),
              _buildPaletteMetric(
                icon: Icons.build_circle_outlined,
                label: 'Assistências',
                value: '11',
                color: _corSecundaria,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPaletteProgressLine('Produtos', 0.78, _corPrimaria),
          const SizedBox(height: 10),
          _buildPaletteProgressLine('Serviços', 0.56, _corSecundaria),
          const SizedBox(height: 10),
          _buildPaletteProgressLine('Recebidos', 0.88, _corDestaque),
        ],
      ),
    );
  }

  Widget _buildPaletteOrderPreview() {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pedido em andamento',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _buildPaletteTag('Prioridade', _corAlerta),
            ],
          ),
          const SizedBox(height: 14),
          _buildPaletteTimelineItem(
            icon: Icons.check_rounded,
            title: 'Cliente identificado',
            subtitle: 'Maria Oliveira',
            color: _corDestaque,
          ),
          _buildPaletteTimelineItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Itens no carrinho',
            subtitle: '3 produtos • 1 serviço',
            color: _corPrimaria,
          ),
          _buildPaletteTimelineItem(
            icon: Icons.credit_card_rounded,
            title: 'Pagamento',
            subtitle: 'Aguardando confirmação',
            color: _corAlerta,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteNavChip({
    required String label,
    required Color color,
    required Color foreground,
    bool selected = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color:
            selected
                ? color
                : Color.alphaBlend(
                  foreground.withValues(alpha: 0.12),
                  Colors.transparent,
                ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? foreground : color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPaletteHeaderStatus({
    required String label,
    required Color color,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.10),
          tokens.surfaceMuted,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteProgressLine(String label, double value, Color color) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: tokens.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 9,
              backgroundColor: tokens.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaletteTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.14),
          Theme.of(context).colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPaletteTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    color.withValues(alpha: 0.14),
                    tokens.surfaceMuted,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 22,
                  margin: const EdgeInsets.only(top: 6),
                  color: tokens.cardBorder,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaletteAlert({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color foreground,
  }) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecoesHeader() {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    final itens = [
      (
        secao: SecaoConfiguracaoSix.geral,
        titulo: 'Geral',
        icone: Icons.apartment_rounded,
      ),
      (
        secao: SecaoConfiguracaoSix.regionalizacao,
        titulo: 'Regionalização',
        icone: Icons.public_rounded,
      ),
      (
        secao: SecaoConfiguracaoSix.aparencia,
        titulo: 'Aparência',
        icone: Icons.palette_rounded,
      ),
      (
        secao: SecaoConfiguracaoSix.comunicacao,
        titulo: 'Comunicação',
        icone: Icons.markunread_outlined,
      ),
      (
        secao: SecaoConfiguracaoSix.documentos,
        titulo: 'Documentos',
        icone: Icons.picture_as_pdf_rounded,
      ),
      (
        secao: SecaoConfiguracaoSix.operacao,
        titulo: 'Regras operacionais',
        icone: Icons.settings_suggest_rounded,
      ),
      (
        secao: SecaoConfiguracaoSix.seguranca,
        titulo: 'Segurança',
        icone: Icons.security_rounded,
      ),
      (
        secao: SecaoConfiguracaoSix.preferenciasUsuario,
        titulo: 'Usuário',
        icone: Icons.person_outline_rounded,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configurações',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: tokens.primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dados institucionais, regionalização, aparência, documentos, segurança e operação do comércio.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: tokens.selectedBackground,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tokens.selectedBorder),
                ),
                child: Text(
                  _tituloSecao(_secaoAtual),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                itens.map((item) {
                  final bool selecionado = _secaoAtual == item.secao;

                  return Semantics(
                    button: true,
                    selected: selecionado,
                    label: 'Abrir ${item.titulo}',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _selecionarSecao(item.secao),
                        child: AnimatedContainer(
                          duration: WebThemeTokens.transitionDuration,
                          curve: WebThemeTokens.transitionCurve,
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                selecionado
                                    ? tokens.selectedBackground
                                    : tokens.cardBackground,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color:
                                  selecionado
                                      ? tokens.selectedBorder
                                      : tokens.cardBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icone,
                                size: 19,
                                color:
                                    selecionado
                                        ? tokens.info
                                        : tokens.secondaryText,
                              ),
                              const SizedBox(width: 9),
                              Text(
                                item.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color:
                                      selecionado
                                          ? tokens.primaryText
                                          : tokens.secondaryText,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String titulo,
    required String descricao,
    required IconData icone,
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icone, size: 30, color: tokens.info),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: tokens.primaryText,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  descricao,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: tokens.secondaryText,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigCard({
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: tokens.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: tokens.primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 16), trailing],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? helperText,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true,
    bool marcarAlteracaoGeral = false,
  }) {
    final tokens = WebThemeTokens.of(context);
    return AnimatedOpacity(
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      opacity: enabled ? 1 : 0.55,
      child: TextField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (_) {
          setState(() {
            if (marcarAlteracaoGeral) {
              _possuiAlteracoesGerais = true;
            }
          });
          _marcarAlteracao();
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          filled: true,
          fillColor: tokens.inputBackground,
          labelStyle: TextStyle(color: tokens.secondaryText),
          hintStyle: TextStyle(color: tokens.mutedText),
          helperStyle: TextStyle(color: tokens.mutedText),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: tokens.cardBorder),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: tokens.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: tokens.selectedBorder, width: 1.4),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return SixWebSelectField(
      label: label,
      value: value,
      items: items,
      enabled: enabled,
      onSelected: (String novo) {
        onChanged(novo);
        _marcarAlteracao();
      },
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    String? disabledSubtitle,
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return AnimatedOpacity(
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      opacity: enabled ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: tokens.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    !enabled && disabledSubtitle != null
                        ? disabledSubtitle
                        : subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.secondaryText,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Switch(
              value: enabled ? value : false,
              activeThumbColor: tokens.success,
              activeTrackColor: tokens.success.withValues(alpha: 0.28),
              inactiveThumbColor: tokens.disabledForeground,
              inactiveTrackColor: tokens.disabledBackground,
              onChanged:
                  enabled
                      ? (novo) {
                        onChanged(novo);
                        _marcarAlteracao();
                      }
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector({
    required String label,
    required Color color,
    required ValueChanged<Color> onColorSelected,
  }) {
    final tokens = WebThemeTokens.of(context);
    final opcoes = [
      const Color(0xFF1F3C88),
      const Color(0xFF5E81F4),
      const Color(0xFF0FA958),
      const Color(0xFFF59E0B),
      const Color(0xFF7C3AED),
      const Color(0xFFEF4444),
      const Color(0xFF0EA5E9),
      const Color(0xFF111827),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: tokens.surfaceMuted,
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: tokens.primaryText,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                opcoes.map((opcao) {
                  final selecionado = opcao.toARGB32() == color.toARGB32();
                  return InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      onColorSelected(opcao);
                      _marcarAlteracao();
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: opcao,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color:
                              selecionado
                                  ? tokens.selectedBorder
                                  : tokens.cardBorder,
                          width: 3,
                        ),
                      ),
                      child:
                          selecionado
                              ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                              )
                              : null,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label) {
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: tokens.selectedBackground,
        border: Border.all(color: tokens.selectedBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.drag_indicator_rounded, size: 16, color: tokens.info),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: tokens.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutChip(String label) {
    final tokens = WebThemeTokens.of(context);
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.flash_on_rounded, size: 18),
      onDeleted: () {
        setState(() {
          _atalhosFavoritos.remove(label);
        });
        _marcarAlteracao();
      },
      backgroundColor: tokens.surfaceMuted,
      labelStyle: TextStyle(
        color: tokens.primaryText,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: tokens.cardBorder),
      ),
    );
  }

  Widget _buildThemeOptionCard({
    required String label,
    required String description,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final bool selected = _temaSelecionado == label;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Tema $label',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _selecionarTemaVisual(label),
          child: AnimatedContainer(
            duration: WebThemeTokens.transitionDuration,
            curve: WebThemeTokens.transitionCurve,
            width: 300,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: selected ? tokens.selectedBackground : tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? tokens.selectedBorder : tokens.cardBorder,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? tokens.surfaceElevated
                            : tokens.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          selected ? tokens.selectedBorder : tokens.cardBorder,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: selected ? tokens.info : tokens.mutedText,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: WebThemeTokens.transitionDuration,
                            child:
                                selected
                                    ? Icon(
                                      Icons.check_circle_rounded,
                                      key: const ValueKey('selected'),
                                      color: tokens.info,
                                      size: 20,
                                    )
                                    : Icon(
                                      Icons.radio_button_unchecked_rounded,
                                      key: const ValueKey('not-selected'),
                                      color: tokens.mutedText,
                                      size: 20,
                                    ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.secondaryText,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: tokens.surfaceElevated,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: tokens.selectedBorder),
                          ),
                          child: Text(
                            'Selecionado',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: tokens.primaryText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOptions() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildThemeOptionCard(
          label: 'Claro',
          description: 'Superfícies claras para ambientes com muita luz.',
          icon: Icons.light_mode_rounded,
        ),
        _buildThemeOptionCard(
          label: 'Escuro',
          description: 'Base fria e confortável para operação prolongada.',
          icon: Icons.dark_mode_rounded,
        ),
        _buildThemeOptionCard(
          label: 'Automático',
          description: 'Segue a preferência do sistema quando disponível.',
          icon: Icons.brightness_auto_rounded,
        ),
      ],
    );
  }

  Widget _buildFloatingActions() {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final bool salvando =
        _carregandoAparencia ||
        _carregandoDadosEmpresa ||
        _selecionandoLogo ||
        _carregandoStatusAtendimento ||
        _salvandoStatusAtendimento;
    final bool compact = MediaQuery.of(context).size.width < 760;

    Widget statusBadge() {
      final bool pendente = _possuiAlteracoesNaoSalvas;
      final Color color = pendente ? tokens.warning : tokens.success;

      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            color.withValues(alpha: 0.12),
            tokens.surfaceElevated,
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              pendente ? 'Alterações pendentes' : 'Tudo salvo',
              style: theme.textTheme.labelMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: tokens.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact) ...[statusBadge(), const SizedBox(width: 8)],
              if (widget.embedded && widget.onBack != null) ...[
                OutlinedButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Fechar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.primaryText,
                    side: BorderSide(color: tokens.cardBorder),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: const StadiumBorder(),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Tooltip(
                message: 'Restaurar valores padrão da seção atual',
                child: OutlinedButton(
                  onPressed: _restaurarPadraoDaSecao,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.info,
                    side: BorderSide(color: tokens.cardBorder),
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 14,
                      vertical: 14,
                    ),
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restart_alt_rounded, size: 18),
                      if (!compact) ...[
                        const SizedBox(width: 8),
                        const Text('Restaurar'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: salvando ? null : _salvarConfiguracoes,
                icon:
                    salvando
                        ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                        : const Icon(Icons.save_outlined, size: 18),
                label: Text(salvando ? 'Salvando...' : 'Salvar'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: const StadiumBorder(),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConteudoSecao() {
    switch (_secaoAtual) {
      case SecaoConfiguracaoSix.geral:
        return _buildSecaoGeral();
      case SecaoConfiguracaoSix.regionalizacao:
        return _buildSecaoRegionalizacao();
      case SecaoConfiguracaoSix.aparencia:
        return _buildSecaoAparencia();
      case SecaoConfiguracaoSix.comunicacao:
        return _buildSecaoComunicacao();
      case SecaoConfiguracaoSix.documentos:
        return _buildSecaoDocumentos();
      case SecaoConfiguracaoSix.operacao:
        return _buildSecaoOperacao();
      case SecaoConfiguracaoSix.seguranca:
        return _buildSecaoSeguranca();
      case SecaoConfiguracaoSix.preferenciasUsuario:
        return _buildSecaoPreferenciasUsuario();
    }
  }

  Widget _buildDadosEmpresaForm() {
    if (_carregandoDadosEmpresa) {
      return SixBackendLoading(
        key: const ValueKey('dados-empresa-loading'),
        presentation: SixBackendLoadingPresentation.updateBanner,
        title: _i18n(
          'empresa.configuracao.waitingData',
          'Aguardando dados da empresa.',
        ),
        subtitle: _i18n(
          'empresa.configuracao.statusSubtitle',
          'As informações salvas aparecem nos documentos e comprovantes do comércio.',
        ),
        animation: SixBackendLoadingAnimation.skeletonPulse,
        leadingIcon: Icons.domain_verification_rounded,
        backgroundColor: WebThemeTokens.of(context).surfaceMuted,
        borderColor: WebThemeTokens.of(context).cardBorder,
      );
    }

    return LayoutBuilder(
      key: const ValueKey('dados-empresa-form'),
      builder: (context, constraints) {
        final double available =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 656;
        final bool compacto = available < 700;
        final double fieldWidth = compacto ? available : 320;
        final double wideFieldWidth = compacto ? available : 656;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_erroDadosEmpresa != null) ...[
              _buildDadosEmpresaErro(),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: fieldWidth,
                  child: _buildTextField(
                    label: _i18n(
                      'configuracoes.companyName',
                      'Nome da empresa',
                    ),
                    controller: _nomeEmpresaController,
                    marcarAlteracaoGeral: true,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _buildTextField(
                    label: _i18n('configuracoes.tradeName', 'Nome fantasia'),
                    controller: _nomeFantasiaController,
                    marcarAlteracaoGeral: true,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _buildTextField(
                    label: _i18n(
                      'configuracoes.taxDocument',
                      'Documento fiscal',
                    ),
                    controller: _documentoFiscalController,
                    marcarAlteracaoGeral: true,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _buildTextField(
                    label: _i18n('configuracoes.phone', 'Telefone'),
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    marcarAlteracaoGeral: true,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _buildTextField(
                    label: _i18n('configuracoes.whatsapp', 'WhatsApp'),
                    controller: _whatsAppController,
                    keyboardType: TextInputType.phone,
                    marcarAlteracaoGeral: true,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _buildTextField(
                    label: _i18n('configuracoes.mainEmail', 'Email principal'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    marcarAlteracaoGeral: true,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: _buildTextField(
                    label: _i18n('configuracoes.website', 'Site'),
                    controller: _siteController,
                    keyboardType: TextInputType.url,
                    marcarAlteracaoGeral: true,
                  ),
                ),
                SizedBox(
                  width: wideFieldWidth,
                  child: _buildTextField(
                    label: _i18n('configuracoes.address', 'Endereço'),
                    controller: _enderecoController,
                    marcarAlteracaoGeral: true,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDadosEmpresaErro() {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.danger.withValues(alpha: 0.22)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Widget message = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: tokens.danger, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _erroDadosEmpresa!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          );
          final Widget retry = TextButton.icon(
            onPressed: _carregarDadosDaEmpresa,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(_i18n('common.tryAgain', 'Tentar novamente')),
          );

          if (constraints.maxWidth < 520) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [message, const SizedBox(height: 10), retry],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: message),
              const SizedBox(width: 12),
              retry,
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrandingInstitucionalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 656),
          child: _buildEmpresaLogoPicker(),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildSwitchTile(
              title: _i18n(
                'configuracoes.preferTradeName',
                'Exibir nome fantasia como principal',
              ),
              subtitle: _i18n(
                'configuracoes.preferTradeNameSubtitle',
                'Quando ativo, o Six prioriza o nome fantasia em documentos e cabeçalhos.',
              ),
              value: true,
              onChanged: (_) {},
            ),
            _buildSwitchTile(
              title: _i18n(
                'configuracoes.allowCustomWebCover',
                'Permitir capa personalizada na web',
              ),
              subtitle: _i18n(
                'configuracoes.allowCustomWebCoverSubtitle',
                'Prepara a plataforma para futura imagem institucional na tela de login web.',
              ),
              value: true,
              onChanged: (_) {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmpresaLogoPicker() {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final bool hasLogo = (_logoBase64 ?? '').trim().isNotEmpty;
    final bool busy = _selecionandoLogo || _carregandoDadosEmpresa;

    return Semantics(
      container: true,
      label:
          hasLogo
              ? _i18n(
                'empresa.configuracao.logoSemantics',
                'Logo cadastrado da empresa.',
              )
              : _i18n(
                'empresa.configuracao.logoEmptySemantics',
                'Nenhum logo cadastrado.',
              ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compacto = constraints.maxWidth < 460;
          final Widget preview = _buildEmpresaLogoPreview(busy: busy);
          final Widget info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _i18n('empresa.configuracao.logoTitle', 'Logo da empresa'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: tokens.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasLogo
                    ? _i18n(
                      'empresa.configuracao.logoRegistered',
                      'Imagem pronta para salvar no cadastro do comércio.',
                    )
                    : _i18n(
                      'empresa.configuracao.logoSubtitle',
                      'Adicione uma imagem nítida, de preferência quadrada.',
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.secondaryText,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : _selecionarLogoEmpresa,
                    icon: Icon(
                      hasLogo
                          ? Icons.change_circle_outlined
                          : Icons.add_photo_alternate_outlined,
                      size: 18,
                    ),
                    label: Text(
                      hasLogo
                          ? _i18n(
                            'empresa.configuracao.logoChange',
                            'Trocar logo',
                          )
                          : _i18n(
                            'empresa.configuracao.logoSelect',
                            'Selecionar logo',
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasLogo)
                    TextButton.icon(
                      onPressed: busy ? null : _removerLogoEmpresa,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: Text(
                        _i18n('empresa.configuracao.logoRemove', 'Remover'),
                      ),
                    ),
                ],
              ),
            ],
          );

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.cardBorder),
            ),
            child:
                compacto
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [preview, const SizedBox(height: 14), info],
                    )
                    : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        preview,
                        const SizedBox(width: 14),
                        Expanded(child: info),
                      ],
                    ),
          );
        },
      ),
    );
  }

  Widget _buildEmpresaLogoPreview({required bool busy}) {
    final tokens = WebThemeTokens.of(context);
    final Uint8List? bytes = _decodeLogoBytes(_logoBase64);
    final String value = (_logoBase64 ?? '').trim();
    final bool isUrl =
        value.startsWith('http://') || value.startsWith('https://');
    final Widget content;

    if (bytes != null) {
      content = Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _buildEmpresaLogoFallback(),
      );
    } else if (isUrl) {
      content = Image.network(
        value,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _buildEmpresaLogoFallback(),
      );
    } else {
      content = _buildEmpresaLogoFallback();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tokens.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: tokens.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        ),
        if (busy)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.cardBackground.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmpresaLogoFallback() {
    final tokens = WebThemeTokens.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.selectedBackground,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Center(
        child: Icon(Icons.image_outlined, color: tokens.info, size: 30),
      ),
    );
  }

  Uint8List? _decodeLogoBytes(String? value) {
    final String normalizado = (value ?? '').trim();
    if (normalizado.isEmpty ||
        normalizado.startsWith('http://') ||
        normalizado.startsWith('https://')) {
      return null;
    }

    String payload = normalizado;
    if (payload.toLowerCase().startsWith('data:') && payload.contains(',')) {
      payload = payload.substring(payload.indexOf(',') + 1);
    }

    try {
      return base64Decode(
        base64.normalize(
          payload
              .replaceAll(RegExp(r'\s+'), '')
              .replaceAll('-', '+')
              .replaceAll('_', '/'),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Widget _buildHorariosAtendimentoForm() {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compacto = constraints.maxWidth < 720;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed:
                      _carregandoDadosEmpresa ? null : _aplicarHorarioDiasUteis,
                  icon: const Icon(Icons.work_history_outlined, size: 18),
                  label: Text(
                    _i18n(
                      'configuracoes.businessHoursApplyWeekdays',
                      'Aplicar segunda a sexta',
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      _carregandoDadosEmpresa
                          ? null
                          : _copiarSegundaParaDiasUteis,
                  icon: const Icon(Icons.content_copy_rounded, size: 18),
                  label: Text(
                    _i18n(
                      'configuracoes.businessHoursCopyMonday',
                      'Copiar segunda para dias úteis',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _i18n(
                'configuracoes.businessHoursHelper',
                'Use fechado para dias sem atendimento. Os horários são salvos por dia da semana e podem ser exibidos no link público do atendimento.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.secondaryText,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: _horariosAtendimento
                  .map(
                    (horario) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildHorarioAtendimentoRow(
                        horario,
                        compacto: compacto,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorarioAtendimentoRow(
    HorarioAtendimentoModel horario, {
    required bool compacto,
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final bool aberto = !horario.fechado;
    final String statusLabel =
        aberto
            ? _i18n('configuracoes.businessHoursOpen', 'Aberto')
            : _i18n('configuracoes.businessHoursClosed', 'Fechado');
    final Widget day = SizedBox(
      width: compacto ? double.infinity : 180,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color:
                  aberto
                      ? tokens.selectedBackground
                      : tokens.disabledBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: aberto ? tokens.selectedBorder : tokens.cardBorder,
              ),
            ),
            child: Icon(
              aberto ? Icons.schedule_rounded : Icons.do_not_disturb_on,
              size: 17,
              color: aberto ? tokens.info : tokens.disabledForeground,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _labelDiaSemana(horario.diaSemana),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
    final Widget toggle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: aberto,
          activeThumbColor: tokens.success,
          activeTrackColor: tokens.success.withValues(alpha: 0.28),
          inactiveThumbColor: tokens.disabledForeground,
          inactiveTrackColor: tokens.disabledBackground,
          onChanged:
              _carregandoDadosEmpresa
                  ? null
                  : (valor) => _alterarDiaAberto(horario, valor),
        ),
        const SizedBox(width: 6),
        Text(
          statusLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: aberto ? tokens.primaryText : tokens.secondaryText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
    final Widget times =
        aberto
            ? Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildHorarioTimeButton(
                  label: _i18n('configuracoes.businessHoursStart', 'Início'),
                  value: horario.inicio ?? '08:00',
                  onTap: () => _selecionarHorario(horario, true),
                ),
                Text(
                  _i18n('configuracoes.businessHoursTo', 'às'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.secondaryText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _buildHorarioTimeButton(
                  label: _i18n('configuracoes.businessHoursEnd', 'Fim'),
                  value: horario.fim ?? '18:00',
                  onTap: () => _selecionarHorario(horario, false),
                ),
              ],
            )
            : Text(
              _i18n(
                'configuracoes.businessHoursClosedDescription',
                'Sem atendimento neste dia.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            );

    return AnimatedContainer(
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: aberto ? tokens.selectedBorder : tokens.cardBorder,
        ),
      ),
      child:
          compacto
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  day,
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [toggle, times],
                  ),
                ],
              )
              : Row(
                children: [
                  day,
                  const SizedBox(width: 12),
                  SizedBox(width: 142, child: toggle),
                  const SizedBox(width: 12),
                  Expanded(child: times),
                ],
              ),
    );
  }

  Widget _buildHorarioTimeButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _carregandoDadosEmpresa ? null : onTap,
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: tokens.inputBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.cardBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time_rounded, color: tokens.info, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecaoGeral() {
    final tokens = WebThemeTokens.of(context);

    return Column(
      children: [
        _buildSectionHeader(
          titulo: _i18n(
            'configuracoes.generalTitle',
            'Configurações institucionais',
          ),
          descricao: _descricaoSecao(SecaoConfiguracaoSix.geral),
          icone: Icons.apartment_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _i18n(
            'configuracoes.businessIdentity',
            'Identidade do comércio',
          ),
          subtitle: _i18n(
            'configuracoes.businessIdentitySubtitle',
            'Informações usadas em cabeçalhos de documentos, relatórios, ordens de serviço e comunicações da loja.',
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: tokens.selectedBackground,
              border: Border.all(color: tokens.selectedBorder),
            ),
            child: Text(
              _i18n('configuracoes.required', 'Obrigatório'),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: tokens.primaryText,
              ),
            ),
          ),
          child: _buildDadosEmpresaForm(),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _i18n(
            'configuracoes.businessHoursTitle',
            'Horário de atendimento',
          ),
          subtitle: _i18n(
            'configuracoes.businessHoursSubtitle',
            'Defina quando o comércio atende clientes e mostre essa informação no acompanhamento público do serviço.',
          ),
          child: _buildHorariosAtendimentoForm(),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: _i18n(
            'configuracoes.institutionalBranding',
            'Branding institucional',
          ),
          subtitle: _i18n(
            'configuracoes.institutionalBrandingSubtitle',
            'Estruture a apresentação da marca para a web, PDFs e comunicações futuras do sistema.',
          ),
          child: _buildBrandingInstitucionalForm(),
        ),
      ],
    );
  }

  String _i18n(String key, String fallback) {
    final locale = _mapIdiomaSelecionadoParaLocale(_idiomaSelecionado);
    return WebI18nStore.instance.string(locale.toLanguageTag(), key) ??
        fallback;
  }

  Widget _buildSecaoRegionalizacao() {
    return Column(
      children: [
        _buildSectionHeader(
          titulo: _i18n('configuracoes.regionalizationTitle', 'XXXXX'),
          descricao: _i18n('configuracoes.descRegionalization', 'XXXXX'),
          icone: Icons.public_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Idioma e convenções regionais',
          subtitle:
              'Defina a experiência local da empresa, incluindo idioma, fuso e padrões de exibição.',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Idioma do sistema',
                  value: _idiomaSelecionado,
                  items: const [
                    'Português (Brasil)',
                    'English (US)',
                    'Español',
                    // 'Polski',
                  ],
                  onChanged: (valor) async {
                    if (valor == null) return;
                    await _alterarIdiomaSistema(valor);
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'País / região',
                  value: _paisRegiaoSelecionado,
                  items: const [
                    'Brasil',
                    'Estados Unidos',
                    'Espanha',
                    'Polônia',
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _paisRegiaoSelecionado = valor!;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Fuso horário',
                  value: _fusoSelecionado,
                  items: const [
                    'America/Sao_Paulo',
                    'UTC',
                    'Europe/Warsaw',
                    'America/New_York',
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _fusoSelecionado = valor!;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Formato de data',
                  value: _formatoDataSelecionado,
                  items: const ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'],
                  onChanged: (valor) {
                    setState(() {
                      _formatoDataSelecionado = valor!;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Formato de hora',
                  value: _formatoHoraSelecionado,
                  items: const ['24 horas', '12 horas'],
                  onChanged: (valor) {
                    setState(() {
                      _formatoHoraSelecionado = valor!;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Primeiro dia da semana',
                  value: _primeiroDiaSemanaSelecionado,
                  items: const ['Segunda-feira', 'Domingo'],
                  onChanged: (valor) {
                    setState(() {
                      _primeiroDiaSemanaSelecionado = valor!;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Formato numérico',
                  value: _formatoNumeroSelecionado,
                  items: const ['1.234,56', '1,234.56'],
                  onChanged: (valor) {
                    setState(() {
                      _formatoNumeroSelecionado = valor!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Moeda e padronização financeira',
          subtitle:
              'Essas definições influenciam dashboards, vendas, ordem de serviço, orçamentos e documentos.',
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 320,
                    child: _buildDropdownField(
                      label: 'Moeda principal',
                      value: _moedaSelecionada,
                      items: const [
                        'R\$ - Real Brasileiro',
                        '\$ - US Dollar',
                        '€ - Euro',
                        'zł - Złoty',
                      ],
                      onChanged: (valor) {
                        setState(() {
                          _moedaSelecionada = valor!;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: _buildDropdownField(
                      label: 'Posição do símbolo',
                      value: _posicaoSimboloSelecionada,
                      items: const ['Antes do valor', 'Depois do valor'],
                      onChanged: (valor) {
                        setState(() {
                          _posicaoSimboloSelecionada = valor!;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: _buildDropdownField(
                      label: 'Casas decimais',
                      value: _casasDecimaisSelecionadas,
                      items: const ['0', '2', '3'],
                      onChanged: (valor) {
                        setState(() {
                          _casasDecimaisSelecionadas = valor!;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: _buildDropdownField(
                      label: 'Separador decimal',
                      value: _separadorDecimalSelecionado,
                      items: const ['Vírgula', 'Ponto'],
                      onChanged: (valor) {
                        setState(() {
                          _separadorDecimalSelecionado = valor!;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: _buildDropdownField(
                      label: 'Separador de milhar',
                      value: _separadorMilharSelecionado,
                      items: const ['Ponto', 'Vírgula', 'Espaço'],
                      onChanged: (valor) {
                        setState(() {
                          _separadorMilharSelecionado = valor!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 430,
                    child: _buildSwitchTile(
                      title: 'Permitir múltiplas moedas',
                      subtitle:
                          'Mantém a base preparada para cenários internacionais e conversão futura.',
                      value: _permitirMultiplasMoedas,
                      onChanged: (valor) {
                        setState(() {
                          _permitirMultiplasMoedas = valor;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 430,
                    child: _buildSwitchTile(
                      title: 'Aplicar arredondamento financeiro',
                      subtitle:
                          'Padroniza cálculos e evita divergências de centavos em documentos e totais.',
                      value: _aplicarArredondamentoFinanceiro,
                      onChanged: (valor) {
                        setState(() {
                          _aplicarArredondamentoFinanceiro = valor;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoAparencia() {
    return Column(
      children: [
        _buildSectionHeader(
          titulo: 'Aparência e personalização visual',
          descricao: _descricaoSecao(SecaoConfiguracaoSix.aparencia),
          icone: Icons.palette_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Tema e densidade visual',
          subtitle:
              'Ajuste a experiência visual do operador para diferentes perfis de uso e ambientes.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThemeOptions(),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 320,
                    child: _buildDropdownField(
                      label: 'Densidade visual',
                      value: _densidadeSelecionada,
                      items: const ['Confortável', 'Compacta', 'Expandida'],
                      onChanged: (valor) {
                        setState(() {
                          _densidadeSelecionada = valor!;
                        });
                        _aplicarAparenciaPreview();
                        _marcarAlteracao();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Paleta do sistema',
          subtitle:
              'Essas cores serão úteis para branding do comércio, dashboards e futura personalização premium.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 320,
                    child: _buildColorSelector(
                      label: 'Cor primária',
                      color: _corPrimaria,
                      onColorSelected: (valor) {
                        setState(() {
                          _corPrimaria = valor;
                        });
                        _aplicarAparenciaPreview();
                        _marcarAlteracao();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: _buildColorSelector(
                      label: 'Cor secundária',
                      color: _corSecundaria,
                      onColorSelected: (valor) {
                        setState(() {
                          _corSecundaria = valor;
                        });
                        _aplicarAparenciaPreview();
                        _marcarAlteracao();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: _buildColorSelector(
                      label: 'Cor de destaque',
                      color: _corDestaque,
                      onColorSelected: (valor) {
                        setState(() {
                          _corDestaque = valor;
                        });
                        _aplicarAparenciaPreview();
                        _marcarAlteracao();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: _buildColorSelector(
                      label: 'Cor de alerta',
                      color: _corAlerta,
                      onColorSelected: (valor) {
                        setState(() {
                          _corAlerta = valor;
                        });
                        _aplicarAparenciaPreview();
                        _marcarAlteracao();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _buildPaletteExperiencePreview(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoComunicacao() {
    return Column(
      children: [
        _buildSectionHeader(
          titulo: 'Comunicação com clientes',
          descricao: _descricaoSecao(SecaoConfiguracaoSix.comunicacao),
          icone: Icons.markunread_outlined,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Canais e automações',
          subtitle:
              'Defina como o Six deve se comunicar com clientes durante o ciclo de venda e assistência técnica.',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Notificar por email',
                  subtitle: 'Envia comunicações formais e comprovantes.',
                  value: _notificarPorEmail,
                  onChanged: (valor) {
                    setState(() {
                      _notificarPorEmail = valor;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Notificar por WhatsApp',
                  subtitle:
                      'Ideal para atualizações rápidas de orçamento e status.',
                  value: _notificarPorWhatsApp,
                  onChanged: (valor) {
                    setState(() {
                      _notificarPorWhatsApp = valor;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Notificar por Telegram',
                  subtitle:
                      'Mantém a base pronta para futuras integrações opcionais.',
                  value: _notificarPorTelegram,
                  onChanged: (valor) {
                    setState(() {
                      _notificarPorTelegram = valor;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Envio automático de status',
                  subtitle:
                      'Dispara mensagens conforme as etapas da assistência técnica.',
                  value: _envioAutomaticoStatus,
                  onChanged: (valor) {
                    setState(() {
                      _envioAutomaticoStatus = valor;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Permitir envio manual',
                  subtitle:
                      'Usuários podem complementar o contato diretamente pela tela.',
                  value: _envioManualPermitido,
                  onChanged: (valor) {
                    setState(() {
                      _envioManualPermitido = valor;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Canal preferencial do cliente',
                  value: _canalPreferencialCliente,
                  items: const ['WhatsApp', 'Email', 'Telegram', 'SMS'],
                  onChanged: (valor) {
                    setState(() {
                      _canalPreferencialCliente = valor!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Textos padrão',
          subtitle:
              'Esses textos mockados já deixam a tela pronta para evoluir depois com templates vindos do backend.',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 460,
                child: _buildTextField(
                  label: 'Assinatura padrão',
                  controller: _assinaturaMensagemController,
                  maxLines: 3,
                ),
              ),
              SizedBox(
                width: 460,
                child: _buildTextField(
                  label: 'Mensagem - ordem criada',
                  controller: _mensagemOrdemCriadaController,
                  maxLines: 3,
                ),
              ),
              SizedBox(
                width: 460,
                child: _buildTextField(
                  label: 'Mensagem - pronto para retirada',
                  controller: _mensagemProntoRetiradaController,
                  maxLines: 3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoDocumentos() {
    return const DocumentosPersonalizadosWebContent();
  }

  Widget _buildSecaoOperacao() {
    return Column(
      children: [
        _buildSectionHeader(
          titulo: 'Regras operacionais',
          descricao: _descricaoSecao(SecaoConfiguracaoSix.operacao),
          icone: Icons.rule_folder_outlined,
        ),
        const SizedBox(height: 20),
        _buildRegrasOperacionaisResumo(),
        const SizedBox(height: 20),
        _buildCatalogoGradeOperacionalCard(),
        const SizedBox(height: 20),
        _buildVendaMesaOperacionalCard(),
        const SizedBox(height: 20),
        _buildClienteCreditoOperacionalCard(),
        const SizedBox(height: 20),
        _buildEstoqueCaixaOperacionalCard(),
        const SizedBox(height: 20),
        _buildDescontoComissaoOperacionalCard(),
        const SizedBox(height: 20),
        _buildUnidadesAssistenciaOperacionalCard(),
        const SizedBox(height: 20),
        _buildStatusAtendimentoOperacionalCard(),
        const SizedBox(height: 20),
        _buildRegrasOperacionaisFooter(),
      ],
    );
  }

  Widget _buildStatusAtendimentoOperacionalCard() {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final int totalFinalizadores =
        _statusAtendimentoCustomizacoes
            .where((item) => item.finalizador)
            .length;

    return _buildBigCard(
      title: 'Fluxo do atendimento técnico',
      subtitle:
          'Personalize como cada etapa aparece na lista, no modal de mudança de status e no acompanhamento público do serviço.',
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildOperationalSummaryPill(
            icon: Icons.flag_outlined,
            title: '${_statusAtendimentoCustomizacoes.length} status',
            subtitle: 'Disponíveis',
          ),
          _buildOperationalSummaryPill(
            icon: Icons.verified_outlined,
            title: '$totalFinalizadores finalizadores',
            subtitle: 'Encerram o fluxo',
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tokens.cardBorder),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 540,
                  child: Text(
                    'Os códigos técnicos continuam estáveis para integrações e regras. Aqui o usuário edita apenas os nomes exibidos em português, inglês e espanhol.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.secondaryText,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed:
                      _carregandoStatusAtendimento
                          ? null
                          : _carregarStatusAtendimentoCustomizacoes,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Atualizar nomes'),
                ),
                TextButton.icon(
                  onPressed:
                      _carregandoStatusAtendimento ||
                              _statusAtendimentoCustomizacoes.isEmpty
                          ? null
                          : _restaurarStatusAtendimentoPadrao,
                  icon: const Icon(Icons.restart_alt_rounded, size: 18),
                  label: const Text('Restaurar padrões'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_carregandoStatusAtendimento)
            SixBackendLoading(
              presentation: SixBackendLoadingPresentation.updateBanner,
              title: 'Carregando nomes dos status',
              subtitle:
                  'Estamos sincronizando o fluxo técnico configurado para este comércio.',
              animation: SixBackendLoadingAnimation.skeletonPulse,
              leadingIcon: Icons.sync_alt_rounded,
              backgroundColor: tokens.surfaceMuted,
              borderColor: tokens.cardBorder,
            )
          else if (_erroStatusAtendimento != null)
            _buildStatusAtendimentoErro(theme, tokens)
          else if (_statusAtendimentoCustomizacoes.isEmpty)
            Text(
              'Nenhum status encontrado para configuração.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.secondaryText,
              ),
            )
          else
            Column(
              children: _statusAtendimentoCustomizacoes
                  .map(_buildStatusAtendimentoLinha)
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusAtendimentoErro(ThemeData theme, WebThemeTokens tokens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: tokens.danger, size: 22),
          SizedBox(
            width: 540,
            child: Text(
              _erroStatusAtendimento ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.primaryText,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _carregarStatusAtendimentoCustomizacoes,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAtendimentoLinha(
    DominioStatusAtendimentoCustomizacaoModel item,
  ) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final bool compacto = MediaQuery.of(context).size.width < 1180;
    final String titulo =
        (_statusPtControllers[item.statusCodigo]?.text ?? '').trim().isNotEmpty
            ? _statusPtControllers[item.statusCodigo]!.text.trim()
            : item.nomeAtualPtBr;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tokens.selectedBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.selectedBorder),
                ),
                child: Icon(
                  item.finalizador
                      ? Icons.verified_outlined
                      : Icons.flag_outlined,
                  color: tokens.info,
                  size: 20,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: tokens.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatusMetadataChip(
                          label: item.statusCodigo,
                          icon: Icons.code_rounded,
                        ),
                        if (item.finalizador)
                          _buildStatusMetadataChip(
                            label: 'Finalizador',
                            icon: Icons.check_circle_outline_rounded,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (compacto)
            Column(
              children: [
                _buildStatusNomeField(
                  item: item,
                  controller: _statusPtControllers[item.statusCodigo]!,
                  label: 'Nome em português',
                  helperText: 'Padrão: ${item.nomePadraoPtBr}',
                  defaultValue: item.nomePadraoPtBr,
                ),
                const SizedBox(height: 12),
                _buildStatusNomeField(
                  item: item,
                  controller: _statusEnControllers[item.statusCodigo]!,
                  label: 'Nome em inglês',
                  helperText: 'Padrão: ${item.nomePadraoEnUs}',
                  defaultValue: item.nomePadraoEnUs,
                ),
                const SizedBox(height: 12),
                _buildStatusNomeField(
                  item: item,
                  controller: _statusEsControllers[item.statusCodigo]!,
                  label: 'Nome em espanhol',
                  helperText: 'Padrão: ${item.nomePadraoEsEs}',
                  defaultValue: item.nomePadraoEsEs,
                ),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildStatusNomeField(
                    item: item,
                    controller: _statusPtControllers[item.statusCodigo]!,
                    label: 'Nome em português',
                    helperText: 'Padrão: ${item.nomePadraoPtBr}',
                    defaultValue: item.nomePadraoPtBr,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusNomeField(
                    item: item,
                    controller: _statusEnControllers[item.statusCodigo]!,
                    label: 'Nome em inglês',
                    helperText: 'Padrão: ${item.nomePadraoEnUs}',
                    defaultValue: item.nomePadraoEnUs,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatusNomeField(
                    item: item,
                    controller: _statusEsControllers[item.statusCodigo]!,
                    label: 'Nome em espanhol',
                    helperText: 'Padrão: ${item.nomePadraoEsEs}',
                    defaultValue: item.nomePadraoEsEs,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusNomeField({
    required DominioStatusAtendimentoCustomizacaoModel item,
    required TextEditingController controller,
    required String label,
    required String helperText,
    required String defaultValue,
  }) {
    final tokens = WebThemeTokens.of(context);
    return TextField(
      controller: controller,
      enabled: !_salvandoStatusAtendimento,
      onChanged: (_) => _marcarAlteracaoStatusAtendimento(),
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        filled: true,
        fillColor: tokens.inputBackground,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: tokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: tokens.selectedBorder, width: 1.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
        suffixIcon: IconButton(
          tooltip: 'Restaurar nome padrão',
          onPressed:
              _salvandoStatusAtendimento
                  ? null
                  : () {
                    controller.text = defaultValue;
                    _marcarAlteracaoStatusAtendimento();
                  },
          icon: const Icon(Icons.restart_alt_rounded, size: 18),
        ),
      ),
    );
  }

  Widget _buildStatusMetadataChip({
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tokens.secondaryText),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegrasOperacionaisResumo() {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final int regrasAtivas =
        <bool>[
          _permitirVendaCatalogoPorLink,
          _cadastroGradeProdutos,
          _controlarEstoquePorVariacao,
          _vendaPorMesa,
          _mesaObrigatoria,
          _exigirClienteNaVenda,
          _validarDocumentoCliente,
          _exigirTelefoneCliente,
          _permitirVendasFiado,
          _controlarEstoque,
          _abrirCaixaObrigatorio,
          _descontoManualPermitido,
          _gerarComissaoColaborador,
          _produtoApenasComUnidadeMedida,
        ].where((bool value) => value).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Wrap(
        spacing: 18,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: tokens.selectedBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: tokens.selectedBorder),
            ),
            child: Icon(Icons.fact_check_outlined, color: tokens.info),
          ),
          SizedBox(
            width: 520,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Regras operacionais sugeridas',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Campos locais para preparar catálogo por link, grade de produtos, venda por mesa, cliente, fiado, crédito, estoque, caixa, desconto, comissão e unidades de medida. Nenhuma integração com backend foi adicionada nesta etapa.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.secondaryText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _buildOperationalSummaryPill(
            icon: Icons.check_circle_outline_rounded,
            title: '$regrasAtivas regras ativas',
            subtitle: 'Mock local',
          ),
          _buildOperationalSummaryPill(
            icon: Icons.table_restaurant_outlined,
            title: _vendaPorMesa ? 'Mesa ativa' : 'Mesa inativa',
            subtitle: _modoAtendimentoMesa,
          ),
          _buildOperationalSummaryPill(
            icon: Icons.credit_score_outlined,
            title: _permitirVendasFiado ? 'Fiado ativo' : 'Fiado inativo',
            subtitle: _politicaCreditoSelecionada,
          ),
          _buildOperationalSummaryPill(
            icon: Icons.view_module_outlined,
            title: '${_atributosGradeSelecionados.length} atributos',
            subtitle: 'Grade',
          ),
          _buildOperationalSummaryPill(
            icon: Icons.straighten_rounded,
            title: '${_unidadesMedidaAutorizadas.length} unidades',
            subtitle: 'Autorizadas',
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogoGradeOperacionalCard() {
    return _buildBigCard(
      title: 'Catálogo por link e grade de produtos',
      subtitle:
          'Campos sugeridos para vender produtos por um link compartilhável e organizar variações de produto por grade.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Permitir venda por catálogo de produtos por link',
                  subtitle:
                      'Habilita uma vitrine compartilhável para o cliente consultar produtos e iniciar uma venda pelo link.',
                  value: _permitirVendaCatalogoPorLink,
                  onChanged: (bool value) {
                    setState(() => _permitirVendaCatalogoPorLink = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Exigir cliente identificado no catálogo',
                  subtitle:
                      'Pede dados mínimos do cliente antes de concluir uma intenção de compra pelo link.',
                  value: _exigirClienteNoCatalogo,
                  enabled: _permitirVendaCatalogoPorLink,
                  onChanged: (bool value) {
                    setState(() => _exigirClienteNoCatalogo = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Permitir compartilhamento do catálogo',
                  subtitle:
                      'Prepara o fluxo para compartilhar o link por WhatsApp, email, SMS ou QR Code.',
                  value: _permitirCompartilhamentoCatalogo,
                  enabled: _permitirVendaCatalogoPorLink,
                  onChanged: (bool value) {
                    setState(() => _permitirCompartilhamentoCatalogo = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildTextField(
                  label: 'Nome público do catálogo',
                  controller: _nomeCatalogoController,
                  enabled: _permitirVendaCatalogoPorLink,
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildTextField(
                  label: 'Identificador do link',
                  controller: _slugCatalogoController,
                  helperText: 'Exemplo futuro: /catalogo/six-repair-center',
                  enabled: _permitirVendaCatalogoPorLink,
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildDropdownField(
                  label: 'Visibilidade do catálogo',
                  value: _visibilidadeCatalogo,
                  items: _visibilidadesCatalogo,
                  enabled: _permitirVendaCatalogoPorLink,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _visibilidadeCatalogo = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildDropdownField(
                  label: 'Validade do link',
                  value: _validadeLinkCatalogo,
                  items: _validadesCatalogo,
                  enabled: _permitirVendaCatalogoPorLink,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _validadeLinkCatalogo = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Cadastro de grade de produtos',
                  subtitle:
                      'Permite cadastrar variações como cor, tamanho, voltagem, modelo, capacidade ou condição.',
                  value: _cadastroGradeProdutos,
                  onChanged: (bool value) {
                    setState(() {
                      _cadastroGradeProdutos = value;
                      if (!value) {
                        _controlarEstoquePorVariacao = false;
                        _exigirGradeParaProdutoVariavel = false;
                      }
                    });
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Controlar estoque por variação',
                  subtitle:
                      'Separa saldo por item da grade, como película preta, branca, P, M, G ou bivolt.',
                  value: _controlarEstoquePorVariacao,
                  enabled: _cadastroGradeProdutos,
                  onChanged: (bool value) {
                    setState(() => _controlarEstoquePorVariacao = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Exigir grade para produto variável',
                  subtitle:
                      'Impede que produtos com variações sejam cadastrados sem ao menos um atributo de grade.',
                  value: _exigirGradeParaProdutoVariavel,
                  enabled: _cadastroGradeProdutos,
                  onChanged: (bool value) {
                    setState(() => _exigirGradeParaProdutoVariavel = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildOperationalChoiceSection(
            title: 'Atributos autorizados para grade',
            subtitle:
                'Sugestão inicial de atributos que podem formar variações de produto.',
            options: _atributosGradeDisponiveis,
            selectedValues: _atributosGradeSelecionados,
            enabled: _cadastroGradeProdutos,
          ),
        ],
      ),
    );
  }

  Widget _buildVendaMesaOperacionalCard() {
    return _buildBigCard(
      title: 'Venda por mesa',
      subtitle:
          'Personalização para restaurante, lanchonete, bar ou atendimento em salão com mesa, comanda e fechamento no caixa.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Permitir venda por mesa',
                  subtitle:
                      'Habilita atendimento por mesa para registrar consumo aberto até o fechamento da conta.',
                  value: _vendaPorMesa,
                  onChanged: (bool value) {
                    setState(() => _vendaPorMesa = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Mesa obrigatória na venda',
                  subtitle:
                      'Exige seleção de mesa antes de lançar itens em operações de salão.',
                  value: _mesaObrigatoria,
                  enabled: _vendaPorMesa,
                  onChanged: (bool value) {
                    setState(() => _mesaObrigatoria = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Permitir transferência de mesa',
                  subtitle:
                      'Permite mover consumo de uma mesa para outra sem perder os itens lançados.',
                  value: _permitirTransferenciaMesa,
                  enabled: _vendaPorMesa,
                  onChanged: (bool value) {
                    setState(() => _permitirTransferenciaMesa = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Permitir juntar mesas',
                  subtitle:
                      'Permite combinar mesas para grupos, eventos ou atendimento compartilhado.',
                  value: _permitirJuntarMesas,
                  enabled: _vendaPorMesa,
                  onChanged: (bool value) {
                    setState(() => _permitirJuntarMesas = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Imprimir comanda da mesa',
                  subtitle:
                      'Prepara emissão de comanda para cozinha, balcão ou conferência do cliente.',
                  value: _imprimirComandaMesa,
                  enabled: _vendaPorMesa,
                  onChanged: (bool value) {
                    setState(() => _imprimirComandaMesa = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Fechar mesa somente no caixa',
                  subtitle:
                      'Mantém o fechamento centralizado no caixa para reduzir divergência de recebimento.',
                  value: _fecharMesaSomenteNoCaixa,
                  enabled: _vendaPorMesa,
                  onChanged: (bool value) {
                    setState(() => _fecharMesaSomenteNoCaixa = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildDropdownField(
                  label: 'Modo de atendimento',
                  value: _modoAtendimentoMesa,
                  items: _modosAtendimentoMesa,
                  enabled: _vendaPorMesa,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _modoAtendimentoMesa = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildDropdownField(
                  label: 'Status inicial da mesa',
                  value: _statusInicialMesa,
                  items: _statusMesa,
                  enabled: _vendaPorMesa,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _statusInicialMesa = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildTextField(
                  label: 'Prefixo de identificação',
                  controller: _prefixoMesaController,
                  helperText: 'Exemplo: Mesa 01, Balcão 02 ou Comanda 15',
                  enabled: _vendaPorMesa,
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildTextField(
                  label: 'Quantidade inicial de mesas',
                  controller: _quantidadeMesasController,
                  keyboardType: TextInputType.number,
                  enabled: _vendaPorMesa,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 420,
            child: _buildSwitchTile(
              title: 'Cobrar taxa de serviço',
              subtitle:
                  'Sugere percentual de serviço no fechamento da mesa, sem alterar valores no backend nesta etapa.',
              value: _cobrarTaxaServicoMesa,
              enabled: _vendaPorMesa,
              onChanged: (bool value) {
                setState(() => _cobrarTaxaServicoMesa = value);
              },
            ),
          ),
          const SizedBox(height: 18),
          _buildOperationalSlider(
            title:
                'Taxa de serviço sugerida: ${_taxaServicoMesaPercentual.toStringAsFixed(0)}%',
            subtitle:
                'Campo pensado para restaurantes e lanchonetes que trabalham com taxa de atendimento no fechamento da mesa.',
            value: _taxaServicoMesaPercentual,
            min: 0,
            max: 20,
            divisions: 20,
            enabled: _vendaPorMesa && _cobrarTaxaServicoMesa,
            onChanged: (double value) {
              setState(() => _taxaServicoMesaPercentual = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCreditoOperacionalCard() {
    final String limiteCreditoFormatado = context
        .watch<LocaleSettingsProvider>()
        .formatCurrency(_limiteCreditoPadrao);

    return _buildBigCard(
      title: 'Cliente, fiado e crédito',
      subtitle:
          'Regras sugeridas para cadastro de clientes, venda fiado, aprovação de crédito, limite e bloqueio por inadimplência.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Cliente obrigatório na venda',
                  subtitle:
                      'Exige cliente vinculado para concluir vendas, orçamentos ou assistências técnicas.',
                  value: _exigirClienteNaVenda,
                  onChanged: (bool value) {
                    setState(() => _exigirClienteNaVenda = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Validar documento do cliente',
                  subtitle:
                      'Prepara validação de CPF, CNPJ ou documento equivalente conforme regionalização futura.',
                  value: _validarDocumentoCliente,
                  onChanged: (bool value) {
                    setState(() => _validarDocumentoCliente = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Telefone obrigatório no cadastro',
                  subtitle:
                      'Garante canal mínimo para contato, cobrança, avisos de assistência e pós-venda.',
                  value: _exigirTelefoneCliente,
                  onChanged: (bool value) {
                    setState(() => _exigirTelefoneCliente = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Endereço obrigatório para venda fiado',
                  subtitle:
                      'Exige endereço completo quando a empresa vender a prazo ou precisar de cobrança posterior.',
                  value: _exigirEnderecoClienteParaFiado,
                  enabled: _permitirVendasFiado,
                  onChanged: (bool value) {
                    setState(() => _exigirEnderecoClienteParaFiado = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Registrar aceite de uso de dados',
                  subtitle:
                      'Sugere controle de consentimento para contato, notificações e tratamento de dados do cliente.',
                  value: _exigirAceiteUsoDadosCliente,
                  onChanged: (bool value) {
                    setState(() => _exigirAceiteUsoDadosCliente = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Exigir anexo no cadastro do cliente',
                  subtitle:
                      'Permite preparar anexos como documento, comprovante ou contrato de prestação de serviço.',
                  value: _exigirAnexoCadastroCliente,
                  onChanged: (bool value) {
                    setState(() => _exigirAnexoCadastroCliente = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildDropdownField(
                  label: 'Perfil padrão do cliente',
                  value: _perfilPadraoCliente,
                  items: _perfisCliente,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _perfilPadraoCliente = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Permitir vendas fiado',
                  subtitle:
                      'Habilita vendas para pagamento posterior, vinculadas ao cliente e à agenda financeira.',
                  value: _permitirVendasFiado,
                  onChanged: (bool value) {
                    setState(() {
                      _permitirVendasFiado = value;
                      if (!value) {
                        _exigirAprovacaoCredito = false;
                        _permitirLimiteCreditoCliente = false;
                        _bloquearClienteInadimplente = false;
                        _notificarVencimentoFiado = false;
                        _permitirParcelamentoFiado = false;
                      }
                    });
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Exigir aprovação de crédito',
                  subtitle:
                      'Antes de vender fiado, exige aprovação de crédito conforme limite, histórico ou permissão.',
                  value: _exigirAprovacaoCredito,
                  enabled: _permitirVendasFiado,
                  onChanged: (bool value) {
                    setState(() => _exigirAprovacaoCredito = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Definir limite de crédito por cliente',
                  subtitle:
                      'Permite controlar quanto cada cliente pode comprar fiado antes de bloquear novas vendas.',
                  value: _permitirLimiteCreditoCliente,
                  enabled: _permitirVendasFiado,
                  onChanged: (bool value) {
                    setState(() => _permitirLimiteCreditoCliente = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Bloquear cliente inadimplente',
                  subtitle:
                      'Impede nova venda fiado quando houver atraso acima da tolerância definida.',
                  value: _bloquearClienteInadimplente,
                  enabled: _permitirVendasFiado,
                  onChanged: (bool value) {
                    setState(() => _bloquearClienteInadimplente = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Notificar vencimento do fiado',
                  subtitle:
                      'Prepara alertas por canais futuros antes e depois do vencimento da conta.',
                  value: _notificarVencimentoFiado,
                  enabled: _permitirVendasFiado,
                  onChanged: (bool value) {
                    setState(() => _notificarVencimentoFiado = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Permitir parcelamento do fiado',
                  subtitle:
                      'Permite dividir a venda fiado em parcelas a receber no financeiro.',
                  value: _permitirParcelamentoFiado,
                  enabled: _permitirVendasFiado,
                  onChanged: (bool value) {
                    setState(() => _permitirParcelamentoFiado = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildDropdownField(
                  label: 'Política de crédito',
                  value: _politicaCreditoSelecionada,
                  items: _politicasCredito,
                  enabled: _permitirVendasFiado,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _politicaCreditoSelecionada = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildDropdownField(
                  label: 'Prazo padrão do fiado',
                  value: _prazoPadraoFiado,
                  items: _prazosFiado,
                  enabled: _permitirVendasFiado,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _prazoPadraoFiado = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildTextField(
                  label: 'Dias de tolerância para bloqueio',
                  controller: _diasBloqueioAtrasoController,
                  helperText: 'Exemplo: bloquear após 7 dias de atraso',
                  keyboardType: TextInputType.number,
                  enabled: _permitirVendasFiado && _bloquearClienteInadimplente,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildOperationalSlider(
            title: 'Limite de crédito padrão: $limiteCreditoFormatado',
            subtitle:
                'Valor inicial sugerido para clientes que ainda não possuem análise individual de crédito.',
            value: _limiteCreditoPadrao,
            min: 0,
            max: 5000,
            divisions: 20,
            enabled: _permitirVendasFiado && _permitirLimiteCreditoCliente,
            valueSuffix: '',
            onChanged: (double value) {
              setState(() => _limiteCreditoPadrao = value);
            },
          ),
          const SizedBox(height: 18),
          _buildOperationalSlider(
            title:
                'Entrada mínima no fiado: ${_entradaMinimaFiadoPercentual.toStringAsFixed(0)}%',
            subtitle:
                'Percentual mínimo que pode ser exigido no ato da venda para reduzir risco de crédito.',
            value: _entradaMinimaFiadoPercentual,
            min: 0,
            max: 80,
            divisions: 16,
            enabled: _permitirVendasFiado,
            onChanged: (double value) {
              setState(() => _entradaMinimaFiadoPercentual = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEstoqueCaixaOperacionalCard() {
    return _buildBigCard(
      title: 'Estoque, venda e caixa',
      subtitle:
          'Sugestão de campos para controlar disponibilidade, baixa de estoque, venda negativa e abertura de caixa.',
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          SizedBox(
            width: 420,
            child: _buildSwitchTile(
              title: 'Controlar estoque',
              subtitle:
                  'Baixa saldo nas vendas e mantém relatórios de movimentação confiáveis.',
              value: _controlarEstoque,
              onChanged: (bool value) {
                setState(() {
                  _controlarEstoque = value;
                  if (!value) _permitirVendaSemEstoque = false;
                });
              },
            ),
          ),
          SizedBox(
            width: 420,
            child: _buildSwitchTile(
              title: 'Permitir venda sem estoque',
              subtitle:
                  'Permite concluir a venda mesmo quando o saldo do produto estiver abaixo de zero.',
              value: _permitirVendaSemEstoque,
              enabled: _controlarEstoque,
              disabledSubtitle:
                  'Disponível apenas quando o controle de estoque estiver ativo.',
              onChanged: (bool value) {
                setState(() => _permitirVendaSemEstoque = value);
              },
            ),
          ),
          SizedBox(
            width: 420,
            child: _buildSwitchTile(
              title: 'Abertura de caixa obrigatória',
              subtitle:
                  'Impede vendas, recebimentos e sangrias antes da abertura formal do caixa.',
              value: _abrirCaixaObrigatorio,
              onChanged: (bool value) {
                setState(() => _abrirCaixaObrigatorio = value);
              },
            ),
          ),
          SizedBox(
            width: 420,
            child: _buildSwitchTile(
              title: 'Permitir edição após fechamento',
              subtitle:
                  'Quando desligado, a operação passa a ser mais rígida e auditável.',
              value: _permitirEdicaoAposFechamento,
              onChanged: (bool value) {
                setState(() => _permitirEdicaoAposFechamento = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescontoComissaoOperacionalCard() {
    return _buildBigCard(
      title: 'Descontos e comissão',
      subtitle:
          'Campos sugeridos para desconto no balcão, justificativa, limite e comissionamento por colaborador.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Conceder desconto na hora da venda',
                  subtitle:
                      'Permite que o operador aplique desconto diretamente no fluxo de venda.',
                  value: _descontoManualPermitido,
                  onChanged: (bool value) {
                    setState(() => _descontoManualPermitido = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Exigir justificativa do desconto',
                  subtitle:
                      'Registra o motivo informado pelo operador para auditoria futura.',
                  value: _exigirJustificativaDesconto,
                  enabled: _descontoManualPermitido,
                  onChanged: (bool value) {
                    setState(() => _exigirJustificativaDesconto = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildDropdownField(
                  label: 'Tipo de desconto permitido',
                  value: _tipoDescontoSelecionado,
                  items: _tiposDesconto,
                  enabled: _descontoManualPermitido,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _tipoDescontoSelecionado = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildOperationalSlider(
            title:
                'Limite máximo de desconto: ${_limiteDesconto.toStringAsFixed(0)}%',
            subtitle:
                'Campo sugerido para restringir descontos manuais conforme política do comércio.',
            value: _limiteDesconto,
            min: 0,
            max: 50,
            divisions: 10,
            enabled: _descontoManualPermitido,
            onChanged: (double value) {
              setState(() => _limiteDesconto = value);
            },
          ),
          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 22),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Gerar comissão para colaborador',
                  subtitle:
                      'Habilita regra futura para comissionamento por responsável da venda ou serviço.',
                  value: _gerarComissaoColaborador,
                  onChanged: (bool value) {
                    setState(() => _gerarComissaoColaborador = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Aplicar comissão em serviços',
                  subtitle:
                      'Inclui mão de obra, assistência técnica e serviços avulsos no cálculo.',
                  value: _aplicarComissaoEmServicos,
                  enabled: _gerarComissaoColaborador,
                  onChanged: (bool value) {
                    setState(() => _aplicarComissaoEmServicos = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Aplicar comissão em produtos',
                  subtitle:
                      'Inclui venda de peças, acessórios e mercadorias no cálculo da comissão.',
                  value: _aplicarComissaoEmProdutos,
                  enabled: _gerarComissaoColaborador,
                  onChanged: (bool value) {
                    setState(() => _aplicarComissaoEmProdutos = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildDropdownField(
                  label: 'Base de cálculo da comissão',
                  value: _baseComissaoSelecionada,
                  items: _basesComissao,
                  enabled: _gerarComissaoColaborador,
                  onChanged: (String? value) {
                    if (value == null) return;
                    setState(() => _baseComissaoSelecionada = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildOperationalSlider(
            title:
                'Comissão padrão sugerida: ${_percentualComissaoPadrao.toStringAsFixed(0)}%',
            subtitle:
                'Valor inicial para novas regras; pode evoluir depois para política por colaborador, produto ou serviço.',
            value: _percentualComissaoPadrao,
            min: 0,
            max: 30,
            divisions: 15,
            enabled: _gerarComissaoColaborador,
            onChanged: (double value) {
              setState(() => _percentualComissaoPadrao = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnidadesAssistenciaOperacionalCard() {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return _buildBigCard(
      title: 'Unidades de medida e assistência técnica',
      subtitle:
          'Limite unidades aceitas pela empresa e mantenha os controles técnicos atuais da operação.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 520,
            child: _buildSwitchTile(
              title:
                  'Permitir cadastro de produto apenas por unidade de medida',
              subtitle:
                  'Exige unidade informada e restringe o cadastro às categorias autorizadas abaixo.',
              value: _produtoApenasComUnidadeMedida,
              onChanged: (bool value) {
                setState(() => _produtoApenasComUnidadeMedida = value);
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildOperationalChoiceSection(
            title: 'Unidades autorizadas para vendas',
            subtitle:
                'Categorias disponíveis: unidades, área, distância, volume, tempo, peso e moeda.',
            options: _unidadesDisponiveis,
            selectedValues: _unidadesMedidaAutorizadas,
          ),
          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 22),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Exigir número de série / IMEI',
                  subtitle:
                      'Ajuda a identificar corretamente o equipamento recebido.',
                  value: _exigirSerialImei,
                  onChanged: (bool value) {
                    setState(() => _exigirSerialImei = value);
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Exigir técnico responsável',
                  subtitle:
                      'Fortalece rastreabilidade e produtividade do time técnico.',
                  value: _exigirTecnicoResponsavel,
                  onChanged: (bool value) {
                    setState(() => _exigirTecnicoResponsavel = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Fluxo de status da assistência',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: tokens.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mock de status já preparado para futura persistência e personalização por comércio.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.secondaryText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _statusAssistencia.map(_buildStatusChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalChoiceSection({
    required String title,
    required String subtitle,
    required List<_ConfiguracaoChoiceOption> options,
    required Set<String> selectedValues,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return AnimatedOpacity(
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      opacity: enabled ? 1 : 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: tokens.primaryText,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.secondaryText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children:
                options.map((_ConfiguracaoChoiceOption option) {
                  final bool selected = selectedValues.contains(option.label);
                  return _buildOperationalChoiceCard(
                    option: option,
                    selected: selected,
                    enabled: enabled,
                    onTap: () {
                      setState(() {
                        if (selected) {
                          selectedValues.remove(option.label);
                        } else {
                          selectedValues.add(option.label);
                        }
                      });
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalChoiceCard({
    required _ConfiguracaoChoiceOption option,
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: option.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap:
              enabled
                  ? () {
                    onTap();
                    _marcarAlteracao();
                  }
                  : null,
          child: AnimatedContainer(
            duration: WebThemeTokens.transitionDuration,
            curve: WebThemeTokens.transitionCurve,
            width: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? tokens.selectedBackground : tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? tokens.selectedBorder : tokens.cardBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color:
                        selected
                            ? tokens.surfaceElevated
                            : tokens.inputBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.cardBorder),
                  ),
                  child: Icon(
                    option.icon,
                    color: selected ? tokens.info : tokens.secondaryText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: tokens.primaryText,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                            color: selected ? tokens.info : tokens.mutedText,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        option.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.secondaryText,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationalSummaryPill({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return Container(
      width: 184,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: tokens.info),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: tokens.primaryText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalSlider({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    bool enabled = true,
    String valueSuffix = '%',
  }) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return AnimatedOpacity(
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      opacity: enabled ? 1 : 0.55,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: tokens.cardBorder),
          color: tokens.surfaceMuted,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: tokens.primaryText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.secondaryText,
                height: 1.35,
              ),
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: '${value.toStringAsFixed(0)}$valueSuffix',
              onChanged:
                  enabled
                      ? (double novo) {
                        onChanged(novo);
                        _marcarAlteracao();
                      }
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegrasOperacionaisFooter() {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 680,
            child: Text(
              'Pronto para evoluir: os campos foram desenhados como rascunho de regra operacional e ainda não persistem no backend.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.secondaryText,
                height: 1.35,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Rascunho das regras operacionais validado localmente. Backend não integrado.',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: tokens.info,
                  ),
                );
            },
            icon: const Icon(Icons.check_rounded),
            label: const Text('Validar rascunho'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoSeguranca() {
    return Column(
      children: [
        _buildSectionHeader(
          titulo: 'Segurança e acesso',
          descricao: _descricaoSecao(SecaoConfiguracaoSix.seguranca),
          icone: Icons.security_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Proteção da conta',
          subtitle:
              'Centralize políticas de sessão, autenticação e comportamento de login da operação.',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Habilitar MFA',
                  subtitle:
                      'Mantém a conta mais protegida para administradores e usuários sensíveis.',
                  value: _mfaHabilitado,
                  onChanged: (valor) {
                    setState(() {
                      _mfaHabilitado = valor;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Encerrar sessões inativas',
                  subtitle:
                      'Reduz risco operacional em computadores compartilhados.',
                  value: _encerrarSessoesInativas,
                  onChanged: (valor) {
                    setState(() {
                      _encerrarSessoesInativas = valor;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Permitir login simultâneo',
                  subtitle:
                      'Controla se o mesmo usuário pode operar em mais de um dispositivo ao mesmo tempo.',
                  value: _permitirLoginMultiplo,
                  onChanged: (valor) {
                    setState(() {
                      _permitirLoginMultiplo = valor;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Exigir troca periódica de senha',
                  subtitle:
                      'Prepara o produto para políticas corporativas mais rígidas.',
                  value: _exigirTrocaSenhaPeriodica,
                  onChanged: (valor) {
                    setState(() {
                      _exigirTrocaSenhaPeriodica = valor;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Tempo de sessão',
                  value: _tempoSessaoSelecionado,
                  items: const ['2 horas', '8 horas', '12 horas', '24 horas'],
                  onChanged: (valor) {
                    setState(() {
                      _tempoSessaoSelecionado = valor!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoPreferenciasUsuario() {
    return Column(
      children: [
        _buildSectionHeader(
          titulo: 'Preferências do usuário',
          descricao: _descricaoSecao(SecaoConfiguracaoSix.preferenciasUsuario),
          icone: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Experiência pessoal de uso',
          subtitle:
              'Essas opções ajudam o operador a trabalhar melhor no dia a dia sem misturar com as configurações globais da empresa.',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Página inicial',
                  value: _paginaInicialSelecionada,
                  items: const [
                    'Painel administrativo',
                    'Vendas',
                    'Ordem de serviço',
                    'Agenda financeira',
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _paginaInicialSelecionada = valor!;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Som de notificação',
                  subtitle: 'Emite feedback sonoro para eventos importantes.',
                  value: _receberSomNotificacao,
                  onChanged: (valor) {
                    setState(() {
                      _receberSomNotificacao = valor;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Notificações desktop',
                  subtitle:
                      'Mantém alertas visíveis durante o uso do sistema na web.',
                  value: _receberNotificacoesDesktop,
                  onChanged: (valor) {
                    setState(() {
                      _receberNotificacoesDesktop = valor;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 420,
                child: _buildSwitchTile(
                  title: 'Mostrar dicas contextuais',
                  subtitle: 'Ajuda novos operadores durante a curva de adoção.',
                  value: _mostrarDicasContextuais,
                  onChanged: (valor) {
                    setState(() {
                      _mostrarDicasContextuais = valor;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Atalhos favoritos',
          subtitle:
              'Deixe acessos rápidos para os fluxos mais usados na operação.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _atalhosFavoritos.map(_buildShortcutChip).toList(),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _atalhosFavoritos.add('Relatórios');
                      });
                      _marcarAlteracao();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Adicionar Relatórios'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _atalhosFavoritos.add('Produtos');
                      });
                      _marcarAlteracao();
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Adicionar Produtos'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConteudoPrincipal() {
    return SingleChildScrollView(
      controller: _conteudoScrollController,
      child: Column(
        children: [
          _buildSecoesHeader(),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: WebThemeTokens.transitionDuration,
            switchInCurve: WebThemeTokens.transitionCurve,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final Animation<Offset> offset = Tween<Offset>(
                begin: const Offset(0, 0.018),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: KeyedSubtree(
              key: ValueKey<SecaoConfiguracaoSix>(_secaoAtual),
              child: _buildConteudoSecao(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = WebThemeTokens.of(context);
    final bodyContent = LayoutBuilder(
      builder: (context, constraints) {
        final bool compactShell =
            widget.embedded && constraints.maxWidth < 1160;
        final double outerPadding = compactShell ? 12 : 16;
        final double cardPadding = compactShell ? 14 : 18;

        return Padding(
          padding: EdgeInsets.all(outerPadding),
          child: Card(
            elevation: 0,
            color: tokens.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: tokens.cardBorder),
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: _buildConteudoPrincipal(),
            ),
          ),
        );
      },
    );

    final bool compactActions =
        widget.embedded && MediaQuery.of(context).size.width < 1280;

    final contentWithFab = AnimatedContainer(
      duration: WebThemeTokens.transitionDuration,
      curve: WebThemeTokens.transitionCurve,
      color: tokens.workspaceBackground,
      child: Stack(
        children: [
          Positioned.fill(child: bodyContent),
          Positioned(
            right: compactActions ? 24 : 36,
            bottom: compactActions ? 24 : 36,
            child: _buildFloatingActions(),
          ),
        ],
      ),
    );

    final themedContent = Theme(
      data: WebThemeTokens.applyTo(theme),
      child: contentWithFab,
    );

    if (widget.embedded) {
      return themedContent;
    }

    return Scaffold(
      backgroundColor: tokens.workspaceBackground,
      body: SafeArea(child: themedContent),
    );
  }

  Locale _mapIdiomaSelecionadoParaLocale(String idioma) {
    switch (idioma) {
      case 'English (US)':
        return const Locale('en', 'US');
      case 'Español':
        return const Locale('es', 'ES');
      case 'Português (Brasil)':
      default:
        return const Locale('pt', 'BR');
    }
  }

  String _mapMoedaSelecionadaParaCurrencyCode(String moedaSelecionada) {
    final String normalized = moedaSelecionada.trim().toUpperCase();
    if (normalized.contains('USD') || normalized.startsWith('\$')) {
      return 'USD';
    }
    if (normalized.contains('EUR') || normalized.startsWith('€')) return 'EUR';
    if (normalized.contains('PLN') || normalized.startsWith('ZŁ')) {
      return 'PLN';
    }
    if (normalized.contains('BRL') || normalized.startsWith('R\$')) {
      return 'BRL';
    }
    return 'BRL';
  }

  String _mapSeparadorMilhar(String valor) {
    switch (valor) {
      case 'Vírgula':
        return ',';
      case 'Espaço':
        return ' ';
      case 'Ponto':
      default:
        return '.';
    }
  }

  Future<void> _alterarIdiomaSistema(String idioma) async {
    setState(() {
      _idiomaSelecionado = idioma;
      _possuiAlteracoesNaoSalvas = true;
      _carregandoAparencia = true;
    });

    try {
      final locale = _mapIdiomaSelecionadoParaLocale(idioma);

      await context.read<LocaleSettingsProvider>().setUserLocale(locale);

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar idioma: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: WebThemeTokens.of(context).danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _carregandoAparencia = false;
        });
      }
    }
  }
}

class _ConfiguracaoChoiceOption {
  const _ConfiguracaoChoiceOption({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;
}
