import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/data/services/regionalizacao/regionalizacao_api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';
import 'package:sixpos/data/models/fatura_cartao_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/presentation/screens/faturas_cartao_web.dart';
import '../../data/services/fatura_cartao_api_client_test.dart' show invoiceJson;
class RegionalClient extends Fake implements RegionalizacaoApiClient {}
class Api extends CartaoCreditoApiClient {
 Api():super(espaco:'PESSOAL');
 bool falha=false,escrita=true;
 @override Future<CartoesCreditoResponse> listar()async=>CartoesCreditoResponse(podeEditar:escrita,cartoes:const[
  CartaoCredito(id:'cartao',nome:'Nubank',instituicao:'Nu',diaFechamento:3,diaVencimento:10,ativo:true,versao:0)]);
 @override Future<List<FaturaCartao>> faturas(String id)async{
  if(falha)throw const CartaoCreditoApiException('connection');return [FaturaCartao.fromJson(invoiceJson())];
 }
}
class DeleteApi extends Api {
 final ids=<String>[];
 final pending=Completer<void>();
 bool removed=false;
 @override Future<List<FaturaCartao>> faturas(String id)async=>removed?[]:super.faturas(id);
 @override Future<void> excluirCompra(String id,int versao,String comandoId)async{
  ids.add(comandoId);if(ids.length==1)throw const CartaoCreditoApiException('connection');
  await pending.future;removed=true;
 }
}
class RecurringApi extends Api {
 bool paid=false,stopped=false;
 final commands=<String>[];
 @override Future<List<FaturaCartao>> faturas(String id)async{
  final j=invoiceJson();j['paga']=paid;
  (j['compras'] as List).first.addAll({'serieRecorrenciaId':'serie','numeroOcorrencia':1,'prevista':!paid,'recorrenciaAtiva':!stopped});
  return [FaturaCartao.fromJson(j)];
 }
 @override Future<void> encerrarRecorrencia(String id,int versao,String comandoId)async{
  commands.add(comandoId);if(commands.length==1)throw const CartaoCreditoApiException('connection');stopped=true;
 }
}
void main(){
 for(final paid in [false,true])testWidgets('recorrencia distingue previsao e encerra inclusive na fatura paga $paid',(tester)async{
  tester.view.physicalSize=const Size(390,1400);tester.view.devicePixelRatio=1;
  addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  final api=RecurringApi()..paid=paid;addTearDown(api.dispose);
  await tester.pumpWidget(ChangeNotifierProvider(create:(_)=>LocaleSettingsProvider(regionalizacaoService:RegionalizacaoService(apiClient:RegionalClient())),child:MaterialApp(
   locale:const Locale('pt'),supportedLocales:const[Locale('pt')],localizationsDelegates:GlobalMaterialLocalizations.delegates,
   home:FaturasCartaoWeb(espaco:'PESSOAL',client:api))));
  await tester.pumpAndSettle();
  if(paid){expect(find.widgetWithText(FilledButton,'Pagar fatura'),findsNothing);}
  else{expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,isNull);}
  await tester.ensureVisible(find.byType(ExpansionTile));await tester.tap(find.byType(ExpansionTile));await tester.pumpAndSettle();
  expect(find.textContaining(paid?'Mensal · Lançada':'Mensal · Prevista'),findsOneWidget);
  await tester.ensureVisible(find.byType(PopupMenuButton<String>));await tester.tap(find.byType(PopupMenuButton<String>));await tester.pumpAndSettle();
  await tester.tap(find.text('Encerrar após esta compra'));await tester.pumpAndSettle();
  expect(find.text('Encerrar recorrência?'),findsOneWidget);expect(tester.takeException(),isNull);
  await tester.ensureVisible(find.text('Encerrar após esta compra'));await tester.tap(find.text('Encerrar após esta compra'));await tester.pumpAndSettle();
  expect(api.commands.length,1);
  await tester.tap(find.text('Encerrar após esta compra'));await tester.pump();await tester.pump(const Duration(seconds:2));await tester.pumpAndSettle();
  expect(api.stopped,isTrue);expect(api.commands[0],api.commands[1]);expect(tester.takeException(),isNull);
 });
 testWidgets('excluir compra confirma impacto, bloqueia envio e permite retry', (tester)async{
  tester.view.physicalSize=const Size(1100,1400);tester.view.devicePixelRatio=1;
  addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
  final api=DeleteApi();addTearDown(api.dispose);
  await tester.pumpWidget(ChangeNotifierProvider(create:(_)=>LocaleSettingsProvider(regionalizacaoService:RegionalizacaoService(apiClient:RegionalClient())),child:MaterialApp(
   locale:const Locale('pt'),supportedLocales:const[Locale('pt')],localizationsDelegates:GlobalMaterialLocalizations.delegates,
   home:FaturasCartaoWeb(espaco:'PESSOAL',client:api))));
  await tester.pumpAndSettle();await tester.tap(find.byType(ExpansionTile));await tester.pumpAndSettle();
  await tester.tap(find.byType(PopupMenuButton<String>));await tester.pumpAndSettle();
  await tester.tap(find.text('Excluir compra'));await tester.pumpAndSettle();
  expect(find.text('Excluir compra?'),findsOneWidget);
  expect(find.byType(BackdropFilter),findsWidgets);
  await tester.tap(find.text('Excluir compra'));await tester.pumpAndSettle();
  expect(api.ids.length,1);
  // The confirmation keeps its command ID after an uncertain response.
  final retry=find.text('Excluir compra');
  await tester.tap(retry);await tester.pump();
  expect(api.ids.length,2);expect(api.ids[0],api.ids[1]);
  await tester.sendKeyEvent(LogicalKeyboardKey.escape);await tester.pump();expect(find.text('Excluir compra?'),findsOneWidget);
  api.pending.complete();await tester.pump();await tester.pump(const Duration(seconds:2));await tester.pumpAndSettle();
  expect(api.removed,isTrue);expect(find.byType(ExpansionTile),findsNothing);expect(tester.takeException(),isNull);
 });
 for(final width in [390.0,1280.0]){
  for(final lang in ['pt','en','es']){
   testWidgets('faturas e categorias sem overflow $width $lang',(tester)async{
    tester.view.physicalSize=Size(width,1400);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final api=Api();addTearDown(api.dispose);
    await tester.pumpWidget(ChangeNotifierProvider(create:(_)=>LocaleSettingsProvider(regionalizacaoService:RegionalizacaoService(apiClient:RegionalClient())),child:MaterialApp(
     locale:Locale(lang),supportedLocales:const[Locale('pt'),Locale('en'),Locale('es')],
     localizationsDelegates:GlobalMaterialLocalizations.delegates,
     home:FaturasCartaoWeb(espaco:'PESSOAL',client:api))));
    await tester.pumpAndSettle();expect(find.byType(ExpansionTile),findsOneWidget);
    await tester.ensureVisible(find.byType(ExpansionTile));await tester.tap(find.byType(ExpansionTile));await tester.pumpAndSettle();
    expect(find.text('Netflix'),findsOneWidget);expect(tester.takeException(),isNull);
    api.falha=true;
    await tester.ensureVisible(find.widgetWithIcon(OutlinedButton,Icons.refresh));
    await tester.tap(find.widgetWithIcon(OutlinedButton,Icons.refresh));await tester.pumpAndSettle();
    expect(find.byType(ExpansionTile),findsOneWidget);expect(find.byType(FilledButton),findsNothing);
    expect(tester.takeException(),isNull);
   });
  }
 }
}
