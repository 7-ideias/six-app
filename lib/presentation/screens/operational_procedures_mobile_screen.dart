import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/datasources/operational_procedure_mock_data_source.dart';
import 'package:sixpos/data/models/operational_procedure_models.dart';
import 'package:sixpos/design_system/themes/six_mobile_palette.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_card.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_filters.dart';
import 'package:sixpos/presentation/components/mobile/operational_procedures/operational_procedure_state_views.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_page_shell.dart';
import 'package:sixpos/presentation/components/mobile_motion.dart';
import 'package:sixpos/presentation/screens/operational_procedure_editor_mobile_screen.dart';
import 'package:sixpos/providers/operational_procedure_provider.dart';

class OperationalProceduresMobileScreen extends StatelessWidget {
  const OperationalProceduresMobileScreen({
    super.key,
    this.dataSource = const OperationalProcedureMockDataSource(),
  });

  final OperationalProcedureMockDataSource dataSource;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OperationalProcedureProvider>(
      create:
          (_) => OperationalProcedureProvider(dataSource: dataSource)..load(),
      child: const _OperationalProceduresMobileView(),
    );
  }
}

class _OperationalProceduresMobileView extends StatelessWidget {
  const _OperationalProceduresMobileView();

  static const Color _backgroundColor = SixMobilePalette.background;
  static const Color _primaryColor = SixMobilePalette.primary;
  static const Color _secondaryColor = SixMobilePalette.secondary;
  static const Color _accentColor = SixMobilePalette.accent;

  @override
  Widget build(BuildContext context) {
    return SixMobilePageShell(
      title: context.t('procedimentos.title', fallback: 'Procedimentos'),
      backgroundColor: _backgroundColor,
      primaryColor: _primaryColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
      bodyBuilder: (
        BuildContext context,
        ScrollController scrollController,
        double topInset,
      ) {
        return SafeArea(
          top: false,
          child: Consumer<OperationalProcedureProvider>(
            builder: (
              BuildContext context,
              OperationalProcedureProvider provider,
              _,
            ) {
              final bool reduceMotion =
                  MediaQuery.disableAnimationsOf(context) ||
                  MediaQuery.accessibleNavigationOf(context);

              return RefreshIndicator(
                onRefresh: provider.reload,
                child: ListView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 28),
                  children: <Widget>[
                    AnimatedSwitcher(
                      duration:
                          reduceMotion
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _buildState(
                        context,
                        provider,
                        reduceMotion: reduceMotion,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildState(
    BuildContext context,
    OperationalProcedureProvider provider, {
    required bool reduceMotion,
  }) {
    if (provider.isLoading) {
      return const OperationalProcedureLoadingState(
        key: ValueKey<String>('procedures-loading'),
      );
    }

    if (provider.hasError) {
      return OperationalProcedureErrorState(
        key: const ValueKey<String>('procedures-error'),
        onRetry: provider.reload,
      );
    }

    if (provider.isEmpty) {
      return OperationalProcedureEmptyState(
        key: const ValueKey<String>('procedures-empty'),
        onCreate: () => _openCreate(context, provider),
      );
    }

    return _ProceduresSuccessState(
      key: const ValueKey<String>('procedures-success'),
      provider: provider,
      reduceMotion: reduceMotion,
      onCreate: () => _openCreate(context, provider),
      onOpen:
          (OperationalProcedure procedure) =>
              _openEdit(context, provider, procedure),
    );
  }

  Future<void> _openCreate(
    BuildContext context,
    OperationalProcedureProvider provider,
  ) async {
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder:
            (_) => ChangeNotifierProvider<OperationalProcedureProvider>.value(
              value: provider,
              child: OperationalProcedureEditorMobileScreen(
                initialProcedure: provider.createEmptyProcedure(),
                isCreating: true,
              ),
            ),
      ),
    );
    if (saved == true && context.mounted) {
      _showSaved(context, true);
    }
  }

  Future<void> _openEdit(
    BuildContext context,
    OperationalProcedureProvider provider,
    OperationalProcedure procedure,
  ) async {
    final OperationalProcedure? current = provider.findById(procedure.id);
    if (current == null) return;
    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder:
            (_) => ChangeNotifierProvider<OperationalProcedureProvider>.value(
              value: provider,
              child: OperationalProcedureEditorMobileScreen(
                initialProcedure: current,
                isCreating: false,
              ),
            ),
      ),
    );
    if (saved == true && context.mounted) {
      _showSaved(context, false);
    }
  }

  void _showSaved(BuildContext context, bool created) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? context.t(
                'procedimentos.createdSuccess',
                fallback: 'Procedimento criado.',
              )
              : context.t(
                'procedimentos.updatedSuccess',
                fallback: 'Procedimento atualizado.',
              ),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ProceduresSuccessState extends StatelessWidget {
  const _ProceduresSuccessState({
    super.key,
    required this.provider,
    required this.reduceMotion,
    required this.onCreate,
    required this.onOpen,
  });

  final OperationalProcedureProvider provider;
  final bool reduceMotion;
  final VoidCallback onCreate;
  final ValueChanged<OperationalProcedure> onOpen;

  @override
  Widget build(BuildContext context) {
    final List<OperationalProcedure> procedures = provider.filteredProcedures;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _entry(
          reduceMotion: reduceMotion,
          child: const OperationalProcedureIntro(),
        ),
        const SizedBox(height: 14),
        _entry(
          reduceMotion: reduceMotion,
          delay: const Duration(milliseconds: 70),
          child: OperationalProcedureFilters(
            selectedFilter: provider.filter,
            onChanged: provider.setFilter,
          ),
        ),
        const SizedBox(height: 16),
        if (procedures.isEmpty)
          _entry(
            reduceMotion: reduceMotion,
            delay: const Duration(milliseconds: 110),
            child: const OperationalProcedureFilteredEmptyNotice(),
          )
        else
          ...procedures.asMap().entries.map((
            MapEntry<int, OperationalProcedure> entry,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _entry(
                reduceMotion: reduceMotion,
                delay: Duration(milliseconds: 110 + (entry.key * 45)),
                child: OperationalProcedureCard(
                  procedure: entry.value,
                  onTap: () => onOpen(entry.value),
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        _entry(
          reduceMotion: reduceMotion,
          delay: const Duration(milliseconds: 260),
          child: OperationalProcedureNewAction(onTap: onCreate),
        ),
      ],
    );
  }

  Widget _entry({
    required bool reduceMotion,
    required Widget child,
    Duration delay = Duration.zero,
  }) {
    if (reduceMotion) return child;
    return SixStaggeredEntry(delay: delay, child: child);
  }
}
