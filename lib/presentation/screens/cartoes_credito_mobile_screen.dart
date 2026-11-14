import 'package:flutter/material.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/core/utils/uuid_v4.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/presentation/components/mobile/cartoes_mobile_widgets.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'faturas_cartao_mobile_screen.dart';

class CartoesCreditoMobileScreen extends StatefulWidget {
  const CartoesCreditoMobileScreen({super.key,required this.espaco,this.client});
  final String espaco; final CartaoCreditoApiClient? client;
  @override State<CartoesCreditoMobileScreen> createState()=>_CartoesState();
}
class _CartoesState extends State<CartoesCreditoMobileScreen> {
  late final api=widget.client??CartaoCreditoApiClient(espaco:widget.espaco);
  CartoesCreditoResponse? data; String? error; bool loading=true;
  @override void initState(){super.initState();load();}
  @override void dispose(){if(widget.client==null)api.dispose();super.dispose();}
  Future<void> load()async{
    setState((){loading=true;error=null;});
    try {final r=await api.listar();if(mounted)setState(()=>data=r);}
    catch(e){if(mounted)setState((){error=erroCartaoMobile(e);if(acessoCartaoNegado(e))data=null;});}
    finally {if(mounted)setState(()=>loading=false);}
  }
  Future<void> edit([CartaoCredito? card])async{
    await Navigator.push(context,MaterialPageRoute<bool>(builder:(_)=>CartaoCreditoMobileEditor(client:api,card:card)));
    if(mounted)await load();
  }
  @override Widget build(BuildContext context)=>CartaoMobilePage(
    title:context.t('cards.title'),actions:[IconButton(onPressed:loading?null:load,tooltip:context.t('cards.refresh'),icon:const Icon(Icons.refresh))],
    floatingActionButton:!loading&&error==null&&data?.podeEditar==true?FloatingActionButton.extended(onPressed:()=>edit(),icon:const Icon(Icons.add),label:Text(context.t('cards.new'))):null,
    bodyBuilder:(context,scroll,topInset)=>RefreshIndicator(onRefresh:load,child:ListView(controller:scroll,padding:EdgeInsets.fromLTRB(16,topInset+12,16,100),physics:const AlwaysScrollableScrollPhysics(),children:[
      Text(context.t('space.${widget.espaco}'),style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:12),
      if(loading)SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('cards.title')),
      if(error!=null)CartaoMobileError(error!,retry:loading?null:load,stale:data!=null),
      if(!loading&&error==null&&data!=null)...[
        if(!data!.podeEditar)Text(context.t('cards.readOnly')),
        if(data!.cartoes.isEmpty)Padding(padding:const EdgeInsets.all(24),child:Text(context.t('cards.empty'))),
      ],
      for(final c in data?.cartoes??<CartaoCredito>[])Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
        Row(children:[Icon(Icons.credit_card,color:context.sixMobileColors.accent),const SizedBox(width:12),Expanded(child:Text(c.nome,style:Theme.of(context).textTheme.titleMedium)),if(data!.podeEditar)IconButton(onPressed:loading||error!=null?null:()=>edit(c),tooltip:context.t('cards.edit'),icon:const Icon(Icons.edit_outlined))]),
        Text('${c.instituicao} · ${context.t(c.ativo?'space.active':'space.inactive')}'),const SizedBox(height:12),
        Text('${context.t('cards.closing')}: ${c.diaFechamento} · ${context.t('cards.due')}: ${c.diaVencimento}'),
        if(c.contaPrevistaNome!=null)Text('${context.t('cards.account')}: ${c.contaPrevistaNome}'),
        TextButton.icon(onPressed:loading||error!=null?null:()async{await Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>FaturasCartaoMobileScreen(espaco:widget.espaco,cartaoId:c.id)));if(mounted)load();},icon:const Icon(Icons.receipt_long_outlined),label:Text(context.t('invoices.title'))),
      ]))),
    ])),
  );
}

class CartaoCreditoMobileEditor extends StatefulWidget {
  const CartaoCreditoMobileEditor({super.key,required this.client,this.card,this.configuracoes,this.onSaved});
  final ValueChanged<CartaoCredito>? onSaved;
  final CartaoCreditoApiClient client; final CartaoCredito? card; final ConfiguracaoFinanceiraService? configuracoes;
  @override State<CartaoCreditoMobileEditor> createState()=>_EditorState();
}
class _EditorState extends State<CartaoCreditoMobileEditor> {
  final form=GlobalKey<FormState>(); final id=gerarUuidV4();
  late final name=TextEditingController(text:widget.card?.nome??'');
  late final bank=TextEditingController(text:widget.card?.instituicao??'');
  late final closing=TextEditingController(text:widget.card?.diaFechamento.toString()??'');
  late final due=TextEditingController(text:widget.card?.diaVencimento.toString()??'');
  late final config=widget.configuracoes??ConfiguracaoFinanceiraService(widget.client.espaco);
  late bool active=widget.card?.ativo??true;
  late String? account=widget.card?.contaPrevistaId;
  List<ConfiguracaoFinanceira> accounts=[]; bool loading=true,saving=false,conflict=false;String? error;
  CartaoCreditoRequest? attempt;
  bool get locked=>saving||attempt!=null;
  @override void initState(){super.initState();load();}
  @override void dispose(){name.dispose();bank.dispose();closing.dispose();due.dispose();if(widget.configuracoes==null)config.dispose();super.dispose();}
  Future<void> load()async{
    setState((){loading=true;error=null;});
    try{final a=await config.listar('CONTAS').timeout(const Duration(seconds:20));if(mounted)setState(()=>accounts=a.where((c)=>c.ativo&&c.tipo!='CAIXA').toList());}
    catch(e){if(mounted)setState(()=>error='cards.accountsError');}
    finally{if(mounted)setState(()=>loading=false);}
  }
  Future<void> save()async{
    if(saving||conflict)return;
    if(attempt==null){if(!form.currentState!.validate())return;
      attempt=CartaoCreditoRequest(id:widget.card?.id??id,nome:name.text,instituicao:bank.text,diaFechamento:int.parse(closing.text),diaVencimento:int.parse(due.text),ativo:active,contaPrevistaId:account,versao:widget.card?.versao);}
    setState((){saving=true;error=null;});
    try{final saved=await widget.client.salvar(attempt!);if(mounted){widget.onSaved?.call(saved);Navigator.pop(context,true);}}
    catch(e){if(mounted)setState((){error=erroCartaoMobile(e);if(rejeicaoCartaoDefinitiva(e)){attempt=null;conflict=e is CartaoCreditoApiException&&(e.statusCode==409||acessoCartaoNegado(e));}});}
    finally{if(mounted)setState(()=>saving=false);}
  }
  Widget field(TextEditingController c,String label,{bool day=false})=>Padding(padding:const EdgeInsets.only(bottom:16),child:TextFormField(controller:c,enabled:!locked&&!conflict,decoration:InputDecoration(labelText:context.t(label)),keyboardType:day?TextInputType.number:TextInputType.text,maxLength:day?2:120,validator:(v){if(day){final n=int.tryParse(v??'');return n==null||n<1||n>31?context.t('cards.dayValidation'):null;}return v==null||v.trim().isEmpty?context.t('invoices.required'):null;}));
  @override Widget build(BuildContext context)=>PopScope(canPop:!saving,child:CartaoMobilePage(title:context.t(widget.card==null?'cards.new':'cards.edit'),canPop:!saving,bodyBuilder:(context,scroll,topInset)=>SafeArea(top:false,child:Form(key:form,child:ListView(controller:scroll,padding:EdgeInsets.fromLTRB(16,topInset+12,16,24),children:[
    field(name,'space.name'),field(bank,'cards.institution'),field(closing,'cards.closing',day:true),field(due,'cards.due',day:true),Text(context.t('cards.daysHint')),const SizedBox(height:16),
    if(loading)SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('cards.account')),
    CartaoMobileField(label:'cards.account',value:accounts.where((a)=>a.id==account).map((a)=>a.nome).firstOrNull??widget.card?.contaPrevistaNome??'',onTap:locked||loading||error!=null||conflict?null:()async{
      final v=await escolherCartaoOpcao(context,'cards.account',{'':context.t('space.none'),for(final a in accounts)a.id:a.nome},account);if(v!=null&&mounted)setState(()=>account=v.isEmpty?null:v);
    }),Text(context.t('cards.accountHint')),
    SwitchListTile(contentPadding:EdgeInsets.zero,title:Text(context.t('space.active')),subtitle:Text(context.t('cards.activeHint')),value:active,onChanged:locked||conflict?null:(v)=>setState(()=>active=v)),
    if(error!=null)CartaoMobileError(error!,retry:!locked&&!conflict?load:null),
    if(attempt!=null&&!saving)Text(context.t('cards.retrySaveHint')),const SizedBox(height:20),
    FilledButton(onPressed:saving||loading||conflict||error=='cards.accountsError'?null:save,child:Text(context.t(saving?'invoices.saving':attempt!=null?'space.retry':'space.save'))),
  ])))));
}
