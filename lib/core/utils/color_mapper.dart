import 'package:flutter/material.dart';

class ColorMapper {
  /// Converte uma [Color] para uma string hexadecimal no formato #RRGGBB.
  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  /// Converte uma string hexadecimal (ex: #1F3C88 ou 1F3C88) para uma [Color].
  /// Se o formato for inválido, retorna [Colors.transparent] ou uma cor padrão.
  static Color fromHex(String hexString, {Color defaultColor = Colors.transparent}) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('ff');
    }
    buffer.write(hexString.replaceFirst('#', ''));
    
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return defaultColor;
    }
  }
}
