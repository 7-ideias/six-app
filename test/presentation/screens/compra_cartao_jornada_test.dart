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
 int edits=0,series=0,installments=0;
 @override Future<List<ParcelaCartao>> previaParcelamento(CompraCartaoRequest r,int n)async=>List.generate(n,(i)=>ParcelaCartao.fromJson({'numero':i+1,'valor':r.valor/n,'vencimento':'2026-12-10','paga':false}));
 @override Future<FaturaCartao> parcelar(CompraCartaoRequest r,int n){installments++;expect(n,2);return comprar(r);}
 @override Future<PreviaFaturaCartao> previaRecorrencia(String id,DateTime data)=>previa(id,data);
 @override Future<FaturaCartao> criarRecorrencia(CompraCartaoRequest r,DateTime? fim){series++;expect(fim,isNull);return comprar(r);}
 @override Future<FaturaCartao> editarCompra(String id,int versao,CompraCartaoRequest r){
  expect(id,'compra');expect(versao,5);edits++;return comprar(r);
 }
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
void main(){for(final mode in ['new','edit','monthly','installments']){final editing=mode=='edit';testWidgets('journey preserves fields and retries, mode=$mode', (tester)async{
 tester.view.physicalSize=const Size(1100,1600);tester.view.devicePixelRatio=1;
 addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
 final api=Cards(),config=Config();addTearDown(api.dispose);addTearDown(config.dispose);
 final description=TextEditingController(text:'Netflix'),amount=TextEditingController(text:'50'),category=TextEditingController(text:'Assinaturas');
 addTearDown(description.dispose);addTearDown(amount.dispose);addTearDown(category.dispose);
 final key=GlobalKey<CompraCartaoWebEditorState>();FaturaCartao? saved;bool locked=false;
 await tester.pumpWidget(ChangeNotifierProvider(create:(_)=>LocaleSettingsProvider(regionalizacaoService:RegionalizacaoService(apiClient:RegionalClient())),child:MaterialApp(
  locale:const Locale('pt'),localizationsDelegates:GlobalMaterialLocalizations.delegates,supportedLocales:const[Locale('pt')],home:Scaffold(body:CompraCartaoWebEditor(
   key:key,client:api,configuracoes:config,cartaoInicial:'cartao',compraInicial:editing?CompraCartao.fromJson({'id':'compra','descricao':'Netflix','dataCompra':'2026-11-11','valor':80,'categoriaId':'category','categoria':'Assinaturas','versao':5}):null,embedded:true,descricaoController:description,valorController:amount,categoriaController:category,
   onSaved:(f)=>saved=f,onLocked:(v)=>locked=v)))));
 await tester.pumpAndSettle();expect(find.byType(FilledButton),findsNothing);
 if(mode=='monthly'){await tester.tap(find.text('Mensal'));await tester.pumpAndSettle();}
 if(mode=='installments'){await tester.tap(find.text('Parcelada'));await tester.pumpAndSettle();expect(key.currentState!.validate(),isFalse);await tester.ensureVisible(find.text('Calcular parcelas'));await tester.tap(find.text('Calcular parcelas'));await tester.pumpAndSettle();}
 expect(key.currentState!.validate(),isTrue);
 description.text='Netflix atualizado';
 await key.currentState!.submit();await tester.pumpAndSettle();
 expect(saved,isNull);expect(locked,isTrue);expect(description.text,'Netflix atualizado');
 await key.currentState!.submit();await tester.pumpAndSettle();
 expect(saved,isNotNull);expect(api.requests.length,2);
 expect(api.requests[0].toJson(),api.requests[1].toJson());expect(api.requests[0].categoriaId,'category');
 expect(api.installments,mode=='installments'?2:0);expect(api.series,mode=='monthly'?2:0);expect(api.edits,editing?2:0);expect(api.requests[0].descricao,'Netflix atualizado');expect(tester.takeException(),isNull);
 });}}
