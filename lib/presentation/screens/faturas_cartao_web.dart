import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';
import 'package:sixpos/data/models/fatura_cartao_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/components/web/pagar_fatura_cartao_web.dart';
import 'package:sixpos/presentation/components/web/financeiro_configuracao_web_dialog.dart';

class FaturasCartaoWeb extends StatefulWidget {
 const FaturasCartaoWeb({super.key,required this.espaco,this.cartaoId,this.faturaId,this.client});
 final String espaco;
 final String? cartaoId,faturaId;
 final CartaoCreditoApiClient? client;
 @override State<FaturasCartaoWeb> createState()=>_FaturasCartaoWebState();
}
class _FaturasCartaoWebState extends State<FaturasCartaoWeb> {
 late final _client=widget.client??CartaoCreditoApiClient(espaco:widget.espaco);
 List<CartaoCredito> _cartoes=[];
 List<FaturaCartao> _faturas=[];
 String? _cartao,_erro;
 bool _loading=true,_canEdit=false,_acting=false;
 @override void initState(){super.initState();_cartao=widget.cartaoId;_load();}
 @override void dispose(){if(widget.client==null)_client.dispose();super.dispose();}
 Future<void> _load()async{
  setState((){_loading=true;_erro=null;_canEdit=false;});
  try{
   final cards=await _client.listar();
   List<FaturaCartao> items=[];
   if(widget.faturaId!=null){items=[await _client.fatura(widget.faturaId!)];_cartao=items.first.cartaoId;}
   else{
    _cartao??=cards.cartoes.isEmpty?null:cards.cartoes.first.id;
    if(_cartao!=null)items=await _client.faturas(_cartao!);
   }
   if(!mounted)return;
   setState((){_cartoes=cards.cartoes;_canEdit=cards.podeEditar;_faturas=items;});
  }catch(e){if(mounted)setState((){
   _erro=e is CartaoCreditoApiException?e.messageKey:'cards.error.server';
   if(e is CartaoCreditoApiException&&(e.statusCode==401||e.statusCode==403)){_cartoes=[];_faturas=[];}
  });}finally{if(mounted)setState(()=>_loading=false);}
 }
 Future<void> _pagar(FaturaCartao f)async{
  setState(()=>_acting=true);
  final result=await showDialog<FaturaCartao>(context:context,barrierDismissible:false,builder:(_)=>Dialog(
   child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:600),child:PagarFaturaCartaoWeb(client:_client,fatura:f))));
  if(!mounted)return;
  setState(()=>_acting=false);
  // Refresh also after a conflict or an uncertain command that the user closed.
  if(result!=null||!_loading)await _load();
 }
 Widget _fatura(FaturaCartao f){final r=context.watch<LocaleSettingsProvider>();final colors=Theme.of(context).colorScheme;
  return SixWebEntry(child:Card(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:BorderSide(color:colors.outlineVariant)),
   child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
    Wrap(alignment:WrapAlignment.spaceBetween,crossAxisAlignment:WrapCrossAlignment.center,spacing:20,runSpacing:12,children:[
     Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text('${context.t('invoices.invoiceDue')} ${r.formatDate(f.vencimento)}',style:Theme.of(context).textTheme.titleMedium),
      Text('${context.t('invoices.closingDate')}: ${r.formatDate(f.fechamento)}'),
     ]),
     Text(r.formatCurrency(f.total),style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w800)),
     Chip(avatar:Icon(f.paga?Icons.check_circle_outline:Icons.schedule,size:18),label:Text(context.t(f.paga?'invoices.paid':'invoices.open'))),
     if(!f.paga&&_canEdit&&_erro==null)FilledButton.icon(onPressed:_acting||_loading?null:()=>_pagar(f),
      icon:const Icon(Icons.account_balance_outlined),label:Text(context.t('invoices.pay'))),
    ]),
    if(f.dataPagamento!=null)Padding(padding:const EdgeInsets.only(top:8),child:Text('${context.t('invoices.paymentDate')}: ${r.formatDate(f.dataPagamento!)}')),
    const SizedBox(height:12),ExpansionTile(key:ValueKey('${f.id}-${f.versao}'),initiallyExpanded:widget.faturaId!=null,
     tilePadding:EdgeInsets.zero,title:Text('${context.t('invoices.purchases')} (${f.compras.length})'),
     children:[...f.compras.map((c)=>Padding(padding:const EdgeInsets.symmetric(vertical:10),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.descricao,style:const TextStyle(fontWeight:FontWeight.w600)),
       Text('${r.formatDate(c.dataCompra)} · ${c.categoria??context.t('invoices.noCategory')}',style:Theme.of(context).textTheme.bodySmall)])),
      const SizedBox(width:16),Flexible(child:Text(r.formatCurrency(c.valor),textAlign:TextAlign.end)),
     ]))),const Divider(),
     Align(alignment:Alignment.centerLeft,child:Text(context.t('invoices.byCategory'),style:const TextStyle(fontWeight:FontWeight.w700))),
     ...f.porCategoria.entries.map((e)=>Padding(padding:const EdgeInsets.symmetric(vertical:8),child:Row(children:[
      Expanded(child:Text(e.key.isEmpty?context.t('invoices.noCategory'):e.key)),const SizedBox(width:16),Flexible(child:Text(r.formatCurrency(e.value),textAlign:TextAlign.end)),
     ]))),
    ]),
   ]))));
 }
 @override Widget build(BuildContext context)=>Scaffold(body:SafeArea(child:ListView(padding:const EdgeInsets.all(24),children:[
  SixWebDashboardHeader(icon:Icons.credit_card_rounded,title:context.t('invoices.title'),
   subtitle:context.t('space.${widget.espaco}'),onBack:()=>Navigator.of(context).maybePop(),actions:[
    OutlinedButton.icon(onPressed:_loading||_acting?null:_load,icon:const Icon(Icons.refresh),label:Text(context.t('cards.refresh'))),
   ]),
  const SizedBox(height:20),Text(context.t('invoices.listHint')),
  if(widget.faturaId==null&&_cartoes.isNotEmpty)Padding(padding:const EdgeInsets.symmetric(vertical:20),child:DropdownButtonFormField<String>(
   key:ValueKey(_cartao),initialValue:_cartao,isExpanded:true,decoration:InputDecoration(labelText:context.t('cards.title')),
   items:_cartoes.map((c)=>DropdownMenuItem(value:c.id,child:Text('${c.nome}${c.ativo?'':' · ${context.t('space.inactive')}'}',overflow:TextOverflow.ellipsis))).toList(),
   onChanged:_loading||_acting?null:(v){setState((){_cartao=v;_faturas=[];});_load();})),
  if(_loading)SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('invoices.title')),
  if(_erro!=null)Padding(padding:const EdgeInsets.symmetric(vertical:16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
   Text(context.t(_erro!),style:TextStyle(color:Theme.of(context).colorScheme.error)),
   if(_faturas.isNotEmpty)Text(context.t('cards.stale')),
   TextButton(onPressed:_loading?null:_load,child:Text(context.t('space.retry'))),
  ])),
  if(!_loading&&_erro==null&&_cartoes.isEmpty)Text(context.t('invoices.noCards')),
  if(!_loading&&_erro==null&&_cartoes.isNotEmpty&&_faturas.isEmpty)Padding(padding:const EdgeInsets.all(24),child:Text(context.t('invoices.empty'))),
  if(!_loading)..._faturas.map(_fatura),
 ])));
}

Future<void> abrirFaturasCartaoWeb(BuildContext context,{required String espaco,String? cartaoId,String? faturaId}) =>
 showFinanceiroConfiguracaoWebDialog<void>(context:context,title:context.t('invoices.title'),
  child:FaturasCartaoWeb(espaco:espaco,cartaoId:cartaoId,faturaId:faturaId));
