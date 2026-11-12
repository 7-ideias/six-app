import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixpos/data/models/gastos_categoria_model.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/providers/locale_settings_provider.dart';
import 'package:sixpos/presentation/components/six_backend_loading.dart';
import 'package:sixpos/presentation/components/web_dashboard_widgets.dart';
import 'package:sixpos/presentation/components/web/financeiro_configuracao_web_dialog.dart';
import 'package:sixpos/presentation/screens/faturas_cartao_web.dart';
class GastosCategoriasWeb extends StatefulWidget {
 const GastosCategoriasWeb({super.key,required this.espaco,required this.inicio,required this.fim,this.client});
 final String espaco;final DateTime inicio,fim;final CartaoCreditoApiClient? client;
 @override State<GastosCategoriasWeb> createState()=>_GastosCategoriasWebState();
}
class _GastosCategoriasWebState extends State<GastosCategoriasWeb> {
 late final _client=widget.client??CartaoCreditoApiClient(espaco:widget.espaco);
 late DateTime _inicio=widget.inicio,_fim=widget.fim;
 GastosCategorias? _dados;String? _erro,_categoria;String _situacao='TODOS';bool _loading=true;int _seq=0;
 @override void initState(){super.initState();_carregar();}
 @override void dispose(){if(widget.client==null)_client.dispose();super.dispose();}
 Future<void> _carregar()async{
  final seq=++_seq;setState((){_loading=true;_erro=null;});
  try{final d=await _client.gastosCategorias(_inicio,_fim);if(!mounted||seq!=_seq)return;
   setState((){_dados=d;if(_categoria!=null&&!d.categorias.any((c)=>c.categoria==_categoria))_categoria=null;});
  }catch(e){if(mounted&&seq==_seq)setState((){_erro=e is CartaoCreditoApiException?e.messageKey:'cards.error.server';if(e is CartaoCreditoApiException&&(e.statusCode==401||e.statusCode==403))_dados=null;});}
  finally{if(mounted&&seq==_seq)setState(()=>_loading=false);}
 }
 Future<void> _periodo()async{
  final range=await showDateRangePicker(context:context,initialDateRange:DateTimeRange(start:_inicio,end:_fim),firstDate:DateTime(2000),lastDate:DateTime(2100));
  if(range==null||!mounted)return;
  if(range.end.isAfter(DateTime(range.start.year+5,range.start.month,range.start.day))){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(context.t('gastos.invalidPeriod'))));return;}
  setState((){_inicio=range.start;_fim=range.end;_dados=null;});await _carregar();
 }
 List<GastoCategoriaItem> _itens(GastoCategoria c)=>c.itens.where((i)=>_situacao=='TODOS'||i.situacao==_situacao).toList();
 String _nome(String c)=>c.isEmpty?context.t('invoices.noCategory'):c;
 Widget _total(String key,double value,IconData icon,Color color){final r=context.read<LocaleSettingsProvider>();return Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(border:Border.all(color:Theme.of(context).colorScheme.outlineVariant),borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(icon,color:color,size:20),const SizedBox(width:8),Expanded(child:Text(context.t(key)))]),const SizedBox(height:10),Text(r.formatCurrency(value),style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w700))]));}
 @override Widget build(BuildContext context){
  final r=context.watch<LocaleSettingsProvider>();final theme=Theme.of(context);final colors=theme.colorScheme;
  final cats=(_dados?.categorias??<GastoCategoria>[]).where((c)=>(_categoria==null||c.categoria==_categoria)&&_itens(c).isNotEmpty).toList();
  final itens=cats.expand(_itens);final realizado=itens.where((i)=>i.situacao=='REALIZADO').fold(0.0,(double s,i)=>s+i.valor);final previsto=itens.where((i)=>i.situacao=='PREVISTO').fold(0.0,(double s,i)=>s+i.valor);
  return Scaffold(body:SafeArea(child:ListView(padding:const EdgeInsets.all(24),children:[
   SixWebDashboardHeader(icon:Icons.category_outlined,title:context.t('gastos.title'),subtitle:context.t('space.${widget.espaco}'),onBack:()=>Navigator.of(context).maybePop(),actions:[OutlinedButton.icon(onPressed:_loading?null:_carregar,icon:const Icon(Icons.refresh),label:Text(context.t('cards.refresh')))]),
   const SizedBox(height:20),Wrap(spacing:12,runSpacing:12,crossAxisAlignment:WrapCrossAlignment.center,children:[
    OutlinedButton.icon(onPressed:_loading?null:_periodo,icon:const Icon(Icons.date_range),label:Text('${r.formatDate(_inicio)} – ${r.formatDate(_fim)}')),
    SizedBox(width:260,child:DropdownButtonFormField<String>(key:ValueKey(_categoria),initialValue:_categoria,isExpanded:true,decoration:InputDecoration(labelText:context.t('gastos.category')),
     items:[DropdownMenuItem<String>(value:null,child:Text(context.t('gastos.allCategories'))),...(_dados?.categorias??<GastoCategoria>[]).map((c)=>DropdownMenuItem(value:c.categoria,child:Text(_nome(c.categoria),overflow:TextOverflow.ellipsis)))],onChanged:_loading?null:(v)=>setState(()=>_categoria=v))),
    Wrap(spacing:8,runSpacing:8,children:[for(final s in ['TODOS','REALIZADO','PREVISTO'])ChoiceChip(label:Text(context.t('gastos.$s')),selected:_situacao==s,onSelected:_loading?null:(_)=>setState(()=>_situacao=s))]),
   ]),
   const SizedBox(height:16),Text(context.t('gastos.rules'),style:theme.textTheme.bodySmall),
   const SizedBox(height:20),
   if(_loading)SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('gastos.title')),
   if(_erro!=null)...[Text(context.t(_erro!),style:TextStyle(color:colors.error)),if(_dados!=null)Text(context.t('cards.stale')),TextButton(onPressed:_loading?null:_carregar,child:Text(context.t('space.retry')))],
   if(_dados!=null)...[
    LayoutBuilder(builder:(_,c){final a=_total('gastos.REALIZADO',realizado,Icons.check_circle_outline,Colors.teal);final b=_total('gastos.PREVISTO',previsto,Icons.schedule,colors.primary);return c.maxWidth>=650?Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Expanded(child:a),const SizedBox(width:16),Expanded(child:b)]):Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[a,const SizedBox(height:12),b]);}),
    const SizedBox(height:20),
    if(cats.isEmpty&&!_loading&&_erro==null)Padding(padding:const EdgeInsets.all(24),child:Text(context.t('gastos.empty'))),
    for(final cat in cats)Card(elevation:0,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:BorderSide(color:colors.outlineVariant)),child:ExpansionTile(key:ValueKey('${cat.categoria}-$_situacao'),initiallyExpanded:_categoria!=null,
      title:Text(_nome(cat.categoria),style:const TextStyle(fontWeight:FontWeight.w700)),
      subtitle:Wrap(spacing:16,runSpacing:4,children:[if(_situacao!='PREVISTO')Text('${context.t('gastos.REALIZADO')}: ${r.formatCurrency(cat.realizado)}'),if(_situacao!='REALIZADO')Text('${context.t('gastos.PREVISTO')}: ${r.formatCurrency(cat.previsto)}')]),
      children:[for(final i in _itens(cat))Padding(padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[
       Text(i.descricao,style:const TextStyle(fontWeight:FontWeight.w600)),
       const SizedBox(height:6),Wrap(spacing:12,runSpacing:6,children:[Text(i.origem=='CARTAO'?(i.cartao??context.t('cards.title')):context.t('gastos.direct')),Text(r.formatDate(i.data)),Text(context.t('gastos.${i.situacao}')),if(i.numeroParcela!=null)Text('${context.t('invoices.installments.part')} ${i.numeroParcela}/${i.quantidadeParcelas}'),Text(r.formatCurrency(i.valor),style:const TextStyle(fontWeight:FontWeight.w700))]),
       if(i.faturaId!=null)Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:_loading||_erro!=null?null:()async{await abrirFaturasCartaoWeb(context,espaco:widget.espaco,faturaId:i.faturaId);if(mounted)await _carregar();},icon:const Icon(Icons.receipt_long_outlined,size:18),label:Text(context.t('gastos.invoice')))),
      ]))],
    )),
   ],
  ])));
 }
}
Future<void> abrirGastosCategoriasWeb(BuildContext context,{required String espaco,required DateTime inicio,required DateTime fim})=>showFinanceiroConfiguracaoWebDialog<void>(context:context,title:context.t('gastos.title'),child:GastosCategoriasWeb(espaco:espaco,inicio:inicio,fim:fim));
