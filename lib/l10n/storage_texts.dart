import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/locale_settings_provider.dart';
import 'six_i18n.dart';

const _storageTexts = <String, List<String>>{
  "plansTitle": [
    "Planos e franquias",
    "Plans and allowances",
    "Planes y cuotas",
  ],
  "plansSubtitle": [
    "Configure o armazenamento e o plano de cada comércio.",
    "Configure storage and the plan for each business.",
    "Configura el almacenamiento y el plan de cada comercio.",
  ],
  "plan": ["Plano", "Plan", "Plan"],
  "noPlan": ["Sem plano vinculado", "No assigned plan", "Sin plan asignado"],
  "quotaNotConfigured": [
    "Franquia não configurada",
    "Allowance not configured",
    "Cuota sin configurar",
  ],
  "quotaWithin": [
    "Dentro da franquia",
    "Within allowance",
    "Dentro de la cuota",
  ],
  "quotaNear": [
    "Você está próximo da franquia.",
    "You are approaching your allowance.",
    "Estás cerca de tu cuota.",
  ],
  "quotaReached": [
    "Franquia atingida. Você pode continuar usando o app.",
    "Allowance reached. You can keep using the app.",
    "Cuota alcanzada. Puedes seguir usando la app.",
  ],
  "quotaExceeded": [
    "Franquia ultrapassada. Você pode continuar usando o app.",
    "Allowance exceeded. You can keep using the app.",
    "Cuota superada. Puedes seguir usando la app.",
  ],
  "of": ["de", "of", "de"],
  "managePlans": [
    "Gerenciar planos e franquias",
    "Manage plans and allowances",
    "Gestionar planes y cuotas",
  ],
  "configure": [
    "Configurar franquias",
    "Configure allowances",
    "Configurar cuotas",
  ],
  "save": ["Salvar alterações", "Save changes", "Guardar cambios"],
  "cancel": ["Cancelar", "Cancel", "Cancelar"],
  "saving": ["Salvando…", "Saving…", "Guardando…"],
  "limitsHint": [
    "Informe valores em MB, sem separador de milhar. Campo vazio significa não configurado. 1 MB = 1.000.000 bytes.",
    "Enter values in MB without thousands separators. An empty field means not configured. 1 MB = 1,000,000 bytes.",
    "Introduce valores en MB sin separadores de miles. Un campo vacío significa sin configurar. 1 MB = 1.000.000 bytes.",
  ],
  "databaseQuota": [
    "Franquia de dados (MB)",
    "Data allowance (MB)",
    "Cuota de datos (MB)",
  ],
  "filesQuota": [
    "Franquia de fotos e arquivos (MB)",
    "Photos and files allowance (MB)",
    "Cuota de fotos y archivos (MB)",
  ],
  "uploadLimit": [
    "Tamanho máximo por arquivo (MB)",
    "Maximum size per file (MB)",
    "Tamaño máximo por archivo (MB)",
  ],
  "uploadConfigured": [
    "Tamanho por arquivo configurado",
    "Configured size per file",
    "Tamaño por archivo configurado",
  ],
  "limitsScope": [
    "Esta alteração se aplica a todos os comércios vinculados ao plano.",
    "This change applies to every business assigned to this plan.",
    "Este cambio se aplica a todos los comercios vinculados al plan.",
  ],
  "informational": [
    "Nesta etapa, as franquias são informativas. Cadastros, vendas e uploads continuam disponíveis, respeitando as restrições técnicas já existentes.",
    "At this stage, allowances are informational. Records, sales and uploads remain available, subject to existing technical restrictions.",
    "En esta etapa, las cuotas son informativas. Los registros, ventas y archivos siguen disponibles, sujetos a las restricciones técnicas existentes.",
  ],
  "assignPlan": [
    "Vincular plano ao comércio",
    "Assign a plan to this business",
    "Vincular un plan al comercio",
  ],
  "applyPlan": [
    "Salvar vínculo do plano",
    "Save plan assignment",
    "Guardar vínculo del plan",
  ],
  "assignmentHint": [
    "Vínculo administrativo para armazenamento. Não ativa cobrança ou assinatura.",
    "Administrative storage assignment. It does not activate billing or a subscription.",
    "Vínculo administrativo de almacenamiento. No activa cobros ni suscripción.",
  ],
  "emptyPlans": [
    "Nenhum plano cadastrado. Crie os planos no painel de gestão web.",
    "No plans registered. Create plans in the web management panel.",
    "No hay planes registrados. Crea los planes en el panel de gestión web.",
  ],
  "saved": ["Alterações salvas.", "Changes saved.", "Cambios guardados."],
  "invalidLimits": [
    "Informe valores positivos de até 1 bilhão de MB, com no máximo 6 casas decimais. O tamanho por arquivo não pode superar a franquia de arquivos.",
    "Enter positive values up to 1 billion MB, with at most 6 decimal places. The size per file cannot exceed the files allowance.",
    "Introduce valores positivos de hasta mil millones de MB y un máximo de 6 decimales. El tamaño por archivo no puede superar la cuota de archivos.",
  ],
  "planConflict": [
    "O plano ou a configuração mudou. Feche a edição e atualize a lista antes de salvar novamente.",
    "The plan or configuration changed. Close the editor and refresh the list before saving again.",
    "El plan o la configuración cambió. Cierra la edición y actualiza la lista antes de volver a guardar.",
  ],
  "planNotFound": [
    "Plano ou comércio não encontrado. Atualize a lista.",
    "Plan or business not found. Refresh the list.",
    "No se encontró el plan o comercio. Actualiza la lista.",
  ],
  "published": ["Publicado", "Published", "Publicado"],
  "draft": ["Rascunho", "Draft", "Borrador"],
  "archived": ["Arquivado", "Archived", "Archivado"],
  "searchPlans": ["Buscar plano", "Search plans", "Buscar plan"],
  "partialQuota": [
    "O consumo exibido é parcial e pode aumentar após a medição completa.",
    "Displayed usage is partial and may increase after a complete measurement.",
    "El consumo mostrado es parcial y puede aumentar tras una medición completa.",
  ],
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
