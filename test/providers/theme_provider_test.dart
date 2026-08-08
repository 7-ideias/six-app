import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  test('usa tema claro quando nao existe preferencia salva', () async {
    final _FakeThemePreferenceStorage storage = _FakeThemePreferenceStorage();
    final ThemeProvider provider = await _loadMobileProvider(storage);

    expect(provider.usesLocalPersistence, isTrue);
    expect(provider.themeMode, ThemeMode.light);
    expect(storage.readCount, 1);
    expect(storage.writeCount, 0);
  });

  test('carrega preferencia salva como claro', () async {
    final _FakeThemePreferenceStorage storage = _FakeThemePreferenceStorage(
      value: 'claro',
    );
    final ThemeProvider provider = await _loadMobileProvider(storage);

    expect(provider.themeMode, ThemeMode.light);
    expect(storage.readCount, 1);
  });

  test('carrega preferencia salva como escuro antes da primeira UI', () async {
    final _FakeThemePreferenceStorage storage = _FakeThemePreferenceStorage(
      value: 'escuro',
    );
    final ThemeProvider provider = await _loadMobileProvider(storage);

    expect(provider.themeMode, ThemeMode.dark);
    expect(SixThemeResolver().tema, TemaSistema.escuro);
    expect(storage.readCount, 1);
  });

  test('valor persistido invalido usa fallback claro seguro', () async {
    final _FakeThemePreferenceStorage storage = _FakeThemePreferenceStorage(
      value: 'automatico',
    );
    final ThemeProvider provider = await _loadMobileProvider(storage);

    expect(provider.themeMode, ThemeMode.light);
    expect(SixThemeResolver().tema, TemaSistema.claro);
  });

  test('erro de leitura usa fallback sem impedir inicializacao', () async {
    final _FakeThemePreferenceStorage storage = _FakeThemePreferenceStorage(
      readError: StateError('read failed'),
    );
    final ThemeProvider provider = await _loadMobileProvider(storage);

    expect(provider.themeMode, ThemeMode.light);
    expect(storage.readCount, 1);
  });

  test('alterna entre claro e escuro', () async {
    final _FakeThemePreferenceStorage storage = _FakeThemePreferenceStorage();
    final ThemeProvider provider = await _loadMobileProvider(storage);

    await provider.toggleTheme(true);
    expect(provider.themeMode, ThemeMode.dark);

    await provider.toggleTheme(false);
    expect(provider.themeMode, ThemeMode.light);
  });

  test('persiste nova escolha de tema no mobile', () async {
    final _FakeThemePreferenceStorage storage = _FakeThemePreferenceStorage();
    final ThemeProvider provider = await _loadMobileProvider(storage);

    await provider.toggleTheme(true);

    expect(storage.value, 'escuro');
    expect(storage.writeCount, 1);
  });

  test('erro de gravacao nao desfaz o tema visual selecionado', () async {
    final _FakeThemePreferenceStorage storage = _FakeThemePreferenceStorage(
      writeError: StateError('write failed'),
    );
    final ThemeProvider provider = await _loadMobileProvider(storage);

    await provider.toggleTheme(true);

    expect(provider.themeMode, ThemeMode.dark);
    expect(storage.value, isNull);
    expect(storage.writeCount, 1);
  });

  test(
    'nao notifica nem grava quando o tema solicitado ja esta ativo',
    () async {
      final _FakeThemePreferenceStorage storage = _FakeThemePreferenceStorage(
        value: 'claro',
      );
      final ThemeProvider provider = await _loadMobileProvider(storage);
      int notifications = 0;
      provider.addListener(() => notifications += 1);

      await provider.setTheme(TemaSistema.claro);

      expect(notifications, 0);
      expect(storage.writeCount, 0);
    },
  );

  test(
    'web ignora storage local mobile e continua refletindo resolver',
    () async {
      final _FakeThemePreferenceStorage storage = _FakeThemePreferenceStorage(
        value: 'escuro',
      );
      final ThemeProvider provider = await ThemeProvider.load(
        enableLocalPersistence: false,
        storage: storage,
      );
      addTearDown(provider.dispose);

      expect(provider.usesLocalPersistence, isFalse);
      expect(provider.themeMode, ThemeMode.light);
      expect(storage.readCount, 0);

      await provider.toggleTheme(true);

      expect(provider.themeMode, ThemeMode.dark);
      expect(storage.writeCount, 0);

      SixThemeResolver().atualizarTema(TemaSistema.claro);
      expect(provider.themeMode, ThemeMode.light);
    },
  );
}

Future<ThemeProvider> _loadMobileProvider(
  _FakeThemePreferenceStorage storage,
) async {
  final ThemeProvider provider = await ThemeProvider.load(
    enableLocalPersistence: true,
    storage: storage,
  );
  addTearDown(provider.dispose);
  return provider;
}

class _FakeThemePreferenceStorage implements ThemePreferenceStorage {
  _FakeThemePreferenceStorage({this.value, this.readError, this.writeError});

  String? value;
  final Object? readError;
  final Object? writeError;
  int readCount = 0;
  int writeCount = 0;

  @override
  Future<String?> readThemeMode() async {
    readCount += 1;
    final Object? error = readError;
    if (error != null) {
      throw error;
    }
    return value;
  }

  @override
  Future<void> writeThemeMode(String code) async {
    writeCount += 1;
    final Object? error = writeError;
    if (error != null) {
      throw error;
    }
    value = code;
  }
}
