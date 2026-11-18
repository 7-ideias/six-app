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
  'scope': ['Toda a plataforma', 'Platform-wide', 'Toda la plataforma'],
  'collected': ['Coleta', 'Collected', 'Recopilado'],
  'rate': ['Requisições/min', 'Requests/min', 'Solicitudes/min'],
  'errors': ['Erros 5xx', '5xx errors', 'Errores 5xx'],
  'latency': ['Tempo de resposta', 'Response time', 'Tiempo de respuesta'],
  'traffic': ['Tráfego da API', 'API traffic', 'Tráfico de la API'],
  'events': ['Eventos recentes', 'Recent events', 'Eventos recientes'],
  'START': ['Backend iniciado', 'Backend started', 'Backend iniciado'],
  'UNAVAILABLE': ['Indisponível', 'Unavailable', 'No disponible'],
  'RECOVERED': [
    'Conexão recuperada',
    'Connection restored',
    'Conexión recuperada',
  ],
  'available': ['Conectado', 'Connected', 'Conectado'],
  'none': [
    'Sem eventos neste período',
    'No events in this period',
    'Sin eventos en este período',
  ],
  'gap': [
    'Sem coleta antes da linha tracejada',
    'No samples before the dashed line',
    'Sin muestras antes de la línea discontinua',
  ],
  'noSamples': ['Sem amostras', 'No samples', 'Sin muestras'],
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
