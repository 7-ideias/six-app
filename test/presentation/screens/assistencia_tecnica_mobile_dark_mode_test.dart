import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        expect(find.text('Novo serviço'), findsOneWidget);
        expect(find.text('Consultar serviços em andamento'), findsOneWidget);
        expect(
          _hasMaterialAncestorColor(
            tester,
            find.text('Novo serviço'),
            themeCase.colors.surface,
          ),
          isTrue,
        );

        await tester.tap(find.text('Novo serviço'));
        await tester.pump();
        await tester.tap(find.text('Consultar serviços em andamento'));
        await tester.pump();

        expect(destinations, hasLength(2));
        expect(destinations.first, isA<AtendimentoTecnicoMobileScreen>());
        expect(destinations.last, isA<AtendimentosTecnicosMobileScreen>());
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
        expect(find.textContaining('Aberta'), findsWidgets);
        expect(find.textContaining('Aguardando avaliação'), findsWidgets);
        expect(find.textContaining('Aguardando aprovação'), findsWidgets);
        expect(find.textContaining('Aprovada'), findsWidgets);
        expect(find.textContaining('Em andamento'), findsWidgets);
        expect(find.textContaining('Aguardando peça'), findsWidgets);
        expect(find.textContaining('Concluída'), findsWidgets);
        expect(find.textContaining('Entregue'), findsWidgets);
        expect(find.textContaining('Cancelada'), findsWidgets);
        expect(find.textContaining('Pendente de pagamento'), findsWidgets);
        expect(find.byIcon(Icons.flag_outlined), findsWidgets);
        expect(
          find.byIcon(Icons.account_balance_wallet_outlined),
          findsWidgets,
        );
        final ChoiceChip selectedStatusChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Todos · 10'),
        );
        expect(selectedStatusChip.selectedColor, themeCase.colors.accent);
        expect(selectedStatusChip.labelStyle?.color, themeCase.colors.onAccent);
        final ChoiceChip inactiveStatusChip = tester.widget<ChoiceChip>(
          find.widgetWithText(ChoiceChip, 'Aberta · 1'),
        );
        expect(
          inactiveStatusChip.backgroundColor,
          themeCase.colors.softSurface,
        );
        expect(
          inactiveStatusChip.labelStyle?.color,
          themeCase.colors.titleText,
        );

        final Finder dateFilter = find.text('Data');
        await Scrollable.ensureVisible(
          tester.element(dateFilter),
          alignment: 0.7,
        );
        await tester.pump();
        expect(
          _hasDecoratedAncestorColor(
            tester,
            dateFilter,
            themeCase.colors.softSurface,
          ),
          isTrue,
        );
        await tester.tap(
          find.ancestor(of: dateFilter, matching: find.byType(InkWell)).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Filtrar por data'), findsOneWidget);
        expect(
          _hasDecoratedAncestorColor(
            tester,
            find.text('Filtrar por data'),
            themeCase.colors.background,
          ),
          isTrue,
        );
        await tester.tap(find.byIcon(Icons.close_rounded).last);
        await tester.pumpAndSettle();

        await _dragUntilTextVisible(tester, 'Buscar por cliente');
        await tester.pump();
        expect(
          find.text('Buscar por cliente, status, equipamento ou número'),
          findsOneWidget,
        );
        final TextField searchField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        expect(searchField.decoration?.filled, isTrue);
        expect(searchField.decoration?.fillColor, themeCase.colors.surface);

        await tester.enterText(find.byType(TextField).first, 'pendente');
        await tester.pump();
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
                .first;
        await Scrollable.ensureVisible(
          tester.element(detailsButton),
          alignment: 0.65,
        );
        await tester.pump();
        await tester.tap(detailsButton);
        await tester.pumpAndSettle();

        expect(find.text('Resumo da ordem de serviço'), findsOneWidget);
        expect(find.byTooltip('Compartilhar atendimento'), findsOneWidget);
        expect(find.byIcon(Icons.send_rounded), findsOneWidget);
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
          'Valores',
          exact: true,
          lastScrollable: true,
        );
        expect(find.text('Valores'), findsOneWidget);
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
        expect(find.byTooltip('Compartilhar atendimento'), findsOneWidget);
        expect(find.byIcon(Icons.send_rounded), findsOneWidget);
        expect(find.byIcon(Icons.close_rounded), findsWidgets);

        await tester.tap(find.byTooltip('Compartilhar atendimento'));
        await tester.pump();
        await tester.tap(
          find.byTooltip('Compartilhar atendimento'),
          warnIfMissed: false,
        );
        await tester.pump();

        expect(pdfShareService.calls, 1);
        expect(pdfShareService.lastAtendimentoId, 'os-pdf');
        expect(pdfShareService.lastSharePositionOrigin, isNotNull);
        expect(find.byType(CircularProgressIndicator), findsWidgets);
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
        expect(find.byType(CircularProgressIndicator), findsNothing);
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
        await tester.tap(find.byTooltip('Compartilhar atendimento'));
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
        await tester.tap(find.byTooltip('Compartilhar atendimento'));
        await tester.pumpAndSettle();

        expect(downloadedPdfShareService.calls, 1);
        expect(find.text('PDF baixado com sucesso.'), findsOneWidget);
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
                .first;
        await tester.tap(detailsButton);
        await tester.pumpAndSettle();
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
        final FilledButton initialCreateButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Iniciar atendimento técnico'),
        );
        expect(initialCreateButton.onPressed, isNotNull);

        await tester.scrollUntilVisible(
          find.text('Iniciar atendimento técnico'),
          420,
          scrollable: _verticalScrollable(),
        );
        await tester.pump();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Iniciar atendimento técnico'),
        );
        await tester.pump();
        expect(
          find.text('Selecione um cliente antes de iniciar o atendimento.'),
          findsOneWidget,
        );
        expect(service.createCalls, 0);

        await tester.drag(_verticalScrollable(), const Offset(0, 900));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(InputDecorator).first);
        await tester.pumpAndSettle();
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

        await tester.scrollUntilVisible(
          find.text('Entrega prevista'),
          420,
          scrollable: _verticalScrollable(),
        );
        await tester.pump();
        await tester.tap(
          find
              .ancestor(
                of: find.text('Entrega prevista').first,
                matching: find.byType(InkWell),
              )
              .first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Aplicar entrega'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Aplicar entrega'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Defeito relatado pelo cliente'),
          -420,
          scrollable: _verticalScrollable(),
        );
        await tester.pump();
        await tester.enterText(
          find.widgetWithText(TextField, 'Defeito relatado pelo cliente'),
          'Tela apaga durante o atendimento.',
        );
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
        await tester.pump();
        await tester.tap(
          find.widgetWithText(FilledButton, 'Iniciar atendimento técnico'),
        );
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
        expect(find.text('Valor aberto'), findsOneWidget);
        expect(find.textContaining('BRL'), findsWidgets);
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
        await tester.tap(find.textContaining('OS-PAGAMENTO').first);
        await tester.pumpAndSettle();
        expect(find.text('Resumo da ordem de serviço'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Receber'), findsOneWidget);
        await _dragUntilTextVisible(
          tester,
          'Valores',
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
        await tester.scrollUntilVisible(
          find.text('Defeito relatado pelo cliente'),
          420,
          scrollable: _verticalScrollable(),
        );
        await tester.pump();
        expect(find.text('Defeito relatado pelo cliente'), findsOneWidget);
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
      await tester.tap(
        find.widgetWithText(FilledButton, 'Iniciar atendimento técnico'),
      );
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
      colaboradorApiClient: _FakeColaboradorUsuarioApiClient(
        <ColaboradorUsuarioResumo>[_tecnico(nome: 'Técnica Six')],
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

Future<void> _fillCreateRequiredFields(WidgetTester tester) async {
  await tester.drag(_verticalScrollable(), const Offset(0, 900));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(InputDecorator).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cliente Six').last);
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

  await tester.scrollUntilVisible(
    find.text('Defeito relatado pelo cliente'),
    420,
    scrollable: _verticalScrollable(),
  );
  await tester.pump();
  await tester.enterText(
    find.widgetWithText(TextField, 'Defeito relatado pelo cliente'),
    'Tela apaga durante o atendimento.',
  );
  await tester.scrollUntilVisible(
    find.text('Iniciar atendimento técnico'),
    420,
    scrollable: _verticalScrollable(),
  );
  await tester.pump();
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
  return <AtendimentoTecnicoModel>[
    _atendimento(
      numero: 'OS-FINAL',
      statusCodigo: 'CONCLUIDO',
      statusNome: 'Concluída',
      valorEmAberto: 0,
      liquidada: true,
      assinaturaAprovada: true,
      dataAtualizacao: DateTime(2026, 8, 9, 10),
    ),
    _atendimento(
      numero: 'OS-ABERTA',
      statusCodigo: 'ABERTA',
      statusNome: 'Aberta',
      dataAtualizacao: DateTime(2026, 8, 8, 9),
    ),
    _atendimento(
      numero: 'OS-AVALIACAO',
      statusCodigo: 'AGUARDANDO_AVALIACAO',
      statusNome: 'Aguardando avaliação',
      dataAtualizacao: DateTime(2026, 8, 7, 9),
    ),
    _atendimento(
      numero: 'OS-APROVACAO',
      statusCodigo: 'AGUARDANDO_APROVACAO',
      statusNome: 'Aguardando aprovação',
      dataAtualizacao: DateTime(2026, 8, 6, 9),
    ),
    _atendimento(
      numero: 'OS-APROVADA',
      statusCodigo: 'APROVADA',
      statusNome: 'Aprovada',
      dataAtualizacao: DateTime(2026, 8, 5, 9),
    ),
    _atendimento(
      numero: 'OS-ANDAMENTO',
      statusCodigo: 'EM_ANDAMENTO',
      statusNome: 'Em andamento',
      dataAtualizacao: DateTime(2026, 8, 4, 9),
    ),
    _atendimento(
      numero: 'OS-PECA',
      statusCodigo: 'AGUARDANDO_PECA',
      statusNome: 'Aguardando peça',
      dataAtualizacao: DateTime(2026, 8, 3, 9),
    ),
    _atendimento(
      numero: 'OS-ENTREGUE',
      statusCodigo: 'ENTREGUE',
      statusNome: 'Entregue',
      valorEmAberto: 0,
      liquidada: true,
      dataAtualizacao: DateTime(2026, 8, 2, 9),
    ),
    _atendimento(
      numero: 'OS-CANCELADA',
      statusCodigo: 'CANCELADO',
      statusNome: 'Cancelada',
      valorEmAberto: 0,
      liquidada: true,
      dataAtualizacao: DateTime(2026, 8, 1, 9),
    ),
    _atendimento(
      numero: 'OS-PAGAMENTO',
      statusCodigo: 'PENDENTE_PAGAMENTO',
      statusNome: 'Pendente de pagamento',
      valorEmAberto: 180,
      liquidada: false,
      dataAtualizacao: DateTime(2026, 7, 31, 9),
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
    idTecnicoResponsavel: 'tec-1',
    nomeTecnicoResponsavelSnapshot: 'Técnica Six',
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
    dataEntregaPrevista: DateTime(2026, 8, 16),
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

ColaboradorUsuarioResumo _tecnico({required String nome}) {
  return ColaboradorUsuarioResumo(
    idUnicoPessoal: 'tec-1',
    nome: nome,
    nomeDeGuerra: 'Técnica',
    celularDeAcesso: '(11) 98888-0000',
    email: 'tecnica@six.test',
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

  @override
  Future<AtendimentoTecnicoDominiosBaseModel> buscarDominiosBase() async {
    return _dominios;
  }

  @override
  Future<List<AtendimentoTecnicoModel>> listar() {
    listCalls++;
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
  }) async {
    lastStatus = status;
    lastStatusObservation = observacao;
    return _atendimento(
      numero: id.toUpperCase(),
      statusCodigo: status.codigo,
      statusNome: status.nomePadraoPtBr,
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
  Future<AtendimentoTecnicoStatusPublicoLinkModel> gerarLinkStatusPublico({
    required String id,
    required String baseUrl,
  }) async {
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
