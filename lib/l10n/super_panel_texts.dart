import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_settings_provider.dart';
import 'six_i18n.dart';

const _texts = <String, List<String>>{
  'title': ['Painel SUPER', 'SUPER panel', 'Panel SUPER'],
  'subtitle': [
    'Monitoramento e saúde da plataforma',
    'Platform monitoring and health',
    'Monitoreo y salud de la plataforma',
  ],
  'restricted': [
    'Acesso exclusivo para usuários SUPER.',
    'Access restricted to SUPER users.',
    'Acceso exclusivo para usuarios SUPER.',
  ],
  'refresh': ['Atualizar', 'Refresh', 'Actualizar'],
  'loading': [
    'Carregando infraestrutura',
    'Loading infrastructure',
    'Cargando infraestructura',
  ],
  'error': [
    'Não foi possível atualizar os dados. Tente novamente.',
    'Could not refresh the data. Please try again.',
    'No se pudieron actualizar los datos. Inténtalo de nuevo.',
  ],
  'empty': [
    'Nenhuma informação de infraestrutura está disponível agora.',
    'No infrastructure information is available right now.',
    'No hay información de infraestructura disponible ahora.',
  ],
  'health': ['Saúde do backend', 'Backend health', 'Salud del backend'],
  'databases': [
    'Bancos monitorados',
    'Monitored databases',
    'Bases de datos monitoreadas',
  ],
  'requests': [
    'Requisições do backend',
    'Backend requests',
    'Solicitudes del backend',
  ],
  'data': ['Dados', 'Data', 'Datos'],
  'storage': ['Armazenamento', 'Storage', 'Almacenamiento'],
  'indexes': ['Índices', 'Indexes', 'Índices'],
  'total': ['Total', 'Total', 'Total'],
  'load': ['Carga', 'Load', 'Carga'],
  'details': ['Ver detalhes', 'View details', 'Ver detalles'],
};

String superPanelText(BuildContext context, String key) {
  final language =
      context.watch<LocaleSettingsProvider>().currentLocale.languageCode;
  final index =
      language == 'en'
          ? 1
          : language == 'es'
          ? 2
          : 0;
  return context.t('superPanel.$key', fallback: _texts[key]?[index] ?? key);
}
