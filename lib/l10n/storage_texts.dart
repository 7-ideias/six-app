import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_settings_provider.dart';
import 'six_i18n.dart';

const _storageTexts = <String, List<String>>{
  "title": ["Armazenamento", "Storage", "Almacenamiento"],
  "subtitle": [
    "Acompanhe os dados e arquivos deste comércio.",
    "Track this business’s data and files.",
    "Consulta los datos y archivos de este comercio.",
  ],
  "database": ["Dados do comércio", "Business data", "Datos del comercio"],
  "files": ["Fotos e documentos", "Photos and documents", "Fotos y documentos"],
  "refresh": ["Atualizar", "Refresh", "Actualizar"],
  "close": ["Fechar", "Close", "Cerrar"],
  "pending": [
    "A primeira medição está sendo preparada.",
    "The first measurement is being prepared.",
    "Se está preparando la primera medición.",
  ],
  "processing": [
    "Atualizando o consumo em segundo plano.",
    "Updating usage in the background.",
    "Actualizando el consumo en segundo plano.",
  ],
  "updated": ["Consumo apurado", "Usage measured", "Consumo calculado"],
  "partial": [
    "Medição parcial: alguns arquivos não puderam ser contabilizados.",
    "Partial measurement: some files could not be measured.",
    "Medición parcial: no se pudieron medir algunos archivos.",
  ],
  "measurementError": [
    "Não foi possível atualizar a medição. Os valores anteriores, quando disponíveis, foram preservados.",
    "The measurement could not be updated. Previous values, when available, were preserved.",
    "No se pudo actualizar la medición. Se conservaron los valores anteriores disponibles.",
  ],
  "error": [
    "Não foi possível consultar o armazenamento. Tente novamente.",
    "Unable to load storage usage. Try again.",
    "No se pudo consultar el almacenamiento. Inténtalo de nuevo.",
  ],
  "forbidden": [
    "Você não tem acesso ao armazenamento deste comércio.",
    "You do not have access to this business’s storage.",
    "No tienes acceso al almacenamiento de este comercio.",
  ],
  "session": [
    "Sua sessão expirou. Entre novamente.",
    "Your session expired. Please sign in again.",
    "Tu sesión caducó. Inicia sesión de nuevo.",
  ],
  "noCompany": [
    "Selecione um comércio para consultar o armazenamento.",
    "Select a business to view storage.",
    "Selecciona un comercio para consultar el almacenamiento.",
  ],
  "companyChanged": [
    "O comércio selecionado mudou. Atualize a consulta.",
    "The selected business changed. Refresh to continue.",
    "El comercio seleccionado cambió. Actualiza la consulta.",
  ],
  "measuredAt": ["Última medição", "Last measured", "Última medición"],
  "scope": [
    "Consumo lógico dos registros atribuídos ao comércio e dos arquivos armazenados. Não inclui índices, backups, dados pessoais compartilhados nem imagens externas.",
    "Logical usage of business-owned records and stored files. Excludes indexes, backups, shared personal data and external images.",
    "Consumo lógico de registros del comercio y archivos almacenados. Excluye índices, copias de seguridad, datos personales compartidos e imágenes externas.",
  ],
  "observation": [
    "Acompanhamento de consumo. Nenhum bloqueio ou cobrança é aplicado nesta etapa.",
    "Usage monitoring. No restrictions or charges apply at this stage.",
    "Seguimiento del consumo. No se aplican bloqueos ni cobros en esta etapa.",
  ],
  "company": ["Comércio", "Business", "Comercio"],
  "view": ["Ver armazenamento", "View storage", "Ver almacenamiento"],
  "noMeasurement": [
    "Aguardando medição",
    "Awaiting measurement",
    "Esperando medición",
  ],
};

String storageText(BuildContext context, String key) {
  final language = Localizations.localeOf(context).languageCode;
  final values = _storageTexts[key] ?? _storageTexts['error']!;
  return context.t(
    'storage.$key',
    fallback:
        values[language == 'en'
            ? 1
            : language == 'es'
            ? 2
            : 0],
  );
}

String storageBytes(BuildContext context, num bytes) {
  final settings = context.read<LocaleSettingsProvider>();
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  double value = bytes.toDouble();
  int unit = 0;
  while (value >= 1000 && unit < units.length - 1) {
    value /= 1000;
    unit++;
  }
  return '${settings.formatDecimal(value)} ${units[unit]}';
}

String storageTimestamp(BuildContext context, DateTime instant) {
  final settings = context.read<LocaleSettingsProvider>();
  final utc = instant.toUtc();
  return '${settings.formatDate(utc)} ${settings.formatTime(utc)} UTC';
}

String storageStatusKey(String status) => switch (status) {
  'PENDENTE' => 'pending',
  'PROCESSANDO' => 'processing',
  'ATUALIZADO' => 'updated',
  'PARCIAL' => 'partial',
  'ERRO' => 'measurementError',
  _ => 'error',
};
