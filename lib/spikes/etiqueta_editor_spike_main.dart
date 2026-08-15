import 'package:flutter/material.dart';
import 'package:sixpos/presentation/spikes/etiqueta_editor_web_spike.dart';

void main() {
  runApp(const _EtiquetaEditorSpikeApp());
}

class _EtiquetaEditorSpikeApp extends StatelessWidget {
  const _EtiquetaEditorSpikeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SixApp · Etiquetas · Lote 0',
      themeMode: ThemeMode.system,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const EtiquetaEditorWebSpike(),
    );
  }
}
