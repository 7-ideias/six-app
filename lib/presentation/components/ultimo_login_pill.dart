import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/utils/ultimo_login.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

/// Átomo de estado: as telas mantêm composição e tokens próprios.
class UltimoLoginPill extends StatelessWidget {
  const UltimoLoginPill({
    super.key,
    required this.ultimoLoginEm,
    required this.hojeColor,
    required this.recenteColor,
    required this.antigoColor,
    required this.semRegistroColor,
  });

  final DateTime? ultimoLoginEm;
  final Color hojeColor;
  final Color recenteColor;
  final Color antigoColor;
  final Color semRegistroColor;

  @override
  Widget build(BuildContext context) {
    final regionalizacao = context.watch<LocaleSettingsProvider>();
    final login = UltimoLogin.fromInstant(
      ultimoLoginEm,
      timeZone: regionalizacao.timeZone,
    );
    final Color color = switch (login.recencia) {
      UltimoLoginRecencia.hoje => hojeColor,
      UltimoLoginRecencia.recente => recenteColor,
      UltimoLoginRecencia.antigo => antigoColor,
      UltimoLoginRecencia.semRegistro => semRegistroColor,
    };
    final String title = context.t('usuariosSixo.lastLogin.label');
    final DateTime? date = login.data;
    final String value;
    final String tooltip;
    if (date == null) {
      value = context.t('usuariosSixo.lastLogin.noRecord');
      tooltip = context.t('usuariosSixo.lastLogin.noRecordHint');
    } else {
      final String day = switch (login.dias) {
        0 => context.t('usuariosSixo.lastLogin.today'),
        1 => context.t('usuariosSixo.lastLogin.yesterday'),
        _ => regionalizacao.formatDate(date),
      };
      value = '$day · ${regionalizacao.formatTime(date)}';
      tooltip =
          '$title: ${regionalizacao.formatDate(date)} '
          '${regionalizacao.formatTime(date)} (${login.fuso}). '
          '${context.t('usuariosSixo.lastLogin.hint')}';
    }
    final String label = '$title · $value';
    return Semantics(
      label: '$title: $value. $tooltip',
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.38)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                date == null ? Icons.history_rounded : Icons.login_rounded,
                size: 15,
                color: color,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  softWrap: true,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
