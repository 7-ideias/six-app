import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/core/utils/uuid_v4.dart';
import 'package:sixpos/data/models/cartao_credito_model.dart';
import 'package:sixpos/data/models/fatura_cartao_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';

class CompraCartaoWebEditor extends StatefulWidget {
  const CompraCartaoWebEditor({super.key,required this.client,this.cartoes,this.cartaoInicial,this.configuracoes,this.embedded=false,this.descricaoController,this.valorController,this.categoriaController,this.onBusy,this.onLocked,this.onError,this.onSaved,this.compraInicial});
  final CartaoCreditoApiClient client;
  final List<CartaoCredito>? cartoes;
  final bool embedded;
  final CompraCartao? compraInicial;
  final TextEditingController? descricaoController,valorController,categoriaController;
  final ValueChanged<bool>? onBusy,onLocked;
  final ValueChanged<String?>? onError;
  final ValueChanged<FaturaCartao>? onSaved;
  final String? cartaoInicial;
  final ConfiguracaoFinanceiraService? configuracoes;
  @override State<CompraCartaoWebEditor> createState()=>CompraCartaoWebEditorState();
}
class CompraCartaoWebEditorState extends State<CompraCartaoWebEditor> {
  final _form=GlobalKey<FormState>();
  late final _descricao=widget.descricaoController??TextEditingController();
  late final _valor=widget.valorController??TextEditingController();
  List<CartaoCredito> _cartoes=[];
  bool _permitido=false;
  final _id=gerarUuidV4();
  late final _config=widget.configuracoes??ConfiguracaoFinanceiraService(widget.client.espaco);
  String? _cartao,_categoria,_erro;
  List<ConfiguracaoFinanceira> _categorias=[];
  DateTime _data=DateTime.now();
  PreviaFaturaCartao? _previa;
  CompraCartaoRequest? _tentativa;
  bool _carregando=true,_prevendo=false,_salvando=false;
  int _seq=0;
  bool _preenchido=false;
  bool get _bloqueado=>_salvando||_tentativa!=null;
  @override void initState(){super.initState();_cartao=widget.cartaoInicial;
    if(widget.cartoes!=null&&!widget.cartoes!.any((c)=>c.id==_cartao&&c.ativo))_cartao=null;
    final compra=widget.compraInicial;if(compra!=null){_descricao.text=compra.descricao;_data=compra.dataCompra;_categoria=compra.categoriaId;}
    _carregar();}
  @override void didChangeDependencies(){super.didChangeDependencies();
    if(!_preenchido&&widget.compraInicial!=null){_preenchido=true;_valor.text=widget.compraInicial!.valor.toStringAsFixed(2).replaceAll('.',context.read<LocaleSettingsProvider>().decimalSeparator);}
  }
  @override void dispose(){if(widget.descricaoController==null)_descricao.dispose();if(widget.valorController==null)_valor.dispose();if(widget.configuracoes==null)_config.dispose();super.dispose();}
  Future<void> _carregar() async {
    setState((){_carregando=true;_erro=null;_previa=null;_permitido=false;});
    try {
      if(widget.cartoes==null){final cards=await widget.client.listar();if(!mounted)return;_cartoes=cards.cartoes;_permitido=cards.podeEditar;}
      else {_cartoes=widget.cartoes!;_permitido=true;}
      final cats=await _config.listar('CATEGORIAS').timeout(const Duration(seconds:20));
      if(!mounted)return;
      setState(()=>_categorias=cats.where((c)=>c.ativo&&c.tipo!='RECEITA').toList());
      syncCategory();
      await _prever();
    }catch(_){if(mounted)setState(()=>_erro='cards.error.connection');}
    finally{if(mounted)setState(()=>_carregando=false);}
  }
  Future<void> _prever() async {
    final seq=++_seq;
    setState((){_previa=null;_prevendo=_cartao!=null;_erro=null;});
    if(_cartao==null)return;
    try{final result=await widget.client.previa(_cartao!,_data);
      if(mounted&&seq==_seq)setState(()=>_previa=result);
    }catch(e){if(mounted&&seq==_seq)setState(()=>_erro=e is CartaoCreditoApiException?e.messageKey:'cards.error.server');}
    finally{if(mounted&&seq==_seq)setState(()=>_prevendo=false);}
  }
  void syncCategory(){
    if(widget.categoriaController==null)return;
    final name=widget.categoriaController!.text.trim();
    _categoria=null;
    for(final c in _categorias){if(c.nome==name){_categoria=c.id;break;}}
  }
  bool validate(){
    syncCategory();
    final valid=_form.currentState?.validate()??false;
    return valid&&!_carregando&&!_prevendo&&_permitido&&_previa!=null&&!_previa!.paga;
  }
  Widget review(){
    final r=context.read<LocaleSettingsProvider>();
    return Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text(_descricao.text,style:Theme.of(context).textTheme.titleLarge),
      const SizedBox(height:12),Text(r.formatCurrency(_valorNumerico()??0)),
      Text(_cartoes.where((c)=>c.id==_cartao).map((c)=>c.nome).join()),
      Text('${context.t('invoices.purchaseDate')}: ${r.formatDate(_data)}'),
      if(_previa!=null)Text('${context.t('invoices.invoiceDue')}: ${r.formatDate(_previa!.vencimento)}'),
      Text(widget.categoriaController?.text??''),
      const SizedBox(height:16),Text(context.t('invoices.noRecurrence')),
    ]);
  }
  double? _valorNumerico(){
    final r=context.read<LocaleSettingsProvider>();
    final raw=_valor.text.trim();
    final sep=RegExp.escape(r.decimalSeparator);
    if(!RegExp('^[0-9]+($sep[0-9]{1,2})?\$').hasMatch(raw))return null;
    return double.tryParse(raw.replaceAll(r.decimalSeparator,'.'));
  }
  Future<void> submit() async {
    if(_salvando)return;
    if(_tentativa==null){
      if(!validate())return;
      _tentativa=CompraCartaoRequest(id:_id,cartaoId:_cartao!,descricao:_descricao.text,
        dataCompra:_data,valor:_valorNumerico()!,previa:_previa!,categoriaId:_categoria);
    }
    setState((){_salvando=true;_erro=null;});
    widget.onBusy?.call(true);widget.onLocked?.call(true);widget.onError?.call(null);
    try{final compra=widget.compraInicial;final f=compra==null?await widget.client.comprar(_tentativa!):await widget.client.editarCompra(compra.id,compra.versao,_tentativa!);if(mounted){if(widget.onSaved!=null){widget.onSaved!(f);}else{Navigator.of(context).pop(f);}}}
    catch(e){if(mounted)setState((){
      _erro=e is CartaoCreditoApiException?e.messageKey:'cards.error.server';
      if(e is CartaoCreditoApiException&&e.statusCode!=null&&e.statusCode!>=400&&e.statusCode!<500){
        _tentativa=null;
        if(e.statusCode==409){_previa=null;_erro=widget.compraInicial==null?'invoices.conflict':'invoices.editConflict';}
      }
    });}finally{if(mounted){setState(()=>_salvando=false);widget.onBusy?.call(false);widget.onLocked?.call(_tentativa!=null);widget.onError?.call(_erro==null?null:'${context.t(_erro!)}${_tentativa==null?'':' ${context.t('invoices.uncertain')}'}');}}
  }
  @override Widget build(BuildContext context){
    final r=context.watch<LocaleSettingsProvider>();
    return PopScope(canPop:!_salvando,child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Form(key:_form,child:Column(
      mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      if(!widget.embedded)Text(context.t(widget.compraInicial==null?'invoices.newPurchase':'invoices.editPurchase'),style:Theme.of(context).textTheme.titleLarge),
      const SizedBox(height:8),Text(context.t('invoices.purchaseHint')),
      const SizedBox(height:20),
      if(!_carregando&&!_permitido)Text(context.t('cards.error.permission')),
      if(!_carregando&&_cartoes.where((c)=>c.ativo).isEmpty)Text(context.t('invoices.noCards')),
      if(_carregando) SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('invoices.title')) else ...[
        DropdownButtonFormField<String>(initialValue:_cartao,isExpanded:true,
          decoration:InputDecoration(labelText:context.t('cards.title')),
          items:_cartoes.where((c)=>c.ativo).map((c)=>DropdownMenuItem(value:c.id,child:Text(c.nome,overflow:TextOverflow.ellipsis))).toList(),
          onChanged:_bloqueado?null:(v){setState(()=>_cartao=v);_prever();},
          validator:(v)=>v==null?context.t('invoices.required'):null),
        const SizedBox(height:16),TextFormField(controller:_descricao,enabled:!_bloqueado,maxLength:255,
          decoration:InputDecoration(labelText:context.t('invoices.description')),
          validator:(v)=>v==null||v.trim().isEmpty?context.t('invoices.required'):null),
        const SizedBox(height:8),TextFormField(controller:_valor,enabled:!_bloqueado,
          keyboardType:const TextInputType.numberWithOptions(decimal:true),
          decoration:InputDecoration(labelText:context.t('invoices.value'),helperText:context.t('invoices.valueHint')),
          validator:(_){final v=_valorNumerico();return v==null||v<=0||!v.isFinite||v>=1e13?context.t('invoices.invalidValue'):null;}),
        const SizedBox(height:16),OutlinedButton.icon(onPressed:_bloqueado?null:()async{
          final d=await showDatePicker(context:context,initialDate:_data,firstDate:DateTime(2000),lastDate:DateTime.now());
          if(d!=null&&mounted){setState(()=>_data=d);_prever();}},
          icon:const Icon(Icons.calendar_today_outlined),label:Text('${context.t('invoices.purchaseDate')}: ${r.formatDate(_data)}')),
        const SizedBox(height:16),DropdownButtonFormField<String>(key:ValueKey(_categoria),initialValue:_categoria,isExpanded:true,
          decoration:InputDecoration(labelText:context.t('invoices.category')),
          validator:(_)=>widget.categoriaController!=null&&widget.categoriaController!.text.trim().isNotEmpty&&_categoria==null?context.t('invoices.required'):null,
          items:[DropdownMenuItem<String>(value:null,child:Text(context.t('space.none'))),
            if(_categoria!=null&&!_categorias.any((c)=>c.id==_categoria))DropdownMenuItem(value:_categoria,child:Text(widget.compraInicial?.categoria??context.t('invoices.category'))),
            ..._categorias.map((c)=>DropdownMenuItem(value:c.id,child:Text(c.nome,overflow:TextOverflow.ellipsis)))],
          onChanged:_bloqueado?null:(v)=>setState((){_categoria=v;widget.categoriaController?.text=v==null?'':_categorias.firstWhere((c)=>c.id==v).nome;})),
        const SizedBox(height:16),
        if(_prevendo)const LinearProgressIndicator(),
        if(_previa!=null)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('${context.t('invoices.invoiceDue')}: ${r.formatDate(_previa!.vencimento)}',style:const TextStyle(fontWeight:FontWeight.w700)),
          Text('${context.t('invoices.closingDate')}: ${r.formatDate(_previa!.fechamento)}'),
          if(_previa!.paga)Text(context.t('invoices.alreadyPaid'),style:TextStyle(color:Theme.of(context).colorScheme.error)),
        ]))),
        Text(context.t('invoices.cycleRule'),style:Theme.of(context).textTheme.bodySmall),
      ],
      if(_erro!=null)...[const SizedBox(height:12),Text(context.t(_erro!),style:TextStyle(color:Theme.of(context).colorScheme.error)),
        if(!_bloqueado)TextButton(onPressed:_carregar,child:Text(context.t('space.retry')))],
      if(_tentativa!=null&&!_salvando)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(context.t('invoices.uncertain'))),
      if(!widget.embedded)...[const SizedBox(height:24),Wrap(alignment:WrapAlignment.end,spacing:12,runSpacing:8,children:[
        TextButton(onPressed:_salvando?null:()=>Navigator.of(context).pop(),child:Text(context.t('common.close'))),
        FilledButton(onPressed:_salvando||_carregando||_prevendo||(_tentativa==null&&(_previa==null||_previa!.paga))?null:submit,
          child:Text(context.t(_salvando?'invoices.saving':_tentativa!=null?'space.retry':widget.compraInicial==null?'invoices.savePurchase':'invoices.saveChanges'))),
      ])]
    ]))));
  }
}
