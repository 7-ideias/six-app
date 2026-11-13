import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/core/utils/uuid_v4.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';
import 'package:sixpos/data/models/fatura_cartao_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/components/mobile/cartoes_mobile_widgets.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'compra_cartao_mobile_screen.dart';

class FaturasCartaoMobileScreen extends StatefulWidget {
 const FaturasCartaoMobileScreen({super.key,required this.espaco,this.cartaoId,this.faturaId,this.client});
 final String espaco;final String? cartaoId,faturaId;final CartaoCreditoApiClient? client;
 @override State<FaturasCartaoMobileScreen> createState()=>_FaturasState();
}
class _FaturasState extends State<FaturasCartaoMobileScreen> {
 late final api=widget.client??CartaoCreditoApiClient(espaco:widget.espaco);
 late String? card=widget.cartaoId;
 List<CartaoCredito> cards=[];List<FaturaCartao> invoices=[];
 bool loading=true,permission=false,acting=false;String? error;
 @override void initState(){super.initState();load();}
 @override void dispose(){if(widget.client==null)api.dispose();super.dispose();}
 Future<void> load()async{
  setState((){loading=true;error=null;permission=false;});
  try{final c=await api.listar();final List<FaturaCartao> f;
   if(widget.faturaId!=null){f=[await api.fatura(widget.faturaId!)];}
   else{if(!c.cartoes.any((c)=>c.id==card))card=c.cartoes.firstOrNull?.id;f=card==null?[]:await api.faturas(card!);}
   if(mounted)setState((){cards=c.cartoes;permission=c.podeEditar;invoices=f;});
  }catch(e){if(mounted)setState((){error=erroCartaoMobile(e);if(acessoCartaoNegado(e)){cards=[];invoices=[];}});}
  finally{if(mounted)setState(()=>loading=false);}
 }
 Future<void> purchaseAction(FaturaCartao f,CompraCartao c)async{
  if(loading||acting||error!=null||!permission)return;
  final v=await escolherCartaoOpcao(context,'invoices.purchaseActions',{
   'duplicate':context.t('agenda.duplicate.action'),
   if(!f.paga)'edit':context.t('invoices.editPurchase'),
   if(!f.paga)'delete':context.t(c.serieRecorrenciaId==null?'invoices.delete.confirm':'invoices.recurring.deleteThis'),
   if(c.recorrenciaAtiva)'stop':context.t('invoices.stop.confirm'),
  },null);
  if(v==null||!mounted)return;
  setState(()=>acting=true);
  if(v=='duplicate'){
   await Navigator.push(context,MaterialPageRoute<FaturaCartao>(builder:(_)=>CompraCartaoMobileScreen(espaco:widget.espaco,client:api,duplicarCompra:c,fatura:f)));
  }else if(v=='edit'){
   await Navigator.push(context,MaterialPageRoute<FaturaCartao>(builder:(_)=>CompraCartaoMobileScreen(espaco:widget.espaco,client:api,compra:c,fatura:f)));
  }else{
   final command=gerarUuidV4(),r=context.read<LocaleSettingsProvider>();
   await confirmarCartaoMobile(context,prefix:v=='stop'?'invoices.stop':'invoices.delete',summary:'${c.descricao}\n${f.nomeCartao} · ${r.formatCurrency(c.valor)}\n${r.formatDate(c.dataCompra)}',
    action:()=>v=='stop'?api.encerrarRecorrencia(c.id,c.versao,command):api.excluirCompra(c.id,c.versao,command));
  }
  if(mounted){setState(()=>acting=false);await load();}
 }
 Future<void> pay(FaturaCartao f)async{
  setState(()=>acting=true);
  await Navigator.push(context,MaterialPageRoute<FaturaCartao>(builder:(_)=>PagarFaturaCartaoMobileScreen(client:api,fatura:f)));
  if(mounted){setState(()=>acting=false);await load();}
 }
 Widget invoice(FaturaCartao f){final r=context.watch<LocaleSettingsProvider>();final enabled=permission&&!loading&&!acting&&error==null;
  return Card(margin:const EdgeInsets.only(bottom:16),child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
   Text(f.nomeCartao,style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:8),Text(r.formatCurrency(f.total),style:Theme.of(context).textTheme.headlineMedium),
   Wrap(spacing:8,runSpacing:8,children:[Chip(label:Text(context.t(f.paga?'invoices.paid':f.total==0?'invoices.emptyInvoice':'invoices.open'))),Text('${context.t('invoices.invoiceDue')}: ${r.formatDate(f.vencimento)}')]),
   Text('${context.t('invoices.closingDate')}: ${r.formatDate(f.fechamento)}'),
   if(f.dataPagamento!=null)Text('${context.t('invoices.paymentDate')}: ${r.formatDate(f.dataPagamento!)}'),
   if(!f.paga&&f.compras.any((c)=>c.prevista))Text(context.t('invoices.recurring.paymentHint')),
   ExpansionTile(key:ValueKey('${f.id}-${f.versao}'),initiallyExpanded:widget.faturaId!=null,tilePadding:EdgeInsets.zero,title:Text('${context.t('invoices.purchases')} (${f.compras.length})'),children:[
    for(final c in f.compras)Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:Text(c.descricao,style:const TextStyle(fontWeight:FontWeight.w600))),if(enabled)IconButton(onPressed:()=>purchaseAction(f,c),tooltip:context.t('invoices.purchaseActions'),icon:const Icon(Icons.more_horiz))]),
     Text(r.formatCurrency(c.valor),style:Theme.of(context).textTheme.titleMedium),Text('${r.formatDate(c.dataCompra)} · ${c.categoria??context.t('invoices.noCategory')}'),
     if(c.parcelamentoId!=null)Text('${context.t('invoices.installments.part')} ${c.numeroParcela}/${c.quantidadeParcelas} · ${r.formatCurrency(c.valorTotalCompra??0)}'),
     if(c.serieRecorrenciaId!=null)Text('${context.t('invoices.recurring.monthly')} · ${context.t(c.prevista?'invoices.recurring.forecast':'invoices.recurring.recorded')} · ${context.t(c.recorrenciaAtiva?'space.active':'invoices.recurring.ended')}'),
    ])),const Divider(),Text(context.t('invoices.byCategory'),style:Theme.of(context).textTheme.titleSmall),
    for(final e in f.porCategoria.entries)ListTile(contentPadding:EdgeInsets.zero,title:Text(e.key.isEmpty?context.t('invoices.noCategory'):e.key),subtitle:Text(r.formatCurrency(e.value))),
   ]),
   if(!f.paga&&f.total>0&&permission)FilledButton.icon(onPressed:enabled&&!f.compras.any((c)=>c.prevista)?()=>pay(f):null,icon:const Icon(Icons.check),label:Text(context.t('invoices.pay'))),
  ])));
 }
 @override Widget build(BuildContext context)=>PopScope(canPop:!acting,child:CartaoMobilePage(title:context.t('invoices.title'),canPop:!acting,actions:[IconButton(onPressed:loading||acting?null:load,tooltip:context.t('cards.refresh'),icon:const Icon(Icons.refresh))],bodyBuilder:(context,scroll,topInset)=>SafeArea(top:false,child:RefreshIndicator(onRefresh:()async{if(!loading&&!acting)await load();},child:ListView(controller:scroll,physics:const AlwaysScrollableScrollPhysics(),padding:EdgeInsets.fromLTRB(16,topInset+12,16,24),children:[
  Text(context.t('space.${widget.espaco}')),const SizedBox(height:12),
  if(widget.faturaId==null&&cards.isNotEmpty)CartaoMobileField(label:'cards.title',value:cards.where((c)=>c.id==card).map((c)=>c.nome).firstOrNull??'',onTap:loading||acting?null:()async{final v=await escolherCartaoOpcao(context,'cards.title',{for(final c in cards)c.id:c.nome},card);if(v!=null&&mounted){setState((){card=v;invoices=[];});load();}}),
  if(loading)SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('invoices.title')),
  if(error!=null)CartaoMobileError(error!,retry:loading?null:load,stale:invoices.isNotEmpty),
  if(!loading&&error==null&&invoices.isEmpty)Text(context.t(cards.isEmpty?'invoices.noCards':'invoices.empty')),
  for(final f in invoices)invoice(f),
 ])))));
}

class PagarFaturaCartaoMobileScreen extends StatefulWidget {
 const PagarFaturaCartaoMobileScreen({super.key,required this.client,required this.fatura,this.configuracoes});
 final CartaoCreditoApiClient client;final FaturaCartao fatura;final ConfiguracaoFinanceiraService? configuracoes;
 @override State<PagarFaturaCartaoMobileScreen> createState()=>_PagamentoState();
}
class _PagamentoState extends State<PagarFaturaCartaoMobileScreen> {
 final id=gerarUuidV4();late final config=widget.configuracoes??ConfiguracaoFinanceiraService(widget.client.espaco);
 List<ConfiguracaoFinanceira> accounts=[];List<FormaPagamentoFatura> methods=[];
 String? account,method,error;late DateTime date=context.read<LocaleSettingsProvider>().calendarNow;bool loading=true,busy=false,conflict=false,loaded=false;
 PagarFaturaCartaoRequest? attempt;bool get locked=>busy||attempt!=null;
 @override void initState(){super.initState();load();}
 @override void dispose(){if(widget.configuracoes==null)config.dispose();super.dispose();}
 Future<void> load()async{
  setState((){loading=true;error=null;loaded=false;});
  try{final a=await config.listar('CONTAS').timeout(const Duration(seconds:20));final m=await widget.client.formasFatura();if(mounted)setState((){loaded=true;accounts=a.where((c)=>c.ativo&&c.tipo!='CAIXA').toList();methods=m;account=accounts.any((c)=>c.id==widget.fatura.contaPrevistaId)?widget.fatura.contaPrevistaId:null;});}
  catch(e){if(mounted)setState(()=>error=erroCartaoMobile(e));}finally{if(mounted)setState(()=>loading=false);}
 }
 Future<void> pay()async{
  if(busy)return;
  attempt??=PagarFaturaCartaoRequest(id:id,faturaId:widget.fatura.id,versao:widget.fatura.versao,valor:widget.fatura.total,contaFinanceiraId:account!,dataPagamento:date,formaPagamento:method!);
  setState((){busy=true;error=null;});
  try{final f=await widget.client.pagar(attempt!);if(mounted)Navigator.pop(context,f);}
  catch(e){if(mounted)setState((){error=erroCartaoMobile(e);if(rejeicaoCartaoDefinitiva(e)){attempt=null;conflict=e is CartaoCreditoApiException&&(e.statusCode==409||acessoCartaoNegado(e));}});}
  finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext context){final r=context.watch<LocaleSettingsProvider>();return PopScope(canPop:!busy,child:CartaoMobilePage(title:context.t('invoices.pay'),canPop:!busy,bodyBuilder:(context,scroll,topInset)=>SafeArea(top:false,child:ListView(controller:scroll,padding:EdgeInsets.fromLTRB(16,topInset+12,16,24),children:[
  Text(widget.fatura.nomeCartao,style:Theme.of(context).textTheme.titleLarge),Text(r.formatCurrency(widget.fatura.total),style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:16),Text(context.t('invoices.payHint')),const SizedBox(height:20),
  if(loading)SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('invoices.pay')),
  if(!loading)...[
   CartaoMobileField(label:'invoices.account',value:accounts.where((c)=>c.id==account).map((c)=>c.nome).firstOrNull??'',onTap:locked||conflict?null:()async{final v=await escolherCartaoOpcao(context,'invoices.account',{for(final a in accounts)a.id:a.nome},account);if(v!=null&&mounted)setState(()=>account=v);}),
   if(accounts.isEmpty)Text(context.t('invoices.noAccounts')),
   CartaoMobileField(label:'invoices.paymentMethod',value:methods.where((c)=>c.codigo==method).map((c)=>c.nome).firstOrNull??'',onTap:locked||conflict?null:()async{final v=await escolherCartaoOpcao(context,'invoices.paymentMethod',{for(final m in methods)m.codigo:m.nome},method);if(v!=null&&mounted)setState(()=>method=v);}),
   CartaoMobileField(label:'invoices.paymentDate',value:r.formatDate(date),icon:Icons.calendar_today_outlined,onTap:locked||conflict?null:()async{final d=await escolherDataCartao(context,'invoices.paymentDate',date,last:context.read<LocaleSettingsProvider>().calendarNow);if(d!=null&&mounted)setState(()=>date=d);}),
  ],
  if(error!=null)CartaoMobileError(error!,retry:locked||conflict?null:load),
  if(attempt!=null&&!busy)Text(context.t('invoices.uncertain')),const SizedBox(height:20),
  FilledButton(onPressed:!loaded||loading||busy||conflict||account==null||method==null||widget.fatura.paga||widget.fatura.total<=0||widget.fatura.compras.any((c)=>c.prevista)?null:pay,child:Text(context.t(busy?'invoices.saving':attempt!=null?'space.retry':'invoices.confirmPayment'))),
 ]))));}
}
