import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/presentation/admin/admin_navigation_shell.dart';
import 'package:sixpos/presentation/admin/admin_portal_components.dart';
import 'package:sixpos/presentation/admin/admin_portal_texts.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    required String profileType,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        home: Builder(
          builder:
              (BuildContext context) => AdminNavigationShell(
                texts: AdminPortalTexts.of(context),
                userInfo: AdminPortalUserInfo(
                  name: 'Usuário',
                  email: 'user@example.com',
                  profileType: profileType,
                ),
                currentRoute: '/admin/dashboard',
                pageTitle: 'Admin',
                onLogout: () {},
                onRefresh: () {},
                refreshing: false,
                loggingOut: false,
                child: const SizedBox(height: 200),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menu de imagens aparece para SUPER', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, profileType: 'SUPER');
    expect(find.text('Imagens'), findsOneWidget);
  });

  testWidgets('menu de imagens fica oculto para perfil não SUPER', (
    WidgetTester tester,
  ) async {
    await pumpShell(tester, profileType: 'ADMIN');
    expect(find.text('Imagens'), findsNothing);
  });
}
