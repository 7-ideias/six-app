import 'package:flutter/material.dart';

import '../../l10n/web_i18n_store.dart';

class AdminPortalTexts {
  const AdminPortalTexts._(this._localeCode);

  final String _localeCode;

  static AdminPortalTexts of(BuildContext context) {
    return AdminPortalTexts._(Localizations.localeOf(context).languageCode);
  }

  String _text(String key) {
    final String? backendValue = WebI18nStore.instance.string(_localeCode, key);
    if (backendValue != null && backendValue.trim().isNotEmpty) {
      return backendValue;
    }
    return _adminDefaults[_localeCode]?[key] ?? _adminDefaults['pt']![key] ?? '';
  }

  String get portalTitle => _text('adminPortalTitle');
  String get dashboard => _text('adminDashboard');
  String get dashboardTitle => _text('adminDashboardTitle');
  String get dashboardSubtitle => _text('adminDashboardSubtitle');
  String get currentPage => _text('adminCurrentPage');
  String get online => _text('adminOnline');
  String get refresh => _text('adminRefresh');
  String get logout => _text('adminLogout');
  String get userFallback => _text('adminUserFallback');
  String get userRole => _text('adminUserRole');
  String get loadingTitle => _text('adminLoadingTitle');
  String get loadingSubtitle => _text('adminLoadingSubtitle');
  String get errorTitle => _text('adminErrorTitle');
  String get errorAction => _text('adminErrorAction');
  String get emptyTitle => _text('adminEmptyTitle');
  String get emptySubtitle => _text('adminEmptySubtitle');
  String get totalCompanies => _text('adminTotalCompanies');
  String get activeCompanies => _text('adminActiveCompanies');
  String get inactiveCompanies => _text('adminInactiveCompanies');
  String get activePercent => _text('adminActivePercent');
  String get totalCompaniesHint => _text('adminTotalCompaniesHint');
  String get activeCompaniesHint => _text('adminActiveCompaniesHint');
  String get inactiveCompaniesHint => _text('adminInactiveCompaniesHint');
  String get activePercentHint => _text('adminActivePercentHint');
  String get overviewTitle => _text('adminOverviewTitle');
  String get overviewSubtitle => _text('adminOverviewSubtitle');
  String get statusSummaryTitle => _text('adminStatusSummaryTitle');
  String get activeLabel => _text('adminActiveLabel');
  String get inactiveLabel => _text('adminInactiveLabel');
  String get totalLabel => _text('adminTotalLabel');
  String get infrastructureTitle => _text('adminInfrastructureTitle');
  String get databasesTitle => _text('adminDatabasesTitle');
  String get actuatorTitle => _text('adminActuatorTitle');
  String get comingSoon => _text('adminComingSoon');
  String get menu => _text('adminMenu');

  String greetingFor(DateTime now, String? userName) {
    final String greetingKey;
    if (now.hour < 12) {
      greetingKey = 'adminGreetingMorning';
    } else if (now.hour < 18) {
      greetingKey = 'adminGreetingAfternoon';
    } else {
      greetingKey = 'adminGreetingEvening';
    }

    final String name = userName?.trim() ?? '';
    if (name.isEmpty) {
      return _text(greetingKey);
    }
    return '${_text(greetingKey)}, $name';
  }
}

const Map<String, Map<String, String>> _adminDefaults = <String, Map<String, String>>{
  'pt': <String, String>{
    'adminPortalTitle': 'Portal Administrativo',
    'adminDashboard': 'Dashboard',
    'adminDashboardTitle': 'Visão administrativa',
    'adminDashboardSubtitle': 'Acompanhe a situação geral das empresas cadastradas no Six.',
    'adminCurrentPage': 'Dashboard administrativo',
    'adminOnline': 'Sistema online',
    'adminRefresh': 'Atualizar',
    'adminLogout': 'Sair',
    'adminUserFallback': 'Usuário autenticado',
    'adminUserRole': 'Acesso administrativo',
    'adminLoadingTitle': 'Carregando visão administrativa',
    'adminLoadingSubtitle': 'Buscando indicadores reais do sistema.',
    'adminErrorTitle': 'Não foi possível carregar o dashboard.',
    'adminErrorAction': 'Tentar novamente',
    'adminEmptyTitle': 'Nenhuma empresa cadastrada ainda',
    'adminEmptySubtitle': 'Assim que houver empresas cadastradas, os indicadores aparecerão aqui.',
    'adminTotalCompanies': 'Empresas cadastradas',
    'adminActiveCompanies': 'Empresas ativas',
    'adminInactiveCompanies': 'Empresas inativas',
    'adminActivePercent': 'Percentual ativo',
    'adminTotalCompaniesHint': 'Total real existente na base.',
    'adminActiveCompaniesHint': 'Empresas marcadas como ativas.',
    'adminInactiveCompaniesHint': 'Calculado como total menos ativas.',
    'adminActivePercentHint': 'Ativas sobre o total cadastrado.',
    'adminOverviewTitle': 'Distribuição das empresas',
    'adminOverviewSubtitle': 'Resumo calculado a partir dos dados reais retornados pelo backend.',
    'adminStatusSummaryTitle': 'Resumo da base',
    'adminActiveLabel': 'Ativas',
    'adminInactiveLabel': 'Inativas',
    'adminTotalLabel': 'Total',
    'adminInfrastructureTitle': 'Infraestrutura',
    'adminDatabasesTitle': 'Bancos monitorados',
    'adminActuatorTitle': 'Saúde do backend',
    'adminComingSoon': 'Novas configurações administrativas serão adicionadas aqui conforme forem definidas.',
    'adminMenu': 'Abrir menu administrativo',
    'adminGreetingMorning': 'Bom dia',
    'adminGreetingAfternoon': 'Boa tarde',
    'adminGreetingEvening': 'Boa noite',
  },
  'en': <String, String>{
    'adminPortalTitle': 'Admin Portal',
    'adminDashboard': 'Dashboard',
    'adminDashboardTitle': 'Administrative overview',
    'adminDashboardSubtitle': 'Track the overall status of companies registered in Six.',
    'adminCurrentPage': 'Admin dashboard',
    'adminOnline': 'System online',
    'adminRefresh': 'Refresh',
    'adminLogout': 'Sign out',
    'adminUserFallback': 'Authenticated user',
    'adminUserRole': 'Administrative access',
    'adminLoadingTitle': 'Loading admin overview',
    'adminLoadingSubtitle': 'Fetching real system indicators.',
    'adminErrorTitle': 'Unable to load the dashboard.',
    'adminErrorAction': 'Try again',
    'adminEmptyTitle': 'No companies registered yet',
    'adminEmptySubtitle': 'Once companies are registered, indicators will appear here.',
    'adminTotalCompanies': 'Registered companies',
    'adminActiveCompanies': 'Active companies',
    'adminInactiveCompanies': 'Inactive companies',
    'adminActivePercent': 'Active percentage',
    'adminTotalCompaniesHint': 'Real total in the database.',
    'adminActiveCompaniesHint': 'Companies currently marked as active.',
    'adminInactiveCompaniesHint': 'Calculated as total minus active.',
    'adminActivePercentHint': 'Active companies over the registered total.',
    'adminOverviewTitle': 'Company distribution',
    'adminOverviewSubtitle': 'Summary calculated from real backend data.',
    'adminStatusSummaryTitle': 'Database summary',
    'adminActiveLabel': 'Active',
    'adminInactiveLabel': 'Inactive',
    'adminTotalLabel': 'Total',
    'adminInfrastructureTitle': 'Infrastructure',
    'adminDatabasesTitle': 'Monitored databases',
    'adminActuatorTitle': 'Backend health',
    'adminComingSoon': 'New administrative settings will be added here as they are defined.',
    'adminMenu': 'Open admin menu',
    'adminGreetingMorning': 'Good morning',
    'adminGreetingAfternoon': 'Good afternoon',
    'adminGreetingEvening': 'Good evening',
  },
  'es': <String, String>{
    'adminPortalTitle': 'Portal Administrativo',
    'adminDashboard': 'Dashboard',
    'adminDashboardTitle': 'Visión administrativa',
    'adminDashboardSubtitle': 'Acompaña la situación general de las empresas registradas en Six.',
    'adminCurrentPage': 'Dashboard administrativo',
    'adminOnline': 'Sistema en línea',
    'adminRefresh': 'Actualizar',
    'adminLogout': 'Salir',
    'adminUserFallback': 'Usuario autenticado',
    'adminUserRole': 'Acceso administrativo',
    'adminLoadingTitle': 'Cargando visión administrativa',
    'adminLoadingSubtitle': 'Buscando indicadores reales del sistema.',
    'adminErrorTitle': 'No fue posible cargar el dashboard.',
    'adminErrorAction': 'Intentar nuevamente',
    'adminEmptyTitle': 'Aún no hay empresas registradas',
    'adminEmptySubtitle': 'Cuando haya empresas registradas, los indicadores aparecerán aquí.',
    'adminTotalCompanies': 'Empresas registradas',
    'adminActiveCompanies': 'Empresas activas',
    'adminInactiveCompanies': 'Empresas inactivas',
    'adminActivePercent': 'Porcentaje activo',
    'adminTotalCompaniesHint': 'Total real existente en la base.',
    'adminActiveCompaniesHint': 'Empresas marcadas como activas.',
    'adminInactiveCompaniesHint': 'Calculado como total menos activas.',
    'adminActivePercentHint': 'Activas sobre el total registrado.',
    'adminOverviewTitle': 'Distribución de empresas',
    'adminOverviewSubtitle': 'Resumen calculado a partir de datos reales del backend.',
    'adminStatusSummaryTitle': 'Resumen de la base',
    'adminActiveLabel': 'Activas',
    'adminInactiveLabel': 'Inactivas',
    'adminTotalLabel': 'Total',
    'adminInfrastructureTitle': 'Infraestructura',
    'adminDatabasesTitle': 'Bancos monitoreados',
    'adminActuatorTitle': 'Salud del backend',
    'adminComingSoon': 'Nuevas configuraciones administrativas serán agregadas aquí conforme sean definidas.',
    'adminMenu': 'Abrir menú administrativo',
    'adminGreetingMorning': 'Buenos días',
    'adminGreetingAfternoon': 'Buenas tardes',
    'adminGreetingEvening': 'Buenas noches',
  },
};
