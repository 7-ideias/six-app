import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixpos/presentation/components/web/cartao_credito_web_editor.dart';
import 'package:sixpos/presentation/theme/web_theme_tokens.dart';
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
  const CompraCartaoWebEditor({super.key,required this.client,this.cartoes,this.cartaoInicial,this.configuracoes,this.embedded=false,this.descricaoController,this.valorController,this.categoriaController,this.onBusy,this.onAvailabilityChanged,this.onLocked,this.onError,this.onSaved,this.compraInicial,this.faturaInicial,this.duplicarCompra});
  final CartaoCreditoApiClient client;
  final List<CartaoCredito>? cartoes;
  final bool embedded;
  final CompraCartao? compraInicial;
  final CompraCartao? duplicarCompra;
  final FaturaCartao? faturaInicial;
  final TextEditingController? descricaoController,valorController,categoriaController;
  final ValueChanged<bool>? onBusy,onLocked;
  final ValueChanged<bool>? onAvailabilityChanged;
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
  late DateTime _data=context.read<LocaleSettingsProvider>().calendarNow;
  bool _mensal=false,_proximas=false,_parcelada=false,_calculando=false;
  final _quantidade=TextEditingController(text:'2');
  List<ParcelaCartao>? _plano;
  double? _planoValor;
  int? _planoQuantidade;
  int _planoSeq=0;
  bool get _parcelaExistente=>widget.compraInicial?.parcelamentoId!=null;
  void _invalidarPlano(){_planoSeq++;_plano=null;}

  DateTime? _fim;
  bool get _recorrente=>widget.compraInicial?.serieRecorrenciaId!=null;
  bool get _configuraSerie=>widget.compraInicial==null?_mensal:_recorrente&&_proximas;
  PreviaFaturaCartao? _previa;
  CompraCartaoRequest? _tentativa;
  bool _carregando=true,_prevendo=false,_salvando=false,_cadastrandoCartao=false;
  final _valorFocus=FocusNode();
  int _seq=0;
  bool _preenchido=false,_dadosCarregados=false;
  bool get _temCartaoDisponivel => _cartoes.any((c) => c.ativo || (_parcelaExistente && c.id == _cartao));
  bool get _podePreencher => !_carregando && _dadosCarregados && _permitido && _temCartaoDisponivel;
  void _notificarDisponibilidade() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onAvailabilityChanged?.call(_podePreencher);
    });
  }
  bool get _bloqueado=>_salvando||_tentativa!=null||_calculando||_cadastrandoCartao;
  @override void initState(){super.initState();_valorFocus.addListener(_normalizarValor);_cartao=widget.cartaoInicial;
    if(!_parcelaExistente&&widget.cartoes!=null&&!widget.cartoes!.any((c)=>c.id==_cartao&&c.ativo))_cartao=null;
    final compra=widget.compraInicial;if(compra!=null){_descricao.text=compra.descricao;_data=compra.dataCompra;_categoria=compra.categoriaId;_mensal=compra.serieRecorrenciaId!=null;_fim=compra.recorrenciaFim;}
    final copia=widget.duplicarCompra;
    if(copia!=null){_categoria=copia.categoriaId;}
    _carregar();}
  @override void didChangeDependencies(){super.didChangeDependencies();
    if(!_preenchido&&widget.duplicarCompra!=null){
      _preenchido=true;final copia=widget.duplicarCompra!;
      _descricao.text=context.t('agenda.duplicate.description').replaceAll('{description}',copia.descricao);
      _valor.text=(copia.valorTotalCompra??copia.valor).toStringAsFixed(2).replaceAll('.',context.read<LocaleSettingsProvider>().decimalSeparator);
    }
    if(!_preenchido&&widget.compraInicial!=null){_preenchido=true;_valor.text=widget.compraInicial!.valor.toStringAsFixed(2).replaceAll('.',context.read<LocaleSettingsProvider>().decimalSeparator);}
  }
  @override void dispose(){_valorFocus.removeListener(_normalizarValor);_valorFocus.dispose();_quantidade.dispose();if(widget.descricaoController==null)_descricao.dispose();if(widget.valorController==null)_valor.dispose();if(widget.configuracoes==null)_config.dispose();super.dispose();}
  Future<void> _carregar() async {
    setState((){_carregando=true;_dadosCarregados=false;_erro=null;_previa=null;_permitido=false;});
    _notificarDisponibilidade();
    try {
      // Read the current permission even when a caller supplied cached cards.
      final cards=await widget.client.listar();
      if(!mounted)return;
      _cartoes=cards.cartoes;_permitido=cards.podeEditar;
      if(!_parcelaExistente&&!_cartoes.any((c)=>c.id==_cartao&&c.ativo))_cartao=null;
      final cats=await _config.listar('CATEGORIAS').timeout(const Duration(seconds:20));
      if(!mounted)return;
      setState((){_categorias=cats.where((c)=>c.ativo&&c.tipo!='RECEITA').toList();_dadosCarregados=true;});
      syncCategory();
      if (_permitido && _temCartaoDisponivel) await _prever();
    }catch(e){if(mounted)setState(()=>_erro=e is CartaoCreditoApiException?e.messageKey:'cards.error.connection');}
    finally{if(mounted){setState(()=>_carregando=false);_notificarDisponibilidade();}}
  }
  Future<void> _prever() async {
    final seq=++_seq;
    _invalidarPlano();
    if(_parcelaExistente&&widget.faturaInicial!=null){
      final f=widget.faturaInicial!;
      setState(()=>_previa=PreviaFaturaCartao.fromJson({'fechamento':dataCartaoIso(f.fechamento),'vencimento':dataCartaoIso(f.vencimento),'versaoCartao':_cartoes.where((c)=>c.id==_cartao).first.versao,'paga':f.paga}));return;
    }
    setState((){_previa=null;_prevendo=_cartao!=null;_erro=null;});
    if(_cartao==null)return;
    try{final result=await ((_mensal||_recorrente)?widget.client.previaRecorrencia(_cartao!,_data):widget.client.previa(_cartao!,_data));
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
    if (!_podePreencher || _cadastrandoCartao) return false;
    syncCategory();
    final valid=_form.currentState?.validate()??false;
    return valid&&(!_parcelada||(_plano!=null&&_planoValor==_valorNumerico()&&_planoQuantidade==int.tryParse(_quantidade.text)&&!_plano!.any((p)=>p.paga)))&&(!_configuraSerie||_fim==null||!_fim!.isBefore(DateTime(_data.year,_data.month,_data.day)))&&!_carregando&&!_prevendo&&!_cadastrandoCartao&&_permitido&&_previa!=null&&!_previa!.paga;
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
      const SizedBox(height:16),Text(context.t(_parcelada?'invoices.installments.hint':_mensal?'invoices.recurring.review':'invoices.noRecurrence')),
      if(_parcelada)..._resumoParcelas(),
      if(_mensal)Text(_fim==null?context.t('invoices.recurring.noEnd'):'${context.t('invoices.recurring.until')}: ${r.formatDate(_fim!)}'),
    ]);
  }
  double? _valorNumerico(){
    final r=context.read<LocaleSettingsProvider>();
    final raw=_valor.text.trim();
    final sep=RegExp.escape(r.decimalSeparator);
    if(!RegExp('^[0-9]*($sep[0-9]{0,2})?\$').hasMatch(raw))return null;
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
    try{final compra=widget.compraInicial;final FaturaCartao f;
      if(compra==null){f=_parcelada?await widget.client.parcelar(_tentativa!,int.parse(_quantidade.text)):_mensal?await widget.client.criarRecorrencia(_tentativa!,_fim):await widget.client.comprar(_tentativa!);}
      else{f=_proximas?await widget.client.editarProximas(compra.id,compra.versao,_tentativa!,_fim):await widget.client.editarCompra(compra.id,compra.versao,_tentativa!);}if(mounted){if(widget.onSaved!=null){widget.onSaved!(f);}else{Navigator.of(context).pop(f);}}}
    catch(e){if(mounted){setState((){
      _erro=e is CartaoCreditoApiException?e.messageKey:'cards.error.server';
      if(e is CartaoCreditoApiException&&e.statusCode!=null&&e.statusCode!>=400&&e.statusCode!<500){
        _tentativa=null;
        if(e.statusCode==409){_previa=null;_erro=widget.compraInicial==null?'invoices.conflict':'invoices.editConflict';}
      }
    });}}finally{if(mounted){setState(()=>_salvando=false);widget.onBusy?.call(false);widget.onLocked?.call(_tentativa!=null);widget.onError?.call(_erro==null?null:'${context.t(_erro!)}${_tentativa==null?'':' ${context.t('invoices.uncertain')}'}');}}
  }
  Future<void> _calcularParcelas()async{
    if(!(_form.currentState?.validate()??false)||_previa==null||_cartao==null)return;
    final n=int.parse(_quantidade.text);final valor=_valorNumerico()!;
    if((valor*100).round()<n){setState(()=>_erro='invoices.installments.invalid');return;}
    final seq=++_planoSeq;setState((){_calculando=true;_erro=null;_plano=null;});
    widget.onBusy?.call(true);
    try{final items=await widget.client.previaParcelamento(CompraCartaoRequest(id:_id,cartaoId:_cartao!,descricao:_descricao.text,dataCompra:_data,valor:valor,previa:_previa!,categoriaId:_categoria),n);
      if(mounted&&seq==_planoSeq)setState((){_plano=items;_planoValor=valor;_planoQuantidade=n;});
    }catch(e){if(mounted&&seq==_planoSeq)setState(()=>_erro=e is CartaoCreditoApiException?e.messageKey:'cards.error.server');}
    finally{if(mounted){setState(()=>_calculando=false);widget.onBusy?.call(false);}}
  }
  List<Widget> _resumoParcelas(){
    final r=context.read<LocaleSettingsProvider>();
    return [if(_plano!=null)...[
      for(final p in _plano!)Padding(padding:const EdgeInsets.symmetric(vertical:6),child:Wrap(alignment:WrapAlignment.spaceBetween,spacing:16,runSpacing:4,children:[
        Text('${p.numero}/${_plano!.length} · ${r.formatDate(p.vencimento)}'),Text(r.formatCurrency(p.valor)),if(p.paga)Text(context.t('invoices.alreadyPaid')),
      ])),
    ]];
  }
  Future<void> _adicionarCartao() async {
    if (!_permitido || _carregando || _bloqueado || _parcelaExistente) return;
    FocusScope.of(context).unfocus();
    setState(() => _cadastrandoCartao = true);
    widget.onBusy?.call(true);
    try {
      final card = await showDialog<CartaoCredito>(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: CartaoCreditoWebEditor(
                  espaco: widget.client.espaco,
                  client: widget.client,
                  contasService: _config,
                ),
              ),
            ),
      );
      if (!mounted || card == null) return;
      // Only select a card confirmed by the server. Keep the purchase draft.
      setState(() {
        _cartoes = [..._cartoes.where((c) => c.id != card.id), card];
        if (card.ativo) _cartao = card.id;
      });
      if (card.ativo) await _prever();
    } finally {
      if (mounted) {
        setState(() => _cadastrandoCartao = false);
        widget.onBusy?.call(false);
        _notificarDisponibilidade();
      }
    }
  }

  void _normalizarValor() {
    if (_valorFocus.hasFocus) return;
    final value = _valorNumerico();
    if (value == null || !value.isFinite) return;
    final text = value
        .toStringAsFixed(2)
        .replaceAll(
          '.',
          context.read<LocaleSettingsProvider>().decimalSeparator,
        );
    _valor.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Widget _seletorCartao() {
    final options =
        _cartoes
            .where((c) => c.ativo || (_parcelaExistente && c.id == _cartao))
            .toList();
    final canCreate = _permitido && !_parcelaExistente;
    final add = OutlinedButton.icon(
      key: const ValueKey('purchase-add-card'),
      onPressed: _bloqueado ? null : _adicionarCartao,
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text(context.t('cards.new')),
    );
    if (options.isEmpty && canCreate) {
      final tokens = WebThemeTokens.of(context);
      return Semantics(
        key: const ValueKey('purchase-card-required'),
        container: true, liveRegion: true,
        child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.cardBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.t('invoices.cardRequiredTitle'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              context.t('invoices.cardRequiredHint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('purchase-add-card'),
              onPressed: _bloqueado ? null : _adicionarCartao,
              icon: const Icon(Icons.add_card_outlined, size: 20),
              label: Text(context.t('cards.new')),
            ),
          ],
        ),
      ));
    }
    final field = DropdownButtonFormField<String>(
      key: ValueKey('purchase-card-${_cartao ?? 'none'}'),
      initialValue: _cartao,
      isExpanded: true,
      decoration: InputDecoration(labelText: context.t('cards.title')),
      items:
          options
              .map(
                (c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.nome, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
      onChanged:
          _bloqueado || !_permitido || _parcelaExistente
              ? null
              : (v) {
                setState(() => _cartao = v);
                _prever();
              },
      validator: (v) => v == null ? context.t('invoices.required') : null,
    );
    if (!canCreate) return field;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 580 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [field, const SizedBox(height: 8), add],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Expanded(child: field), const SizedBox(width: 12), add],
        );
      },
    );
  }

  Widget _valorEData() {
    final r = context.watch<LocaleSettingsProvider>();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            SizedBox(
              width: constraints.maxWidth.clamp(0, 240).toDouble(),
              child: TextFormField(
                key: const ValueKey('purchase-amount'),
                controller: _valor,
                focusNode: _valorFocus,
                enabled: !_bloqueado && !_parcelaExistente,
                onChanged: (_) => setState(_invalidarPlano),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 20),
                inputFormatters: [
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (!newValue.composing.isCollapsed) return newValue;
                    // Also accept the decimal key on a numeric keypad in comma locales.
                    final text = newValue.text.replaceAll(
                      '.',
                      r.decimalSeparator,
                    );
                    final sep = RegExp.escape(r.decimalSeparator);
                    if (!RegExp(
                      '^[0-9]{0,13}($sep[0-9]{0,2})?\$',
                    ).hasMatch(text)) {
                      return oldValue;
                    }
                    return newValue.copyWith(text: text);
                  }),
                ],
                decoration: InputDecoration(
                  labelText: context.t(
                    _parcelada
                        ? 'invoices.installments.total'
                        : 'invoices.value',
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixText: '${r.currencySymbol} ',
                  hintText: '0${r.decimalSeparator}00',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  errorMaxLines: 3,
                ),
                validator: (_) {
                  final v = _valorNumerico();
                  return v == null || v <= 0 || !v.isFinite || v >= 1e13
                      ? context.t('invoices.invalidValue')
                      : null;
                },
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth.clamp(0, 320).toDouble(),
                minHeight: 52,
              ),
              child: OutlinedButton.icon(
                key: const ValueKey('purchase-date'),
                onPressed:
                    _bloqueado || _parcelaExistente
                        ? null
                        : () async {
                          final today =
                              context
                                  .read<LocaleSettingsProvider>()
                                  .calendarNow;
                          final d = await showDatePicker(
                            context: context,
                            initialDate: _data,
                            firstDate: DateTime(2000),
                            lastDate:
                                (_mensal || _recorrente)
                                    ? (widget.compraInicial != null
                                        ? DateTime(2100)
                                        : DateTime(
                                          today.year + 1,
                                          today.month,
                                          today.day,
                                        ))
                                    : today,
                          );
                          if (d != null && mounted) {
                            setState(() => _data = d);
                            _prever();
                          }
                        },
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  '${context.t('invoices.purchaseDate')}: ${r.formatDate(_data)}',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override Widget build(BuildContext context){
    final r=context.watch<LocaleSettingsProvider>();
    return PopScope(canPop:!_salvando&&!_cadastrandoCartao,child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:Form(key:_form,child:Column(
      mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.stretch,children:[
      if(!widget.embedded)Text(context.t(widget.compraInicial==null?'invoices.newPurchase':'invoices.editPurchase'),style:Theme.of(context).textTheme.titleLarge),
      if (_carregando)
        SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('cards.title'))
      else if (_dadosCarregados && !_permitido)
        Semantics(liveRegion:true,child:Padding(padding:const EdgeInsets.symmetric(vertical:20),child:Text(context.t('invoices.cardPermissionHint'))))
      else if (_dadosCarregados && !_temCartaoDisponivel)
        _seletorCartao(),
      if (_podePreencher) ...[
      const SizedBox(height:8),Text(context.t('invoices.purchaseHint')),
      const SizedBox(height:20),
      if(widget.compraInicial==null)...[
        Wrap(spacing:8,runSpacing:8,children:[
          for(final mode in ['once','monthly','installments'])ChoiceChip(label:Text(context.t(mode=='installments'?'invoices.installments.title':'invoices.recurring.$mode')),
            selected:mode=='installments'?_parcelada:mode=='monthly'?_mensal:!_mensal&&!_parcelada,
            onSelected:_bloqueado?null:(_){setState((){_mensal=mode=='monthly';_parcelada=mode=='installments';if(!_mensal&&_data.isAfter(context.read<LocaleSettingsProvider>().calendarNow))_data=context.read<LocaleSettingsProvider>().calendarNow;});_prever();}),
        ]),
        if(_parcelada)...[
          const SizedBox(height:12),Text(context.t('invoices.installments.hint')),
          TextFormField(controller:_quantidade,enabled:!_bloqueado,keyboardType:TextInputType.number,
            decoration:InputDecoration(labelText:context.t('invoices.installments.count')),
            onChanged:(_)=>setState(_invalidarPlano),validator:(_){final n=int.tryParse(_quantidade.text);return n==null||n<2||n>48?context.t('invoices.installments.invalid'):null;}),
        ],
        const SizedBox(height:16),
      ],
      if(_parcelaExistente)Text(context.t('invoices.installments.editHint')),
      if(_recorrente&&widget.compraInicial!.recorrenciaAtiva)...[
        DropdownButtonFormField<bool>(initialValue:false,isExpanded:true,
          decoration:InputDecoration(labelText:context.t('invoices.recurring.editScope')),
          items:[DropdownMenuItem(value:false,child:Text(context.t('invoices.recurring.onlyThis'))),DropdownMenuItem(value:true,child:Text(context.t('invoices.recurring.thisAndNext')))],
          onChanged:_bloqueado?null:(v)=>setState(()=>_proximas=v??false)),
        const SizedBox(height:16),
      ],
      if(_configuraSerie)...[
        Text(context.t('invoices.recurring.hint')),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed:_bloqueado?null:()async{
          final start=DateTime(_data.year,_data.month,_data.day);
          final d=await showDatePicker(context:context,initialDate:_fim!=null&&!_fim!.isBefore(start)?_fim!:start,firstDate:start,lastDate:DateTime(start.year+10,12,31));
          if(d!=null&&mounted)setState(()=>_fim=d);},icon:const Icon(Icons.event_outlined),
          label:Text(_fim==null?context.t('invoices.recurring.noEnd'):'${context.t('invoices.recurring.until')}: ${r.formatDate(_fim!)}')),
        if(_fim!=null)TextButton(onPressed:_bloqueado?null:()=>setState(()=>_fim=null),child:Text(context.t('invoices.recurring.removeEnd'))),
        if(_fim!=null&&_fim!.isBefore(DateTime(_data.year,_data.month,_data.day)))Text(context.t('invoices.recurring.invalidEnd'),style:TextStyle(color:Theme.of(context).colorScheme.error)),
        const SizedBox(height:16),
      ],
        _seletorCartao(),
        const SizedBox(height:16),TextFormField(controller:_descricao,enabled:!_bloqueado,maxLength:255,
          decoration:InputDecoration(labelText:context.t('invoices.description')),
          validator:(v)=>v==null||v.trim().isEmpty?context.t('invoices.required'):null),
        const SizedBox(height:8),_valorEData(),
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
        if(_parcelada)...[
          const SizedBox(height:12),OutlinedButton.icon(onPressed:_bloqueado||_previa==null?null:_calcularParcelas,icon:const Icon(Icons.calculate_outlined),label:Text(context.t('invoices.installments.preview'))),
          if(_calculando)SixBackendLoading(title:context.t('space.loading'),subtitle:context.t('invoices.installments.preview')),
          ..._resumoParcelas(),
        ],
        Text(context.t('invoices.cycleRule'),style:Theme.of(context).textTheme.bodySmall),
      ],
      if(_erro!=null)...[const SizedBox(height:12),Text(context.t(_erro!),style:TextStyle(color:Theme.of(context).colorScheme.error)),
        if(!_bloqueado)TextButton(onPressed:_carregar,child:Text(context.t('space.retry')))],
      if(_tentativa!=null&&!_salvando)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(context.t('invoices.uncertain'))),
      if(!widget.embedded)...[const SizedBox(height:24),Wrap(alignment:WrapAlignment.end,spacing:12,runSpacing:8,children:[
        TextButton(onPressed:_salvando?null:()=>Navigator.of(context).pop(),child:Text(context.t('common.close'))),
        if (_podePreencher) FilledButton(onPressed:_salvando||_carregando||_prevendo||(_tentativa==null&&(_previa==null||_previa!.paga))?null:submit,
          child:Text(context.t(_salvando?'invoices.saving':_tentativa!=null?'space.retry':widget.compraInicial==null?'invoices.savePurchase':'invoices.saveChanges'))),
      ])]
    ]))));
  }
}
