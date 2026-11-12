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
import 'cartoes_credito_mobile_screen.dart';

/// Mobile purchase route: bottom-sheet selectors, stacked form and review.
class CompraCartaoMobileScreen extends StatefulWidget {
  const CompraCartaoMobileScreen({super.key,required this.espaco,this.client,this.compra,this.fatura,this.configuracoes});
  final String espaco;final CartaoCreditoApiClient? client;final CompraCartao? compra;final FaturaCartao? fatura;final ConfiguracaoFinanceiraService? configuracoes;
  @override State<CompraCartaoMobileScreen> createState()=>_CompraState();
}
class _CompraState extends State<CompraCartaoMobileScreen> {
  late final api=widget.client??CartaoCreditoApiClient(espaco:widget.espaco);
  late final config=widget.configuracoes??ConfiguracaoFinanceiraService(widget.espaco);
  final form=GlobalKey<FormState>();final id=gerarUuidV4();
  late final description=TextEditingController(text:widget.compra?.descricao??'');
  final amount=TextEditingController(),count=TextEditingController(text:'2');
  late DateTime date=widget.compra?.dataCompra??DateTime.now();late DateTime? end=widget.compra?.recorrenciaFim;
  late String? card=widget.fatura?.cartaoId,category=widget.compra?.categoriaId;
  List<CartaoCredito> cards=[];List<ConfiguracaoFinanceira> categories=[];
  String mode='once';bool nextOccurrences=false,loading=true,busy=false,permission=false,review=false,conflict=false,seeded=false;
  String? error;PreviaFaturaCartao? preview;List<ParcelaCartao>? plan;
  CompraCartaoRequest? attempt;
  bool get installment=>widget.compra?.parcelamentoId!=null;
  bool get recurring=>widget.compra?.serieRecorrenciaId!=null;
  bool get series=>widget.compra==null?mode=='monthly':recurring&&nextOccurrences;
  bool get locked=>busy||attempt!=null;
  @override void initState(){super.initState();load();}
  @override void didChangeDependencies(){super.didChangeDependencies();if(!seeded){seeded=true;amount.text=widget.compra==null?'':widget.compra!.valor.toStringAsFixed(2).replaceAll('.',context.read<LocaleSettingsProvider>().decimalSeparator);}}
  @override void dispose(){description.dispose();amount.dispose();count.dispose();if(widget.client==null)api.dispose();if(widget.configuracoes==null)config.dispose();super.dispose();}
  Future<void> load()async{
    setState((){loading=true;error=null;permission=false;});
    try{final result=await api.listar();final cats=await config.listar('CATEGORIAS').timeout(const Duration(seconds:20));
      if(mounted)setState((){cards=result.cartoes;permission=result.podeEditar;categories=cats.where((c)=>c.ativo&&c.tipo!='RECEITA').toList();});}
    catch(e){if(mounted)setState(()=>error=erroCartaoMobile(e));}
    finally{if(mounted)setState(()=>loading=false);}
  }
  double? value(){final sep=context.read<LocaleSettingsProvider>().decimalSeparator;final raw=amount.text.trim();if(!RegExp('^[0-9]+(${RegExp.escape(sep)}[0-9]{1,2})?\$').hasMatch(raw))return null;return double.tryParse(raw.replaceAll(sep,'.'));}
  Future<void> prepare()async{
    if(locked||!permission||!form.currentState!.validate())return;
    if(card==null||!cards.any((c)=>c.id==card&&(c.ativo||installment))){setState(()=>error='invoices.required');return;}
    if(series&&end!=null&&end!.isBefore(DateUtils.dateOnly(date))){setState(()=>error='invoices.recurring.invalidEnd');return;}
    setState((){busy=true;error=null;plan=null;preview=null;});
    try{
      final p=installment?PreviaFaturaCartao.fromJson({'fechamento':dataCartaoIso(widget.fatura!.fechamento),'vencimento':dataCartaoIso(widget.fatura!.vencimento),'versaoCartao':cards.firstWhere((c)=>c.id==card).versao,'paga':widget.fatura!.paga})
        :await (mode=='monthly'||recurring?api.previaRecorrencia(card!,date):api.previa(card!,date));
      if(!mounted)return;
      if(p.paga){setState(()=>error='invoices.alreadyPaid');return;}
      preview=p;
      if(mode=='installments'&&widget.compra==null){
        final n=int.parse(count.text);if((value()!*100).round()<n){setState(()=>error='invoices.installments.invalid');return;}
        final list=await api.previaParcelamento(request(),n);if(!mounted)return;
        if(list.any((p)=>p.paga)){setState(()=>error='invoices.alreadyPaid');return;}plan=list;
      }
      setState(()=>review=true);
    }catch(e){if(mounted)setState(()=>error=erroCartaoMobile(e));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  CompraCartaoRequest request()=>CompraCartaoRequest(id:id,cartaoId:card!,descricao:description.text,dataCompra:date,valor:value()!,previa:preview!,categoriaId:category);
  Future<void> save()async{
    if(busy||conflict||!permission)return;
    attempt??=request();setState((){busy=true;error=null;});
    try{final c=widget.compra;final FaturaCartao result;
      if(c!=null){result=nextOccurrences?await api.editarProximas(c.id,c.versao,attempt!,end):await api.editarCompra(c.id,c.versao,attempt!);}
      else if(mode=='monthly'){result=await api.criarRecorrencia(attempt!,end);}
      else if(mode=='installments'){result=await api.parcelar(attempt!,int.parse(count.text));}
      else {result=await api.comprar(attempt!);}
      if(mounted)Navigator.pop(context,result);
    }catch(e){if(mounted)setState((){error=erroCartaoMobile(e);if(rejeicaoCartaoDefinitiva(e)){attempt=null;conflict=e is CartaoCreditoApiException&&(e.statusCode==409||acessoCartaoNegado(e));if(!conflict)review=false;}});}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> pick(String label,Map<String,String> options,String? selected,ValueChanged<String> change)async{
    final v=await escolherCartaoOpcao(context,label,options,selected);if(v!=null&&mounted)setState(()=>change(v));
  }
  Widget textField(TextEditingController controller,String label,{bool number=false,bool enabled=true})=>Padding(padding:const EdgeInsets.only(bottom:16),child:TextFormField(controller:controller,enabled:enabled&&!locked,
    decoration:InputDecoration(labelText:context.t(label)),keyboardType:number?const TextInputType.numberWithOptions(decimal:true):TextInputType.text,
    maxLength:number?16:255,validator:(v){if(controller==amount){final n=value();return n==null||!n.isFinite||n<=0||n>=1e13?context.t('invoices.invalidValue'):null;}
      if(controller==count){final n=int.tryParse(v??'');return n==null||n<2||n>48?context.t('invoices.installments.invalid'):null;}
      return v==null||v.trim().isEmpty?context.t('invoices.required'):null;}));
  @override Widget build(BuildContext context){final r=context.watch<LocaleSettingsProvider>();final selected=cards.where((c)=>c.id==card).firstOrNull;
    return PopScope(canPop:!busy,child:CartaoMobilePage(title:context.t(widget.compra==null?'invoices.newPurchase':'invoices.editPurchase'),canPop:!busy,
      bodyBuilder:(context,scroll,topInset)=>SafeArea(top:false,child:ListView(controller:scroll,padding:EdgeInsets.fromLTRB(16,topInset+12,16,24),children:[
        Text(context.t('space.${widget.espaco}')),const SizedBox(height:12),
        if(loading)SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('cards.title')),
        if(error!=null)CartaoMobileError(error!,retry:!locked&&!conflict&&!review?load:null),
        if(!loading&&!permission&&error==null)Text(context.t('cards.readOnly')),
        if(!loading&&permission&&cards.where((c)=>c.ativo).isEmpty&&widget.compra==null)...[
          Text(context.t('invoices.noCards')),TextButton.icon(onPressed:()async{await Navigator.push(context,MaterialPageRoute<bool>(builder:(_)=>CartaoCreditoMobileEditor(client:api)));if(mounted)load();},icon:const Icon(Icons.add),label:Text(context.t('cards.new'))),
        ],
        if(!loading&&!review)Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
          CartaoMobileField(label:'cards.title',value:selected?.nome??'',onTap:locked||installment?null:()=>pick('cards.title',{for(final c in cards.where((c)=>c.ativo))c.id:c.nome},card,(v)=>card=v)),
          if(widget.compra==null)CartaoMobileField(label:'mobile.cards.purchaseType',value:context.t(mode=='installments'?'invoices.installments.title':'invoices.recurring.$mode'),onTap:locked?null:()=>pick('mobile.cards.purchaseType',{'once':context.t('invoices.recurring.once'),'monthly':context.t('invoices.recurring.monthly'),'installments':context.t('invoices.installments.title')},mode,(v){mode=v;if(v!='monthly'&&date.isAfter(DateTime.now()))date=DateTime.now();})),
          if(recurring&&widget.compra!.recorrenciaAtiva)CartaoMobileField(label:'invoices.recurring.editScope',value:context.t(nextOccurrences?'invoices.recurring.thisAndNext':'invoices.recurring.onlyThis'),onTap:locked?null:()=>pick('invoices.recurring.editScope',{'this':context.t('invoices.recurring.onlyThis'),'next':context.t('invoices.recurring.thisAndNext')},nextOccurrences?'next':'this',(v)=>nextOccurrences=v=='next')),
          textField(description,'invoices.description'),textField(amount,mode=='installments'?'invoices.installments.total':'invoices.value',number:true,enabled:!installment),
          if(mode=='installments'&&widget.compra==null)textField(count,'invoices.installments.count',number:true),
          if(installment)Text(context.t('invoices.installments.editHint')),
          CartaoMobileField(label:'invoices.purchaseDate',value:r.formatDate(date),icon:Icons.calendar_today_outlined,onTap:locked||installment?null:()async{final d=await escolherDataCartao(context,'invoices.purchaseDate',date,last:mode=='monthly'||recurring?DateTime(DateTime.now().year+1,12,31):DateTime.now());if(d!=null&&mounted)setState(()=>date=d);}),
          if(series)...[
            CartaoMobileField(label:'invoices.recurring.until',value:end==null?context.t('invoices.recurring.noEnd'):r.formatDate(end!),icon:Icons.calendar_today_outlined,onTap:locked?null:()async{final d=await escolherDataCartao(context,'invoices.recurring.until',end??date,first:DateUtils.dateOnly(date));if(d!=null&&mounted)setState(()=>end=d);}),
            if(end!=null)TextButton(onPressed:locked?null:()=>setState(()=>end=null),child:Text(context.t('invoices.recurring.removeEnd'))),
          ],
          CartaoMobileField(label:'invoices.category',value:categories.where((c)=>c.id==category).map((c)=>c.nome).firstOrNull??widget.compra?.categoria??'',onTap:locked?null:()=>pick('invoices.category',{'':context.t('invoices.noCategory'),for(final c in categories)c.id:c.nome},category,(v)=>category=v.isEmpty?null:v)),
          const SizedBox(height:20),FilledButton(onPressed:locked||!permission||conflict?null:prepare,child:Text(context.t(busy?'invoices.saving':'mobile.cards.review'))),
        ])),
        if(review)...[
          Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
            Text(description.text,style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:12),Text(r.formatCurrency(value()!),style:Theme.of(context).textTheme.headlineSmall),Text(selected?.nome??''),
            Text('${context.t('invoices.purchaseDate')}: ${r.formatDate(date)}'),Text('${context.t('invoices.invoiceDue')}: ${r.formatDate(preview!.vencimento)}'),
            Text(context.t(mode=='installments'?'invoices.installments.hint':series?'invoices.recurring.review':'invoices.noRecurrence')),
            if(series)Text(end==null?context.t('invoices.recurring.noEnd'):r.formatDate(end!)),
            for(final p in plan??<ParcelaCartao>[])Padding(padding:const EdgeInsets.only(top:8),child:Text('${p.numero}/${plan!.length} · ${r.formatDate(p.vencimento)} · ${r.formatCurrency(p.valor)}')),
          ]))),
          if(attempt!=null&&!busy)Text(context.t('invoices.uncertain')),
          const SizedBox(height:20),FilledButton(onPressed:busy||conflict?null:save,child:Text(context.t(busy?'invoices.saving':attempt!=null?'space.retry':widget.compra==null?'invoices.savePurchase':'invoices.saveChanges'))),
          TextButton(onPressed:locked||conflict?null:()=>setState(()=>review=false),child:Text(context.t('agenda.journey.back'))),
        ],
      ])),
    ));
  }
}
