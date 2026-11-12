import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/gastos_categoria_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/screens/gastos_categorias_web.dart';
import 'faturas_cartao_web_test.dart' show RegionalClient;
class GastosApi extends CartaoCreditoApiClient {
 GastosApi():super(espaco:'PESSOAL');bool fail=false;
 @override Future<GastosCategorias> gastosCategorias(DateTime inicio,DateTime fim)async{
  if(fail)throw const CartaoCreditoApiException('connection');
  return GastosCategorias.fromJson({'inicio':'2026-11-01','fim':'2026-11-30','realizado':50,'previsto':80,'categorias':[{'categoria':'Assinaturas','realizado':50,'previsto':80,'itens':[
   {'id':'a','descricao':'Netflix','origem':'CARTAO','cartao':'Nubank','faturaId':'fatura','data':'2026-11-10','situacao':'REALIZADO','valor':50},
   {'id':'b','descricao':'Internet','origem':'DIRETO','data':'2026-11-20','situacao':'PREVISTO','valor':80}
  ]}]});
 }
}
void main(){for(final width in [390.0,1280.0])for(final lang in ['pt','en','es'])testWidgets('categorias detalham origens e preservam erro $width $lang',(tester)async{
 tester.view.physicalSize=Size(width,1600);tester.view.devicePixelRatio=1;addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
 final api=GastosApi();addTearDown(api.dispose);
 await tester.pumpWidget(ChangeNotifierProvider(create:(_)=>LocaleSettingsProvider(regionalizacaoService:RegionalizacaoService(apiClient:RegionalClient())),child:MaterialApp(locale:Locale(lang),supportedLocales:const[Locale('pt'),Locale('en'),Locale('es')],localizationsDelegates:GlobalMaterialLocalizations.delegates,home:GastosCategoriasWeb(espaco:'PESSOAL',inicio:DateTime(2026,11,1),fim:DateTime(2026,11,30),client:api))));
 await tester.pumpAndSettle();expect(find.byType(ExpansionTile),findsOneWidget);
 await tester.ensureVisible(find.byType(ExpansionTile));await tester.tap(find.byType(ExpansionTile));await tester.pumpAndSettle();expect(find.text('Netflix'),findsOneWidget);expect(find.text('Internet'),findsOneWidget);expect(find.text('Nubank'),findsOneWidget);expect(tester.takeException(),isNull);
 api.fail=true;final refresh=find.widgetWithIcon(OutlinedButton,Icons.refresh);await tester.ensureVisible(refresh);await tester.tap(refresh);await tester.pumpAndSettle();expect(find.byType(ExpansionTile),findsOneWidget);expect(tester.takeException(),isNull);
});}
