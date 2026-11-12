import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sixpos/data/models/fatura_cartao_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';

Map<String,dynamic> invoiceJson()=>{'id':'fatura','cartaoId':'cartao','nomeCartao':'Nubank','idLancamento':'op',
 'fechamento':'2026-12-03','vencimento':'2026-12-10','total':80.0,'versao':1,'paga':false,'contaPrevistaId':null,
 'compras':[{'id':'compra','descricao':'Netflix','dataCompra':'2026-11-11','valor':80,'categoria':'Assinaturas'}],
 'porCategoria':{'Assinaturas':80.0}};
void main(){
 test('recorrencia usa contratos proprios, escopo e termino inclusivo',()async{
  final calls=<http.Request>[];
  final api=CartaoCreditoApiClient(espaco:'PESSOAL',tokenProvider:()async=>'token',client:MockClient((r)async{
   calls.add(r);
   if(r.url.path.endsWith('/previa-recorrencia'))return http.Response(jsonEncode({'fechamento':'2027-02-03','vencimento':'2027-02-10','versaoCartao':0,'paga':false}),200);
   if(r.url.path.endsWith('/encerrar-recorrencia'))return http.Response('{"encerrada":true}',200);
   return http.Response(jsonEncode(invoiceJson()),200);
  }));addTearDown(api.dispose);
  final p=await api.previaRecorrencia('cartao',DateTime(2027,1,31));
  final r=CompraCartaoRequest(id:'comando',cartaoId:'cartao',descricao:'Mensal',dataCompra:DateTime(2027,1,31),valor:80,previa:p);
  await api.criarRecorrencia(r,DateTime(2027,3,31));
  expect(calls[1].url.path.endsWith('/cartao/recorrencias'),isTrue);
  expect(jsonDecode(calls[1].body)['fim'],'2027-03-31');
  await api.editarProximas('compra',5,r,null);
  expect(jsonDecode(calls[2].body)['escopo'],'ESTE_E_PROXIMOS');
  expect(jsonDecode(calls[2].body)['versao'],5);
  await api.encerrarRecorrencia('compra',5,'parar');
  expect(jsonDecode(calls[3].body)['comandoId'],'parar');
  final c=CompraCartao.fromJson({'id':'x','descricao':'Mensal','dataCompra':'2027-01-31','valor':80,'serieRecorrenciaId':'serie','numeroOcorrencia':2,'prevista':true,'recorrenciaAtiva':true,'recorrenciaFim':'2027-03-31'});
  expect(c.prevista,isTrue);expect(c.recorrenciaAtiva,isTrue);expect(c.numeroOcorrencia,2);expect(c.recorrenciaFim,DateTime(2027,3,31));
 });
 test('editar e excluir enviam versao e comando e propagam conflitos',()async{
  final api=CartaoCreditoApiClient(espaco:'PESSOAL',tokenProvider:()async=>'token',client:MockClient((r)async{
   final j=jsonDecode(r.body);expect(j['versao'],5);
   if(r.method=='PUT'){expect(r.url.path.endsWith('/compras/compra'),isTrue);expect(j['cartaoId'],'outro');expect(j['compra']['id'],'comando');return http.Response(jsonEncode(invoiceJson()),200);}
   expect(r.url.path.endsWith('/compras/compra/exclusao'),isTrue);expect(j['comandoId'],'excluir');return http.Response('{}',409);
  }));addTearDown(api.dispose);
  await api.editarCompra('compra',5,CompraCartaoRequest(id:'comando',cartaoId:'outro',descricao:'Compra',dataCompra:DateTime(2026,11,11),valor:80,
   previa:PreviaFaturaCartao.fromJson({'fechamento':'2026-12-03','vencimento':'2026-12-10','versaoCartao':0,'paga':false})));
  await expectLater(api.excluirCompra('compra',5,'excluir'),throwsA(isA<CartaoCreditoApiException>().having((e)=>e.statusCode,'status',409)));
 });
 test('compra envia previa e retry repete ID sem criar outra compra',()async{
  final bodies=<String>[];
  final api=CartaoCreditoApiClient(espaco:'PESSOAL',tokenProvider:()async=>'token',client:MockClient((r)async{
   expect(r.url.path.endsWith('/cartoes/cartao/compras'),isTrue);expect(r.headers['espacoFinanceiro'],'PESSOAL');
   bodies.add(r.body);if(bodies.length==1)throw http.ClientException('offline');
   return http.Response(jsonEncode(invoiceJson()),200);
  }));addTearDown(api.dispose);
  final input=CompraCartaoRequest(id:'tentativa',cartaoId:'cartao',descricao:' Netflix ',dataCompra:DateTime(2026,11,11),valor:80,
   previa:PreviaFaturaCartao.fromJson({'fechamento':'2026-12-03','vencimento':'2026-12-10','versaoCartao':2,'paga':false}));
  await expectLater(api.comprar(input),throwsA(isA<CartaoCreditoApiException>()));
  expect((await api.comprar(input)).compras.single.descricao,'Netflix');expect(bodies.first,bodies.last);
  expect(jsonDecode(bodies.last)['versaoCartao'],2);expect(jsonDecode(bodies.last)['vencimentoConfirmado'],'2026-12-10');
 });
 test('pagamento envia versao, conta e data efetiva; conflito nao vira sucesso',()async{
  final api=CartaoCreditoApiClient(espaco:'EMPRESA',tokenProvider:()async=>'token',empresaProvider:()async=>'empresa',client:MockClient((r)async{
   expect(r.url.path.endsWith('/cartoes/faturas/fatura/pagamento'),isTrue);expect(r.headers['idUnicoDaEmpresa'],'empresa');
   final j=jsonDecode(r.body);expect(j['versao'],1);expect(j['contaFinanceiraId'],'banco');expect(j['dataPagamento'],'2026-12-09');
   return http.Response('{}',409);
  }));addTearDown(api.dispose);
  await expectLater(api.pagar(PagarFaturaCartaoRequest(id:'id',faturaId:'fatura',versao:1,valor:80,contaFinanceiraId:'banco',dataPagamento:DateTime(2026,12,9),formaPagamento:'tipo2')),
   throwsA(isA<CartaoCreditoApiException>().having((e)=>e.kind,'kind','conflict')));
 });
 test('erro e contrato invalido nunca viram faturas vazias',()async{
  for(final status in [200,500]){
   final api=CartaoCreditoApiClient(espaco:'PESSOAL',tokenProvider:()async=>'token',client:MockClient((_)async=>http.Response('{}',status)));
   await expectLater(api.faturas('cartao'),throwsA(isA<CartaoCreditoApiException>()));api.dispose();
  }
 });
}
