import 'package:flutter/material.dart';
import 'dart:ui';

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
  SecaoConfiguracaoSix _secaoAtual = SecaoConfiguracaoSix.geral;
  bool _mostrarResumoLateral = true;
  bool _possuiAlteracoesNaoSalvas = true;

  // =========================
  // MOCKS / ESTADO DA TELA
  // =========================

  // Geral
  final TextEditingController _nomeEmpresaController =
  TextEditingController(text: 'Six Assistência Premium');
  final TextEditingController _nomeFantasiaController =
  TextEditingController(text: 'Six Repair Center');
  final TextEditingController _documentoFiscalController =
  TextEditingController(text: '12.345.678/0001-90');
  final TextEditingController _telefoneController =
  TextEditingController(text: '+55 (47) 99999-8888');
  final TextEditingController _whatsAppController =
  TextEditingController(text: '+55 (47) 99999-7777');
  final TextEditingController _emailController =
  TextEditingController(text: 'contato@sixrepair.com');
  final TextEditingController _siteController =
  TextEditingController(text: 'www.sixrepair.com');
  final TextEditingController _enderecoController =
  TextEditingController(text: 'Av. Central, 1500 - Centro - Itajaí/SC');

  // Regionalização
  String _idiomaSelecionado = 'Português (Brasil)';
  String _paisRegiaoSelecionado = 'Brasil';
  String _fusoSelecionado = 'America/Sao_Paulo';
  String _formatoDataSelecionado = 'dd/MM/yyyy';
  String _formatoHoraSelecionado = '24 horas';
  String _primeiroDiaSemanaSelecionado = 'Segunda-feira';
  String _formatoNumeroSelecionado = '1.234,56';

  // Financeiro / moeda
  String _moedaSelecionada = 'BRL - Real Brasileiro (R\$)';
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
  final TextEditingController _assinaturaMensagemController =
  TextEditingController(
    text:
    'Equipe Six agradece o seu contato. Qualquer dúvida, estamos à disposição.',
  );
  final TextEditingController _mensagemOrdemCriadaController =
  TextEditingController(
    text: 'Sua ordem de serviço foi criada com sucesso.',
  );
  final TextEditingController _mensagemProntoRetiradaController =
  TextEditingController(
    text: 'Seu equipamento está pronto para retirada.',
  );

  // Documentos
  String _modeloOrcamentoSelecionado = 'Modelo corporativo moderno';
  String _modeloOrdemServicoSelecionado = 'Modelo técnico com checklist';
  String _modeloReciboSelecionado = 'Modelo enxuto com logo';
  bool _exibirLogoNoPdf = true;
  bool _exibirAssinaturaCliente = true;
  bool _exibirQrCode = false;
  String _tamanhoPapelSelecionado = 'A4';
  String _idiomaDocumentoSelecionado = 'Mesmo idioma do sistema';
  String _moedaDocumentoSelecionada = 'Mesma moeda da empresa';
  final TextEditingController _rodapeDocumentoController =
  TextEditingController(
    text:
    'Obrigado pela preferência. Este documento foi gerado automaticamente pelo Six.',
  );
  final TextEditingController _termosCondicoesController =
  TextEditingController(
    text:
    'Após aprovação do orçamento, poderá haver necessidade de peças adicionais conforme análise técnica.',
  );

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
    _rodapeDocumentoController.dispose();
    _termosCondicoesController.dispose();
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

  void _salvarConfiguracoes() {
    setState(() {
      _possuiAlteracoesNaoSalvas = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configurações salvas com sucesso.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _restaurarPadraoDaSecao() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Os valores padrão da seção "${_tituloSecao(_secaoAtual)}" foram restaurados (mock).',
        ),
        behavior: SnackBarBehavior.floating,
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
        return 'Operação';
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
        return 'Regras de venda, assistência técnica, controle operacional e comportamento do fluxo.';
      case SecaoConfiguracaoSix.seguranca:
        return 'Sessão, autenticação, acesso, políticas de proteção e gestão de segurança da conta.';
      case SecaoConfiguracaoSix.preferenciasUsuario:
        return 'Ajustes pessoais do operador para melhorar produtividade e experiência no dia a dia.';
    }
  }

  int _quantidadeConfiguracoesAtivas() {
    int total = 0;
    final booleanos = [
      _permitirMultiplasMoedas,
      _aplicarArredondamentoFinanceiro,
      _notificarPorEmail,
      _notificarPorWhatsApp,
      _notificarPorTelegram,
      _envioAutomaticoStatus,
      _envioManualPermitido,
      _exibirLogoNoPdf,
      _exibirAssinaturaCliente,
      _exibirQrCode,
      _controlarEstoque,
      _exigirClienteNaVenda,
      _exigirSerialImei,
      _exigirTecnicoResponsavel,
      _abrirCaixaObrigatorio,
      _permitirVendaSemEstoque,
      _gerarComissaoColaborador,
      _permitirEdicaoAposFechamento,
      _descontoManualPermitido,
      _mfaHabilitado,
      _encerrarSessoesInativas,
      _permitirLoginMultiplo,
      _exigirTrocaSenhaPeriodica,
      _receberSomNotificacao,
      _receberNotificacoesDesktop,
      _mostrarDicasContextuais,
    ];

    for (final item in booleanos) {
      if (item) total++;
    }

    return total;
  }

  int _quantidadeCamposObrigatoriosPreenchidos() {
    final campos = [
      _nomeEmpresaController.text.trim(),
      _nomeFantasiaController.text.trim(),
      _telefoneController.text.trim(),
      _emailController.text.trim(),
      _idiomaSelecionado.trim(),
      _moedaSelecionada.trim(),
    ];

    return campos.where((item) => item.isNotEmpty).length;
  }

  Widget _buildHeaderTag({
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIndicator({
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoSidebarHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Configs',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Tooltip(
            message: 'Ocultar painel',
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() {
                  _mostrarResumoLateral = false;
                });
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoSidebar() {
    final theme = Theme.of(context);

    final itens = [
      {
        'titulo': 'Idioma ativo',
        'valor': _idiomaSelecionado,
        'icone': Icons.language_rounded,
      },
      {
        'titulo': 'Moeda principal',
        'valor': _moedaSelecionada.split(' - ').first,
        'icone': Icons.attach_money_rounded,
      },
      {
        'titulo': 'Tema',
        'valor': _temaSelecionado,
        'icone': Icons.dark_mode_rounded,
      },
      {
        'titulo': 'Canal preferencial',
        'valor': _canalPreferencialCliente,
        'icone': Icons.chat_bubble_outline_rounded,
      },
      {
        'titulo': 'Modelo OS',
        'valor': _modeloOrdemServicoSelecionado,
        'icone': Icons.description_rounded,
      },
      {
        'titulo': 'Abertura de caixa',
        'valor': _abrirCaixaObrigatorio ? 'Obrigatória' : 'Opcional',
        'icone': Icons.point_of_sale_rounded,
      },
      {
        'titulo': 'MFA',
        'valor': _mfaHabilitado ? 'Habilitado' : 'Desabilitado',
        'icone': Icons.security_rounded,
      },
    ];

    return Container(
      width: 330,
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildResumoSidebarHeader(),
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.08),
                  theme.colorScheme.surfaceContainerHighest.withOpacity(0.70),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Painel inteligente',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Visualize rapidamente os principais parâmetros operacionais e de branding antes de salvar.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: itens.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = itens[index];
                return _buildResumoCard(
                  icon: item['icone'] as IconData,
                  title: item['titulo'] as String,
                  value: item['valor'] as String,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _buildPreviewBrandingCard(),
        ],
      ),
    );
  }

  Widget _buildResumoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewBrandingCard() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview visual',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  _corPrimaria.withOpacity(0.16),
                  _corSecundaria.withOpacity(0.10),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nomeFantasiaController.text.isEmpty
                      ? 'Sua marca aqui'
                      : _nomeFantasiaController.text,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tema $_temaSelecionado • Moeda ${_moedaSelecionada.split(' - ').first} • Idioma ${_idiomaSelecionado.split(' ').first}',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildColorBadge(_corPrimaria, 'Primária'),
                    _buildColorBadge(_corSecundaria, 'Secundária'),
                    _buildColorBadge(_corDestaque, 'Destaque'),
                    _buildColorBadge(_corAlerta, 'Alerta'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBadge(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoSidebarCollapsed() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 14, right: 12),
      child: Tooltip(
        message: 'Mostrar painel',
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _mostrarResumoLateral = true;
            });
          },
          child: Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.dashboard_customize_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 10),
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Resumo',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuLateralSecoes() {
    final theme = Theme.of(context);

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
      titulo: 'Operação',
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seções',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          ...itens.map((item) {
            final selecionado = _secaoAtual == item.secao;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    _secaoAtual = item.secao;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selecionado
                        ? theme.colorScheme.primary.withOpacity(0.10)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selecionado
                          ? theme.colorScheme.primary.withOpacity(0.25)
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: selecionado
                              ? theme.colorScheme.primary.withOpacity(0.12)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item.icone,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.titulo,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: selecionado
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icone,
              size: 30,
              color: theme.colorScheme.primary,
            ),
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
                    color: theme.colorScheme.primary,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  descricao,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                trailing,
              ],
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
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) {
        setState(() {});
        _marcarAlteracao();
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: (novo) {
        onChanged(novo);
        _marcarAlteracao();
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        ),
      )
          .toList(),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: (novo) {
              onChanged(novo);
              _marcarAlteracao();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector({
    required String label,
    required Color color,
    required ValueChanged<Color> onColorSelected,
  }) {
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
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: opcoes.map((opcao) {
              final selecionado = opcao.value == color.value;
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
                      color: selecionado ? Colors.black : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: selecionado
                      ? const Icon(Icons.check_rounded, color: Colors.white)
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.drag_indicator_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutChip(String label) {
    return Chip(
      label: Text(label),
      avatar: const Icon(Icons.flash_on_rounded, size: 18),
      onDeleted: () {
        setState(() {
          _atalhosFavoritos.remove(label);
        });
        _marcarAlteracao();
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  Widget _buildFloatingActions() {
    final theme = Theme.of(context);

    Widget secondaryAction({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: Ink(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.30),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.embedded && widget.onBack != null) ...[
                secondaryAction(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Voltar',
                  onPressed: widget.onBack!,
                ),
                const SizedBox(height: 10),
              ],
              secondaryAction(
                icon: Icons.restart_alt_rounded,
                tooltip: 'Restaurar padrão',
                onPressed: _restaurarPadraoDaSecao,
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _salvarConfiguracoes,
                  child: Ink(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.save_rounded,
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Salvar',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildSecaoGeral() {
    return Column(
      children: [
        _buildSectionHeader(
          titulo: 'Configurações institucionais',
          descricao: _descricaoSecao(SecaoConfiguracaoSix.geral),
          icone: Icons.apartment_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Identidade do comércio',
          subtitle:
          'Informações usadas em cabeçalhos de documentos, relatórios, ordens de serviço e comunicações da loja.',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
            ),
            child: Text(
              'Obrigatório',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 320,
                child: _buildTextField(
                  label: 'Nome da empresa',
                  controller: _nomeEmpresaController,
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildTextField(
                  label: 'Nome fantasia',
                  controller: _nomeFantasiaController,
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildTextField(
                  label: 'Documento fiscal',
                  controller: _documentoFiscalController,
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildTextField(
                  label: 'Telefone',
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildTextField(
                  label: 'WhatsApp',
                  controller: _whatsAppController,
                  keyboardType: TextInputType.phone,
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildTextField(
                  label: 'Email principal',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildTextField(
                  label: 'Site',
                  controller: _siteController,
                ),
              ),
              SizedBox(
                width: 656,
                child: _buildTextField(
                  label: 'Endereço',
                  controller: _enderecoController,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Branding institucional',
          subtitle:
          'Estruture a apresentação da marca para a web, PDFs e comunicações futuras do sistema.',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildSwitchTile(
                title: 'Exibir nome fantasia como principal',
                subtitle:
                'Quando ativo, o Six prioriza o nome fantasia em documentos e cabeçalhos.',
                value: true,
                onChanged: (_) {},
              ),
              _buildSwitchTile(
                title: 'Permitir capa personalizada na web',
                subtitle:
                'Prepara a plataforma para futura imagem institucional na tela de login web.',
                value: true,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoRegionalizacao() {
    return Column(
      children: [
        _buildSectionHeader(
          titulo: 'Idioma, região e moeda',
          descricao: _descricaoSecao(SecaoConfiguracaoSix.regionalizacao),
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
                    'Polski',
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _idiomaSelecionado = valor!;
                    });
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
                  items: const [
                    'dd/MM/yyyy',
                    'MM/dd/yyyy',
                    'yyyy-MM-dd',
                  ],
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
                  items: const [
                    '24 horas',
                    '12 horas',
                  ],
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
                  items: const [
                    'Segunda-feira',
                    'Domingo',
                  ],
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
                  items: const [
                    '1.234,56',
                    '1,234.56',
                  ],
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
                        'BRL - Real Brasileiro (R\$)',
                        'USD - US Dollar (\$)',
                        'EUR - Euro (€)',
                        'PLN - Złoty (zł)',
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
                      items: const [
                        'Antes do valor',
                        'Depois do valor',
                      ],
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
                      items: const [
                        '0',
                        '2',
                        '3',
                      ],
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
                      items: const [
                        'Vírgula',
                        'Ponto',
                      ],
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
                      items: const [
                        'Ponto',
                        'Vírgula',
                        'Espaço',
                      ],
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
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Tema do sistema',
                  value: _temaSelecionado,
                  items: const [
                    'Claro',
                    'Escuro',
                    'Automático',
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _temaSelecionado = valor!;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Densidade visual',
                  value: _densidadeSelecionada,
                  items: const [
                    'Confortável',
                    'Compacta',
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _densidadeSelecionada = valor!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Paleta do sistema',
          subtitle:
          'Essas cores serão úteis para branding do comércio, dashboards e futura personalização premium.',
          child: Wrap(
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
                  },
                ),
              ),
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
                  items: const [
                    'WhatsApp',
                    'Email',
                    'Telegram',
                    'SMS',
                  ],
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
    return Column(
      children: [
        _buildSectionHeader(
          titulo: 'Documentos, PDFs e comprovantes',
          descricao: _descricaoSecao(SecaoConfiguracaoSix.documentos),
          icone: Icons.picture_as_pdf_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Modelos principais',
          subtitle:
          'Escolha os padrões visuais que serão aplicados em orçamentos, ordem de serviço e comprovantes.',
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Modelo de orçamento',
                  value: _modeloOrcamentoSelecionado,
                  items: const [
                    'Modelo corporativo moderno',
                    'Modelo técnico detalhado',
                    'Modelo comercial enxuto',
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _modeloOrcamentoSelecionado = valor!;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Modelo de ordem de serviço',
                  value: _modeloOrdemServicoSelecionado,
                  items: const [
                    'Modelo técnico com checklist',
                    'Modelo padrão resumido',
                    'Modelo com termos ampliados',
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _modeloOrdemServicoSelecionado = valor!;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Modelo de recibo',
                  value: _modeloReciboSelecionado,
                  items: const [
                    'Modelo enxuto com logo',
                    'Modelo fiscal completo',
                    'Modelo simples',
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _modeloReciboSelecionado = valor!;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Tamanho do papel',
                  value: _tamanhoPapelSelecionado,
                  items: const [
                    'A4',
                    'Carta',
                    '80mm térmico',
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _tamanhoPapelSelecionado = valor!;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Idioma do documento',
                  value: _idiomaDocumentoSelecionado,
                  items: const [
                    'Mesmo idioma do sistema',
                    'Português (Brasil)',
                    'English (US)',
                    'Español',
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _idiomaDocumentoSelecionado = valor!;
                    });
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: _buildDropdownField(
                  label: 'Moeda do documento',
                  value: _moedaDocumentoSelecionada,
                  items: const [
                    'Mesma moeda da empresa',
                    'BRL',
                    'USD',
                    'EUR',
                  ],
                  onChanged: (valor) {
                    setState(() {
                      _moedaDocumentoSelecionada = valor!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Composição visual do PDF',
          subtitle:
          'Ajustes que impactam o compartilhamento via email, WhatsApp e a apresentação final do documento.',
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 420,
                    child: _buildSwitchTile(
                      title: 'Exibir logo no PDF',
                      subtitle: 'Inclui a identidade da empresa no cabeçalho.',
                      value: _exibirLogoNoPdf,
                      onChanged: (valor) {
                        setState(() {
                          _exibirLogoNoPdf = valor;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 420,
                    child: _buildSwitchTile(
                      title: 'Exibir assinatura do cliente',
                      subtitle:
                      'Mantém a tela pronta para futuros fluxos de assinatura.',
                      value: _exibirAssinaturaCliente,
                      onChanged: (valor) {
                        setState(() {
                          _exibirAssinaturaCliente = valor;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 420,
                    child: _buildSwitchTile(
                      title: 'Exibir QR Code',
                      subtitle:
                      'Pode ser usado para validação, consulta ou link temporário no futuro.',
                      value: _exibirQrCode,
                      onChanged: (valor) {
                        setState(() {
                          _exibirQrCode = valor;
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
                    width: 460,
                    child: _buildTextField(
                      label: 'Rodapé padrão',
                      controller: _rodapeDocumentoController,
                      maxLines: 3,
                    ),
                  ),
                  SizedBox(
                    width: 460,
                    child: _buildTextField(
                      label: 'Termos e condições',
                      controller: _termosCondicoesController,
                      maxLines: 5,
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

  Widget _buildSecaoOperacao() {
    return Column(
      children: [
        _buildSectionHeader(
          titulo: 'Regras operacionais do comércio',
          descricao: _descricaoSecao(SecaoConfiguracaoSix.operacao),
          icone: Icons.settings_suggest_rounded,
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Venda, estoque e caixa',
          subtitle:
          'Defina o comportamento operacional padrão do Six no balcão e na rotina do caixa.',
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: 420,
                    child: _buildSwitchTile(
                      title: 'Controlar estoque',
                      subtitle:
                      'Atualiza saldo de produtos e permite relatórios operacionais.',
                      value: _controlarEstoque,
                      onChanged: (valor) {
                        setState(() {
                          _controlarEstoque = valor;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 420,
                    child: _buildSwitchTile(
                      title: 'Exigir cliente na venda',
                      subtitle:
                      'Garante rastreabilidade de compras e histórico por pessoa.',
                      value: _exigirClienteNaVenda,
                      onChanged: (valor) {
                        setState(() {
                          _exigirClienteNaVenda = valor;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 420,
                    child: _buildSwitchTile(
                      title: 'Abertura de caixa obrigatória',
                      subtitle:
                      'Impede operações antes da abertura formal do caixa.',
                      value: _abrirCaixaObrigatorio,
                      onChanged: (valor) {
                        setState(() {
                          _abrirCaixaObrigatorio = valor;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 420,
                    child: _buildSwitchTile(
                      title: 'Permitir venda sem estoque',
                      subtitle:
                      'Útil para cenários específicos, mas exige cuidado operacional.',
                      value: _permitirVendaSemEstoque,
                      onChanged: (valor) {
                        setState(() {
                          _permitirVendaSemEstoque = valor;
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 420,
                    child: _buildSwitchTile(
                      title: 'Gerar comissão para colaborador',
                      subtitle:
                      'Prepara o sistema para metas, comissão e dashboards futuros.',
                      value: _gerarComissaoColaborador,
                      onChanged: (valor) {
                        setState(() {
                          _gerarComissaoColaborador = valor;
                        });
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
                      onChanged: (valor) {
                        setState(() {
                          _permitirEdicaoAposFechamento = valor;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Política de desconto',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Defina se o operador pode conceder descontos e qual limite padrão.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 420,
                          child: _buildSwitchTile(
                            title: 'Permitir desconto manual',
                            subtitle:
                            'Libera desconto direto pelo operador no fluxo.',
                            value: _descontoManualPermitido,
                            onChanged: (valor) {
                              setState(() {
                                _descontoManualPermitido = valor;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 420,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Limite máximo de desconto: ${_limiteDesconto.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Slider(
                                value: _limiteDesconto,
                                min: 0,
                                max: 50,
                                divisions: 10,
                                label: '${_limiteDesconto.toStringAsFixed(0)}%',
                                onChanged: (valor) {
                                  setState(() {
                                    _limiteDesconto = valor;
                                  });
                                  _marcarAlteracao();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildBigCard(
          title: 'Assistência técnica',
          subtitle:
          'Parametrize o fluxo de reparo para refletir a operação real da loja.',
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
                      title: 'Exigir número de série / IMEI',
                      subtitle:
                      'Ajuda a identificar corretamente o equipamento recebido.',
                      value: _exigirSerialImei,
                      onChanged: (valor) {
                        setState(() {
                          _exigirSerialImei = valor;
                        });
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
                      onChanged: (valor) {
                        setState(() {
                          _exigirTecnicoResponsavel = valor;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Fluxo de status da assistência',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mock de status já preparado para futura persistência e personalização por comércio.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        ),
      ],
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
                  items: const [
                    '2 horas',
                    '8 horas',
                    '12 horas',
                    '24 horas',
                  ],
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
          descricao:
          _descricaoSecao(SecaoConfiguracaoSix.preferenciasUsuario),
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
                  subtitle:
                  'Ajuda novos operadores durante a curva de adoção.',
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool layoutEmpilhado = constraints.maxWidth < 1180;

          if (layoutEmpilhado) {
            return Column(
              children: [
                _buildMenuLateralSecoes(),
                const SizedBox(height: 20),
                _buildConteudoSecao(),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 300,
                child: _buildMenuLateralSecoes(),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildConteudoSecao(),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_mostrarResumoLateral) ...[
            _buildResumoSidebar(),
            const SizedBox(width: 20),
          ] else ...[
            _buildResumoSidebarCollapsed(),
          ],
          Expanded(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: _buildConteudoPrincipal(),
              ),
            ),
          ),
        ],
      ),
    );

    final contentWithFab = Stack(
      children: [
        Positioned.fill(child: bodyContent),
        Positioned(
          right: 36,
          bottom: 36,
          child: _buildFloatingActions(),
        )
      ],
    );

    if (widget.embedded) {
      return contentWithFab;
    }

    return Scaffold(
      body: SafeArea(child: contentWithFab),
    );
  }

}