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
class Api extends CartaoCreditoApiClient {
 Api():super(espaco:'PESSOAL');
 bool falha=false,escrita=true;
 @override Future<CartoesCreditoResponse> listar()async=>CartoesCreditoResponse(podeEditar:escrita,cartoes:const[
  CartaoCredito(id:'cartao',nome:'Nubank',instituicao:'Nu',diaFechamento:3,diaVencimento:10,ativo:true,versao:0)]);
 @override Future<List<FaturaCartao>> faturas(String id)async{
  if(falha)throw const CartaoCreditoApiException('connection');return [FaturaCartao.fromJson(invoiceJson())];
 }
}
void main(){
 for(final width in [390.0,1280.0]){
  for(final lang in ['pt','en','es']){
   testWidgets('faturas e categorias sem overflow $width $lang',(tester)async{
    tester.view.physicalSize=Size(width,1400);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final api=Api();addTearDown(api.dispose);
    await tester.pumpWidget(ChangeNotifierProvider(create:(_)=>LocaleSettingsProvider(),child:MaterialApp(
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
