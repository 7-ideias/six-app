import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signature/signature.dart';
import 'package:sixpos/core/services/pdf_file_share_service.dart';
import 'package:sixpos/data/models/atendimento_tecnico_models.dart';
import 'package:sixpos/data/models/caixa_completo_movimentos_models.dart';
import 'package:sixpos/data/models/caixa_models.dart';
import 'package:sixpos/data/models/cliente_usuario_model.dart';
import 'package:sixpos/data/models/colaborador_usuario_model.dart';
import 'package:sixpos/data/models/dominio_models.dart';
import 'package:sixpos/data/models/regionalizacao_models.dart';
import 'package:sixpos/data/services/caixa/caixa_api_client.dart';
import 'package:sixpos/data/services/cliente_usuario/cliente_usuario_api_client.dart';
import 'package:sixpos/data/services/colaborador_usuario/colaborador_usuario_api_client.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:sixpos/design_system/helpers/six_theme_resolver.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/domain/models/aparencia_models.dart';
import 'package:sixpos/domain/models/regionalizacao_models.dart';
import 'package:sixpos/domain/services/atendimento_tecnico/atendimento_pdf_share_service.dart';
import 'package:sixpos/domain/services/atendimento_tecnico/atendimento_tecnico_service.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/presentation/components/mobile/sixoapp_mobile_loading_scene.dart';
import 'package:sixpos/presentation/screens/atendimento_tecnico_editar_mobile_screen.dart';
import 'package:sixpos/presentation/screens/atendimento_tecnico_mobile_screen.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_mobile_screen.dart';
import 'package:sixpos/presentation/screens/atendimentos_tecnicos_pendentes_pagamento_mobile_screen.dart';
import 'package:sixpos/presentation/screens/opcoes_servicos_atendimento_mobile_screen.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'accessToken': 'token-test',
      'idUnicoDaEmpresa': 'empresa-test',
    });
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  tearDown(() {
    SixThemeResolver().atualizarTema(TemaSistema.claro);
  });

  for (final _ThemeCase themeCase in _themeCases) {
    testWidgets(
      'service menu opens assistance screens in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final List<Widget> destinations = <Widget>[];

        await _pumpMobile(
          tester,
          brightness: themeCase.brightness,
          size: const Size(430, 940),
          child: OpcoesServicosAtendimentoMobileScreen(
            onNavigate: (_, Widget page) => destinations.add(page),
          ),
        );

        expect(_scaffoldBackground(tester), themeCase.colors.background);
        final Finder serviceCardLabel = find.descendant(
          of: find.byKey(const ValueKey<String>('servicos-action-new-service')),
          matching: find.text('Serviços'),
        );
        expect(serviceCardLabel, findsOneWidget);
        expect(find.text('Consultar serviços em andamento'), findsOneWidget);
        expect(find.text('Orçamentos aguardando aprovação'), findsOneWidget);
        expect(find.text('Serviços já encerrados'), findsOneWidget);
        expect(
          find.text(
            'Consulte serviços que ainda precisam da aprovação do cliente',
          ),
          findsOneWidget,
        );
        expect(
          _hasMaterialAncestorColor(
            tester,
            serviceCardLabel,
            themeCase.colors.surface,
          ),
          isTrue,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('servicos-action-in-progress')),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(
            const ValueKey<String>('servicos-action-waiting-approval'),
          ),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey<String>('servicos-action-closed-services')),
        );
        await tester.pump();

        expect(destinations, hasLength(3));
        final AtendimentosTecnicosMobileScreen inProgressPage =
            destinations.first as AtendimentosTecnicosMobileScreen;
        expect(inProgressPage.listContext.statusFilter, isNull);
        final AtendimentosTecnicosMobileScreen approvalPage =
            destinations[1] as AtendimentosTecnicosMobileScreen;
        expect(
          approvalPage.listContext.statusFilter,
          'WAITING_CUSTOMER_APROVAL',
        );
        final AtendimentosTecnicosMobileScreen closedPage =
            destinations.last as AtendimentosTecnicosMobileScreen;
        expect(closedPage.listContext.statusFilter, 'FINALIZED_GROUP');
      },
    );

    testWidgets(
      'technical list loading empty and error states use ${themeCase.description} theme',
      (WidgetTester tester) async {
        final Completer<List<AtendimentoTecnicoModel>> loadingCompleter =
            Completer<List<AtendimentoTecnicoModel>>();

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: _FakeAtendimentoTecnicoService(
            listCompleter: loadingCompleter,
          ),
          settle: false,
        );
        await tester.pump();

        expect(_scaffoldBackground(tester), themeCase.colors.background);
        expect(
          find.bySemanticsLabel('Carregando atendimentos técnicos'),
          findsOneWidget,
        );

        loadingCompleter.complete(<AtendimentoTecnicoModel>[]);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));

        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Nenhum atendimento encontrado'),
          420,
          scrollable: _verticalScrollable(),
        );
        await tester.pump();

        expect(find.text('Nenhum atendimento encontrado'), findsOneWidget);
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Nenhum atendimento encontrado'),
            themeCase.colors.surface,
          ),
          isTrue,
        );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: _FakeAtendimentoTecnicoService(throwOnList: true),
        );

        expect(
          find.text('Não foi possível carregar os atendimentos'),
          findsOneWidget,
        );
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Não foi possível carregar os atendimentos'),
            themeCase.colors.surface,
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'technical list cards detail and filters expose semantic states in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService(
              atendimentos: _atendimentosTecnicos(),
            );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
        );

        expect(find.text('Atendimentos técnicos'), findsOneWidget);
        expect(
          find.text(
            'Buscar por cliente, técnico, status, equipamento ou número',
          ),
          findsOneWidget,
        );
        expect(find.text('10 atendimentos'), findsOneWidget);
        final Finder summaryCard = find.byKey(
          const ValueKey<String>('atendimentos-tecnicos-resumo-compacto'),
        );
        expect(summaryCard, findsOneWidget);
        expect(
          find.descendant(
            of: summaryCard,
            matching: find.text('Resumo do período'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: summaryCard, matching: find.text('10')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: summaryCard, matching: find.text('atendimentos')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: summaryCard, matching: find.text('7')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: summaryCard, matching: find.text('em aberto')),
          findsWidgets,
        );
        expect(
          find.descendant(of: summaryCard, matching: find.text('1')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: summaryCard, matching: find.text('assinado')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: summaryCard, matching: find.text('R\$ 1.260,00')),
          findsOneWidget,
        );
        expect(find.text('Total exibido'), findsNothing);
        expect(find.text('Aguardam recebimento'), findsNothing);
        expect(find.text('Com aceite do cliente'), findsNothing);
        expect(find.text('Saldo pendente'), findsNothing);
        expect(
          tester.getTopLeft(summaryCard).dy,
          lessThan(tester.getTopLeft(find.text('10 atendimentos')).dy),
        );
        expect(find.text('Mais recentes'), findsOneWidget);
        expect(
          find.byIcon(Icons.account_balance_wallet_outlined),
          findsWidgets,
        );
        final TextField searchField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        expect(searchField.decoration?.filled, isTrue);
        expect(searchField.decoration?.fillColor, themeCase.colors.surface);

        expect(service.listCalls, 1);
        Finder sheetText(String text) => find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.text(text),
        );
        Finder sheetWidget(Finder finder) => find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: finder,
        );

        await tester.tap(find.byIcon(Icons.tune_rounded).first);
        await tester.pumpAndSettle();
        expect(find.text('Filtrar atendimentos'), findsOneWidget);
        expect(sheetText('Período'), findsOneWidget);
        expect(sheetText('Todas as datas'), findsOneWidget);
        expect(sheetText('Técnico responsável'), findsOneWidget);
        expect(sheetText('Todos os técnicos'), findsOneWidget);
        expect(sheetText('Status'), findsOneWidget);
        expect(sheetText('Todos os status'), findsOneWidget);
        expect(sheetText('Status do pagamento'), findsOneWidget);
        expect(sheetText('Todos os pagamentos'), findsOneWidget);
        expect(sheetText('Técnica'), findsNothing);
        expect(
          tester.getTopLeft(sheetText('Status')).dy,
          greaterThan(tester.getTopLeft(sheetText('Técnico responsável')).dy),
        );
        expect(
          tester.getTopLeft(sheetText('Status do pagamento')).dy,
          greaterThan(tester.getTopLeft(sheetText('Status')).dy),
        );
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Filtrar atendimentos'),
            themeCase.colors.background,
          ),
          isTrue,
        );
        await tester.tap(find.byIcon(Icons.close_rounded).last);
        await tester.pumpAndSettle();
        expect(find.text('10 atendimentos'), findsOneWidget);
        expect(service.listCalls, 1);

        await tester.tap(find.byIcon(Icons.tune_rounded).first);
        await tester.pumpAndSettle();
        await tester.tap(sheetText('Período'));
        await tester.pumpAndSettle();
        expect(sheetText('Próximos 7 dias'), findsOneWidget);
        await tester.tap(sheetText('Próximos 7 dias'));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
        await tester.pumpAndSettle();
        expect(sheetText('Próximos 7 dias'), findsOneWidget);
        expect(sheetText('Todos os técnicos'), findsOneWidget);

        await tester.tap(sheetText('Técnico responsável'));
        await tester.pumpAndSettle();
        expect(sheetText('Buscar técnico'), findsOneWidget);
        expect(
          tester.getTopLeft(sheetText('Todos os técnicos')).dy,
          lessThan(tester.getTopLeft(sheetText('Técnica')).dy),
        );
        await tester.enterText(sheetWidget(find.byType(TextField)), 'tecnica');
        await tester.pump();
        expect(sheetText('Técnica'), findsOneWidget);
        await tester.enterText(sheetWidget(find.byType(TextField)), 'zzzz');
        await tester.pump();
        expect(sheetText('Nenhum técnico encontrado.'), findsOneWidget);
        await tester.enterText(sheetWidget(find.byType(TextField)), 'tecnica');
        await tester.pump();
        await tester.tap(sheetText('Técnica'));
        await tester.pump();
        expect(
          sheetWidget(find.byIcon(Icons.check_box_rounded)),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
        await tester.pumpAndSettle();
        expect(sheetText('Técnica'), findsOneWidget);
        expect(sheetText('Próximos 7 dias'), findsOneWidget);

        await tester.tap(sheetText('Status do pagamento'));
        await tester.pumpAndSettle();
        await tester.tap(sheetText('Em aberto'));
        await tester.pumpAndSettle();
        expect(sheetText('Próximos 7 dias'), findsOneWidget);
        expect(sheetText('Técnica'), findsOneWidget);
        expect(sheetText('Em aberto'), findsOneWidget);
        await tester.tap(
          find.widgetWithText(FilledButton, 'Ver 7 atendimentos'),
        );
        await tester.pumpAndSettle();

        expect(find.text('7 atendimentos'), findsOneWidget);
        expect(service.listCalls, 1);
        expect(find.text('3'), findsWidgets);
        expect(find.widgetWithText(InputChip, 'Técnica'), findsOneWidget);
        expect(find.widgetWithText(InputChip, 'Em aberto'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.tune_rounded).first);
        await tester.pumpAndSettle();
        expect(sheetText('Técnica'), findsOneWidget);
        await tester.tap(sheetText('Técnico responsável'));
        await tester.pumpAndSettle();
        expect(
          sheetWidget(find.byIcon(Icons.check_box_rounded)),
          findsOneWidget,
        );
        await tester.tap(sheetText('Todos os técnicos'));
        await tester.pump();
        await tester.tap(find.byIcon(Icons.arrow_back_rounded).last);
        await tester.pumpAndSettle();
        expect(sheetText('Técnica'), findsOneWidget);

        await tester.tap(sheetText('Técnico responsável'));
        await tester.pumpAndSettle();
        await tester.tap(sheetText('Todos os técnicos'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
        await tester.pumpAndSettle();
        expect(sheetText('Todos os técnicos'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close_rounded).last);
        await tester.pumpAndSettle();
        expect(find.text('7 atendimentos'), findsOneWidget);
        expect(find.widgetWithText(InputChip, 'Técnica'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.tune_rounded).first);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Limpar'));
        await tester.pump();
        expect(sheetText('Todas as datas'), findsOneWidget);
        expect(sheetText('Todos os técnicos'), findsOneWidget);
        expect(sheetText('Todos os status'), findsOneWidget);
        expect(sheetText('Todos os pagamentos'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close_rounded).last);
        await tester.pumpAndSettle();
        expect(find.text('7 atendimentos'), findsOneWidget);
        expect(find.widgetWithText(InputChip, 'Técnica'), findsOneWidget);

        final InputChip paymentChip = tester.widget<InputChip>(
          find.widgetWithText(InputChip, 'Em aberto'),
        );
        paymentChip.onDeleted!();
        await tester.pump();
        expect(find.text('10 atendimentos'), findsOneWidget);
        expect(find.text('2'), findsWidgets);
        final ActionChip clearFiltersChip = tester.widget<ActionChip>(
          find.widgetWithText(ActionChip, 'Limpar filtros'),
        );
        clearFiltersChip.onPressed!();
        await tester.pump();
        expect(find.text('10 atendimentos'), findsOneWidget);
        expect(find.widgetWithText(InputChip, 'Técnica'), findsNothing);

        await tester.enterText(find.byType(TextField).first, 'pendente');
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('10 atendimentos'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('1 atendimento'), findsOneWidget);
        final Finder searchSummaryCard = find.byKey(
          const ValueKey<String>('atendimentos-tecnicos-resumo-compacto'),
        );
        expect(
          find.descendant(
            of: searchSummaryCard,
            matching: find.text('R\$ 180,00'),
          ),
          findsOneWidget,
        );
        await _dragUntilTextVisible(tester, 'OS-PAGAMENTO');
        await tester.pump();
        expect(find.textContaining('OS-PAGAMENTO'), findsOneWidget);
        expect(find.text('Financeiro aberto'), findsWidgets);

        await tester.enterText(find.byType(TextField).first, 'sem resultado');
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.text(
            'Nenhum atendimento encontrado com os filtros selecionados.',
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            const ValueKey<String>('atendimentos-tecnicos-resumo-compacto'),
          ),
          findsNothing,
        );
        await tester.tap(find.widgetWithText(OutlinedButton, 'Limpar filtros'));
        await tester.pump();
        expect(find.text('10 atendimentos'), findsOneWidget);

        await tester.enterText(find.byType(TextField).first, 'pendente');
        await tester.pump(const Duration(milliseconds: 500));
        await _dragUntilTextVisible(tester, 'OS-PAGAMENTO');
        await tester.pump();
        expect(find.textContaining('OS-PAGAMENTO'), findsOneWidget);
        expect(find.text('Financeiro aberto'), findsWidgets);

        final Finder detailsButton =
            find
                .byWidgetPredicate(
                  (Widget widget) =>
                      widget is IconButton &&
                      widget.tooltip == 'Ver detalhes do atendimento',
                )
                .last;
        await Scrollable.ensureVisible(
          tester.element(detailsButton),
          alignment: 0.65,
        );
        await tester.pump();
        await tester.tap(detailsButton);
        await tester.pumpAndSettle();

        await _dragUntilTextVisible(
          tester,
          'Resumo da ordem de serviço',
          exact: true,
          lastScrollable: true,
        );
        await tester.pump();
        expect(find.text('Resumo da ordem de serviço'), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Compartilhar PDF'),
          findsOneWidget,
        );
        expect(find.byTooltip('Compartilhar atendimento'), findsNothing);
        expect(find.byIcon(Icons.send_rounded), findsNothing);
        expect(service.detailCalls, 1);
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Resumo da ordem de serviço'),
            themeCase.colors.surface,
          ),
          isTrue,
        );
        final FilledButton receiveButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Receber'),
        );
        expect(receiveButton.onPressed, isNotNull);
        expect(service.receiveCalls, 0);

        await _dragUntilTextVisible(
          tester,
          'Equipamento e diagnóstico',
          exact: true,
          lastScrollable: true,
        );
        expect(find.text('Equipamento e diagnóstico'), findsOneWidget);

        await _dragUntilTextVisible(
          tester,
          'Resumo financeiro',
          exact: true,
          lastScrollable: true,
        );
        expect(find.text('Resumo financeiro'), findsOneWidget);
        expect(find.text('Liquidação'), findsOneWidget);

        await _dragUntilTextVisible(
          tester,
          'Itens',
          exact: true,
          lastScrollable: true,
        );
        expect(find.text('Itens'), findsOneWidget);
        expect(find.text('Tela iPhone compatível'), findsOneWidget);
        expect(find.text('Mão de obra técnica'), findsOneWidget);

        await _dragUntilTextVisible(
          tester,
          'Histórico de status',
          exact: true,
          lastScrollable: true,
        );
        expect(find.text('Histórico de status'), findsOneWidget);

        await _dragUntilTextVisible(
          tester,
          'Histórico de auditoria',
          exact: true,
          lastScrollable: true,
        );
        expect(find.text('Histórico de auditoria'), findsOneWidget);
      },
    );

    testWidgets(
      'advanced status filter supports multiple selections in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService(
              atendimentos: _atendimentosTecnicos(),
            );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
        );

        Finder sheetText(String text) => find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.text(text),
        );

        await tester.tap(find.byIcon(Icons.tune_rounded).first);
        await tester.pumpAndSettle();
        expect(sheetText('Status'), findsOneWidget);
        expect(sheetText('Todos os status'), findsOneWidget);

        await tester.tap(sheetText('Status'));
        await tester.pumpAndSettle();
        expect(sheetText('Todos os status'), findsOneWidget);
        expect(sheetText('Aberta'), findsOneWidget);
        expect(sheetText('Pendente de pagamento'), findsOneWidget);

        await tester.tap(sheetText('Aberta'));
        await tester.pump();
        await tester.tap(sheetText('Pendente de pagamento'));
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(DraggableScrollableSheet),
            matching: find.byIcon(Icons.check_box_rounded),
          ),
          findsNWidgets(2),
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
        await tester.pumpAndSettle();
        expect(sheetText('2 selecionados'), findsOneWidget);
        expect(sheetText('Aberta'), findsNothing);
        await tester.tap(
          find.widgetWithText(FilledButton, 'Ver 2 atendimentos'),
        );
        await tester.pumpAndSettle();

        expect(find.text('2 atendimentos'), findsOneWidget);
        expect(
          find.widgetWithText(InputChip, '2 selecionados'),
          findsOneWidget,
        );
        final Finder filteredSummaryCard = find.byKey(
          const ValueKey<String>('atendimentos-tecnicos-resumo-compacto'),
        );
        expect(
          find.descendant(of: filteredSummaryCard, matching: find.text('2')),
          findsNWidgets(2),
        );
        expect(
          find.descendant(
            of: filteredSummaryCard,
            matching: find.text('atendimentos'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('OS-ABERTA'), findsOneWidget);
        await _dragUntilTextVisible(tester, 'OS-PAGAMENTO');
        expect(find.textContaining('OS-PAGAMENTO'), findsOneWidget);
        expect(service.listCalls, 1);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'advanced technician filter is scrollable and supports multiple selections in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final List<ColaboradorUsuarioResumo> tecnicos =
            List<ColaboradorUsuarioResumo>.generate(32, (int index) {
              final String suffix = (index + 1).toString().padLeft(2, '0');
              return _tecnico(
                nome: 'Técnico $suffix Six',
                id: 'tec-$suffix',
                nomeDeGuerra: 'Técnico $suffix',
                email: 'tecnico$suffix@six.test',
              );
            });
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService(
              atendimentos: <AtendimentoTecnicoModel>[
                _atendimento(
                  numero: 'OS-TEC-01',
                  statusCodigo: 'ABERTA',
                  statusNome: 'Aberta',
                  idTecnicoResponsavel: 'tec-01',
                  nomeTecnicoResponsavel: 'Técnico 01',
                  dataAtualizacao: DateTime(2026, 8, 7, 9),
                ),
                _atendimento(
                  numero: 'OS-TEC-25',
                  statusCodigo: 'EM_ANDAMENTO',
                  statusNome: 'Em andamento',
                  idTecnicoResponsavel: 'tec-25',
                  nomeTecnicoResponsavel: 'Técnico 25',
                  dataAtualizacao: DateTime(2026, 8, 9, 9),
                ),
                _atendimento(
                  numero: 'OS-TEC-32',
                  statusCodigo: 'AGUARDANDO_PECA',
                  statusNome: 'Aguardando peça',
                  idTecnicoResponsavel: 'tec-32',
                  nomeTecnicoResponsavel: 'Técnico 32',
                  dataAtualizacao: DateTime(2026, 8, 8, 9),
                ),
              ],
            );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
          size: const Size(390, 680),
          tecnicos: tecnicos,
        );

        Finder sheetText(String text) => find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.text(text),
        );
        Finder sheetWidget(Finder finder) => find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: finder,
        );

        await tester.tap(find.byIcon(Icons.tune_rounded).first);
        await tester.pumpAndSettle();

        expect(sheetText('Técnico responsável'), findsOneWidget);
        expect(sheetText('Todos os técnicos'), findsOneWidget);
        expect(sheetText('Técnico 25'), findsNothing);
        expect(
          tester.getTopLeft(sheetText('Status do pagamento')).dy,
          greaterThan(tester.getTopLeft(sheetText('Técnico responsável')).dy),
        );

        await tester.tap(sheetText('Técnico responsável'));
        await tester.pumpAndSettle();

        expect(sheetText('Todos os técnicos'), findsOneWidget);
        expect(sheetText('Técnico 01'), findsOneWidget);
        expect(
          tester.getTopLeft(sheetText('Todos os técnicos')).dy,
          lessThan(tester.getTopLeft(sheetText('Técnico 01')).dy),
        );
        expect(sheetText('Técnico 25'), findsNothing);

        final Finder technicianSearch = sheetWidget(find.byType(TextField));
        await tester.showKeyboard(technicianSearch);
        await tester.enterText(technicianSearch, 'tecnico 25');
        await tester.pump();

        expect(sheetText('Buscar técnico'), findsOneWidget);
        expect(sheetText('Técnico 25'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(sheetText('Técnico 25'));
        await tester.pump();
        expect(
          sheetWidget(find.byIcon(Icons.check_box_rounded)),
          findsOneWidget,
        );

        await tester.enterText(technicianSearch, 'sem match');
        await tester.pump();
        expect(sheetText('Nenhum técnico encontrado.'), findsOneWidget);

        await tester.enterText(technicianSearch, '');
        await tester.pump();
        await _dragUntilTextVisible(
          tester,
          'Técnico 32',
          exact: true,
          lastScrollable: true,
        );
        await tester.pump();

        expect(sheetText('Técnico 32'), findsOneWidget);
        await tester.tap(sheetText('Técnico 32'));
        await tester.pump();
        expect(
          sheetWidget(find.byIcon(Icons.check_box_rounded)),
          findsOneWidget,
        );
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
        await tester.pumpAndSettle();

        expect(sheetText('2 selecionados'), findsOneWidget);
        await tester.tap(
          find.widgetWithText(FilledButton, 'Ver 2 atendimentos'),
        );
        await tester.pumpAndSettle();

        expect(find.text('2 atendimentos'), findsOneWidget);
        expect(
          find.widgetWithText(InputChip, '2 selecionados'),
          findsOneWidget,
        );
        expect(find.textContaining('OS-TEC-25'), findsOneWidget);
        await _dragUntilTextVisible(tester, 'OS-TEC-32');
        expect(find.textContaining('OS-TEC-32'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'compact technical summary tolerates narrow width and larger text in ${themeCase.description} mode',
      (WidgetTester tester) async {
        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: _FakeAtendimentoTecnicoService(
            atendimentos: _atendimentosTecnicos(),
          ),
          size: const Size(320, 760),
          textScale: 1.3,
        );

        final Finder summaryCard = find.byKey(
          const ValueKey<String>('atendimentos-tecnicos-resumo-compacto'),
        );
        expect(summaryCard, findsOneWidget);
        expect(
          find.descendant(
            of: summaryCard,
            matching: find.text('Resumo do período'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: summaryCard, matching: find.text('R\$ 1.260,00')),
          findsOneWidget,
        );
        expect(find.text('Total exibido'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'technical list highlights unsigned open attendances in ${themeCase.description} mode',
      (WidgetTester tester) async {
        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: _FakeAtendimentoTecnicoService(
            atendimentos: <AtendimentoTecnicoModel>[
              _atendimento(
                numero: 'OS-ABERTA-SEM-ASSINATURA',
                statusCodigo: 'EM_ANDAMENTO',
                statusNome: 'Em andamento',
              ),
              _atendimento(
                numero: 'OS-FINAL-SEM-ASSINATURA',
                statusCodigo: 'CONCLUIDO',
                statusNome: 'Concluída',
                valorEmAberto: 0,
                liquidada: true,
              ),
              _atendimento(
                numero: 'OS-ABERTA-ASSINADA',
                statusCodigo: 'EM_ANDAMENTO',
                statusNome: 'Em andamento',
                assinaturaAprovada: true,
              ),
            ],
          ),
        );

        expect(find.textContaining('OS-ABERTA-SEM-ASSINATURA'), findsOneWidget);
        expect(find.textContaining('OS-FINAL-SEM-ASSINATURA'), findsOneWidget);
        expect(find.textContaining('OS-ABERTA-ASSINADA'), findsOneWidget);
        expect(find.text('Cliente não assinou'), findsOneWidget);
        expect(find.byIcon(Icons.assignment_late_outlined), findsOneWidget);

        final Text warningText = tester.widget<Text>(
          find.text('Cliente não assinou'),
        );
        expect(warningText.style?.color, themeCase.colors.error);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'in progress exposes every status while closed remains grouped in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService inProgressService =
            _FakeAtendimentoTecnicoService(
              atendimentos: <AtendimentoTecnicoModel>[
                _atendimento(
                  numero: 'OS-ABERTA',
                  statusCodigo: 'ABERTA',
                  statusNome: 'Aberto',
                ),
                for (int index = 1; index <= 4; index++)
                  _atendimento(
                    numero: 'OS-ENTREGUE-$index',
                    statusCodigo: 'ENTREGUE',
                    statusNome: 'ENTREGUE(editado2)',
                    valorEmAberto: 0,
                    liquidada: true,
                  ),
              ],
            );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: inProgressService,
          listContext: const AtendimentosTecnicosMobileListContext.inProgress(),
        );

        expect(inProgressService.lastListStatus, isNull);
        expect(find.text('Serviços em andamento'), findsWidgets);
        expect(find.text('5 atendimentos'), findsOneWidget);

        Finder sheetText(String text) => find.descendant(
          of: find.byType(DraggableScrollableSheet),
          matching: find.text(text),
        );
        await tester.tap(find.byIcon(Icons.tune_rounded).first);
        await tester.pumpAndSettle();
        await tester.tap(sheetText('Status'));
        await tester.pumpAndSettle();
        expect(sheetText('ENTREGUE(editado2)'), findsOneWidget);
        expect(sheetText('4'), findsOneWidget);
        await tester.tap(sheetText('ENTREGUE(editado2)'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Ver 4 atendimentos'),
        );
        await tester.pumpAndSettle();
        expect(find.text('4 atendimentos'), findsOneWidget);
        expect(find.textContaining('OS-ENTREGUE-1'), findsOneWidget);

        final _FakeAtendimentoTecnicoService closedService =
            _FakeAtendimentoTecnicoService();

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: closedService,
          listContext: const AtendimentosTecnicosMobileListContext.closed(),
        );

        expect(closedService.lastListStatus, 'FINALIZED_GROUP');
        expect(find.text('Serviços já encerrados'), findsWidgets);

        await tester.scrollUntilVisible(
          find.text('Nenhum serviço encerrado encontrado.'),
          420,
          scrollable: _verticalScrollable(),
        );
        await tester.pump();

        expect(
          find.text('Nenhum serviço encerrado encontrado.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'waiting approval query uses contextual status and texts in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService();

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
          listContext:
              const AtendimentosTecnicosMobileListContext.waitingCustomerApproval(),
        );

        expect(service.lastListStatus, 'WAITING_CUSTOMER_APROVAL');
        expect(find.text('Orçamentos aguardando aprovação'), findsWidgets);
        expect(find.text('0 atendimentos'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Nenhum orçamento aguardando aprovação no momento.'),
          420,
          scrollable: _verticalScrollable(),
        );
        await tester.pump();

        expect(
          find.text('Nenhum orçamento aguardando aprovação no momento.'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Quando um orçamento for enviado e estiver aguardando a decisão do cliente, ele aparecerá aqui.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'waiting approval status is friendly and API errors remain contextual in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService(
              atendimentos: <AtendimentoTecnicoModel>[
                _atendimento(
                  numero: 'OS-WAITING',
                  statusCodigo: 'WAITING_CUSTOMER_APROVAL',
                  statusNome: '',
                ),
              ],
            );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
          listContext:
              const AtendimentosTecnicosMobileListContext.waitingCustomerApproval(),
        );

        expect(service.lastListStatus, 'WAITING_CUSTOMER_APROVAL');
        expect(
          find.textContaining('Aguardando aprovação do cliente'),
          findsWidgets,
        );
        expect(find.textContaining('WAITING_CUSTOMER_APROVAL'), findsNothing);

        final _FakeAtendimentoTecnicoService errorService =
            _FakeAtendimentoTecnicoService(throwOnList: true);
        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: errorService,
          listContext:
              const AtendimentosTecnicosMobileListContext.waitingCustomerApproval(),
        );

        expect(errorService.lastListStatus, 'WAITING_CUSTOMER_APROVAL');
        expect(
          find.text(
            'Não foi possível consultar os orçamentos. Tente novamente.',
          ),
          findsOneWidget,
        );
        expect(find.text('Tentar novamente'), findsOneWidget);
      },
    );

    testWidgets(
      'technical detail shares pdf once and keeps close button in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService(
              atendimentos: <AtendimentoTecnicoModel>[
                _atendimento(
                  numero: 'OS-PDF',
                  statusCodigo: 'EM_ANDAMENTO',
                  statusNome: 'Em andamento',
                ),
              ],
            );
        final _FakeAtendimentoPdfShareService pdfShareService =
            _FakeAtendimentoPdfShareService(
              completer: Completer<AtendimentoPdfShareResult>(),
            );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
          pdfShareService: pdfShareService,
        );

        await _dragUntilTextVisible(tester, 'OS-PDF');
        await tester.pump();
        final Finder detailsButton = find.byTooltip(
          'Ver detalhes do atendimento',
        );
        await tester.tap(detailsButton.first);
        await tester.pumpAndSettle();

        expect(service.detailCalls, 1);
        expect(pdfShareService.calls, 0);
        expect(find.text('Documento do atendimento'), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Compartilhar PDF'),
          findsOneWidget,
        );
        expect(find.byTooltip('Compartilhar atendimento'), findsNothing);
        expect(find.byIcon(Icons.send_rounded), findsNothing);
        expect(
          find.widgetWithText(OutlinedButton, 'Compartilhar link'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(OutlinedButton, 'Status público'),
          findsNothing,
        );
        expect(find.byIcon(Icons.close_rounded), findsWidgets);
        await tester.tap(
          find.byKey(
            const ValueKey<String>('atendimento-detail-share-pdf-action'),
          ),
        );
        await tester.pump();
        await tester.tap(
          find.byKey(
            const ValueKey<String>('atendimento-detail-share-pdf-action'),
          ),
          warnIfMissed: false,
        );
        await tester.pump();

        expect(pdfShareService.calls, 1);
        expect(pdfShareService.lastAtendimentoId, 'os-pdf');
        expect(pdfShareService.lastSharePositionOrigin, isNotNull);
        expect(find.byType(SixoAppMobileLoadingScene), findsOneWidget);
        expect(find.text('SixoApp'), findsNothing);
        expect(find.text('Gerando PDF do atendimento'), findsOneWidget);
        expect(
          find.text('Aguarde enquanto o documento é preparado.'),
          findsOneWidget,
        );

        pdfShareService.completer!.complete(
          const AtendimentoPdfShareResult(
            disposition: PdfFileShareDisposition.shared,
            fileName: 'atendimento-tecnico-os-pdf.pdf',
            mimeType: 'application/pdf',
            sizeBytes: 20,
          ),
        );
        await tester.pumpAndSettle();

        expect(pdfShareService.calls, 1);
        expect(find.byType(SixoAppMobileLoadingScene), findsNothing);
        expect(find.text('Gerando PDF do atendimento'), findsNothing);

        await tester.tap(find.byIcon(Icons.close_rounded).last);
        await tester.pumpAndSettle();
        expect(find.text('Resumo da ordem de serviço'), findsNothing);
      },
    );

    testWidgets(
      'technical detail shows friendly pdf errors and download fallback in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService(
              atendimentos: <AtendimentoTecnicoModel>[
                _atendimento(
                  numero: 'OS-ERRO-PDF',
                  statusCodigo: 'EM_ANDAMENTO',
                  statusNome: 'Em andamento',
                ),
              ],
            );
        final _FakeAtendimentoPdfShareService invalidPdfShareService =
            _FakeAtendimentoPdfShareService(
              failure: AtendimentoPdfShareFailure.invalidFile,
            );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
          pdfShareService: invalidPdfShareService,
        );

        await _dragUntilTextVisible(tester, 'OS-ERRO-PDF');
        await tester.pump();
        await tester.tap(find.byTooltip('Ver detalhes do atendimento').first);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const ValueKey<String>('atendimento-detail-share-pdf-action'),
          ),
        );
        await tester.pumpAndSettle();

        expect(invalidPdfShareService.calls, 1);
        expect(find.text('O arquivo recebido é inválido.'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.close_rounded).last);
        await tester.pumpAndSettle();

        final _FakeAtendimentoPdfShareService downloadedPdfShareService =
            _FakeAtendimentoPdfShareService(
              result: const AtendimentoPdfShareResult(
                disposition: PdfFileShareDisposition.downloaded,
                fileName: 'atendimento-tecnico-os-erro-pdf.pdf',
                mimeType: 'application/pdf',
                sizeBytes: 24,
              ),
            );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
          pdfShareService: downloadedPdfShareService,
        );
        await _dragUntilTextVisible(tester, 'OS-ERRO-PDF');
        await tester.pump();
        await tester.tap(find.byTooltip('Ver detalhes do atendimento').first);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(
            const ValueKey<String>('atendimento-detail-share-pdf-action'),
          ),
        );
        await tester.pumpAndSettle();

        expect(downloadedPdfShareService.calls, 1);
        expect(find.text('PDF baixado com sucesso.'), findsOneWidget);
      },
    );

    testWidgets(
      'technical detail shares public status from its card in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService(
              atendimentos: <AtendimentoTecnicoModel>[
                _atendimento(
                  numero: 'OS-STATUS',
                  statusCodigo: 'ENTREGUE',
                  statusNome: 'Entregue',
                ),
              ],
            );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
        );

        await _dragUntilTextVisible(tester, 'OS-STATUS');
        await tester.pump();
        await tester.tap(find.byTooltip('Ver detalhes do atendimento').first);
        await tester.pumpAndSettle();

        expect(find.text('Status público'), findsOneWidget);
        expect(find.text('Entregue'), findsWidgets);
        expect(
          find.widgetWithText(OutlinedButton, 'Compartilhar link'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(OutlinedButton, 'Status público'),
          findsNothing,
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>(
              'atendimento-detail-public-status-share-action',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(service.statusLinkCalls, 1);
        expect(service.lastStatusLinkId, 'os-status');
        expect(service.lastStatusLinkBaseUrl, contains('/atendimento/status'));
      },
    );

    testWidgets(
      'technical detail operational actions keep edit and status callbacks in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService(
              atendimentos: <AtendimentoTecnicoModel>[
                _atendimento(
                  numero: 'OS-ACOES',
                  statusCodigo: 'EM_ANDAMENTO',
                  statusNome: 'Em andamento',
                ),
              ],
            );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
        );

        await _dragUntilTextVisible(tester, 'OS-ACOES');
        await tester.pump();
        await tester.tap(find.byTooltip('Ver detalhes do atendimento').first);
        await tester.pumpAndSettle();

        final Finder editAction = find.byKey(
          const ValueKey<String>('atendimento-detail-edit-action'),
        );
        final Finder changeStatusAction = find.byKey(
          const ValueKey<String>('atendimento-detail-change-status-action'),
        );
        await tester.ensureVisible(changeStatusAction);
        await tester.pump();

        expect(editAction, findsOneWidget);
        expect(changeStatusAction, findsOneWidget);
        expect(
          tester.getTopLeft(editAction).dy,
          tester.getTopLeft(changeStatusAction).dy,
        );

        await tester.tap(find.widgetWithText(OutlinedButton, 'Editar'));
        await tester.pumpAndSettle();
        expect(find.text('Salvar atendimento'), findsOneWidget);

        Navigator.of(tester.element(find.text('Salvar atendimento'))).pop();
        await tester.pumpAndSettle();
        await _dragUntilTextVisible(tester, 'OS-ACOES');
        await tester.pump();
        await tester.tap(find.byTooltip('Ver detalhes do atendimento').first);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Mudar status'));
        await tester.pumpAndSettle();

        expect(find.text('Mudar status'), findsOneWidget);
        expect(find.text('Buscar status'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextField, 'Buscar status'),
          'conclu',
        );
        await tester.pump();
        await tester.tap(find.text('Concluída').last);
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
        await tester.pumpAndSettle();

        expect(service.statusChangeCalls, 1);
        expect(service.lastStatus?.codigo, 'CONCLUIDO');
      },
    );

    testWidgets(
      'technical detail requires signature decision before advanced status in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService(
              atendimentos: <AtendimentoTecnicoModel>[
                _atendimento(
                  numero: 'OS-SEM-ASSINATURA',
                  statusCodigo: 'ABERTA',
                  statusNome: 'Aberta',
                ),
              ],
            );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
        );

        await _dragUntilTextVisible(tester, 'OS-SEM-ASSINATURA');
        await tester.pump();
        await tester.tap(find.byTooltip('Ver detalhes do atendimento').first);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Mudar status'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Buscar status'),
          'andamento',
        );
        await tester.pump();
        await tester.tap(find.text('Em andamento').last);
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
        await tester.pumpAndSettle();

        expect(find.text('Assinatura necessária'), findsOneWidget);
        expect(find.text('Enviar link ao cliente'), findsOneWidget);
        expect(find.text('Assinar neste dispositivo'), findsOneWidget);
        expect(find.text('Avançar sem assinatura'), findsOneWidget);
        expect(service.statusChangeCalls, 0);

        await tester.tap(find.text('Avançar sem assinatura'));
        await tester.pumpAndSettle();

        expect(service.statusChangeCalls, 1);
        expect(service.lastStatus?.codigo, 'EM_ANDAMENTO');
        expect(service.lastBypassAssinatura, isTrue);
      },
    );

    testWidgets(
      'technical detail collects device signature and registers selected status in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService(
              atendimentos: <AtendimentoTecnicoModel>[
                _atendimento(
                  numero: 'OS-ASSINAR-NO-DISPOSITIVO',
                  statusCodigo: 'ABERTA',
                  statusNome: 'Aberta',
                ),
              ],
            );

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
        );

        await _dragUntilTextVisible(tester, 'OS-ASSINAR-NO-DISPOSITIVO');
        await tester.pump();
        await tester.tap(find.byTooltip('Ver detalhes do atendimento').first);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(OutlinedButton, 'Mudar status'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Buscar status'),
          'andamento',
        );
        await tester.pump();
        await tester.tap(find.text('Em andamento').last);
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Aplicar'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Assinar neste dispositivo'));
        await tester.pumpAndSettle();

        expect(find.text('Coletar assinatura'), findsOneWidget);
        expect(find.text('Registrar assinatura'), findsOneWidget);
        expect(find.byType(Signature), findsOneWidget);
        await tester.ensureVisible(find.byType(Signature));
        await tester.pumpAndSettle();
        final SignatureController signatureController =
            tester.widget<Signature>(find.byType(Signature)).controller;
        signatureController.addPoint(
          Point(const Offset(24, 42), PointType.tap, 1),
        );
        signatureController.addPoint(
          Point(const Offset(88, 62), PointType.move, 1),
        );
        signatureController.addPoint(
          Point(const Offset(148, 48), PointType.tap, 1),
        );
        expect(signatureController.isNotEmpty, isTrue);
        await tester.pumpAndSettle();
        final Finder registerSignatureButton = find.widgetWithText(
          FilledButton,
          'Registrar assinatura',
        );
        await tester.ensureVisible(registerSignatureButton);
        await tester.pumpAndSettle();
        final VoidCallback? registerSignature =
            tester.widget<FilledButton>(registerSignatureButton).onPressed;
        expect(registerSignature, isNotNull);
        registerSignature?.call();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        expect(
          find.text('Faça a assinatura no quadro indicado.'),
          findsNothing,
        );

        expect(service.deviceSignatureCalls, 1);
        expect(service.lastDeviceSignatureStatus?.codigo, 'EM_ANDAMENTO');
        expect(service.lastDeviceSigner, startsWith('Cliente Six'));
        expect(
          service.lastDeviceSignatureDataUrl,
          startsWith('data:image/svg+xml;base64,'),
        );
        expect(service.signatureLinkCalls, 0);
        expect(service.statusChangeCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'technical detail actions adapt and settled finance stays disabled in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService(
              atendimentos: <AtendimentoTecnicoModel>[
                _atendimento(
                  numero: 'OS-LIQUIDADO',
                  statusCodigo: 'CONCLUIDO',
                  statusNome: 'Concluída',
                  valorEmAberto: 0,
                  liquidada: true,
                ),
              ],
            );
        final _FakeCaixaApiClient caixaApiClient = _FakeCaixaApiClient();

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
          caixaApiClient: caixaApiClient,
          size: const Size(320, 760),
          textScale: 1.3,
        );

        await _dragUntilTextVisible(tester, 'OS-LIQUIDADO');
        await tester.pump();
        await tester.tap(find.byTooltip('Ver detalhes do atendimento').first);
        await tester.pumpAndSettle();

        final Finder editAction = find.byKey(
          const ValueKey<String>('atendimento-detail-edit-action'),
        );
        final Finder changeStatusAction = find.byKey(
          const ValueKey<String>('atendimento-detail-change-status-action'),
        );
        await tester.ensureVisible(changeStatusAction);
        await tester.pump();

        expect(
          tester.getTopLeft(changeStatusAction).dy,
          greaterThan(tester.getTopLeft(editAction).dy),
        );
        final OutlinedButton settledButton = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'Financeiro liquidado'),
        );
        expect(settledButton.onPressed, isNull);

        await tester.tap(
          find.widgetWithText(OutlinedButton, 'Financeiro liquidado'),
          warnIfMissed: false,
        );
        await tester.pump();

        expect(caixaApiClient.informacoesBasicasCalls, 0);
        expect(service.receiveCalls, 0);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'technical detail opens receipt flow with selected item in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService(
              atendimentos: <AtendimentoTecnicoModel>[
                _atendimento(
                  numero: 'OS-PAGAMENTO',
                  statusCodigo: 'PENDENTE_PAGAMENTO',
                  statusNome: 'Pendente de pagamento',
                  valorEmAberto: 180,
                  liquidada: false,
                ),
              ],
            );
        final _FakeCaixaApiClient caixaApiClient = _FakeCaixaApiClient();

        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: service,
          caixaApiClient: caixaApiClient,
        );

        await _dragUntilTextVisible(tester, 'OS-PAGAMENTO');
        await tester.pump();
        final Finder detailsButton =
            find
                .byWidgetPredicate(
                  (Widget widget) =>
                      widget is IconButton &&
                      widget.tooltip == 'Ver detalhes do atendimento',
                )
                .last;
        await tester.tap(detailsButton);
        await tester.pumpAndSettle();
        await _dragUntilTextVisible(
          tester,
          'Resumo da ordem de serviço',
          exact: true,
          lastScrollable: true,
        );
        await tester.pump();
        expect(find.text('Resumo da ordem de serviço'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Receber'), findsOneWidget);
        expect(service.receiveCalls, 0);

        await tester.tap(find.widgetWithText(FilledButton, 'Receber'));
        await tester.pumpAndSettle();
        expect(find.text('Receber atendimento técnico'), findsOneWidget);
        expect(find.text('Smartphone Six Pro Max'), findsWidgets);
        expect(find.textContaining('Cliente Six'), findsWidgets);
        expect(find.text('Valor em aberto'), findsWidgets);
        expect(find.textContaining('180'), findsWidgets);
        expect(caixaApiClient.informacoesBasicasCalls, 1);
        expect(service.receiveCalls, 0);
        expect(service.lastReceiveId, isNull);
        expect(service.lastReceiveInput, isNull);

        final Finder receiveTotalButton = find.widgetWithText(
          FilledButton,
          'Receber total',
        );
        await Scrollable.ensureVisible(
          tester.element(receiveTotalButton),
          alignment: 0.85,
        );
        await tester.pump();
        await tester.tap(receiveTotalButton);
        await tester.pumpAndSettle();
        expect(service.receiveCalls, 1);
        expect(service.lastReceiveId, 'os-pagamento');
        expect(service.lastReceiveInput?.valor, 180);
        expect(service.lastReceiveInput?.codigoFormaRecebimento, 'tipo2');
        expect(service.lastReceiveInput?.nomeFormaRecebimento, 'Pix');
        expect(service.lastReceiveInput?.recebimentos, hasLength(1));
        expect(service.lastReceiveInput?.recebimentos?.single.valor, 180);
      },
    );

    testWidgets(
      'technical create form validates selectors date and save in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService();

        await _pumpMobile(
          tester,
          brightness: themeCase.brightness,
          child: AtendimentoTecnicoMobileScreen(
            service: service,
            clienteApiClient: _FakeClienteUsuarioApiClient(<ClienteUsuario>[
              _cliente(nome: 'Cliente Six'),
            ]),
            colaboradorApiClient: _FakeColaboradorUsuarioApiClient(
              <ColaboradorUsuarioResumo>[_tecnico(nome: 'Técnica Six')],
            ),
          ),
        );

        expect(find.text('Iniciar assistência'), findsOneWidget);
        expect(find.byType(TextField), findsWidgets);
        final InputDecorator inputDecorator = tester.widget<InputDecorator>(
          find.byType(InputDecorator).first,
        );
        expect(
          inputDecorator.decoration.fillColor,
          themeCase.colors.softSurface,
        );
        expect(service.createCalls, 0);
        final FilledButton initialContinueButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Continuar'),
        );
        expect(initialContinueButton.onPressed, isNotNull);

        await _pressFilledButton(tester, 'Continuar');
        await tester.pump();
        expect(
          find.text('Selecione um cliente para continuar.'),
          findsOneWidget,
        );
        expect(service.createCalls, 0);

        await _openCustomerSelector(tester);
        expect(find.text('Selecionar cliente'), findsOneWidget);
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Selecionar cliente'),
            themeCase.colors.background,
          ),
          isTrue,
        );
        await tester.tap(find.text('Cliente Six').last);
        await tester.pumpAndSettle();

        final Finder responsibleText = find.text('Selecione o responsável');
        await Scrollable.ensureVisible(
          tester.element(responsibleText),
          alignment: 0.35,
        );
        await tester.pump();
        await tester.tap(
          find
              .ancestor(of: responsibleText, matching: find.byType(InkWell))
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Responsável técnico'), findsWidgets);
        expect(find.text('Buscar responsável'), findsOneWidget);
        expect(find.text('Técnica'), findsOneWidget);
        await tester.tap(find.text('Técnica').last);
        await tester.pumpAndSettle();

        await _pressFilledButton(tester, 'Continuar');
        await tester.pumpAndSettle();
        expect(find.text('Equipamento'), findsWidgets);
        await _pressFilledButton(tester, 'Continuar');
        await tester.pumpAndSettle();
        expect(find.text('Fotos do serviço'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextField, 'Defeito relatado pelo cliente'),
          'Tela apaga durante o atendimento.',
        );
        await _pressFilledButton(tester, 'Continuar');
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Entrega prevista'),
          420,
          scrollable: _verticalScrollable(),
        );
        await tester.pump();
        final Finder deliveryDateLabel = find.text('Entrega prevista').last;
        await Scrollable.ensureVisible(
          tester.element(deliveryDateLabel),
          alignment: 0.35,
        );
        await tester.pump();
        final InkWell deliveryDateTile = tester.widget<InkWell>(
          find
              .ancestor(of: deliveryDateLabel, matching: find.byType(InkWell))
              .last,
        );
        deliveryDateTile.onTap!();
        await tester.pumpAndSettle();
        expect(find.text('Aplicar entrega'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Aplicar entrega'));
        await tester.pumpAndSettle();

        await _pressFilledButton(tester, 'Continuar');
        await tester.pumpAndSettle();
        final FilledButton validCreateButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Iniciar atendimento técnico'),
        );
        expect(validCreateButton.onPressed, isNotNull);
        service.createCompleter = Completer<AtendimentoTecnicoModel>();
        await tester.scrollUntilVisible(
          find.text('Iniciar atendimento técnico'),
          420,
          scrollable: _verticalScrollable(),
        );
        await _pressFilledButton(tester, 'Iniciar atendimento técnico');
        await tester.pump();

        expect(service.createCalls, 1);
        expect(service.lastCreateInput?.idCliente, 'cliente-1');
        expect(service.lastCreateInput?.nomeClienteSnapshot, 'Cliente Six');
        expect(service.lastCreateInput?.idTecnicoResponsavel, 'tec-1');
        expect(
          service.lastCreateInput?.nomeTecnicoResponsavelSnapshot,
          'Técnica',
        );
        expect(service.lastCreateInput?.equipamento?.tipo, 'SMARTPHONE');
        expect(
          service.lastCreateInput?.defeitoRelatado,
          'Tela apaga durante o atendimento.',
        );
        expect(service.lastCreateDueDate, isNotNull);
        final FilledButton savingButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Iniciando atendimento...'),
        );
        expect(savingButton.onPressed, isNull);

        await tester.tap(
          find.widgetWithText(FilledButton, 'Iniciando atendimento...'),
        );
        await tester.pump();
        expect(service.createCalls, 1);

        service.createCompleter!.complete(
          _atendimento(
            numero: 'OS-CRIADA',
            statusCodigo: 'ABERTA',
            statusNome: 'Aberta',
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Atendimento OS-CRIADA iniciado.'), findsOneWidget);
        expect(service.createCalls, 1);
      },
    );

    testWidgets(
      'technical edit form keeps existing data and updates in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final _FakeAtendimentoTecnicoService service =
            _FakeAtendimentoTecnicoService();

        await _pumpMobile(
          tester,
          brightness: themeCase.brightness,
          child: AtendimentoTecnicoEditarMobileScreen(
            atendimento: _atendimento(
              numero: 'OS-EDIT',
              statusCodigo: 'EM_ANDAMENTO',
              statusNome: 'Em andamento',
              liquidada: false,
            ),
            service: service,
            clienteApiClient: _FakeClienteUsuarioApiClient(<ClienteUsuario>[
              _cliente(nome: 'Cliente Six'),
            ]),
            colaboradorApiClient: _FakeColaboradorUsuarioApiClient(
              <ColaboradorUsuarioResumo>[_tecnico(nome: 'Técnica Six')],
            ),
          ),
        );

        expect(find.text('OS-EDIT'), findsOneWidget);
        expect(find.text('Dados principais'), findsOneWidget);
        expect(find.text('Diagnóstico técnico'), findsOneWidget);
        expect(find.text('Salvar atendimento'), findsOneWidget);
        expect(find.text('Cliente Six'), findsWidgets);
        expect(find.widgetWithText(TextField, 'OS-EDIT'), findsNothing);
        expect(service.createCalls, 0);
        expect(service.updateCalls, 0);
        final InputDecorator inputDecorator = tester.widget<InputDecorator>(
          find.byType(InputDecorator).first,
        );
        expect(
          inputDecorator.decoration.fillColor,
          themeCase.colors.softSurface,
        );

        await tester.enterText(
          find.widgetWithText(TextField, 'Diagnóstico técnico'),
          'Atualizado com orçamento aprovado.',
        );
        service.updateCompleter = Completer<AtendimentoTecnicoModel>();
        final Finder saveButton = find.widgetWithText(
          FilledButton,
          'Salvar atendimento',
        );
        await tester.ensureVisible(saveButton);
        await tester.pump();
        await tester.drag(_verticalScrollable(), const Offset(0, -180));
        await tester.pump();
        await tester.tap(saveButton);
        await tester.pump();

        expect(service.updateCalls, 1);
        expect(service.createCalls, 0);
        expect(
          service.lastUpdateInput?.diagnosticoTecnico,
          'Atualizado com orçamento aprovado.',
        );
        expect(service.lastUpdatedId, 'os-edit');
        expect(service.lastUpdateInput?.idCliente, 'cliente-1');
        expect(service.lastUpdateInput?.idTecnicoResponsavel, 'tec-1');
        expect(
          service.lastUpdateInput?.observacaoAuditoria,
          'Atualização realizada pelo mobile.',
        );
        final FilledButton savingButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Salvando...'),
        );
        expect(savingButton.onPressed, isNull);

        await tester.tap(find.widgetWithText(FilledButton, 'Salvando...'));
        await tester.pump();
        expect(service.updateCalls, 1);

        service.updateCompleter!.complete(
          _atendimento(
            numero: 'OS-EDIT',
            statusCodigo: 'EM_ANDAMENTO',
            statusNome: 'Em andamento',
          ),
        );
        await tester.pumpAndSettle();
        expect(service.updateCalls, 1);
      },
    );

    testWidgets(
      'pending payments covers loading empty error and item in ${themeCase.description} mode',
      (WidgetTester tester) async {
        final Completer<List<AtendimentoTecnicoModel>> loadingCompleter =
            Completer<List<AtendimentoTecnicoModel>>();

        await _pumpPendingPayments(
          tester,
          themeCase: themeCase,
          service: _FakeAtendimentoTecnicoService(
            listCompleter: loadingCompleter,
          ),
          settle: false,
        );
        await tester.pump();
        expect(find.text('Carregando atendimentos'), findsOneWidget);
        loadingCompleter.complete(<AtendimentoTecnicoModel>[]);
        await tester.pump();

        await _pumpPendingPayments(
          tester,
          themeCase: themeCase,
          service: _FakeAtendimentoTecnicoService(
            atendimentos: <AtendimentoTecnicoModel>[],
          ),
        );
        expect(find.text('Nenhum serviço a receber'), findsOneWidget);
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Nenhum serviço a receber'),
            themeCase.colors.surface,
          ),
          isTrue,
        );

        await _pumpPendingPayments(
          tester,
          themeCase: themeCase,
          service: _FakeAtendimentoTecnicoService(throwOnList: true),
        );
        expect(find.text('Não foi possível carregar'), findsOneWidget);

        await _pumpPendingPayments(
          tester,
          themeCase: themeCase,
          service: _FakeAtendimentoTecnicoService(
            atendimentos: <AtendimentoTecnicoModel>[
              _atendimento(
                numero: 'OS-PENDENTE',
                statusCodigo: 'PENDENTE_PAGAMENTO',
                statusNome: 'Pendente de pagamento',
                valorEmAberto: 180,
                liquidada: false,
              ),
            ],
          ),
        );

        expect(find.text('Financeiro aberto'), findsWidgets);
        expect(find.text('Valor em aberto'), findsOneWidget);
        expect(find.text('Pendente de pagamento'), findsOneWidget);
        expect(find.byIcon(Icons.build_circle_outlined), findsWidgets);
      },
    );

    testWidgets(
      'technical list and create form tolerate text scale in ${themeCase.description} mode',
      (WidgetTester tester) async {
        await _pumpTechnicalList(
          tester,
          themeCase: themeCase,
          service: _FakeAtendimentoTecnicoService(
            atendimentos: _atendimentosTecnicos(),
          ),
          textScale: 1.3,
          size: const Size(390, 940),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Atendimentos técnicos'), findsOneWidget);
        expect(find.text('10 atendimentos'), findsOneWidget);
        expect(find.textContaining('Pendente de pagamento'), findsWidgets);
        await _dragUntilTextVisible(tester, 'OS-PAGAMENTO');
        await tester.pump();
        expect(find.textContaining('OS-PAGAMENTO'), findsOneWidget);
        expect(
          find.textContaining('Cliente Six com nome comercial longo'),
          findsWidgets,
        );
        expect(find.textContaining('Smartphone Six Pro Max'), findsWidgets);
        expect(find.text('Financeiro aberto'), findsWidgets);
        final Finder detailsButton =
            find
                .byWidgetPredicate(
                  (Widget widget) =>
                      widget is IconButton &&
                      widget.tooltip == 'Ver detalhes do atendimento',
                )
                .last;
        await Scrollable.ensureVisible(
          tester.element(detailsButton),
          alignment: 0.65,
        );
        await tester.pump();
        await tester.tap(detailsButton);
        await tester.pumpAndSettle();
        await _dragUntilTextVisible(
          tester,
          'Resumo da ordem de serviço',
          exact: true,
          lastScrollable: true,
        );
        await tester.pump();
        expect(find.text('Resumo da ordem de serviço'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Receber'), findsOneWidget);
        await _dragUntilTextVisible(
          tester,
          'Resumo financeiro',
          exact: true,
          lastScrollable: true,
        );
        await tester.pump();
        expect(find.text('Valor original'), findsWidgets);
        expect(find.text('Valor já recebido'), findsWidgets);
        expect(find.text('Valor em aberto'), findsWidgets);
        expect(tester.takeException(), isNull);
        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await _pumpMobile(
          tester,
          brightness: themeCase.brightness,
          textScale: 1.3,
          size: const Size(390, 940),
          child: AtendimentoTecnicoMobileScreen(
            service: _FakeAtendimentoTecnicoService(),
            clienteApiClient: _FakeClienteUsuarioApiClient(<ClienteUsuario>[
              _cliente(nome: 'Cliente Six com nome comercial longo'),
            ]),
            colaboradorApiClient: _FakeColaboradorUsuarioApiClient(
              <ColaboradorUsuarioResumo>[_tecnico(nome: 'Técnica Six')],
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Iniciar assistência'), findsOneWidget);
        await _fillCreateRequiredFields(tester);
        await tester.scrollUntilVisible(
          find.text('Iniciar atendimento técnico'),
          420,
          scrollable: _verticalScrollable(),
        );
        await tester.pump();
        expect(
          find.widgetWithText(FilledButton, 'Iniciar atendimento técnico'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('technical create form remains scrollable with keyboard inset', (
    WidgetTester tester,
  ) async {
    await _pumpMobile(
      tester,
      brightness: Brightness.dark,
      viewInsets: const EdgeInsets.only(bottom: 320),
      child: AtendimentoTecnicoMobileScreen(
        service: _FakeAtendimentoTecnicoService(),
        clienteApiClient: _FakeClienteUsuarioApiClient(<ClienteUsuario>[
          _cliente(nome: 'Cliente Six com nome comercial longo'),
        ]),
        colaboradorApiClient: _FakeColaboradorUsuarioApiClient(
          <ColaboradorUsuarioResumo>[_tecnico(nome: 'Técnica Six')],
        ),
      ),
    );

    await _advanceCreateToTechnicalRecord(tester);
    await tester.scrollUntilVisible(
      find.text('Defeito relatado pelo cliente'),
      420,
      scrollable: _verticalScrollable(),
    );
    await tester.pump();
    final Finder defectField = find.widgetWithText(
      TextField,
      'Defeito relatado pelo cliente',
    );
    await Scrollable.ensureVisible(
      tester.element(defectField),
      alignment: 0.45,
    );
    await tester.pump();
    await tester.showKeyboard(defectField);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.enterText(
      defectField,
      'Descrição longa informada com teclado aberto no balcão técnico.',
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      find.text(
        'Descrição longa informada com teclado aberto no balcão técnico.',
      ),
      findsOneWidget,
    );

    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await _pressFilledButton(tester, 'Continuar');
    await tester.pumpAndSettle();
    await _pressFilledButton(tester, 'Continuar');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Iniciar atendimento técnico'),
      420,
      scrollable: _verticalScrollable(),
    );
    await tester.pump();
    expect(
      find.widgetWithText(FilledButton, 'Iniciar atendimento técnico'),
      findsOneWidget,
    );
    final FilledButton createButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Iniciar atendimento técnico'),
    );
    expect(createButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'technical create surfaces service error without duplicate writes',
    (WidgetTester tester) async {
      final _FakeAtendimentoTecnicoService service =
          _FakeAtendimentoTecnicoService(throwOnCreate: true);

      await _pumpMobile(
        tester,
        brightness: Brightness.dark,
        child: AtendimentoTecnicoMobileScreen(
          service: service,
          clienteApiClient: _FakeClienteUsuarioApiClient(<ClienteUsuario>[
            _cliente(nome: 'Cliente Six'),
          ]),
          colaboradorApiClient: _FakeColaboradorUsuarioApiClient(
            <ColaboradorUsuarioResumo>[_tecnico(nome: 'Técnica Six')],
          ),
        ),
      );

      await _fillCreateRequiredFields(tester);
      await _pressFilledButton(tester, 'Iniciar atendimento técnico');
      await tester.pumpAndSettle();

      expect(service.createCalls, 1);
      expect(service.updateCalls, 0);
      expect(service.receiveCalls, 0);
      expect(
        find.textContaining('Não foi possível iniciar o atendimento'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'technical edit surfaces service error without creating another assistance',
    (WidgetTester tester) async {
      final _FakeAtendimentoTecnicoService service =
          _FakeAtendimentoTecnicoService(throwOnUpdate: true);

      await _pumpMobile(
        tester,
        brightness: Brightness.dark,
        child: AtendimentoTecnicoEditarMobileScreen(
          atendimento: _atendimento(
            numero: 'OS-EDIT',
            statusCodigo: 'EM_ANDAMENTO',
            statusNome: 'Em andamento',
            liquidada: false,
          ),
          service: service,
          clienteApiClient: _FakeClienteUsuarioApiClient(<ClienteUsuario>[
            _cliente(nome: 'Cliente Six'),
          ]),
          colaboradorApiClient: _FakeColaboradorUsuarioApiClient(
            <ColaboradorUsuarioResumo>[_tecnico(nome: 'Técnica Six')],
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Diagnóstico técnico'),
        'Atualização que deve falhar no serviço fake.',
      );
      final Finder saveButton = find.widgetWithText(
        FilledButton,
        'Salvar atendimento',
      );
      await tester.ensureVisible(saveButton);
      await tester.pump();
      await tester.drag(_verticalScrollable(), const Offset(0, -180));
      await tester.pump();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(service.updateCalls, 1);
      expect(service.createCalls, 0);
      expect(service.lastUpdatedId, 'os-edit');
      expect(find.textContaining('Não foi possível salvar'), findsOneWidget);
    },
  );
}

const List<_ThemeCase> _themeCases = <_ThemeCase>[
  _ThemeCase(
    description: 'dark',
    brightness: Brightness.dark,
    colors: SixMobileColorScheme.dark,
  ),
  _ThemeCase(
    description: 'light',
    brightness: Brightness.light,
    colors: SixMobileColorScheme.light,
  ),
];

const List<Locale> _testSupportedLocales = <Locale>[Locale('pt')];

const List<LocalizationsDelegate<dynamic>> _testLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

Future<void> _pumpMobile(
  WidgetTester tester, {
  required Widget child,
  required Brightness brightness,
  Size size = const Size(390, 900),
  double textScale = 1,
  EdgeInsets viewInsets = EdgeInsets.zero,
  bool settle = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final bool isDark = brightness == Brightness.dark;
  SixThemeResolver().atualizarTema(
    isDark ? TemaSistema.escuro : TemaSistema.claro,
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<LocaleSettingsProvider>(
      create:
          (_) => LocaleSettingsProvider(
            regionalizacaoService: RegionalizacaoService(
              apiClient: _FakeRegionalizacaoApiClient(),
            ),
          ),
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: _testSupportedLocales,
        localizationsDelegates: _testLocalizationsDelegates,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: true,
            accessibleNavigation: true,
            size: size,
            devicePixelRatio: 1,
            textScaler: TextScaler.linear(textScale),
            viewInsets: viewInsets,
          ),
          child: child,
        ),
      ),
    ),
  );

  await tester.pump();
  if (settle) {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }
}

Future<void> _pumpTechnicalList(
  WidgetTester tester, {
  required _ThemeCase themeCase,
  required _FakeAtendimentoTecnicoService service,
  bool settle = true,
  Size size = const Size(390, 940),
  double textScale = 1,
  CaixaApiClient? caixaApiClient,
  AtendimentoPdfShareService? pdfShareService,
  List<ColaboradorUsuarioResumo>? tecnicos,
  AtendimentosTecnicosMobileListContext listContext =
      const AtendimentosTecnicosMobileListContext.standard(),
}) {
  return _pumpMobile(
    tester,
    brightness: themeCase.brightness,
    size: size,
    textScale: textScale,
    settle: settle,
    child: AtendimentosTecnicosMobileScreen(
      key: UniqueKey(),
      service: service,
      pdfShareService: pdfShareService,
      caixaApiClient: caixaApiClient,
      listContext: listContext,
      colaboradorApiClient: _FakeColaboradorUsuarioApiClient(
        tecnicos ?? <ColaboradorUsuarioResumo>[_tecnico(nome: 'Técnica Six')],
      ),
    ),
  );
}

Future<void> _pumpPendingPayments(
  WidgetTester tester, {
  required _ThemeCase themeCase,
  required _FakeAtendimentoTecnicoService service,
  bool settle = true,
  Size size = const Size(390, 900),
}) {
  return _pumpMobile(
    tester,
    brightness: themeCase.brightness,
    size: size,
    settle: settle,
    child: AtendimentosTecnicosPendentesPagamentoMobileScreen(
      key: UniqueKey(),
      service: service,
    ),
  );
}

Future<void> _dragUntilTextVisible(
  WidgetTester tester,
  String text, {
  int maxAttempts = 8,
  bool exact = false,
  bool lastScrollable = false,
}) async {
  final Finder finder = exact ? find.text(text) : find.textContaining(text);
  for (int attempt = 0; attempt < maxAttempts; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.drag(
      _verticalScrollable(last: lastScrollable),
      const Offset(0, -360),
    );
    await tester.pump();
  }
}

Future<void> _openCustomerSelector(WidgetTester tester) async {
  final Finder customerPrompt = find.text('Selecione um cliente').first;
  await Scrollable.ensureVisible(
    tester.element(customerPrompt),
    alignment: 0.35,
  );
  await tester.pump();
  await tester.tap(
    find.ancestor(of: customerPrompt, matching: find.byType(InkWell)).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _pressFilledButton(WidgetTester tester, String label) async {
  final Finder buttonFinder = find.widgetWithText(FilledButton, label);
  await tester.ensureVisible(buttonFinder);
  await tester.pump();
  final FilledButton button = tester.widget<FilledButton>(buttonFinder);
  expect(button.onPressed, isNotNull);
  button.onPressed!();
}

Future<void> _fillCreateRequiredFields(WidgetTester tester) async {
  await _advanceCreateToTechnicalRecord(tester);
  await tester.enterText(
    find.widgetWithText(TextField, 'Defeito relatado pelo cliente'),
    'Tela apaga durante o atendimento.',
  );
  await _pressFilledButton(tester, 'Continuar');
  await tester.pumpAndSettle();
  await _pressFilledButton(tester, 'Continuar');
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('Iniciar atendimento técnico'),
    420,
    scrollable: _verticalScrollable(),
  );
  await tester.pump();
}

Future<void> _advanceCreateToTechnicalRecord(WidgetTester tester) async {
  await _openCustomerSelector(tester);
  await tester.tap(find.textContaining('Cliente Six').last);
  await tester.pumpAndSettle();

  final Finder responsibleText = find.text('Selecione o responsável');
  await Scrollable.ensureVisible(
    tester.element(responsibleText),
    alignment: 0.35,
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.ancestor(of: responsibleText, matching: find.byType(InkWell)).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Técnica').last);
  await tester.pumpAndSettle();

  await _pressFilledButton(tester, 'Continuar');
  await tester.pumpAndSettle();
  await _pressFilledButton(tester, 'Continuar');
  await tester.pumpAndSettle();
}

Finder _verticalScrollable({bool last = false}) {
  final Finder finder = find.byWidgetPredicate((Widget widget) {
    return widget is Scrollable &&
        axisDirectionToAxis(widget.axisDirection) == Axis.vertical;
  });
  return last ? finder.last : finder.first;
}

Color? _scaffoldBackground(WidgetTester tester) {
  return tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor;
}

bool _hasMaterialAncestorColor(
  WidgetTester tester,
  Finder child,
  Color expected,
) {
  return tester
      .widgetList<Material>(
        find.ancestor(of: child, matching: find.byType(Material)),
      )
      .any((Material material) => material.color == expected);
}

bool _hasDecoratedAncestorColor(
  WidgetTester tester,
  Finder child,
  Color expected,
) {
  return tester
      .widgetList<Container>(
        find.ancestor(of: child, matching: find.byType(Container)),
      )
      .any((Container container) {
        final Decoration? decoration = container.decoration;
        return decoration is BoxDecoration && decoration.color == expected;
      });
}

List<AtendimentoTecnicoModel> _atendimentosTecnicos() {
  final DateTime entregaFiltro = DateTime.now().add(const Duration(days: 7));
  return <AtendimentoTecnicoModel>[
    _atendimento(
      numero: 'OS-FINAL',
      statusCodigo: 'CONCLUIDO',
      statusNome: 'Concluída',
      valorEmAberto: 0,
      liquidada: true,
      assinaturaAprovada: true,
      dataAtualizacao: DateTime(2026, 8, 9, 10),
      dataEntregaPrevista: entregaFiltro,
    ),
    _atendimento(
      numero: 'OS-ABERTA',
      statusCodigo: 'ABERTA',
      statusNome: 'Aberta',
      dataAtualizacao: DateTime(2026, 8, 8, 9),
      dataEntregaPrevista: entregaFiltro,
    ),
    _atendimento(
      numero: 'OS-AVALIACAO',
      statusCodigo: 'AGUARDANDO_AVALIACAO',
      statusNome: 'Aguardando avaliação',
      dataAtualizacao: DateTime(2026, 8, 7, 9),
      dataEntregaPrevista: entregaFiltro,
    ),
    _atendimento(
      numero: 'OS-APROVACAO',
      statusCodigo: 'AGUARDANDO_APROVACAO',
      statusNome: 'Aguardando aprovação',
      dataAtualizacao: DateTime(2026, 8, 6, 9),
      dataEntregaPrevista: entregaFiltro,
    ),
    _atendimento(
      numero: 'OS-APROVADA',
      statusCodigo: 'APROVADA',
      statusNome: 'Aprovada',
      dataAtualizacao: DateTime(2026, 8, 5, 9),
      dataEntregaPrevista: entregaFiltro,
    ),
    _atendimento(
      numero: 'OS-ANDAMENTO',
      statusCodigo: 'EM_ANDAMENTO',
      statusNome: 'Em andamento',
      dataAtualizacao: DateTime(2026, 8, 4, 9),
      dataEntregaPrevista: entregaFiltro,
    ),
    _atendimento(
      numero: 'OS-PECA',
      statusCodigo: 'AGUARDANDO_PECA',
      statusNome: 'Aguardando peça',
      dataAtualizacao: DateTime(2026, 8, 3, 9),
      dataEntregaPrevista: entregaFiltro,
    ),
    _atendimento(
      numero: 'OS-ENTREGUE',
      statusCodigo: 'ENTREGUE',
      statusNome: 'Entregue',
      valorEmAberto: 0,
      liquidada: true,
      dataAtualizacao: DateTime(2026, 8, 2, 9),
      dataEntregaPrevista: entregaFiltro,
    ),
    _atendimento(
      numero: 'OS-CANCELADA',
      statusCodigo: 'CANCELADO',
      statusNome: 'Cancelada',
      valorEmAberto: 0,
      liquidada: true,
      dataAtualizacao: DateTime(2026, 8, 1, 9),
      dataEntregaPrevista: entregaFiltro,
    ),
    _atendimento(
      numero: 'OS-PAGAMENTO',
      statusCodigo: 'PENDENTE_PAGAMENTO',
      statusNome: 'Pendente de pagamento',
      valorEmAberto: 180,
      liquidada: false,
      dataAtualizacao: DateTime(2026, 7, 31, 9),
      dataEntregaPrevista: entregaFiltro,
    ),
  ];
}

AtendimentoTecnicoModel _atendimento({
  required String numero,
  required String statusCodigo,
  required String statusNome,
  double valorEmAberto = 180,
  bool liquidada = false,
  bool assinaturaAprovada = false,
  bool requerNovaAssinatura = false,
  DateTime? dataAtualizacao,
  DateTime? dataEntregaPrevista,
  String idTecnicoResponsavel = 'tec-1',
  String nomeTecnicoResponsavel = 'Técnica Six',
}) {
  final int statusId =
      _dominios.statusAtendimentoTecnico
          .firstWhere(
            (DominioOpcaoModel status) => status.codigo == statusCodigo,
            orElse: () => _dominios.statusAtendimentoTecnico.first,
          )
          .id;
  final double valorTotal = 300;
  return AtendimentoTecnicoModel(
    id: numero.toLowerCase(),
    idOperacaoFinanceira: liquidada ? null : 'fin-$numero',
    numero: numero,
    descricao: 'Atendimento técnico com descrição extensa para validar quebra.',
    idCliente: 'cliente-1',
    nomeClienteSnapshot: 'Cliente Six com nome comercial longo',
    idTecnicoResponsavel: idTecnicoResponsavel,
    nomeTecnicoResponsavelSnapshot: nomeTecnicoResponsavel,
    statusId: statusId,
    statusCodigo: statusCodigo,
    statusI18nKey: 'atendimento.status.${statusCodigo.toLowerCase()}',
    statusNomePtBr: statusNome,
    assinaturaAprovada: assinaturaAprovada,
    requerNovaAssinatura: requerNovaAssinatura,
    assinaturaNomeAssinante: assinaturaAprovada ? 'Cliente Six' : null,
    assinaturaDataHora:
        assinaturaAprovada ? DateTime(2026, 8, 6, 16, 15) : null,
    validadeOrcamentoEm: DateTime(2026, 8, 20),
    dataVencimentoEm: DateTime(2026, 8, 18),
    dataEntregaPrevista: dataEntregaPrevista ?? DateTime(2026, 8, 16),
    versaoOrcamento: 2,
    dataUltimaAlteracaoOrcamento: DateTime(2026, 8, 5, 12),
    equipamento: const AtendimentoTecnicoEquipamentoModel(
      tipo: 'Smartphone',
      marca: 'Six',
      modelo: 'Pro Max',
      numeroSerie: 'SERIE-LONGA-1234567890',
      imei: '359999999999999',
      acessorios: 'Capa e película',
      observacoesEntrada: 'Tela trincada com marcas de queda.',
    ),
    defeitoRelatado: 'Tela apaga ao abrir o aplicativo de câmera.',
    diagnosticoTecnico: 'Necessária troca do módulo frontal.',
    valorTotalProdutos: 120,
    valorTotalServicos: 180,
    valorTotalAtendimento: valorTotal,
    valorRecebido: liquidada ? valorTotal : valorTotal - valorEmAberto,
    valorEmAberto: valorEmAberto,
    operacaoLiquidada: liquidada,
    statusLiquidacaoCodigo: liquidada ? 'LIQUIDADA' : 'NAO_LIQUIDADA',
    itens: const <AtendimentoTecnicoItemModel>[
      AtendimentoTecnicoItemModel(
        id: 'item-produto',
        tipoItemId: 1,
        tipoItemCodigo: 'PRODUTO',
        tipoItemI18nKey: 'domain.item.produto',
        descricaoSnapshot: 'Tela iPhone compatível',
        quantidade: 1,
        valorUnitario: 120,
        desconto: 0,
        valorTotal: 120,
        movimentaEstoque: true,
        statusEstoqueId: 1,
        statusEstoqueCodigo: 'RESERVADO',
      ),
      AtendimentoTecnicoItemModel(
        id: 'item-servico',
        tipoItemId: 2,
        tipoItemCodigo: 'SERVICO',
        tipoItemI18nKey: 'domain.item.servico',
        descricaoSnapshot: 'Mão de obra técnica',
        quantidade: 1,
        valorUnitario: 180,
        desconto: 0,
        valorTotal: 180,
        movimentaEstoque: false,
        statusEstoqueId: 2,
        statusEstoqueCodigo: 'NAO_MOVIMENTA',
      ),
    ],
    historicoStatus: <AtendimentoTecnicoHistoricoStatusModel>[
      AtendimentoTecnicoHistoricoStatusModel(
        statusId: 1,
        statusCodigo: 'ABERTA',
        statusI18nKey: 'atendimento.status.aberta',
        statusNomePtBr: 'Aberta',
        observacao: 'Atendimento aberto no balcão.',
        dataHora: DateTime(2026, 8, 1, 9),
      ),
      AtendimentoTecnicoHistoricoStatusModel(
        statusAnteriorId: 1,
        statusAnteriorCodigo: 'ABERTA',
        statusAnteriorI18nKey: 'atendimento.status.aberta',
        statusAnteriorNomePtBr: 'Aberta',
        statusId: statusId,
        statusCodigo: statusCodigo,
        statusI18nKey: 'atendimento.status.${statusCodigo.toLowerCase()}',
        statusNomePtBr: statusNome,
        observacao: 'Status atualizado pela equipe técnica.',
        dataHora: DateTime(2026, 8, 5, 15),
      ),
    ],
    historicoAuditoria: const <AtendimentoTecnicoAuditoriaModel>[
      AtendimentoTecnicoAuditoriaModel(
        id: 'audit-1',
        tipo: 'ORCAMENTO_ATUALIZADO',
        versaoOrcamento: 2,
        observacao: 'Orçamento revisado.',
      ),
    ],
    recebimentos:
        liquidada
            ? const <AtendimentoTecnicoRecebimentoModel>[
              AtendimentoTecnicoRecebimentoModel(
                id: 'rec-1',
                codigoFormaRecebimento: 'PIX',
                nomeFormaRecebimento: 'Pix',
                valor: 300,
              ),
            ]
            : const <AtendimentoTecnicoRecebimentoModel>[],
    dataAtualizacao: dataAtualizacao ?? DateTime(2026, 8, 8, 12),
  );
}

ClienteUsuario _cliente({required String nome}) {
  return ClienteUsuario(
    id: 'cliente-1',
    idUsuario: 'usuario-1',
    idUnicoDaEmpresa: 'empresa-test',
    ativo: true,
    tipoPessoa: 'PF',
    documento: '12345678909',
    nome: nome,
    telefone: '(11) 99999-0000',
    email: 'cliente@six.test',
    cep: '01001000',
    logradouro: 'Rua Teste',
    numero: '100',
    complemento: '',
    bairro: 'Centro',
    cidade: 'São Paulo',
    uf: 'SP',
    observacoes: '',
    origemAutoCadastro: 'MANUAL',
    enviadoEm: null,
    criadoEm: DateTime(2026, 8, 1),
    atualizadoEm: DateTime(2026, 8, 1),
    foto: '',
    permiteCompraFiado: false,
    limiteFiado: 0,
    saldoFiado: 0,
    prazoPagamentoDias: 0,
    bloqueadoFiado: false,
  );
}

ColaboradorUsuarioResumo _tecnico({
  required String nome,
  String id = 'tec-1',
  String nomeDeGuerra = 'Técnica',
  String email = 'tecnica@six.test',
}) {
  return ColaboradorUsuarioResumo(
    idUnicoPessoal: id,
    nome: nome,
    nomeDeGuerra: nomeDeGuerra,
    celularDeAcesso: '(11) 98888-0000',
    email: email,
    foto: '',
    dataCadastro: DateTime(2026, 8, 1),
    ehUmTecnicoEFazAssistenciaTecnica: true,
  );
}

DominioOpcaoModel _status(
  int id,
  String codigo,
  String nome, {
  bool finalizador = false,
}) {
  return DominioOpcaoModel(
    id: id,
    grupo: 'STATUS_ATENDIMENTO_TECNICO',
    codigo: codigo,
    i18nKey: 'atendimento.status.${codigo.toLowerCase()}',
    nomePadraoPtBr: nome,
    nomePadraoEnUs: nome,
    nomePadraoEsEs: nome,
    ordem: id,
    cor: '#0F766E',
    icone: 'flag',
    finalizador: finalizador,
  );
}

final AtendimentoTecnicoDominiosBaseModel _dominios =
    AtendimentoTecnicoDominiosBaseModel(
      tiposOperacao: const <DominioOpcaoModel>[],
      statusAtendimentoTecnico: <DominioOpcaoModel>[
        _status(1, 'ABERTA', 'Aberta'),
        _status(2, 'AGUARDANDO_AVALIACAO', 'Aguardando avaliação'),
        _status(3, 'AGUARDANDO_APROVACAO', 'Aguardando aprovação'),
        _status(4, 'APROVADA', 'Aprovada'),
        _status(5, 'EM_ANDAMENTO', 'Em andamento'),
        _status(6, 'AGUARDANDO_PECA', 'Aguardando peça'),
        _status(7, 'CONCLUIDO', 'Concluída', finalizador: true),
        _status(8, 'ENTREGUE', 'Entregue', finalizador: true),
        _status(9, 'CANCELADO', 'Cancelada', finalizador: true),
        _status(10, 'PENDENTE_PAGAMENTO', 'Pendente de pagamento'),
        _status(
          11,
          'WAITING_CUSTOMER_APROVAL',
          'Aguardando aprovação do cliente',
        ),
      ],
      statusOrcamentoAtendimento: const <DominioOpcaoModel>[],
      tiposItem: const <DominioOpcaoModel>[],
      statusEstoqueAtendimento: const <DominioOpcaoModel>[],
    );

class _FakeAtendimentoTecnicoService extends AtendimentoTecnicoService {
  _FakeAtendimentoTecnicoService({
    this.atendimentos = const <AtendimentoTecnicoModel>[],
    this.listCompleter,
    this.throwOnList = false,
    this.throwOnCreate = false,
    this.throwOnUpdate = false,
  });

  final List<AtendimentoTecnicoModel> atendimentos;
  final Completer<List<AtendimentoTecnicoModel>>? listCompleter;
  final bool throwOnList;
  final bool throwOnCreate;
  final bool throwOnUpdate;

  int listCalls = 0;
  int detailCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;
  int receiveCalls = 0;
  int statusChangeCalls = 0;
  int statusLinkCalls = 0;
  int signatureLinkCalls = 0;
  int deviceSignatureCalls = 0;
  Completer<AtendimentoTecnicoModel>? createCompleter;
  Completer<AtendimentoTecnicoModel>? updateCompleter;
  Completer<AtendimentoTecnicoModel>? receiveCompleter;
  AtendimentoTecnicoCreateInput? lastCreateInput;
  DateTime? lastCreateDueDate;
  AtendimentoTecnicoUpdateInput? lastUpdateInput;
  DateTime? lastUpdateDueDate;
  String? lastUpdatedId;
  String? lastReceiveId;
  AtendimentoTecnicoRecebimentoInput? lastReceiveInput;
  DominioOpcaoModel? lastStatus;
  String? lastStatusObservation;
  String? lastStatusLinkId;
  String? lastStatusLinkBaseUrl;
  String? lastSignatureLinkId;
  String? lastSignatureLinkBaseUrl;
  DominioOpcaoModel? lastDeviceSignatureStatus;
  String? lastDeviceSignatureStatusObservation;
  String? lastDeviceSigner;
  String? lastDeviceSignerDocument;
  String? lastDeviceSignatureDataUrl;
  String? lastDeviceSignatureObservation;
  bool? lastBypassAssinatura;
  String? lastListStatus;

  @override
  Future<AtendimentoTecnicoDominiosBaseModel> buscarDominiosBase() async {
    return _dominios;
  }

  @override
  Future<List<AtendimentoTecnicoModel>> listar({String? status}) {
    listCalls++;
    lastListStatus = status;
    if (throwOnList) {
      return Future<List<AtendimentoTecnicoModel>>.error(StateError('offline'));
    }
    final Completer<List<AtendimentoTecnicoModel>>? completer = listCompleter;
    if (completer != null) return completer.future;
    return Future<List<AtendimentoTecnicoModel>>.value(atendimentos);
  }

  @override
  Future<AtendimentoTecnicoModel> buscarPorId(String id) async {
    detailCalls++;
    return atendimentos.firstWhere(
      (AtendimentoTecnicoModel atendimento) => atendimento.id == id,
      orElse:
          () => _atendimento(
            numero: id.toUpperCase(),
            statusCodigo: 'EM_ANDAMENTO',
            statusNome: 'Em andamento',
          ),
    );
  }

  @override
  Future<AtendimentoTecnicoModel> criar(
    AtendimentoTecnicoCreateInput input, {
    DateTime? dataVencimentoEm,
  }) async {
    createCalls++;
    lastCreateInput = input;
    lastCreateDueDate = dataVencimentoEm;
    if (throwOnCreate) {
      throw StateError('create failed');
    }
    final Completer<AtendimentoTecnicoModel>? completer = createCompleter;
    if (completer != null) return completer.future;
    return _atendimento(
      numero: 'OS-CRIADA',
      statusCodigo: 'ABERTA',
      statusNome: 'Aberta',
    );
  }

  @override
  Future<AtendimentoTecnicoModel> atualizar({
    required String id,
    required AtendimentoTecnicoUpdateInput input,
    DateTime? dataVencimentoEm,
  }) async {
    updateCalls++;
    lastUpdatedId = id;
    lastUpdateInput = input;
    lastUpdateDueDate = dataVencimentoEm;
    if (throwOnUpdate) {
      throw StateError('update failed');
    }
    final Completer<AtendimentoTecnicoModel>? completer = updateCompleter;
    if (completer != null) return completer.future;
    return _atendimento(
      numero: 'OS-EDIT',
      statusCodigo: 'EM_ANDAMENTO',
      statusNome: 'Em andamento',
    );
  }

  @override
  Future<AtendimentoTecnicoModel> alterarStatus({
    required String id,
    required DominioOpcaoModel status,
    String? observacao,
    bool bypassAssinatura = false,
  }) async {
    statusChangeCalls++;
    lastStatus = status;
    lastStatusObservation = observacao;
    lastBypassAssinatura = bypassAssinatura;
    return _atendimento(
      numero: id.toUpperCase(),
      statusCodigo: status.codigo,
      statusNome: status.nomePadraoPtBr,
    );
  }

  @override
  Future<AtendimentoTecnicoModel> assinarNoDispositivo({
    required String id,
    required DominioOpcaoModel status,
    String? observacaoStatus,
    required String nomeAssinante,
    String? documentoAssinante,
    required String assinaturaDataUrl,
    String? observacaoAssinatura,
  }) async {
    deviceSignatureCalls++;
    lastDeviceSignatureStatus = status;
    lastDeviceSignatureStatusObservation = observacaoStatus;
    lastDeviceSigner = nomeAssinante;
    lastDeviceSignerDocument = documentoAssinante;
    lastDeviceSignatureDataUrl = assinaturaDataUrl;
    lastDeviceSignatureObservation = observacaoAssinatura;
    return _atendimento(
      numero: id.toUpperCase(),
      statusCodigo: status.codigo,
      statusNome: status.nomePadraoPtBr,
      assinaturaAprovada: true,
    );
  }

  @override
  Future<AtendimentoTecnicoModel> receber({
    required String id,
    required AtendimentoTecnicoRecebimentoInput input,
  }) async {
    receiveCalls++;
    lastReceiveId = id;
    lastReceiveInput = input;
    final Completer<AtendimentoTecnicoModel>? completer = receiveCompleter;
    if (completer != null) return completer.future;
    return _atendimento(
      numero: id.toUpperCase(),
      statusCodigo: 'CONCLUIDO',
      statusNome: 'Concluída',
      valorEmAberto: 0,
      liquidada: true,
    );
  }

  @override
  Future<Map<String, dynamic>> gerarLinkAssinatura({
    required String id,
    required String baseUrl,
  }) async {
    signatureLinkCalls++;
    lastSignatureLinkId = id;
    lastSignatureLinkBaseUrl = baseUrl;
    return <String, dynamic>{
      'link':
          'https://six.test/atendimento/assinatura?idUnicoDaEmpresa=empresa-test&token=token-assinatura',
    };
  }

  @override
  Future<AtendimentoTecnicoStatusPublicoLinkModel> gerarLinkStatusPublico({
    required String id,
    required String baseUrl,
  }) async {
    statusLinkCalls++;
    lastStatusLinkId = id;
    lastStatusLinkBaseUrl = baseUrl;
    return const AtendimentoTecnicoStatusPublicoLinkModel(
      status: 'OK',
      code: 'OK',
      message: 'Link gerado',
      token: 'token',
      link: 'https://six.test/status/token',
    );
  }
}

class _FakeAtendimentoPdfShareService extends AtendimentoPdfShareService {
  _FakeAtendimentoPdfShareService({
    this.completer,
    this.failure,
    this.result = const AtendimentoPdfShareResult(
      disposition: PdfFileShareDisposition.shared,
      fileName: 'atendimento-tecnico-os-test.pdf',
      mimeType: 'application/pdf',
      sizeBytes: 16,
    ),
  });

  Completer<AtendimentoPdfShareResult>? completer;
  final AtendimentoPdfShareFailure? failure;
  final AtendimentoPdfShareResult result;

  int calls = 0;
  String? lastAtendimentoId;
  Rect? lastSharePositionOrigin;

  @override
  Future<AtendimentoPdfShareResult> compartilharAtendimento({
    required String atendimentoId,
    Rect? sharePositionOrigin,
  }) {
    calls++;
    lastAtendimentoId = atendimentoId;
    lastSharePositionOrigin = sharePositionOrigin;
    final AtendimentoPdfShareFailure? failure = this.failure;
    if (failure != null) {
      return Future<AtendimentoPdfShareResult>.error(
        AtendimentoPdfShareException(failure),
      );
    }
    final Completer<AtendimentoPdfShareResult>? completer = this.completer;
    if (completer != null) return completer.future;
    return Future<AtendimentoPdfShareResult>.value(result);
  }
}

class _FakeCaixaApiClient implements CaixaApiClient {
  int informacoesBasicasCalls = 0;

  @override
  Future<InformacoesBasicasCaixaResponse> getInformacoesBasicasDoCaixa() async {
    informacoesBasicasCalls++;
    return InformacoesBasicasCaixaResponse(
      possuiSessaoAberta: true,
      tiposRecebimento: <TiposRecebimento>[
        TiposRecebimento(
          codigoTipo: 'tipo2',
          descricaoExibicao: 'Pix',
          naturezaRecebimento: 'IMEDIATO',
          aceitaParcelamento: false,
          ativo: true,
          exigeCliente: false,
          ordemExibicao: 1,
          corHex: '#16A34A',
          icone: 'pix',
        ),
      ],
      caixas: const <String>[],
      caixaOuGuiche: const <CaixaOuGuiche>[],
      formas: const <FormaMovimento>[],
    );
  }

  @override
  Future<void> abrirCaixa(AbrirCaixaRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<TiposRecebimento> atualizarTipoRecebimentoConfiguravel({
    required String codigoTipo,
    required TiposRecebimento request,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> cancelarMovimento(String id) {
    throw UnimplementedError();
  }

  @override
  Future<void> fecharCaixa(FecharCaixaRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<List<MovimentoCaixa>> getMovimentos(String idSessaoCaixa) {
    throw UnimplementedError();
  }

  @override
  Future<ResumoCaixa> getResumo(String idSessaoCaixa) {
    throw UnimplementedError();
  }

  @override
  Future<InformacoesCaixaComSomatorioResponse>
  getResumoDeMovimentosComSomatorio(String idSessaoCaixa) {
    throw UnimplementedError();
  }

  @override
  Future<CaixaSessao?> getSessaoAtual() {
    throw UnimplementedError();
  }

  @override
  Future<List<CaixaSessao>> getSessoesAbertas() {
    throw UnimplementedError();
  }

  @override
  Future<List<TiposRecebimento>> listarTiposRecebimentoConfiguraveis() {
    throw UnimplementedError();
  }

  @override
  Future<void> registrarMovimento(RegistrarMovimentoRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> restaurarTiposRecebimentoPadrao() {
    throw UnimplementedError();
  }

  @override
  Future<CaixaOuGuiche> criarCaixaOuGuiche(String nome) {
    throw UnimplementedError();
  }

  @override
  Future<CaixaOuGuiche> editarCaixaOuGuiche({
    required String id,
    required String nome,
  }) {
    throw UnimplementedError();
  }
}

class _FakeClienteUsuarioApiClient implements ClienteUsuarioApiClient {
  const _FakeClienteUsuarioApiClient(this.clientes);

  final List<ClienteUsuario> clientes;

  @override
  Future<ClienteUsuarioListResponse> listarClientesUsuario() async {
    return ClienteUsuarioListResponse(
      idUnicoDaEmpresa: 'empresa-test',
      total: clientes.length,
      clientes: clientes,
    );
  }

  @override
  Future<ClienteUsuario> cadastrarClienteUsuario(
    ClienteUsuarioRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<ClienteUsuario> atualizarClienteUsuario(
    String idCliente,
    ClienteUsuarioRequest request,
  ) {
    throw UnimplementedError();
  }
}

class _FakeColaboradorUsuarioApiClient implements ColaboradorUsuarioApiClient {
  const _FakeColaboradorUsuarioApiClient(this.colaboradores);

  final List<ColaboradorUsuarioResumo> colaboradores;

  @override
  Future<List<ColaboradorUsuarioResumo>> listarColaboradores() async {
    return colaboradores;
  }

  @override
  Future<List<ColaboradorUsuarioResumo>>
  listarTecnicosAssistenciaTecnica() async {
    return colaboradores
        .where(
          (ColaboradorUsuarioResumo item) =>
              item.ehTecnicoAssistenciaTecnica && item.ativo,
        )
        .toList(growable: false);
  }

  @override
  Future<ColaboradorUsuarioDetalhe> buscarColaborador(String idUnicoDoUsuario) {
    throw UnimplementedError();
  }

  @override
  Future<void> editarColaborador(Map<String, dynamic> payload) {
    throw UnimplementedError();
  }
}

class _FakeRegionalizacaoApiClient implements RegionalizacaoApiClient {
  @override
  Future<ConfiguracaoRegionalizacaoResponse> buscarRegionalizacao() async {
    return ConfiguracaoRegionalizacaoResponse.fromJson(
      ConfiguracaoRegionalizacaoSistema.defaultConfiguration().toTestJson(),
    );
  }

  @override
  Future<ConfiguracaoRegionalizacaoResponse> salvarRegionalizacao(
    SalvarConfiguracaoRegionalizacaoRequest request,
  ) async {
    return ConfiguracaoRegionalizacaoResponse.fromJson(request.toJson());
  }
}

class _ThemeCase {
  const _ThemeCase({
    required this.description,
    required this.brightness,
    required this.colors,
  });

  final String description;
  final Brightness brightness;
  final SixMobileColorScheme colors;
}

extension on ConfiguracaoRegionalizacaoSistema {
  Map<String, dynamic> toTestJson() {
    return <String, dynamic>{
      'languageCode': languageCode,
      'countryCode': countryCode,
      'currencyCode': formatting.currencyCode,
      'timeZone': formatting.timeZone,
      'dateFormat': formatting.dateFormat,
      'timeFormat': formatting.timeFormat,
      'decimalSeparator': formatting.decimalSeparator,
      'thousandSeparator': formatting.thousandSeparator,
      'firstDayOfWeek': formatting.firstDayOfWeek,
      'numberPattern': formatting.numberPattern,
      'decimalPlaces': formatting.decimalPlaces,
      'allowMultipleCurrencies': formatting.allowMultipleCurrencies,
      'applyFinancialRounding': formatting.applyFinancialRounding,
    };
  }
}
