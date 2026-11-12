import 'package:flutter/material.dart';
import 'package:sixpos/l10n/six_i18n.dart';
import 'package:sixpos/data/services/cartoes/cartao_credito_api_client.dart';
import 'package:sixpos/presentation/components/date_selector_mobile_bottom_sheet.dart';
import 'package:sixpos/presentation/components/mobile/six_mobile_selection_sheet.dart';
import 'package:sixpos/design_system/themes/six_mobile_color_scheme.dart';

String erroCartaoMobile(Object e) => e is CartaoCreditoApiException ? e.messageKey : 'cards.error.connection';
bool acessoCartaoNegado(Object e) => e is CartaoCreditoApiException && (e.statusCode == 401 || e.statusCode == 403);
bool rejeicaoCartaoDefinitiva(Object e) => e is CartaoCreditoApiException && e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500;

Future<String?> escolherCartaoOpcao(BuildContext context, String title, Map<String,String> options, String? selected) => showSixMobileSelectionSheet<String>(
  context: context, title: context.t(title), options: options.entries.map((e) => SixMobileSelectionOption(value: e.key, title: e.value)).toList(),
  selectedValue: selected, emptyTitle: context.t('space.none'), searchHint: context.t('common.search'),
);
Future<DateTime?> escolherDataCartao(BuildContext context, String title, DateTime value, {DateTime? first, DateTime? last}) => showModalBottomSheet<DateTime>(
  context: context, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent,
  builder: (_) => DateSelectorMobileBottomSheet(title: context.t(title), initialDate: value, firstDate: first ?? DateTime(2000), lastDate: last ?? DateTime(2100)),
);

class CartaoMobileField extends StatelessWidget {
  const CartaoMobileField({super.key, required this.label, required this.value, this.onTap, this.icon = Icons.expand_more});
  final String label, value; final VoidCallback? onTap; final IconData icon;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Material(
    color: context.sixMobileColors.surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: context.sixMobileColors.border)),
    child: ListTile(onTap: onTap, title: Text(context.t(label), style: Theme.of(context).textTheme.labelMedium), subtitle: Text(value.isEmpty ? context.t('space.none') : value), trailing: Icon(icon)),
  ));
}
class CartaoMobileError extends StatelessWidget {
  const CartaoMobileError(this.message, {super.key, this.retry, this.stale = false});
  final String message; final VoidCallback? retry; final bool stale;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text(context.t(message), style: TextStyle(color: context.sixMobileColors.error)),
    if(stale) Text(context.t('cards.stale')),
    if(retry != null) TextButton.icon(onPressed: retry, icon: const Icon(Icons.refresh), label: Text(context.t('space.retry'))),
  ])));
}

/// A mobile confirmation keeps its command closure for safe retries after timeout.
Future<bool?> confirmarCartaoMobile(BuildContext context, {required String prefix, required String summary, required Future<void> Function() action}) => showModalBottomSheet<bool>(
  context: context, isScrollControlled: true, useSafeArea: true, isDismissible: false, enableDrag: false,
  builder: (_) => _Confirmacao(prefix: prefix, summary: summary, action: action),
);
class _Confirmacao extends StatefulWidget {
  const _Confirmacao({required this.prefix, required this.summary, required this.action});
  final String prefix, summary; final Future<void> Function() action;
  @override State<_Confirmacao> createState() => _ConfirmacaoState();
}
class _ConfirmacaoState extends State<_Confirmacao> {
  bool busy=false, conflict=false; String? error;
  Future<void> run() async {
    setState((){busy=true;error=null;});
    try {await widget.action();if(mounted)Navigator.pop(context,true);}
    catch(e){if(mounted)setState((){error=erroCartaoMobile(e);conflict=rejeicaoCartaoDefinitiva(e);});}
    finally {if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context) => PopScope(canPop: !busy, child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min,crossAxisAlignment: CrossAxisAlignment.stretch,children:[
    Text(context.t('${widget.prefix}.title'),style:Theme.of(context).textTheme.titleLarge),const SizedBox(height:16),Text(widget.summary),const SizedBox(height:16),Text(context.t('${widget.prefix}.impact')),
    if(error!=null)CartaoMobileError(error!),const SizedBox(height:20),
    FilledButton(onPressed:busy||conflict?null:run,child:Text(context.t(busy?'${widget.prefix}.processing':error!=null?'space.retry':'${widget.prefix}.confirm'))),
    TextButton(onPressed:busy?null:()=>Navigator.pop(context,false),child:Text(context.t('common.close'))),
  ]))));
}
