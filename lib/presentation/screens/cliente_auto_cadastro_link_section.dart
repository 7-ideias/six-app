import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart' as sharing;
import 'package:sixpos/core/services/auth_service.dart';
import 'package:sixpos/core/services/auto_customer_token_service.dart';

Future<void> showClienteAutoCadastroLinkDialog(
  BuildContext context, {
  String? initialTipoPessoa,
  String? initialDocumento,
  bool actionsOnly = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.link_outlined, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Auto cadastro', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(
                            'Gere e compartilhe o link público para o cliente completar os dados.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClienteAutoCadastroLinkSection(
                  initialTipoPessoa: initialTipoPessoa,
                  initialDocumento: initialDocumento,
                  showAsCard: false,
                  actionsOnly: actionsOnly,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class ClienteAutoCadastroLinkSection extends StatefulWidget {
  const ClienteAutoCadastroLinkSection({
    super.key,
    this.initialTipoPessoa,
    this.initialDocumento,
    this.showAsCard = true,
    this.actionsOnly = false,
  });

  final String? initialTipoPessoa;
  final String? initialDocumento;
  final bool showAsCard;
  final bool actionsOnly;

  @override
  State<ClienteAutoCadastroLinkSection> createState() => _ClienteAutoCadastroLinkSectionState();
}

class _ClienteAutoCadastroLinkSectionState extends State<ClienteAutoCadastroLinkSection> {
  final AutoCustomerTokenService _autoCustomerTokenService = AutoCustomerTokenService();
  final TextEditingController _empresaController = TextEditingController();
  final TextEditingController _canalController = TextEditingController(text: 'WhatsApp');
  final TextEditingController _destinoController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _mensagemController = TextEditingController(
    text: 'Olá! Use este link para concluir seu auto-cadastro e liberar compras no crediário.',
  );

  bool _habilitado = true;
  bool _loading = false;
  late String _tipoPessoa;

  @override
  void initState() {
    super.initState();
    final String tipo = (widget.initialTipoPessoa ?? '').trim().toUpperCase();
    _tipoPessoa = tipo == 'PJ' ? 'PJ' : 'PF';
    _carregarEmpresa();
  }

  @override
  void dispose() {
    _empresaController.dispose();
    _canalController.dispose();
    _destinoController.dispose();
    _linkController.dispose();
    _mensagemController.dispose();
    super.dispose();
  }

  Future<void> _carregarEmpresa() async {
    final String empresaId = (await AuthService().getEmpresaId())?.trim() ?? '';
    if (!mounted || empresaId.isEmpty) return;
    setState(() => _empresaController.text = empresaId);
  }

  String _fallbackErroGeracaoLink(AutoCustomerTokenApiResponse response) {
    switch (response.statusCode) {
      case 403:
        return 'Usuário sem vínculo com a empresa selecionada.';
      case 404:
        return 'Empresa inválida ou não encontrada.';
      case 400:
        return 'Dados inválidos para gerar o link.';
      case 500:
        return 'Falha ao gerar token de auto-cadastro.';
      default:
        return 'Erro ao gerar link (HTTP ${response.statusCode}).';
    }
  }

  InputDecoration _dec(String label, IconData icon, {String? hintText}) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.error, width: 1.4),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
  }

  Future<String?> _gerarLink({bool mostrarMensagem = true}) async {
    final String empresaId = _empresaController.text.trim();
    if (empresaId.isEmpty) {
      _showSnack('Não foi possível identificar a empresa para gerar o link.');
      return null;
    }

    setState(() => _loading = true);
    try {
      final AutoCustomerTokenApiResponse response = await _autoCustomerTokenService.gerarToken(
        idUnicoDaEmpresa: empresaId,
        tipoPessoa: _tipoPessoa,
        documento: widget.initialDocumento,
        validadeMinutos: 1440,
      );

      if (!mounted) return null;
      final String message = response.message.trim().isNotEmpty
          ? response.message.trim()
          : (response.isSuccess ? 'Token de auto-cadastro criado com sucesso.' : _fallbackErroGeracaoLink(response));

      if (!response.isSuccess) {
        _showSnack(message);
        return null;
      }

      await Clipboard.setData(ClipboardData(text: response.link));
      setState(() => _linkController.text = response.link);
      if (mostrarMensagem) _showSnack('$message Link copiado para a área de transferência.');
      return response.link;
    } catch (error) {
      if (!mounted) return null;
      _showSnack('Falha ao gerar link: $error');
      return null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copiarLink() async {
    String link = _linkController.text.trim();
    if (link.isEmpty) link = (await _gerarLink(mostrarMensagem: false)) ?? '';
    if (link.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    _showSnack('Link de auto-cadastro copiado para a área de transferência.');
  }

  Future<void> _enviarLink() async {
    String link = _linkController.text.trim();
    if (link.isEmpty) link = (await _gerarLink(mostrarMensagem: false)) ?? '';
    if (link.isEmpty) return;

    final String mensagem = _mensagemController.text.trim().isEmpty
        ? 'Use este link para concluir seu auto-cadastro.'
        : _mensagemController.text.trim();
    final String textoCompartilhamento = <String>[mensagem, link].join('\n\n');
    await sharing.Share.share(textoCompartilhamento, subject: 'Auto-cadastro de cliente');
  }

  Widget _switchTile() {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _habilitado ? colorScheme.primary.withOpacity(0.05) : colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _habilitado ? colorScheme.primary.withOpacity(0.18) : colorScheme.outline.withOpacity(0.16)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Habilitar auto-cadastro', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  'Quando ativo, o cliente recebe um link para revisar e completar os dados.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(value: _habilitado, onChanged: _loading ? null : (bool value) => setState(() => _habilitado = value)),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hintText,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: _habilitado,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _dec(label, icon, hintText: hintText),
    );
  }

  List<Widget> _buildActions(bool compact) {
    return <Widget>[
      SizedBox(
        width: compact ? double.infinity : null,
        child: OutlinedButton.icon(
          onPressed: _loading ? null : () => _gerarLink(),
          icon: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.auto_awesome_outlined),
          label: Text(_loading ? 'Gerando...' : 'Gerar link'),
        ),
      ),
      SizedBox(
        width: compact ? double.infinity : null,
        child: OutlinedButton.icon(
          onPressed: _loading ? null : _copiarLink,
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copiar link'),
        ),
      ),
      SizedBox(
        width: compact ? double.infinity : null,
        child: FilledButton.icon(
          onPressed: _loading ? null : _enviarLink,
          icon: const Icon(Icons.send_outlined),
          label: const Text('Enviar para cliente'),
        ),
      ),
    ];
  }

  Widget _buildContent(BoxConstraints constraints) {
    final bool compact = constraints.maxWidth < 560;
    final bool actionsOnly = widget.actionsOnly || compact;
    final double smallFieldWidth = compact ? double.infinity : 220;
    final double largeFieldWidth = compact ? double.infinity : 320;
    final List<Widget> actions = _buildActions(compact);

    if (actionsOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int index = 0; index < actions.length; index++) ...<Widget>[
            actions[index],
            if (index < actions.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _switchTile(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: <Widget>[
            SizedBox(
              width: smallFieldWidth,
              child: DropdownButtonFormField<String>(
                value: _tipoPessoa,
                isExpanded: true,
                decoration: _dec('Tipo pessoa', Icons.apartment_outlined),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem<String>(value: 'PF', child: Text('PF')),
                  DropdownMenuItem<String>(value: 'PJ', child: Text('PJ')),
                ],
                onChanged: !_habilitado || _loading ? null : (String? value) => setState(() => _tipoPessoa = value ?? 'PF'),
              ),
            ),
            SizedBox(width: smallFieldWidth, child: _field(_canalController, 'Canal de envio', Icons.alt_route_outlined, hintText: 'WhatsApp, E-mail, SMS')),
            SizedBox(
              width: largeFieldWidth,
              child: _field(
                _destinoController,
                'Destino do envio',
                Icons.send_outlined,
                hintText: '+55... ou email@dominio.com',
                keyboardType: TextInputType.emailAddress,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _field(_linkController, 'Link de auto-cadastro', Icons.link, readOnly: true),
        const SizedBox(height: 16),
        _field(_mensagemController, 'Mensagem de convite', Icons.message_outlined, maxLines: compact ? 4 : 3),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, children: actions),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool actionsOnly = widget.actionsOnly || constraints.maxWidth < 560;
        final Widget content = _buildContent(constraints);
        if (!widget.showAsCard) return content;

        final ColorScheme colorScheme = Theme.of(context).colorScheme;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!actionsOnly) ...<Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.link_outlined, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Auto-cadastro por link', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          Text('Gere, copie e envie o link para o cliente finalizar cadastro.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
              ],
              content,
            ],
          ),
        );
      },
    );
  }
}
