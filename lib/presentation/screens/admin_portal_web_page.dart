import 'package:flutter/material.dart';

import '../../core/services/admin_portal_service.dart';
import '../../core/services/auth_service.dart';
import '../components/six_backend_loading.dart';

class AdminPortalWebPage extends StatefulWidget {
  const AdminPortalWebPage({super.key});

  @override
  State<AdminPortalWebPage> createState() => _AdminPortalWebPageState();
}

class _AdminPortalWebPageState extends State<AdminPortalWebPage> {
  final AdminPortalService _service = AdminPortalService();
  final AuthService _authService = AuthService();

  bool _carregando = true;
  bool _saindo = false;
  AdminPortalResumo? _resumo;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final AdminPortalResumo resumo = await _service.buscarResumo();
      if (!mounted) return;
      setState(() {
        _resumo = resumo;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      final String mensagem = e.toString().replaceAll('Exception: ', '');
      if (mensagem.toLowerCase().contains('login') || mensagem.toLowerCase().contains('sessão')) {
        Navigator.of(context).pushNamedAndRemoveUntil('/admin', (Route<dynamic> route) => false);
        return;
      }
      setState(() {
        _erro = mensagem;
        _carregando = false;
      });
    }
  }

  Future<void> _logout() async {
    if (_saindo) return;
    setState(() => _saindo = true);
    try {
      await _authService.logout();
    } finally {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/admin', (Route<dynamic> route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _AdminBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _HeaderCard(
                        saindo: _saindo,
                        onLogout: _logout,
                        onRefresh: _carregarResumo,
                        carregando: _carregando,
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _buildContent(theme),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_carregando) {
      return const _AdminGlassCard(
        key: ValueKey<String>('loading'),
        child: SixBackendLoading(
          title: 'Carregando portal administrativo',
          subtitle: 'Buscando indicadores gerais do sistema.',
          animation: SixBackendLoadingAnimation.skeletonPulse,
        ),
      );
    }

    if (_erro != null) {
      return _AdminGlassCard(
        key: const ValueKey<String>('error'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 42),
            const SizedBox(height: 12),
            Text('Não foi possível carregar o resumo.', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(_erro!, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _carregarResumo,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final AdminPortalResumo resumo = _resumo ?? const AdminPortalResumo(totalEmpresasCadastradas: 0, totalEmpresasAtivas: 0);
    final AdminBancoDadosResumo? bancoPrincipal = resumo.bancosDeDados.isNotEmpty ? resumo.bancosDeDados.first : null;
    final AdminActuatorResumo? actuator = resumo.actuator;

    return Column(
      key: const ValueKey<String>('dashboard'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compacto = constraints.maxWidth < 760;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: <Widget>[
                SizedBox(
                  width: compacto ? constraints.maxWidth : (constraints.maxWidth - 16) / 2,
                  child: _AdminMetricCard(
                    icon: Icons.business_rounded,
                    title: 'Empresas cadastradas',
                    value: resumo.totalEmpresasCadastradas.toString(),
                    subtitle: 'Total de empresas existentes no sistema.',
                  ),
                ),
                SizedBox(
                  width: compacto ? constraints.maxWidth : (constraints.maxWidth - 16) / 2,
                  child: _AdminMetricCard(
                    icon: Icons.verified_rounded,
                    title: 'Empresas ativas',
                    value: resumo.totalEmpresasAtivas.toString(),
                    subtitle: 'Empresas atualmente marcadas como ativas.',
                  ),
                ),
              ],
            );
          },
        ),
        if (bancoPrincipal != null) ...<Widget>[
          const SizedBox(height: 16),
          _BancoDadosResumoSection(banco: bancoPrincipal),
        ],
        if (resumo.bancosDeDados.length > 1) ...<Widget>[
          const SizedBox(height: 16),
          _BancosDadosListaSection(bancos: resumo.bancosDeDados),
        ],
        if (actuator != null) ...<Widget>[
          const SizedBox(height: 16),
          _ActuatorResumoSection(actuator: actuator),
        ],
        const SizedBox(height: 16),
        const _AdminGlassCard(
          child: Row(
            children: <Widget>[
              Icon(Icons.construction_rounded, color: Color(0xFF123B69)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Novas configurações administrativas serão adicionadas aqui conforme forem definidas.',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.saindo,
    required this.onLogout,
    required this.onRefresh,
    required this.carregando,
  });

  final bool saindo;
  final VoidCallback onLogout;
  final VoidCallback onRefresh;
  final bool carregando;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return _AdminGlassCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF0B1F3A), Color(0xFF2563EB)],
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.22), blurRadius: 20, offset: const Offset(0, 10)),
              ],
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Portal administrativo', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF0B1F3A))),
                const SizedBox(height: 4),
                const Text('Área inicial para manutenção e configurações globais do Six.'),
              ],
            ),
          ),
          const SizedBox(width: 14),
          OutlinedButton.icon(
            onPressed: carregando ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Atualizar'),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: saindo ? null : onLogout,
            icon: saindo
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.logout_rounded),
            label: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

class _BancoDadosResumoSection extends StatelessWidget {
  const _BancoDadosResumoSection({required this.banco});

  final AdminBancoDadosResumo banco;

  @override
  Widget build(BuildContext context) {
    return _AdminGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF123B69).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.storage_rounded, color: Color(0xFF123B69)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Banco de dados', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0B1F3A), fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('Banco principal: ${banco.nome}', style: TextStyle(color: Colors.black.withOpacity(0.58), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compacto = constraints.maxWidth < 820;
              final double width = compacto ? constraints.maxWidth : (constraints.maxWidth - 32) / 3;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width: width,
                    child: _AdminMetricCard.flat(
                      icon: Icons.data_object_rounded,
                      title: 'Dados',
                      value: _formatarBytes(banco.tamanhoDadosBytes),
                      subtitle: 'Volume lógico de documentos.',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _AdminMetricCard.flat(
                      icon: Icons.inventory_2_rounded,
                      title: 'Armazenado',
                      value: _formatarBytes(banco.tamanhoArmazenadoBytes),
                      subtitle: 'Espaço ocupado no storage.',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _AdminMetricCard.flat(
                      icon: Icons.speed_rounded,
                      title: 'Índices',
                      value: _formatarBytes(banco.tamanhoIndicesBytes),
                      subtitle: 'Espaço usado por índices.',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _InfoPill(label: 'Total', value: _formatarBytes(banco.tamanhoTotalBytes)),
              _InfoPill(label: 'Coleções/Tabelas', value: banco.quantidadeColecoes.toString()),
              _InfoPill(label: 'Objetos/Registros', value: banco.quantidadeObjetos.toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _BancosDadosListaSection extends StatelessWidget {
  const _BancosDadosListaSection({required this.bancos});

  final List<AdminBancoDadosResumo> bancos;

  @override
  Widget build(BuildContext context) {
    return _AdminGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Bancos monitorados', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0B1F3A), fontSize: 18)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(label: Text('Banco')),
                DataColumn(label: Text('Dados')),
                DataColumn(label: Text('Armazenado')),
                DataColumn(label: Text('Índices')),
                DataColumn(label: Text('Coleções/Tabelas')),
                DataColumn(label: Text('Objetos/Registros')),
              ],
              rows: bancos
                  .map(
                    (AdminBancoDadosResumo banco) => DataRow(
                      cells: <DataCell>[
                        DataCell(Text(banco.nome)),
                        DataCell(Text(_formatarBytes(banco.tamanhoDadosBytes))),
                        DataCell(Text(_formatarBytes(banco.tamanhoArmazenadoBytes))),
                        DataCell(Text(_formatarBytes(banco.tamanhoIndicesBytes))),
                        DataCell(Text(banco.quantidadeColecoes.toString())),
                        DataCell(Text(banco.quantidadeObjetos.toString())),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActuatorResumoSection extends StatelessWidget {
  const _ActuatorResumoSection({required this.actuator});

  final AdminActuatorResumo actuator;

  @override
  Widget build(BuildContext context) {
    final bool statusOk = actuator.status.toUpperCase() == 'UP';
    final Color statusColor = statusOk ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return _AdminGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.monitor_heart_rounded, color: statusColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Actuator / Saúde do backend', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0B1F3A), fontSize: 18)),
                    const SizedBox(height: 4),
                    Text('Status reportado pelo Spring Boot Actuator e runtime da JVM.', style: TextStyle(color: Colors.black.withOpacity(0.58), fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              _StatusBadge(status: actuator.status, color: statusColor),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compacto = constraints.maxWidth < 900;
              final double width = compacto ? constraints.maxWidth : (constraints.maxWidth - 32) / 3;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: <Widget>[
                  SizedBox(
                    width: width,
                    child: _AdminMetricCard.flat(
                      icon: Icons.timer_outlined,
                      title: 'Uptime',
                      value: _formatarDuracao(actuator.uptimeSegundos),
                      subtitle: 'Tempo em execução do backend.',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _AdminMetricCard.flat(
                      icon: Icons.memory_rounded,
                      title: 'Heap JVM',
                      value: _formatarBytes(actuator.memoriaHeapUsadaBytes),
                      subtitle: 'Máximo: ${_formatarBytes(actuator.memoriaHeapMaxBytes)}.',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _AdminMetricCard.flat(
                      icon: Icons.account_tree_rounded,
                      title: 'Threads',
                      value: actuator.threadsAtivas.toString(),
                      subtitle: 'Pico: ${actuator.threadsPico} • Daemon: ${actuator.threadsDaemon}.',
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _InfoPill(label: 'Non-heap', value: '${_formatarBytes(actuator.memoriaNonHeapUsadaBytes)} / ${_formatarBytes(actuator.memoriaNonHeapMaxBytes)}'),
              _InfoPill(label: 'Processadores', value: actuator.processadoresDisponiveis.toString()),
              _InfoPill(label: 'Carga', value: _formatarCarga(actuator.cargaSistema)),
              _InfoPill(label: 'Java', value: actuator.versaoJava),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 0.6)),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF123B69).withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF123B69).withOpacity(0.08)),
      ),
      child: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF123B69))),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  }) : flat = false;

  const _AdminMetricCard.flat({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  }) : flat = true;

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Widget content = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double progress, Widget? child) {
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: Row(
        children: <Widget>[
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF123B69).withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: const Color(0xFF123B69)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF152033))),
                const SizedBox(height: 6),
                Text(value, style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF0B1F3A), letterSpacing: -1.2)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.black.withOpacity(0.58), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );

    if (flat) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.58),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF123B69).withOpacity(0.08)),
        ),
        child: content,
      );
    }

    return _AdminGlassCard(child: content);
  }
}

class _AdminGlassCard extends StatelessWidget {
  const _AdminGlassCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.78)),
        boxShadow: <BoxShadow>[
          BoxShadow(color: const Color(0xFF0B1F3A).withOpacity(0.08), blurRadius: 34, offset: const Offset(0, 18)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: child,
      ),
    );
  }
}

class _AdminBackground extends StatelessWidget {
  const _AdminBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFF4F7FB), Color(0xFFE7F0FA), Color(0xFFF8FAFC)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(top: -170, right: -120, child: _Orb(size: 390, color: const Color(0xFF2563EB).withOpacity(0.12))),
          Positioned(bottom: -180, left: -130, child: _Orb(size: 430, color: const Color(0xFF0B1F3A).withOpacity(0.08))),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

String _formatarBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const List<String> unidades = <String>['B', 'KB', 'MB', 'GB', 'TB'];
  double valor = bytes.toDouble();
  int unidade = 0;
  while (valor >= 1024 && unidade < unidades.length - 1) {
    valor = valor / 1024;
    unidade++;
  }
  final String texto = valor >= 10 || unidade == 0 ? valor.toStringAsFixed(0) : valor.toStringAsFixed(1);
  return '$texto ${unidades[unidade]}';
}

String _formatarDuracao(int segundos) {
  if (segundos <= 0) return '0s';
  final int dias = segundos ~/ 86400;
  final int horas = (segundos % 86400) ~/ 3600;
  final int minutos = (segundos % 3600) ~/ 60;
  if (dias > 0) return '${dias}d ${horas}h';
  if (horas > 0) return '${horas}h ${minutos}min';
  return '${minutos}min';
}

String _formatarCarga(double carga) {
  if (carga < 0) return 'indisponível';
  return carga.toStringAsFixed(2);
}
