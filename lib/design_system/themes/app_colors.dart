import 'package:flutter/material.dart';

enum AppPalette {
  corporate, // Sóbria Corporativa
  modernPremium, // Moderna Premium
  lightContemporary, // Leve/Contemporânea
}

class AppColors {
  // --- Paleta Corporativa (Padrão) ---
  static const Color corporatePrimary = Color(0xFF1B3B5A);
  static const Color corporateSecondary = Color(0xFF4A90E2);
  static const Color corporateAccent = Color(0xFFF5A623);
  static const Color corporateBackground = Color(0xFFF4F7F9);
  static const Color corporateSurface = Colors.white;
  static const Color corporateError = Color(0xFFD0021B);

  // --- Paleta Moderna Premium ---
  static const Color premiumPrimary = Color(0xFF121212);
  static const Color premiumSecondary = Color(0xFFB89655); // Dourado Champagne
  static const Color premiumAccent = Color(0xFF6C5CE7);
  static const Color premiumBackground = Color(0xFFF9F9FB);
  static const Color premiumSurface = Colors.white;
  static const Color premiumError = Color(0xFFE74C3C);

  // --- Paleta Leve Contemporânea ---
  static const Color contemporaryPrimary = Color(0xFF00B894); // Menta Profundo
  static const Color contemporarySecondary = Color(0xFF0984E3);
  static const Color contemporaryAccent = Color(0xFF6C5CE7);
  static const Color contemporaryBackground = Color(0xFFF0F2F5);
  static const Color contemporarySurface = Colors.white;
  static const Color contemporaryError = Color(0xFFFF7675);

  // --- Cores Dark Mode (Geral) ---
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkPrimary = Color(0xFF90CAF9);
  static const Color darkSecondary = Color(0xFFF48FB1);
}
