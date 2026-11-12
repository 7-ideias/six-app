import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/data/models/fatura_cartao_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/domain/services/regionalizacao/regionalizacao_service.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/components/web/compra_cartao_web_editor.dart';
import 'faturas_cartao_web_test.dart' show Api,RegionalClient;
import '../../data/services/fatura_cartao_api_client_test.dart' show invoiceJson;
class Cards extends Api {
 final requests=<CompraCartaoRequest>[];
 @override Future<PreviaFaturaCartao> previa(String id,DateTime data)async=>PreviaFaturaCartao.fromJson({'fechamento':'2026-12-03','vencimento':'2026-12-10','versaoCartao':0,'paga':false});
 @override Future<FaturaCartao> comprar(CompraCartaoRequest r)async{
  requests.add(r);if(requests.length==1)throw const CartaoCreditoApiException('connection');
  return FaturaCartao.fromJson(invoiceJson());
 }
}
class Config extends ConfiguracaoFinanceiraService {
 Config():super('PESSOAL');
 @override Future<List<ConfiguracaoFinanceira>> listar(String grupo)async=>const[ConfiguracaoFinanceira(id:'category',nome:'Assinaturas',tipo:'DESPESA')];
}
void main(){testWidgets('journey shares fields, preserves category and retries the same purchase', (tester)async{
 tester.view.physicalSize=const Size(1100,1600);tester.view.devicePixelRatio=1;
 addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
 final api=Cards(),config=Config();addTearDown(api.dispose);addTearDown(config.dispose);
 final description=TextEditingController(text:'Netflix'),amount=TextEditingController(text:'50'),category=TextEditingController(text:'Assinaturas');
 addTearDown(description.dispose);addTearDown(amount.dispose);addTearDown(category.dispose);
 final key=GlobalKey<CompraCartaoWebEditorState>();FaturaCartao? saved;bool locked=false;
 await tester.pumpWidget(ChangeNotifierProvider(create:(_)=>LocaleSettingsProvider(regionalizacaoService:RegionalizacaoService(apiClient:RegionalClient())),child:MaterialApp(
  locale:const Locale('pt'),localizationsDelegates:GlobalMaterialLocalizations.delegates,supportedLocales:const[Locale('pt')],home:Scaffold(body:CompraCartaoWebEditor(
   key:key,client:api,configuracoes:config,cartaoInicial:'cartao',embedded:true,descricaoController:description,valorController:amount,categoriaController:category,
   onSaved:(f)=>saved=f,onLocked:(v)=>locked=v)))));
 await tester.pumpAndSettle();expect(find.byType(FilledButton),findsNothing);
 expect(key.currentState!.validate(),isTrue);
 description.text='Netflix atualizado';
 await key.currentState!.submit();await tester.pumpAndSettle();
 expect(saved,isNull);expect(locked,isTrue);expect(description.text,'Netflix atualizado');
 await key.currentState!.submit();await tester.pumpAndSettle();
 expect(saved,isNotNull);expect(api.requests.length,2);
 expect(api.requests[0].toJson(),api.requests[1].toJson());expect(api.requests[0].categoriaId,'category');
 expect(api.requests[0].descricao,'Netflix atualizado');expect(tester.takeException(),isNull);
 });}
