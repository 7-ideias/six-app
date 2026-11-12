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
  const CompraCartaoWebEditor({super.key,required this.client,required this.cartoes,this.cartaoInicial,this.configuracoes});
  final CartaoCreditoApiClient client;
  final List<CartaoCredito> cartoes;
  final String? cartaoInicial;
  final ConfiguracaoFinanceiraService? configuracoes;
  @override State<CompraCartaoWebEditor> createState()=>_CompraCartaoWebEditorState();
}
class _CompraCartaoWebEditorState extends State<CompraCartaoWebEditor> {
  final _form=GlobalKey<FormState>();
  final _descricao=TextEditingController(),_valor=TextEditingController();
  final _id=gerarUuidV4();
  late final _config=widget.configuracoes??ConfiguracaoFinanceiraService(widget.client.espaco);
  String? _cartao,_categoria,_erro;
  List<ConfiguracaoFinanceira> _categorias=[];
  DateTime _data=DateTime.now();
  PreviaFaturaCartao? _previa;
  CompraCartaoRequest? _tentativa;
  bool _carregando=true,_prevendo=false,_salvando=false;
  int _seq=0;
  bool get _bloqueado=>_salvando||_tentativa!=null;
  @override void initState(){super.initState();_cartao=widget.cartaoInicial;_carregar();}
  @override void dispose(){_descricao.dispose();_valor.dispose();if(widget.configuracoes==null)_config.dispose();super.dispose();}
  Future<void> _carregar() async {
    setState((){_carregando=true;_erro=null;});
    try { final cats=await _config.listar('CATEGORIAS').timeout(const Duration(seconds:20));
      if(!mounted)return;
      setState(()=>_categorias=cats.where((c)=>c.ativo&&c.tipo!='RECEITA').toList());
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
  double? _valorNumerico(){
    final r=context.read<LocaleSettingsProvider>();
    final raw=_valor.text.trim();
    final sep=RegExp.escape(r.decimalSeparator);
    if(!RegExp('^[0-9]+($sep[0-9]{1,2})?\$').hasMatch(raw))return null;
    return double.tryParse(raw.replaceAll(r.decimalSeparator,'.'));
  }
  Future<void> _salvar() async {
    if(_tentativa==null){
      if(!_form.currentState!.validate()||_previa==null||_previa!.paga)return;
      _tentativa=CompraCartaoRequest(id:_id,cartaoId:_cartao!,descricao:_descricao.text,
        dataCompra:_data,valor:_valorNumerico()!,previa:_previa!,categoriaId:_categoria);
    }
    setState((){_salvando=true;_erro=null;});
    try{final f=await widget.client.comprar(_tentativa!);if(mounted)Navigator.of(context).pop(f);}
    catch(e){if(mounted)setState((){
      _erro=e is CartaoCreditoApiException?e.messageKey:'cards.error.server';
      if(e is CartaoCreditoApiException&&e.statusCode!=null&&e.statusCode!>=400&&e.statusCode!<500){
        _tentativa=null;
        if(e.statusCode==409){_previa=null;_erro='invoices.conflict';}
      }
    });}finally{if(mounted)setState(()=>_salvando=false);}
  }
  @override Widget build(BuildContext context){
    final r=context.watch<LocaleSettingsProvider>();
    return PopScope(canPop:!_salvando,child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Form(key:_form,child:Column(
      mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      Text(context.t('invoices.newPurchase'),style:Theme.of(context).textTheme.titleLarge),
      const SizedBox(height:8),Text(context.t('invoices.purchaseHint')),
      const SizedBox(height:20),
      if(_carregando) SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('invoices.title')) else ...[
        DropdownButtonFormField<String>(initialValue:_cartao,isExpanded:true,
          decoration:InputDecoration(labelText:context.t('cards.title')),
          items:widget.cartoes.where((c)=>c.ativo).map((c)=>DropdownMenuItem(value:c.id,child:Text(c.nome,overflow:TextOverflow.ellipsis))).toList(),
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
        const SizedBox(height:16),DropdownButtonFormField<String>(initialValue:_categoria,isExpanded:true,
          decoration:InputDecoration(labelText:context.t('invoices.category')),
          items:[DropdownMenuItem<String>(value:null,child:Text(context.t('space.none'))),
            ..._categorias.map((c)=>DropdownMenuItem(value:c.id,child:Text(c.nome,overflow:TextOverflow.ellipsis)))],
          onChanged:_bloqueado?null:(v)=>setState(()=>_categoria=v)),
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
      const SizedBox(height:24),Wrap(alignment:WrapAlignment.end,spacing:12,runSpacing:8,children:[
        TextButton(onPressed:_salvando?null:()=>Navigator.of(context).pop(),child:Text(context.t('common.close'))),
        FilledButton(onPressed:_salvando||_carregando||_prevendo||(_tentativa==null&&(_previa==null||_previa!.paga))?null:_salvar,
          child:Text(context.t(_salvando?'invoices.saving':_tentativa!=null?'space.retry':'invoices.savePurchase'))),
      ])
    ]))));
  }
}
