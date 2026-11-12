import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/gastos_categoria_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/components/mobile/cartoes_mobile_widgets.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'faturas_cartao_mobile_screen.dart';

class GastosCategoriasMobileScreen extends StatefulWidget {
 const GastosCategoriasMobileScreen({super.key,required this.espaco,required this.inicio,required this.fim,this.client});
 final String espaco;final DateTime inicio,fim;final CartaoCreditoApiClient? client;
 @override State<GastosCategoriasMobileScreen> createState()=>_GastosState();
}
class _GastosState extends State<GastosCategoriasMobileScreen> {
 late final api=widget.client??CartaoCreditoApiClient(espaco:widget.espaco);
 late DateTime start=widget.inicio,end=widget.fim;
 GastosCategorias? data;String? error;String category='*',status='TODOS';bool loading=true;
 @override void initState(){super.initState();load();}
 @override void dispose(){if(widget.client==null)api.dispose();super.dispose();}
 Future<void> load()async{
  if(end.isBefore(start)||end.difference(start).inDays>1830){setState(()=>error='gastos.invalidPeriod');return;}
  setState((){loading=true;error=null;});
  try{final r=await api.gastosCategorias(start,end);if(mounted)setState((){data=r;if(category!='*'&&!r.categorias.any((c)=>c.categoria==category))category='*';});}
  catch(e){if(mounted)setState((){error=erroCartaoMobile(e);if(acessoCartaoNegado(e))data=null;});}
  finally{if(mounted)setState(()=>loading=false);}
 }
 @override Widget build(BuildContext context){final r=context.watch<LocaleSettingsProvider>();
  final entries=(data?.categorias??<GastoCategoria>[]).where((c)=>category=='*'||c.categoria==category).expand((c)=>c.itens).where((i)=>status=='TODOS'||i.situacao==status).toList();
  final paid=entries.where((i)=>i.situacao=='REALIZADO').fold<double>(0,(sum,i)=>sum+i.valor),expected=entries.where((i)=>i.situacao=='PREVISTO').fold<double>(0,(sum,i)=>sum+i.valor);
  return Scaffold(appBar:AppBar(title:Text(context.t('gastos.title')),actions:[IconButton(onPressed:loading?null:load,tooltip:context.t('cards.refresh'),icon:const Icon(Icons.refresh))]),body:SafeArea(child:ListView(padding:const EdgeInsets.all(16),children:[
   Text(context.t('space.${widget.espaco}')),const SizedBox(height:12),
   CartaoMobileField(label:'mobile.cards.start',value:r.formatDate(start),icon:Icons.calendar_today_outlined,onTap:loading?null:()async{final d=await escolherDataCartao(context,'mobile.cards.start',start);if(d!=null&&mounted){setState((){start=d;if(end.isBefore(d))end=d;data=null;});load();}}),
   CartaoMobileField(label:'mobile.cards.end',value:r.formatDate(end),icon:Icons.calendar_today_outlined,onTap:loading?null:()async{final d=await escolherDataCartao(context,'mobile.cards.end',end,first:start,last:start.add(const Duration(days:1830)));if(d!=null&&mounted){setState((){end=d;data=null;});load();}}),
   CartaoMobileField(label:'gastos.category',value:category=='*'?context.t('gastos.allCategories'):category.isEmpty?context.t('invoices.noCategory'):category,onTap:loading?null:()async{final v=await escolherCartaoOpcao(context,'gastos.category',{'*':context.t('gastos.allCategories'),for(final c in data?.categorias??<GastoCategoria>[])c.categoria:c.categoria.isEmpty?context.t('invoices.noCategory'):c.categoria},category);if(v!=null&&mounted)setState(()=>category=v);}),
   CartaoMobileField(label:'agenda.form.situation',value:context.t('gastos.$status'),onTap:loading?null:()async{final v=await escolherCartaoOpcao(context,'agenda.form.situation',{for(final s in ['TODOS','REALIZADO','PREVISTO'])s:context.t('gastos.$s')},status);if(v!=null&&mounted)setState(()=>status=v);}),
   if(loading)SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('gastos.title')),
   if(error!=null)CartaoMobileError(error!,retry:loading?null:load,stale:data!=null),
   if(data!=null)...[
    Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
     Text('${context.t('gastos.REALIZADO')}: ${r.formatCurrency(paid)}',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:12),Text('${context.t('gastos.PREVISTO')}: ${r.formatCurrency(expected)}',style:Theme.of(context).textTheme.titleMedium),
    ]))),
    if(entries.isEmpty)Text(context.t('gastos.empty')),
    for(final c in data!.categorias.where((c)=>(category=='*'||c.categoria==category)&&c.itens.any((i)=>status=='TODOS'||i.situacao==status)))Card(child:ExpansionTile(
     title:Text(c.categoria.isEmpty?context.t('invoices.noCategory'):c.categoria),subtitle:Text(r.formatCurrency(c.itens.where((i)=>status=='TODOS'||i.situacao==status).fold<double>(0,(s,i)=>s+i.valor))),
     children:[for(final i in c.itens.where((i)=>status=='TODOS'||i.situacao==status))ListTile(title:Text(i.descricao),subtitle:Text('${r.formatCurrency(i.valor)} · ${context.t('gastos.${i.situacao}')}\n${r.formatDate(i.data)} · ${i.cartao??context.t('gastos.direct')}${i.numeroParcela==null?'':' · ${i.numeroParcela}/${i.quantidadeParcelas}'}'),
      trailing:i.faturaId==null?null:const Icon(Icons.chevron_right),onTap:i.faturaId==null||loading||error!=null?null:()async{await Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>FaturasCartaoMobileScreen(espaco:widget.espaco,faturaId:i.faturaId)));if(mounted)load();}),
     ],
    )),
   ],
   const SizedBox(height:16),Text(context.t('gastos.rules'),style:Theme.of(context).textTheme.bodySmall),
  ])));
 }
}
