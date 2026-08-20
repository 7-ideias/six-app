import 'package:flutter/widgets.dart';
import 'package:sixpos/l10n/six_i18n.dart';

String documentoTr(
  BuildContext context,
  String key, {
  required String pt,
  required String en,
  required String es,
}) {
  final String language = Localizations.localeOf(context).languageCode;
  final String fallback = switch (language) {
    'en' => en,
    'es' => es,
    _ => pt,
  };
  return context.t(key, fallback: fallback);
}

extension DocumentoFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final Iterator<T> iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
