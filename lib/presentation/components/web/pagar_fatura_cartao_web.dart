import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/core/services/configuracao_financeira_service.dart';
import 'package:sixpos/core/utils/uuid_v4.dart';
import 'package:sixpos/data/models/fatura_cartao_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';

class PagarFaturaCartaoWeb extends StatefulWidget {
 const PagarFaturaCartaoWeb({super.key,required this.client,required this.fatura,this.configuracoes});
 final CartaoCreditoApiClient client;
 final FaturaCartao fatura;
 final ConfiguracaoFinanceiraService? configuracoes;
 @override State<PagarFaturaCartaoWeb> createState()=>_PagarFaturaCartaoWebState();
}
class _PagarFaturaCartaoWebState extends State<PagarFaturaCartaoWeb> {
 final _id=gerarUuidV4();
 late final _config=widget.configuracoes??ConfiguracaoFinanceiraService(widget.client.espaco);
 List<ConfiguracaoFinanceira> _contas=[];
 List<FormaPagamentoFatura> _formas=[];
 String? _conta,_forma,_erro;
 DateTime _data=DateTime.now();
 bool _loading=true,_saving=false,_conflito=false;
 PagarFaturaCartaoRequest? _tentativa;
 bool get _bloqueado=>_saving||_tentativa!=null;
 @override void initState(){super.initState();_load();}
 @override void dispose(){if(widget.configuracoes==null)_config.dispose();super.dispose();}
 Future<void> _load()async{
  setState((){_loading=true;_erro=null;});
  try{
   final contas=await _config.listar('CONTAS').timeout(const Duration(seconds:20));
   final formas=await widget.client.formasFatura();
   if(!mounted)return;
   setState((){
    _contas=contas.where((c)=>c.ativo&&c.tipo!='CAIXA').toList();_formas=formas;
    _conta=_contas.any((c)=>c.id==widget.fatura.contaPrevistaId)?widget.fatura.contaPrevistaId:null;
   });
  }catch(e){if(mounted)setState(()=>_erro=e is CartaoCreditoApiException?e.messageKey:'cards.error.connection');}
  finally{if(mounted)setState(()=>_loading=false);}
 }
 Future<void> _pagar()async{
  _tentativa??=PagarFaturaCartaoRequest(id:_id,faturaId:widget.fatura.id,versao:widget.fatura.versao,
   valor:widget.fatura.total,contaFinanceiraId:_conta!,dataPagamento:_data,formaPagamento:_forma!);
  setState((){_saving=true;_erro=null;});
  try{final f=await widget.client.pagar(_tentativa!);if(mounted)Navigator.of(context).pop(f);}
  catch(e){if(mounted)setState((){
   _erro=e is CartaoCreditoApiException?e.messageKey:'cards.error.server';
   if(e is CartaoCreditoApiException&&e.statusCode!=null&&e.statusCode!>=400&&e.statusCode!<500){
    _tentativa=null;if(e.statusCode==409){_conflito=true;_erro='invoices.conflict';}
   }
  });}finally{if(mounted)setState(()=>_saving=false);}
 }
 @override Widget build(BuildContext context){final r=context.watch<LocaleSettingsProvider>();
  return PopScope(canPop:!_saving,child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Column(
   crossAxisAlignment:CrossAxisAlignment.stretch,mainAxisSize:MainAxisSize.min,children:[
   Text(context.t('invoices.pay'),style:Theme.of(context).textTheme.titleLarge),
   const SizedBox(height:12),Text(widget.fatura.nomeCartao),
   Text(r.formatCurrency(widget.fatura.total),style:Theme.of(context).textTheme.headlineMedium),
   Text('${context.t('invoices.invoiceDue')}: ${r.formatDate(widget.fatura.vencimento)}'),
   const SizedBox(height:12),Text(context.t('invoices.payHint')),
   const SizedBox(height:20),
   if(_loading)SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('invoices.title')) else ...[
    DropdownButtonFormField<String>(initialValue:_conta,isExpanded:true,
     decoration:InputDecoration(labelText:context.t('invoices.account')),
     items:_contas.map((c)=>DropdownMenuItem(value:c.id,child:Text(c.nome,overflow:TextOverflow.ellipsis))).toList(),
     onChanged:_bloqueado?null:(v)=>setState(()=>_conta=v)),
    if(_contas.isEmpty)Text(context.t('invoices.noAccounts')),
    const SizedBox(height:16),DropdownButtonFormField<String>(initialValue:_forma,isExpanded:true,
     decoration:InputDecoration(labelText:context.t('invoices.paymentMethod')),
     items:_formas.map((c)=>DropdownMenuItem(value:c.codigo,child:Text(c.nome,overflow:TextOverflow.ellipsis))).toList(),
     onChanged:_bloqueado?null:(v)=>setState(()=>_forma=v)),
    const SizedBox(height:16),OutlinedButton.icon(onPressed:_bloqueado?null:()async{
      final d=await showDatePicker(context:context,initialDate:_data,firstDate:DateTime(2000),lastDate:DateTime.now());
      if(d!=null&&mounted)setState(()=>_data=d);},icon:const Icon(Icons.calendar_today_outlined),
      label:Text('${context.t('invoices.paymentDate')}: ${r.formatDate(_data)}')),
   ],
   if(_erro!=null)...[const SizedBox(height:12),Text(context.t(_erro!),style:TextStyle(color:Theme.of(context).colorScheme.error)),
    if(!_conflito&&!_bloqueado)TextButton(onPressed:_load,child:Text(context.t('space.retry')))],
   if(_tentativa!=null&&!_saving)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(context.t('invoices.uncertain'))),
   const SizedBox(height:24),Wrap(alignment:WrapAlignment.end,spacing:12,runSpacing:8,children:[
    TextButton(onPressed:_saving?null:()=>Navigator.of(context).pop(),child:Text(context.t('common.close'))),
    FilledButton(onPressed:_saving||_loading||_conflito||_conta==null||_forma==null?null:_pagar,
     child:Text(context.t(_saving?'invoices.saving':_tentativa!=null?'space.retry':'invoices.confirmPayment'))),
   ])
  ])));
 }
}
