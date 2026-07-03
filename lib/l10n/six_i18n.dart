import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'web_i18n_store.dart';

extension SixI18nBuildContext on BuildContext {
  /// Resolve textos do Six a partir do pacote de traduções carregado do backend.
  ///
  /// Uso preferencial em telas web, Android e iOS:
  /// `context.t('common.save')`.
  ///
  /// [fallback] deve ser usado apenas como proteção mínima durante migração ou
  /// quando o endpoint de i18n ainda não trouxe a chave.
  String t(String key, {String? fallback}) {
    final code = _sixCurrentLanguageCode();
    final value = SixI18nStore.instance.string(code, key);
    if (value != null && value.isNotEmpty) {
      return value;
    }

    final resolvedFallback = fallback ?? _fallbacks[code]?[key] ?? _fallbacks['pt']?[key];
    if (resolvedFallback != null && resolvedFallback.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('[i18n] chave ausente: $key para idioma=$code. Usando fallback.');
      }
      return resolvedFallback;
    }

    if (kDebugMode) {
      debugPrint('[i18n] chave ausente: $key para idioma=$code.');
    }
    return key;
  }

  String _sixCurrentLanguageCode() {
    try {
      return Localizations.localeOf(this).languageCode;
    } catch (_) {
      return 'pt';
    }
  }
}

const Map<String, Map<String, String>> _fallbacks = {
  'pt': {
    'app.title': 'Six',
    'common.save': 'Salvar',
    'common.cancel': 'Cancelar',
    'common.back': 'Voltar',
    'common.tryAgain': 'Tentar novamente',
    'common.unexpectedError': 'Erro inesperado',
    'common.unableToLoad': 'Não foi possível carregar.',
    'auth.loginRequiredFields': 'Por favor, preencha o e-mail e a senha',
    'auth.loginTitleMobile': 'Entrar',
    'auth.loginSubtitleMobile': 'Para entrar em sua conta, informe\nseu e-mail e senha',
    'auth.email': 'E-mail',
    'auth.password': 'Senha',
    'auth.forgotPassword': 'Esqueceu a senha?',
    'auth.continue': 'Continuar',
    'auth.noAccount': 'Ainda não tem uma conta?',
    'auth.createAccount': 'Criar conta',
    'auth.signInWithApple': 'Entrar com Apple',
    'auth.signInWithGoogle': 'Entrar com Google',
    'auth.googleLoginError': 'Não foi possível concluir o login com Google.',
    'auth.appleLoginMock': 'Login com Apple (mocked)',
    'auth.termsPrefix': 'Ao clicar em "Continuar", declaro ter lido e concordo com os ',
    'auth.terms': 'Termos de Uso e Política de Privacidade',
    'configuracoes.regionalizationTitle': 'Regionalização',
    'configuracoes.descRegionalization': 'Idioma, país, moeda, fuso horário, formatos de data e padronização financeira da empresa.',
    'configuracoes.languageAndRegionalConventions': 'Idioma e convenções regionais',
    'configuracoes.languageAndRegionalConventionsDesc': 'Defina a experiência local da empresa, incluindo idioma, fuso e padrões de exibição.',
    'configuracoes.systemLanguage': 'Idioma do sistema',
    'configuracoes.countryRegion': 'País / região',
    'configuracoes.timeZone': 'Fuso horário',
    'configuracoes.dateFormat': 'Formato de data',
    'configuracoes.timeFormat': 'Formato de hora',
    'configuracoes.firstDayOfWeek': 'Primeiro dia da semana',
    'configuracoes.numberFormat': 'Formato numérico',
    'configuracoes.currencyAndFinancialStandard': 'Moeda e padronização financeira',
    'configuracoes.currencyAndFinancialStandardDesc': 'Essas definições influenciam dashboards, vendas, ordem de serviço, orçamentos e documentos.',
    'configuracoes.mainCurrency': 'Moeda principal',
    'configuracoes.symbolPosition': 'Posição do símbolo',
    'configuracoes.decimalPlaces': 'Casas decimais',
    'configuracoes.decimalSeparator': 'Separador decimal',
    'configuracoes.thousandSeparator': 'Separador de milhar',
    'configuracoes.allowMultipleCurrencies': 'Permitir múltiplas moedas',
    'configuracoes.allowMultipleCurrenciesDesc': 'Mantém a base preparada para cenários internacionais e conversão futura.',
    'configuracoes.applyFinancialRounding': 'Aplicar arredondamento financeiro',
    'configuracoes.applyFinancialRoundingDesc': 'Padroniza cálculos e evita divergências de centavos em documentos e totais.',
  },
  'en': {
    'app.title': 'Six',
    'common.save': 'Save',
    'common.cancel': 'Cancel',
    'common.back': 'Back',
    'common.tryAgain': 'Try again',
    'common.unexpectedError': 'Unexpected error',
    'common.unableToLoad': 'Could not load.',
    'auth.loginRequiredFields': 'Please fill in email and password',
    'auth.loginTitleMobile': 'Sign in',
    'auth.loginSubtitleMobile': 'To access your account, enter\nyour email and password',
    'auth.email': 'Email',
    'auth.password': 'Password',
    'auth.forgotPassword': 'Forgot password?',
    'auth.continue': 'Continue',
    'auth.noAccount': 'Don\'t have an account yet?',
    'auth.createAccount': 'Create account',
    'auth.signInWithApple': 'Sign in with Apple',
    'auth.signInWithGoogle': 'Sign in with Google',
    'auth.googleLoginError': 'Could not complete Google sign-in.',
    'auth.appleLoginMock': 'Apple sign-in (mocked)',
    'auth.termsPrefix': 'By clicking "Continue", I confirm that I have read and agree with the ',
    'auth.terms': 'Terms of Use and Privacy Policy',
  },
  'es': {
    'app.title': 'Six',
    'common.save': 'Guardar',
    'common.cancel': 'Cancelar',
    'common.back': 'Volver',
    'common.tryAgain': 'Intentar de nuevo',
    'common.unexpectedError': 'Error inesperado',
    'common.unableToLoad': 'No se pudo cargar.',
    'auth.loginRequiredFields': 'Completa el correo electrónico y la contraseña',
    'auth.loginTitleMobile': 'Entrar',
    'auth.loginSubtitleMobile': 'Para acceder a tu cuenta, ingresa\ntu correo y contraseña',
    'auth.email': 'Correo electrónico',
    'auth.password': 'Contraseña',
    'auth.forgotPassword': '¿Olvidaste tu contraseña?',
    'auth.continue': 'Continuar',
    'auth.noAccount': '¿Aún no tienes una cuenta?',
    'auth.createAccount': 'Crear cuenta',
    'auth.signInWithApple': 'Entrar con Apple',
    'auth.signInWithGoogle': 'Entrar con Google',
    'auth.googleLoginError': 'No se pudo completar el inicio de sesión con Google.',
    'auth.appleLoginMock': 'Inicio de sesión con Apple (mocked)',
    'auth.termsPrefix': 'Al hacer clic en "Continuar", declaro que leí y acepto los ',
    'auth.terms': 'Términos de Uso y Política de Privacidad',
  },
};
