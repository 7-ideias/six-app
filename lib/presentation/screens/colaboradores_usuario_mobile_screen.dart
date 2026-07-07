import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sixpos/core/config/app_config.dart';
import 'package:sixpos/core/services/colaborador_convite_web_service.dart';
import 'package:sixpos/data/models/colaborador_convite_model.dart';
import 'package:sixpos/data/models/colaborador_usuario_model.dart';
import 'package:sixpos/data/services/colaborador_usuario/colaborador_usuario_api_client.dart';

class ColaboradoresUsuarioMobileScreen extends StatefulWidget {
  const ColaboradoresUsuarioMobileScreen({super.key, this.apiClient});

  final ColaboradorUsuarioApiClient? apiClient;

  @override
  State<ColaboradoresUsuarioMobileScreen> createState() =>
      _ColaboradoresUsuarioMobileScreenState();
}

class _ColaboradoresUsuarioMobileScreenState
    extends State<ColaboradoresUsuarioMobileScreen> {
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _secondaryColor = Color(0xFF123B69);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  late final ColaboradorUsuarioApiClient _api;
  final TextEditingController _search = TextEditingController();
  final NumberFormat _number = NumberFormat.decimalPattern('pt_BR');
  final DateFormat _date = DateFormat('dd/MM/yyyy', 'pt_BR');

  bool _loading = false;
  String? _erro;
  String _filter = '';
  List<ColaboradorUsuarioResumo> _colaboradores = <ColaboradorUsuarioResumo>[];

  List<ColaboradorUsuarioResumo> get _items {
    final String term = _filter
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');

    if (term.isEmpty) {
      return _colaboradores;
    }

    return _colaboradores.where((ColaboradorUsuarioResumo colaborador) {
      final String source =
          '${colaborador.nome} ${colaborador.nomeDeGuerra} ${colaborador.email} ${colaborador.celularDeAcesso}'
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]'), '');
      return source.contains(term);
    }).toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _api = widget.apiClient ?? HttpColaboradorUsuarioApiClient();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final List<ColaboradorUsuarioResumo> data =
          await _api.listarColaboradores();
      if (!mounted) {
        return;
      }
      setState(() {
        _colaboradores = data;
        _loading = false;
      });
    } on ColaboradorUsuarioApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _erro = _message(error.statusCode);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _erro = 'Não foi possível carregar a lista de colaboradores.';
      });
    }
  }

  String _message(int code) {
    switch (code) {
      case 400:
        return 'Dados inválidos ou empresa não informada.';
      case 401:
        return 'Sessão expirada. Faça login novamente.';
      case 403:
        return 'Usuário sem vínculo com a empresa.';
      default:
        return 'Erro ao carregar colaboradores (HTTP $code).';
    }
  }

  Future<void> _openNovoColaborador() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(bottomSheetContext).bottom,
          ),
          child: const _ColaboradorConviteMobileSheet(),
        );
      },
    );

    if (mounted) {
      _reload();
    }
  }

  Future<void> _openEditar(ColaboradorUsuarioResumo resumo) async {
    try {
      final ColaboradorUsuarioDetalhe detalhe =
          await _api.buscarColaborador(resumo.idUnicoPessoal);
      if (!mounted) {
        return;
      }

      final Map<String, dynamic>? payload =
          await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext bottomSheetContext) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(bottomSheetContext).bottom,
            ),
            child: _EditarColaboradorMobileSheet(
              resumo: resumo,
              detalhe: detalhe,
            ),
          );
        },
      );

      if (payload == null) {
        return;
      }

      await _api.editarColaborador(payload);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colaborador atualizado com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _reload();
    } on ColaboradorUsuarioApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_message(error.statusCode)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Colaboradores',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _body()),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _openNovoColaborador,
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Novo colaborador'),
      ),
    );
  }

  Widget _body() {
    if (_loading && _colaboradores.isEmpty) {
      return const _MobileColaboradoresLoading();
    }

    if (_erro != null && _colaboradores.isEmpty) {
      return _errorState();
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: <Widget>[
          _headerCard(),
          const SizedBox(height: 14),
          _summaryRow(),
          const SizedBox(height: 14),
          _searchBox(),
          if (_erro != null) ...<Widget>[
            const SizedBox(height: 12),
            _inlineError(_erro!),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Colaboradores encontrados',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _borderColor),
                ),
                child: Text(
                  _number.format(_items.length),
                  style: const TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_items.isEmpty) _emptyState() else ..._items.map(_colaboradorCard),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[_primaryColor, _secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x220B1F3A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: const Icon(Icons.badge_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Equipe do comércio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Convide, acompanhe e ajuste permissões dos colaboradores.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.82),
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

  Widget _summaryRow() {
    final int comEmail = _colaboradores
        .where((ColaboradorUsuarioResumo item) => item.email.trim().isNotEmpty)
        .length;
    final int comCelular = _colaboradores
        .where(
          (ColaboradorUsuarioResumo item) =>
              item.celularDeAcesso.trim().isNotEmpty,
        )
        .length;
    final int incompletos = _colaboradores
        .where((ColaboradorUsuarioResumo item) => item.nome.trim().isEmpty)
        .length;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _summaryCard(
                Icons.groups_2_outlined,
                'Equipe',
                _number.format(_colaboradores.length),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                Icons.alternate_email_rounded,
                'Com e-mail',
                _number.format(comEmail),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _summaryCard(
                Icons.phone_iphone_rounded,
                'Com celular',
                _number.format(comCelular),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _summaryCard(
                Icons.manage_accounts_outlined,
                'Incompleto',
                _number.format(incompletos),
                highlight: incompletos > 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final Color iconColor = highlight ? Colors.orange.shade800 : _primaryColor;
    final Color bgColor = highlight ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _mutedTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _titleTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: TextField(
        controller: _search,
        onChanged: (String value) => setState(() => _filter = value),
        decoration: InputDecoration(
          hintText: 'Buscar colaborador...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _search.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _search.clear();
                    setState(() => _filter = '');
                  },
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
        ),
      ),
    );
  }

  Widget _colaboradorCard(ColaboradorUsuarioResumo colaborador) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(
                  _initials(colaborador.nome),
                  style: const TextStyle(
                    color: _primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      colaborador.nome.isEmpty
                          ? 'Colaborador sem nome'
                          : colaborador.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _titleTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      colaborador.nomeDeGuerra.isEmpty
                          ? 'Sem nome de guerra'
                          : colaborador.nomeDeGuerra,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _status('Ativo'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _chip(
                Icons.mail_outline,
                colaborador.email.isEmpty ? 'Sem e-mail' : colaborador.email,
              ),
              _chip(
                Icons.phone_outlined,
                colaborador.celularDeAcesso.isEmpty
                    ? 'Sem celular'
                    : colaborador.celularDeAcesso,
              ),
              _chip(Icons.badge_outlined, colaborador.idUnicoPessoal),
            ],
          ),
          const SizedBox(height: 12),
          _accessHint(colaborador),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDetails(colaborador),
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  label: const Text('Resumo'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _openEditar(colaborador),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Editar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: _primaryColor),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(String label) {
    final Color color = Colors.green.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _accessHint(ColaboradorUsuarioResumo colaborador) {
    final bool semEmail = colaborador.email.trim().isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: semEmail ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: semEmail ? const Color(0xFFFED7AA) : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            semEmail
                ? Icons.warning_amber_rounded
                : Icons.admin_panel_settings_outlined,
            color: semEmail ? Colors.orange.shade800 : _primaryColor,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              semEmail
                  ? 'Informe um e-mail para liberar vínculo de acesso.'
                  : 'Acesso controlado por convite e permissões.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.group_add_outlined, color: _primaryColor),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhum colaborador encontrado',
            style: TextStyle(
              color: _titleTextColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Convide colaboradores para vendas, atendimento e gestão diária.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _mutedTextColor),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _openNovoColaborador,
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Novo colaborador'),
          ),
        ],
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cloud_off_rounded, size: 44, color: _primaryColor),
            const SizedBox(height: 12),
            Text(
              _erro ?? 'Não foi possível carregar os colaboradores.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineError(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.35),
      ),
      child: Text(message),
    );
  }

  void _showDetails(ColaboradorUsuarioResumo colaborador) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (BuildContext bottomSheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                colaborador.nome.isEmpty ? 'Colaborador' : colaborador.nome,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              _detailRow(
                'Nome guerra',
                colaborador.nomeDeGuerra.isEmpty ? '-' : colaborador.nomeDeGuerra,
              ),
              _detailRow(
                'Celular',
                colaborador.celularDeAcesso.isEmpty
                    ? '-'
                    : colaborador.celularDeAcesso,
              ),
              _detailRow('E-mail', colaborador.email.isEmpty ? '-' : colaborador.email),
              _detailRow(
                'Cadastro',
                colaborador.dataCadastro == null
                    ? '-'
                    : _date.format(colaborador.dataCadastro!),
              ),
              _detailRow('Identificador', colaborador.idUnicoPessoal),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(bottomSheetContext).pop(),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: _mutedTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final List<String> parts =
        name.trim().split(' ').where((String item) => item.isNotEmpty).toList();
    if (parts.isEmpty) {
      return 'CO';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ColaboradorConviteMobileSheet extends StatefulWidget {
  const _ColaboradorConviteMobileSheet();

  @override
  State<_ColaboradorConviteMobileSheet> createState() =>
      _ColaboradorConviteMobileSheetState();
}

class _ColaboradorConviteMobileSheetState
    extends State<_ColaboradorConviteMobileSheet> {
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ColaboradorConviteWebService _service = ColaboradorConviteWebService();
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _celular = TextEditingController(text: '+55');

  bool _fazVenda = true;
  bool _lancaServico = true;
  bool _editaCliente = true;
  bool _acessaFinanceiro = false;
  bool _geraRelatorio = false;
  bool _gerenciaPermissoes = false;
  bool _loading = false;
  ColaboradorConviteResponse? _convite;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _celular.dispose();
    super.dispose();
  }

  Future<void> _criarConvite() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _convite = null;
    });

    try {
      final ColaboradorConviteResponse response = await _service.criarConvite(
        ColaboradorConviteRequest(
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          celular: _celular.text.trim(),
          permissoes: _permissoesSelecionadas(),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() => _convite = response);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Convite de colaborador criado com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceAll('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<String> _permissoesSelecionadas() {
    return <String>[
      if (_fazVenda) 'VENDAS_CRIAR',
      if (_lancaServico) 'ASSISTENCIA_TECNICA_CRIAR',
      if (_editaCliente) 'CLIENTES_EDITAR',
      if (_acessaFinanceiro) 'FINANCEIRO_ACESSAR',
      if (_geraRelatorio) 'RELATORIOS_GERAR',
      if (_gerenciaPermissoes) 'PERMISSOES_GERENCIAR',
    ];
  }

  String _linkConvite(ColaboradorConviteResponse convite) {
    final Uri publicUrl = Uri.parse(AppConfig.autoCustomerBaseUrl);
    final String origin = publicUrl.hasScheme && publicUrl.host.isNotEmpty
        ? publicUrl.origin
        : Uri.base.origin;
    return '$origin/colaborador/convites/${convite.codigo}';
  }

  Future<void> _copiarLink() async {
    final ColaboradorConviteResponse? convite = _convite;
    if (convite == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: _linkConvite(convite)));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link do convite copiado.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColaboradorConviteResponse? convite = _convite;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.group_add_outlined, color: _primaryColor),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Novo colaborador',
                          style: TextStyle(
                            color: _titleTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Gere um convite com permissões iniciais.',
                          style: TextStyle(color: _mutedTextColor, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nome,
                decoration: _input('Nome do colaborador', Icons.person_outline),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty ? 'Informe o nome.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: _input('E-mail de login', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
                validator: (String? value) => value == null || value.trim().isEmpty
                    ? 'Informe o e-mail.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _celular,
                decoration: _input('Celular', Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              Text(
                'Permissões iniciais',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _switchCard(
                'Vendas',
                'Pode criar vendas.',
                _fazVenda,
                (bool value) => setState(() => _fazVenda = value),
              ),
              _switchCard(
                'Assistência técnica',
                'Pode lançar atendimentos técnicos.',
                _lancaServico,
                (bool value) => setState(() => _lancaServico = value),
              ),
              _switchCard(
                'Clientes',
                'Pode editar clientes.',
                _editaCliente,
                (bool value) => setState(() => _editaCliente = value),
              ),
              _switchCard(
                'Financeiro',
                'Pode acessar financeiro.',
                _acessaFinanceiro,
                (bool value) => setState(() => _acessaFinanceiro = value),
              ),
              _switchCard(
                'Relatórios',
                'Pode gerar relatórios.',
                _geraRelatorio,
                (bool value) => setState(() => _geraRelatorio = value),
              ),
              _switchCard(
                'Permissões',
                'Pode gerenciar permissões.',
                _gerenciaPermissoes,
                (bool value) => setState(() => _gerenciaPermissoes = value),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _criarConvite,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_loading ? 'Gerando convite...' : 'Gerar convite'),
                ),
              ),
              if (convite != null) ...<Widget>[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Convite criado',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _linkConvite(convite),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _copiarLink,
                          icon: const Icon(Icons.copy_outlined),
                          label: const Text('Copiar link'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _switchCard(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _EditarColaboradorMobileSheet extends StatefulWidget {
  const _EditarColaboradorMobileSheet({
    required this.resumo,
    required this.detalhe,
  });

  final ColaboradorUsuarioResumo resumo;
  final ColaboradorUsuarioDetalhe detalhe;

  @override
  State<_EditarColaboradorMobileSheet> createState() =>
      _EditarColaboradorMobileSheetState();
}

class _EditarColaboradorMobileSheetState
    extends State<_EditarColaboradorMobileSheet> {
  static const Color _primaryColor = Color(0xFF0B1F3A);
  static const Color _backgroundColor = Color(0xFFF4F7FB);
  static const Color _mutedTextColor = Color(0xFF64748B);
  static const Color _titleTextColor = Color(0xFF0F172A);
  static const Color _borderColor = Color(0xFFE2E8F0);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _nomeDeGuerra;
  late final TextEditingController _email;
  late final TextEditingController _celular;

  bool _podeVender = false;
  bool _podeServico = false;
  bool _podeEditarCliente = false;
  bool _podeRelatorio = false;
  bool _podeFinanceiro = false;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(
      text: widget.detalhe.nome.isNotEmpty
          ? widget.detalhe.nome
          : widget.resumo.nome,
    );
    _nomeDeGuerra = TextEditingController(
      text: widget.detalhe.nomeDeGuerra.isNotEmpty
          ? widget.detalhe.nomeDeGuerra
          : widget.resumo.nomeDeGuerra,
    );
    _email = TextEditingController(
      text: widget.detalhe.email.isNotEmpty
          ? widget.detalhe.email
          : widget.resumo.email,
    );
    _celular = TextEditingController(
      text: widget.detalhe.celularDeAcesso.isNotEmpty
          ? widget.detalhe.celularDeAcesso
          : widget.resumo.celularDeAcesso,
    );

    final Map<String, dynamic> json = widget.detalhe.toJson();
    final Map<String, dynamic> autorizacoes = _ensureMap(json['objAutorizacoes']);
    _podeVender = _ensureMap(autorizacoes['objVendasPode'])['fazVenda'] == true;
    _podeServico =
        _ensureMap(autorizacoes['objAssistenciaTecnicaPode'])['lancaServico'] ==
            true;
    _podeEditarCliente =
        _ensureMap(autorizacoes['objClientesPode'])['podeEditarCliente'] == true;
    _podeRelatorio =
        _ensureMap(autorizacoes['objRelatoriosPode'])['geraRelatorioDeVendas'] ==
            true;
    final Map<String, dynamic> financeiro =
        _ensureMap(autorizacoes['objLancamentosFinanceirosPode']);
    _podeFinanceiro = financeiro['podeReceberNoCaixa'] == true ||
        financeiro['podeVerQuantoVendeu'] == true;
  }

  @override
  void dispose() {
    _nome.dispose();
    _nomeDeGuerra.dispose();
    _email.dispose();
    _celular.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    final Map<String, dynamic> json = widget.detalhe.toJson();
    final Map<String, dynamic> info = _ensureMap(json['objInformacoesDoCadastro']);
    info['idUnicoDoUsuario'] = widget.resumo.idUnicoPessoal;
    json['objInformacoesDoCadastro'] = info;
    json['celularDeAcesso'] = _celular.text.trim();
    json['senhaParaPermitirOAcessoDoColaborador'] = null;

    final Map<String, dynamic> pessoa = _ensureMap(json['objPessoa']);
    pessoa['nome'] = _nome.text.trim();
    pessoa['nomeDeGuerra'] = _nomeDeGuerra.text.trim();
    pessoa['email'] = _email.text.trim();
    pessoa['celular'] = _celular.text.trim();
    pessoa['senha'] = null;
    json['objPessoa'] = pessoa;

    final Map<String, dynamic> autorizacoes = _ensureMap(json['objAutorizacoes']);
    autorizacoes['podeCadastrarProduto'] =
        autorizacoes['podeCadastrarProduto'] ?? false;
    autorizacoes['podeFazerDevolucao'] =
        autorizacoes['podeFazerDevolucao'] ?? false;
    autorizacoes['objVendasPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objVendasPode']),
      'fazVenda': _podeVender,
    };
    autorizacoes['objAssistenciaTecnicaPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objAssistenciaTecnicaPode']),
      'lancaServico': _podeServico,
    };
    autorizacoes['objClientesPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objClientesPode']),
      'podeEditarCliente': _podeEditarCliente,
    };
    autorizacoes['objRelatoriosPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objRelatoriosPode']),
      'geraRelatorioDeVendas': _podeRelatorio,
    };
    autorizacoes['objLancamentosFinanceirosPode'] = <String, dynamic>{
      ..._ensureMap(autorizacoes['objLancamentosFinanceirosPode']),
      'podeReceberNoCaixa': _podeFinanceiro,
      'podeVerQuantoVendeu': _podeFinanceiro,
    };
    json['objAutorizacoes'] = autorizacoes;
    return json;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.edit_outlined, color: _primaryColor),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Editar colaborador',
                          style: TextStyle(
                            color: _titleTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Atualize dados de acesso e permissões.',
                          style: TextStyle(color: _mutedTextColor, height: 1.25),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nome,
                decoration: _input('Nome', Icons.person_outline),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty ? 'Informe o nome.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nomeDeGuerra,
                decoration: _input('Nome de guerra', Icons.badge_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: _input('E-mail', Icons.email_outlined),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _celular,
                decoration: _input('Celular', Icons.phone_outlined),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              Text(
                'Permissões operacionais',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              _switchCard(
                'Vendas',
                'Pode realizar vendas no comércio.',
                _podeVender,
                (bool value) => setState(() => _podeVender = value),
              ),
              _switchCard(
                'Assistência técnica',
                'Pode lançar serviços técnicos.',
                _podeServico,
                (bool value) => setState(() => _podeServico = value),
              ),
              _switchCard(
                'Clientes',
                'Pode editar dados de clientes.',
                _podeEditarCliente,
                (bool value) => setState(() => _podeEditarCliente = value),
              ),
              _switchCard(
                'Relatórios',
                'Pode gerar relatórios de vendas.',
                _podeRelatorio,
                (bool value) => setState(() => _podeRelatorio = value),
              ),
              _switchCard(
                'Financeiro',
                'Pode acessar recebimentos e valores vendidos.',
                _podeFinanceiro,
                (bool value) => setState(() => _podeFinanceiro = value),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        Navigator.of(context).pop(_payload());
                      },
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _switchCard(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: _mutedTextColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  static Map<String, dynamic> _ensureMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }
}

class _MobileColaboradoresLoading extends StatelessWidget {
  const _MobileColaboradoresLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: const <Widget>[
        _LoadingBlock(height: 96),
        SizedBox(height: 14),
        Row(
          children: <Widget>[
            Expanded(child: _LoadingBlock(height: 104)),
            SizedBox(width: 10),
            Expanded(child: _LoadingBlock(height: 104)),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(child: _LoadingBlock(height: 104)),
            SizedBox(width: 10),
            Expanded(child: _LoadingBlock(height: 104)),
          ],
        ),
        SizedBox(height: 14),
        _LoadingBlock(height: 76),
        SizedBox(height: 16),
        _LoadingBlock(height: 190),
        SizedBox(height: 12),
        _LoadingBlock(height: 190),
      ],
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
    );
  }
}
