import 'package:flutter/material.dart';

class AdminVisualAssetSettingsTexts {
  AdminVisualAssetSettingsTexts(BuildContext context)
    : language = Localizations.localeOf(context).languageCode;
  final String language;
  String pick(String pt, String en, String es) =>
      language == 'en'
          ? en
          : language == 'es'
          ? es
          : pt;
  String get title => pick(
    'Esmaecimento dos cabeçalhos',
    'Header fade',
    'Desvanecimiento de encabezados',
  );
  String get description => pick(
    'Configuração global para todos os cabeçalhos Web deste ambiente. Ajuste cada tema e confira a prévia antes de salvar.',
    'Global settings for all Web headers in this environment. Adjust each theme and preview before saving.',
    'Configuración global de los encabezados Web de este entorno. Ajusta cada tema y revisa la vista previa antes de guardar.',
  );
  String get light => pick('Tema claro', 'Light theme', 'Tema claro');
  String get dark => pick('Tema escuro', 'Dark theme', 'Tema oscuro');
  String get intensity => pick('Intensidade', 'Intensity', 'Intensidad');
  String get extent => pick(
    'Alcance da área esmaecida',
    'Fade coverage',
    'Alcance del desvanecimiento',
  );
  String get compact => pick(
    'Simular cabeçalho compacto',
    'Preview compact header',
    'Simular encabezado compacto',
  );
  String get preview => pick(
    'Prévia do cabeçalho',
    'Header preview',
    'Vista previa del encabezado',
  );
  String get previewText => pick(
    'Confira a leitura do texto sobre a imagem.',
    'Check text readability over the image.',
    'Comprueba la legibilidad del texto sobre la imagen.',
  );
  String get save => pick(
    'Salvar esmaecimento',
    'Save fade settings',
    'Guardar desvanecimiento',
  );
  String get saved => pick(
    'Esmaecimento salvo.',
    'Fade settings saved.',
    'Desvanecimiento guardado.',
  );
  String get saving => pick('Salvando…', 'Saving…', 'Guardando…');
  String get reset => pick(
    'Restaurar valores originais',
    'Restore original values',
    'Restaurar valores originales',
  );
  String get error => pick(
    'Não foi possível concluir. Tente novamente.',
    'Could not complete the action. Try again.',
    'No se pudo completar. Inténtalo de nuevo.',
  );
  String get retry => pick('Tentar novamente', 'Try again', 'Reintentar');
  String get delete => pick('Apagar imagem', 'Delete image', 'Eliminar imagen');
  String get consequence => pick(
    'A imagem deste contexto será removida e o padrão global passará a valer. Outras especialidades serão preservadas. Imagens já agendadas continuarão com suas datas de ativação.',
    'This context’s image will be removed and the global default will apply. Other specialties will be preserved. Scheduled images will keep their activation dates.',
    'La imagen de este contexto se eliminará y se aplicará el valor global. Se conservarán las demás especialidades. Las imágenes programadas conservarán sus fechas de activación.',
  );
  String get cancel => pick('Cancelar', 'Cancel', 'Cancelar');
  String get deleting =>
      pick('Apagando imagem…', 'Deleting image…', 'Eliminando imagen…');
  String get deleted => pick(
    'Imagem removida. Padrão global aplicado.',
    'Image removed. Global default applied.',
    'Imagen eliminada. Valor global aplicado.',
  );
  String get deleteScheduled =>
      pick('Apagar agendada', 'Delete scheduled image', 'Eliminar programada');
  String get scheduledConsequence => pick(
    'Esta imagem agendada será removida de todos os contextos do seu cadastro e não será ativada. A imagem atual será mantida.',
    'This scheduled image will be removed from all contexts in its registration and will not activate. The current image will be kept.',
    'Esta imagen programada se eliminará de todos los contextos de su registro y no se activará. La imagen actual se conservará.',
  );
  String get scheduledDeleted => pick(
    'Imagem agendada removida.',
    'Scheduled image removed.',
    'Imagen programada eliminada.',
  );
  String get protectedGlobal => pick(
    'Este é o padrão global, usado quando não há imagem específica para o comércio, segmento ou especialidade. Use adicionar/substituir para atualizar esse padrão.',
    'This global default is used when no image is configured for the business, segment or specialty. Add or replace it to update this default.',
    'Este valor global se usa cuando no hay imagen específica para el negocio, segmento o especialidad. Añádela o sustitúyela para actualizarlo.',
  );
  String get globalRequired => pick(
    'Cadastre primeiro uma imagem no padrão global desta posição.',
    'First register a global default image for this position.',
    'Primero registra una imagen global para esta posición.',
  );
}
