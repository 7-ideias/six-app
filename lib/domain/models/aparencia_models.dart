import 'package:flutter/material.dart';

enum TemaSistema {
  claro,
  escuro,
  automatico;

  String get label {
    switch (this) {
      case TemaSistema.claro:
        return 'Claro';
      case TemaSistema.escuro:
        return 'Escuro';
      case TemaSistema.automatico:
        return 'Automático';
    }
  }

  static TemaSistema fromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'claro':
        return TemaSistema.claro;
      case 'escuro':
        return TemaSistema.escuro;
      case 'automático':
      case 'automatico':
        return TemaSistema.automatico;
      default:
        return TemaSistema.claro;
    }
  }
}

class PaletaSistema {
  final Color primaria;
  final Color secundaria;
  final Color destaque;
  final Color alerta;
  final Color fundo;
  final Color superficie;
  final Color textoPrimario;
  final Color textoSecundario;

  PaletaSistema({
    required this.primaria,
    required this.secundaria,
    required this.destaque,
    required this.alerta,
    required this.fundo,
    required this.superficie,
    required this.textoPrimario,
    required this.textoSecundario,
  });

  factory PaletaSistema.defaultPalette() {
    return PaletaSistema(
      primaria: const Color(0xFF1F3C88),
      secundaria: const Color(0xFF5E81F4),
      destaque: const Color(0xFF0FA958),
      alerta: const Color(0xFFF59E0B),
      fundo: const Color(0xFFF8FAFC),
      superficie: const Color(0xFFFFFFFF),
      textoPrimario: const Color(0xFF0F172A),
      textoSecundario: const Color(0xFF475569),
    );
  }
}

class ConfiguracaoAparenciaSistema {
  final String? id;
  final String? idEmpresa;
  final TemaSistema tema;
  final PaletaSistema paleta;

  ConfiguracaoAparenciaSistema({
    this.id,
    this.idEmpresa,
    required this.tema,
    required this.paleta,
  });
}
