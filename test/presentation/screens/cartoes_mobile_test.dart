import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';
import 'package:sixpos/data/models/fatura_cartao_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/screens/cartoes_credito_mobile_screen.dart';
import 'package:sixpos/presentation/screens/compra_cartao_mobile_screen.dart';
import 'package:sixpos/presentation/screens/faturas_cartao_mobile_screen.dart';
import 'faturas_cartao_web_test.dart' show RegionalClient;

FaturaCartao invoice()=>FaturaCartao.fromJson({'id':'invoice','cartaoId':'card','nomeCartao':'Nubank','idLancamento':'entry','fechamento':'2026-11-03','vencimento':'2026-11-10','total':50,'versao':1,'paga':false,'contaPrevistaId':'bank','compras':[],'porCategoria':{}});
class Api extends CartaoCreditoApiClient {
 Api():super(espaco:'PESSOAL');
 bool failRead=false,editable=true;final purchases=<CompraCartaoRequest>[];final payments=<PagarFaturaCartaoRequest>[];
 @override Future<CartoesCreditoResponse> listar()async{
  if(failRead)throw const CartaoCreditoApiException('connection');
  return CartoesCreditoResponse(podeEditar:editable,cartoes:const[CartaoCredito(id:'card',nome:'Nubank',instituicao:'Nu',diaFechamento:3,diaVencimento:10,ativo:true,versao:0)]);
 }
 @override Future<PreviaFaturaCartao> previa(String id,DateTime date)async=>PreviaFaturaCartao.fromJson({'fechamento':'2026-11-03','vencimento':'2026-11-10','versaoCartao':0,'paga':false});
 @override Future<FaturaCartao> comprar(CompraCartaoRequest r)async{purchases.add(r);if(purchases.length==1)throw const CartaoCreditoApiException('connection');return invoice();}
 @override Future<List<FormaPagamentoFatura>> formasFatura()async=>const[FormaPagamentoFatura('tipo2','Pix personalizado')];
 @override Future<FaturaCartao> pagar(PagarFaturaCartaoRequest r)async{payments.add(r);if(payments.length==1)throw const CartaoCreditoApiException('connection');return invoice();}
}
class Config extends ConfiguracaoFinanceiraService {
 Config():super('PESSOAL');
 @override Future<List<ConfiguracaoFinanceira>> listar(String group)async=>group=='CONTAS'?const[ConfiguracaoFinanceira(id:'bank',nome:'Conta pessoal',tipo:'BANCO')]:const[ConfiguracaoFinanceira(id:'category',nome:'Assinaturas',tipo:'DESPESA')];
}
Future<void> open(WidgetTester t,Widget page,{String language='pt'})async{
 t.view.physicalSize=const Size(390,844);t.view.devicePixelRatio=1;addTearDown(t.view.resetPhysicalSize);addTearDown(t.view.resetDevicePixelRatio);
 await t.pumpWidget(ChangeNotifierProvider(create:(_)=>LocaleSettingsProvider(regionalizacaoService:RegionalizacaoService(apiClient:RegionalClient())),child:MaterialApp(locale:Locale(language),supportedLocales:const[Locale('pt'),Locale('en'),Locale('es')],localizationsDelegates:GlobalMaterialLocalizations.delegates,home:page)));
 await t.pumpAndSettle();
}
Future<void> tap(WidgetTester t,Finder f)async{await t.ensureVisible(f);await t.tap(f);await t.pumpAndSettle();}
Finder field(String text)=>find.byWidgetPredicate((w)=>w is TextField&&w.decoration?.labelText==text);
void main(){
 for(final language in ['pt','en','es'])testWidgets('mobile card list errors and permission $language',(t)async{
  final api=Api()..failRead=true;addTearDown(api.dispose);
  await open(t,CartoesCreditoMobileScreen(espaco:'PESSOAL',client:api),language:language);
  expect(find.byType(FloatingActionButton),findsNothing);expect(find.text('Nubank'),findsNothing);
  api.failRead=false;api.editable=false;
  await tap(t,find.byIcon(Icons.refresh).first);
  expect(find.text('Nubank'),findsOneWidget);expect(find.byType(FloatingActionButton),findsNothing);expect(find.byIcon(Icons.edit_outlined),findsNothing);expect(t.takeException(),isNull);
 });
 testWidgets('mobile purchase reviews and retries the same request',(t)async{
  final api=Api(),config=Config();addTearDown(api.dispose);addTearDown(config.dispose);
  await open(t,CompraCartaoMobileScreen(espaco:'PESSOAL',client:api,configuracoes:config));
  await tap(t,find.text('Cartões de crédito'));
  await tap(t,find.text('Nubank'));
  await t.enterText(field('Descrição'),'Netflix');await t.enterText(field('Valor da compra'),'50');
  await tap(t,find.text('Revisar compra'));
  await tap(t,find.text('Adicionar à fatura'));
  expect(api.purchases.length,1);
  await tap(t,find.widgetWithText(FilledButton,'Não foi possível carregar. Tentar novamente'));
  expect(api.purchases.length,2);expect(api.purchases.first.toJson(),api.purchases.last.toJson());expect(t.takeException(),isNull);
 });
 testWidgets('mobile invoice payment retains account and id on timeout',(t)async{
  final api=Api(),config=Config();addTearDown(api.dispose);addTearDown(config.dispose);
  await open(t,PagarFaturaCartaoMobileScreen(client:api,fatura:invoice(),configuracoes:config));
  await tap(t,find.text('Forma de pagamento'));
  await tap(t,find.text('Pix personalizado'));
  await tap(t,find.text('Confirmar pagamento integral'));
  expect(api.payments.length,1);expect(api.payments.single.contaFinanceiraId,'bank');
  await tap(t,find.widgetWithText(FilledButton,'Não foi possível carregar. Tentar novamente'));
  expect(api.payments.length,2);expect(api.payments.first.toJson(),api.payments.last.toJson());expect(t.takeException(),isNull);
 });
}
