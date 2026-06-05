import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../design_system/tokens/web_root_tokens.dart';
import '../../l10n/web_root_l10n.dart';
import '../components/web_root/web_i18n_gate.dart';
import '../components/web_root/web_language_switcher.dart';

/// Plano vindo do backend (`WebRootL10n.plans`). Mesmo formato usado na
/// `PricingSection` — fonte única de preços.
typedef _Plan = ({
  String name,
  String price,
  String cadence,
  String pitch,
  List<String> features,
  String cta,
  bool featured,
});

/// Método de pagamento selecionado no segmented control.
enum _PayMethod { card, pix, boleto }

// ── Tokens locais ───────────────────────────────────────────────────────────
// Cores/raios presentes no design (Claude Design / Six Design System) que ainda
// não têm constante em [WebRootTokens]. Mantidos aqui, comentados, para não
// hardcodar valores soltos no meio do layout.
const Color _kLineStrong = Color(0xFFBCBCBC); // outline forte (--six-line-strong)
const Color _kFgDim = Color(0xFF696969); // fine print (--six-fg-dim)

const double _kRadiusXs = 6; // badge "economize"
const double _kRadiusMd = 12; // card de detalhes / QR
const double _kRadiusField = 14; // campos, CTA, grupo de planos
const double _kRadiusSheet = 24; // folha externa

/// Checkout web redesenhado a partir do design feito no Claude Design sobre o
/// Six Design System. Estrutura: folha central com topbar (cancelar / logo /
/// ajuda) e corpo em duas colunas — esquerda com seleção de plano, forma de
/// pagamento (cartão/Pix/Boleto) e CTA; direita com os detalhes do plano.
///
/// Conteúdo via [WebRootL10n] (backend + defaults PT-BR locais) e planos/preços
/// do backend (`WebRootL10n.plans`), unificados com o pricing da landing.
class WebCheckoutPage extends StatefulWidget {
  const WebCheckoutPage({super.key, this.initialUri});

  static const String routeName = '/checkout';

  final Uri? initialUri;

  @override
  State<WebCheckoutPage> createState() => _WebCheckoutPageState();
}

class _WebCheckoutPageState extends State<WebCheckoutPage> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();
  final TextEditingController _cardNameController = TextEditingController();

  /// Nome do plano selecionado (ex.: "Professional"). Vem da query `?plan=`.
  String? _selectedPlanName;
  _PayMethod _payMethod = _PayMethod.card;

  @override
  void initState() {
    super.initState();
    _selectedPlanName = widget.initialUri?.queryParameters['plan'];
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cardNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WebI18nGate(
      builder: (context) {
        final l10n = WebRootL10n.of(context);
        final plans = l10n.plans;
        final selected = _resolveSelected(plans);

        return Scaffold(
          backgroundColor: WebRootTokens.bgCanvas,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: _sheet(context, l10n, plans, selected)
                      .animate()
                      .fadeIn(duration: 360.ms)
                      .slideY(begin: 0.03, end: 0, curve: Curves.easeOut),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _Plan? _resolveSelected(List<_Plan> plans) {
    if (plans.isEmpty) return null;
    for (final p in plans) {
      if (p.name == _selectedPlanName) return p;
    }
    for (final p in plans) {
      if (p.featured) return p;
    }
    return plans.first;
  }

  // ── Folha (card externo) ───────────────────────────────────────────────────
  Widget _sheet(
    BuildContext context,
    WebRootL10n l10n,
    List<_Plan> plans,
    _Plan? selected,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: WebRootTokens.surface,
        borderRadius: BorderRadius.circular(_kRadiusSheet),
        border: Border.all(color: WebRootTokens.line),
        boxShadow: WebRootTokens.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(context, l10n),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCols = constraints.maxWidth >= 880;
              final left = _leftColumn(context, l10n, plans, selected);
              final right = _rightColumn(l10n, selected);

              if (!twoCols) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [left, const SizedBox(height: 40), right],
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(56, 48, 56, 56),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 106, child: left),
                    const SizedBox(width: 72),
                    Expanded(flex: 94, child: right),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Topbar ─────────────────────────────────────────────────────────────────
  Widget _topBar(BuildContext context, WebRootL10n l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: WebRootTokens.line)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showHelp = constraints.maxWidth >= 700;
          return Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _cancelButton(context, l10n),
                ),
              ),
              Image.asset(
                'assets/images/six-logo-flecha.png',
                height: 30,
                fit: BoxFit.contain,
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showHelp) ...[
                      _helpLink(l10n),
                      const SizedBox(width: 18),
                    ],
                    const WebLanguageSwitcher(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cancelButton(BuildContext context, WebRootL10n l10n) {
    return _HoverButton(
      onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
        '/',
        (route) => false,
      ),
      builder: (hovered) => Container(
        height: 42,
        padding: const EdgeInsets.fromLTRB(14, 0, 18, 0),
        decoration: BoxDecoration(
          color: hovered ? WebRootTokens.field : WebRootTokens.surface,
          borderRadius: BorderRadius.circular(WebRootTokens.radiusPill),
          border: Border.all(color: _kLineStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close, size: 19, color: WebRootTokens.fg),
            const SizedBox(width: 8),
            Text(
              l10n.checkoutCancel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: WebRootTokens.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpLink(WebRootL10n l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.support_agent, size: 20, color: WebRootTokens.ink),
        const SizedBox(width: 8),
        Text(
          '${l10n.checkoutHelp} ',
          style: const TextStyle(fontSize: 14, color: WebRootTokens.fgSoft),
        ),
        _HoverButton(
          onTap: () {},
          builder: (hovered) => Text(
            l10n.checkoutHelpLink,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: hovered ? WebRootTokens.ink : WebRootTokens.fg,
              decoration: TextDecoration.underline,
              decorationColor: hovered ? WebRootTokens.ink : WebRootTokens.fg,
            ),
          ),
        ),
      ],
    );
  }

  // ── Coluna esquerda ─────────────────────────────────────────────────────────
  Widget _leftColumn(
    BuildContext context,
    WebRootL10n l10n,
    List<_Plan> plans,
    _Plan? selected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _colTitle(l10n.checkoutChoosePlan),
        const SizedBox(height: 20),
        _planGroup(l10n, plans, selected),
        const _Rule(margin: 32),
        _colTitle(l10n.checkoutPayment),
        const SizedBox(height: 20),
        _paySegment(l10n),
        const SizedBox(height: 24),
        _payPanel(l10n),
        const _Rule(margin: 32),
        _legal(l10n),
        const SizedBox(height: 24),
        _ctaButton(context, l10n, selected),
      ],
    );
  }

  Widget _colTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: WebRootTokens.fg,
        ),
      );

  // ── Grupo de planos ─────────────────────────────────────────────────────────
  Widget _planGroup(WebRootL10n l10n, List<_Plan> plans, _Plan? selected) {
    if (plans.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: WebRootTokens.surface,
        borderRadius: BorderRadius.circular(_kRadiusField),
        border: Border.all(color: WebRootTokens.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < plans.length; i++)
            _PlanRow(
              plan: plans[i],
              selected: selected?.name == plans[i].name,
              showTopBorder: i != 0,
              popularLabel: l10n.checkoutPopularBadge,
              onTap: () =>
                  setState(() => _selectedPlanName = plans[i].name),
            ),
        ],
      ),
    );
  }

  // ── Segmented control (forma de pagamento) ───────────────────────────────────
  Widget _paySegment(WebRootL10n l10n) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: WebRootTokens.field,
        borderRadius: BorderRadius.circular(WebRootTokens.radiusPill),
      ),
      child: Row(
        children: [
          _SegButton(
            label: l10n.checkoutCard,
            icon: Icons.credit_card,
            selected: _payMethod == _PayMethod.card,
            onTap: () => setState(() => _payMethod = _PayMethod.card),
          ),
          const SizedBox(width: 4),
          _SegButton(
            label: l10n.checkoutPix,
            icon: Icons.qr_code_2,
            selected: _payMethod == _PayMethod.pix,
            onTap: () => setState(() => _payMethod = _PayMethod.pix),
          ),
          const SizedBox(width: 4),
          _SegButton(
            label: l10n.checkoutBoleto,
            icon: Icons.receipt_long,
            selected: _payMethod == _PayMethod.boleto,
            onTap: () => setState(() => _payMethod = _PayMethod.boleto),
          ),
        ],
      ),
    );
  }

  Widget _payPanel(WebRootL10n l10n) {
    switch (_payMethod) {
      case _PayMethod.card:
        return _cardForm(l10n);
      case _PayMethod.pix:
        return _altPanel(
          icon: Icons.qr_code_2,
          title: l10n.checkoutPixTitle,
          body: l10n.checkoutPixBody,
        );
      case _PayMethod.boleto:
        return _altPanel(
          icon: Icons.receipt_long,
          title: l10n.checkoutBoletoTitle,
          body: l10n.checkoutBoletoBody,
        );
    }
  }

  // ── Formulário de cartão ─────────────────────────────────────────────────────
  Widget _cardForm(WebRootL10n l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilledField(
          label: l10n.checkoutCardNumberLabel,
          controller: _cardNumberController,
          hint: '1234 1234 1234 1234',
          leadingIcon: Icons.credit_card,
          keyboardType: TextInputType.number,
          trailing: const _CardBrandChips(),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final expiry = _FilledField(
              label: l10n.checkoutCardExpiryLabel,
              controller: _cardExpiryController,
              hint: 'MM / AA',
              keyboardType: TextInputType.number,
            );
            final cvv = _FilledField(
              label: l10n.checkoutCardCvvLabel,
              controller: _cardCvvController,
              hint: 'CVV',
              keyboardType: TextInputType.number,
              trailing: const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.badge_outlined,
                    size: 20, color: WebRootTokens.fgMuted),
              ),
            );
            if (constraints.maxWidth < 420) {
              return Column(
                children: [expiry, const SizedBox(height: 20), cvv],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: expiry),
                const SizedBox(width: 16),
                Expanded(child: cvv),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        _FilledField(
          label: l10n.checkoutCardNameLabel,
          controller: _cardNameController,
          hint: l10n.checkoutCardNameHint,
        ),
        const SizedBox(height: 20),
        _SelectField(
          label: l10n.checkoutCardCountryLabel,
          value: l10n.checkoutCardCountryValue,
        ),
        const SizedBox(height: 16),
        Text(
          l10n.checkoutCardFinePrint,
          style: const TextStyle(fontSize: 12, height: 1.5, color: _kFgDim),
        ),
      ],
    );
  }

  Widget _altPanel({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: WebRootTokens.field,
        borderRadius: BorderRadius.circular(_kRadiusField),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              color: WebRootTokens.surface,
              borderRadius: BorderRadius.circular(_kRadiusMd),
              border: Border.all(color: WebRootTokens.line),
            ),
            child: Icon(icon, size: 64, color: WebRootTokens.ink),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: WebRootTokens.fg,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: WebRootTokens.fgSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Texto legal ──────────────────────────────────────────────────────────────
  Widget _legal(WebRootL10n l10n) {
    const style = TextStyle(
      fontSize: 13,
      height: 1.45,
      color: WebRootTokens.fgSoft,
    );
    final parts = l10n.checkoutLegal.split('{terms}');
    final spans = <InlineSpan>[TextSpan(text: parts.first)];
    if (parts.length > 1) {
      spans.add(TextSpan(
        text: l10n.checkoutTermsLink,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: WebRootTokens.fg,
          decoration: TextDecoration.underline,
        ),
      ));
      spans.add(TextSpan(text: parts.sublist(1).join('{terms}')));
    }
    return Text.rich(TextSpan(style: style, children: spans));
  }

  Widget _ctaButton(BuildContext context, WebRootL10n l10n, _Plan? selected) {
    return _HoverButton(
      onTap: () => _finishCheckout(l10n, selected),
      builder: (hovered) => Opacity(
        opacity: hovered ? 0.92 : 1,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: WebRootTokens.ink,
            borderRadius: BorderRadius.circular(_kRadiusField),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 20, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                l10n.checkoutSubmit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Coluna direita (detalhes do plano) ───────────────────────────────────────
  Widget _rightColumn(WebRootL10n l10n, _Plan? selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _colTitle(l10n.checkoutPlanDetails),
        const SizedBox(height: 20),
        _detailsCard(l10n, selected),
      ],
    );
  }

  Widget _detailsCard(WebRootL10n l10n, _Plan? selected) {
    final langCode = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: WebRootTokens.surface,
        borderRadius: BorderRadius.circular(_kRadiusMd),
        border: Border.all(color: WebRootTokens.line),
        boxShadow: WebRootTokens.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: WebRootTokens.field,
                  borderRadius: BorderRadius.circular(_kRadiusField),
                ),
                child: Image.asset(
                  'assets/images/six-logo-flecha.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.checkoutSubscriptionName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: WebRootTokens.fg,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selected?.name ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: WebRootTokens.fgSoft,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.checkoutRenewPrefix} '
                      '${_renewDateLabel(langCode, selected?.cadence ?? '')}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: WebRootTokens.fgMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (selected != null && selected.features.isNotEmpty) ...[
            const SizedBox(height: 26),
            for (final f in selected.features) _FeatureItem(text: f),
          ],
          const _Rule(margin: 26),
          if (selected != null) _lineRow(selected.name, selected.price),
          const _Rule(margin: 18),
          _totalRow(l10n.checkoutTotalToday, selected?.price ?? ''),
          const SizedBox(height: 22),
          Row(
            children: [
              const Icon(Icons.verified_user,
                  size: 17, color: WebRootTokens.success),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.checkoutSecure,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: WebRootTokens.fgMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _lineRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, color: WebRootTokens.fg),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: WebRootTokens.fg,
          ),
        ),
      ],
    );
  }

  Widget _totalRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: WebRootTokens.fg,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: WebRootTokens.fg,
          ),
        ),
      ],
    );
  }

  // ── Data de renovação ────────────────────────────────────────────────────────
  String _renewDateLabel(String langCode, String cadence) {
    final now = DateTime.now();
    final renew = DateTime(now.year, now.month + _monthsForCadence(cadence),
        now.day);
    const monthsByLang = <String, List<String>>{
      'pt': ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set',
        'out', 'nov', 'dez'],
      'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep',
        'Oct', 'Nov', 'Dec'],
      'es': ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep',
        'oct', 'nov', 'dic'],
    };
    final abbr = monthsByLang[langCode] ?? monthsByLang['pt']!;
    return '${renew.day} ${abbr[renew.month - 1]} ${renew.year}';
  }

  int _monthsForCadence(String cadence) {
    final c = cadence.toLowerCase();
    if (c.contains('trimest') || c.contains('quarter')) return 3;
    if (c.contains('semes')) return 6;
    if (c.contains('mês') ||
        c.contains('mes') ||
        c.contains('month') ||
        c.contains('mensal')) {
      return 1;
    }
    return 12; // anual / yearly (default)
  }

  // ── Ação ─────────────────────────────────────────────────────────────────────
  void _finishCheckout(WebRootL10n l10n, _Plan? selected) {
    if (_payMethod == _PayMethod.card &&
        (_cardNumberController.text.trim().isEmpty ||
            _cardExpiryController.text.trim().isEmpty ||
            _cardCvvController.text.trim().isEmpty ||
            _cardNameController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.checkoutRequired)),
      );
      return;
    }

    final payload = {
      'plan': selected?.name,
      'price': selected?.price,
      'cadence': selected?.cadence,
      'paymentMethod': _payMethod.name,
      if (_payMethod == _PayMethod.card) ...{
        'cardName': _cardNameController.text.trim(),
        'cardLast4': _last4(_cardNumberController.text),
      },
      'createdAt': DateTime.now().toIso8601String(),
    };

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.checkoutSimulatedTitle),
          content: SizedBox(
            width: 520,
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(payload),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _last4(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return digits.length <= 4 ? digits : digits.substring(digits.length - 4);
  }
}

// ── Linha divisória ───────────────────────────────────────────────────────────
class _Rule extends StatelessWidget {
  const _Rule({required this.margin});

  final double margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: margin),
      child: const Divider(height: 1, thickness: 1, color: WebRootTokens.line),
    );
  }
}

// ── Linha de plano (rádio-lista) ──────────────────────────────────────────────
class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.selected,
    required this.showTopBorder,
    required this.popularLabel,
    required this.onTap,
  });

  final _Plan plan;
  final bool selected;
  final bool showTopBorder;
  final String popularLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final priceSpans = <InlineSpan>[
      TextSpan(text: '${plan.price} ${plan.cadence}'.trim()),
      if (plan.pitch.isNotEmpty)
        TextSpan(
          text: '  ·  ${plan.pitch}',
          style: const TextStyle(color: WebRootTokens.fgMuted),
        ),
    ];

    return _HoverButton(
      onTap: onTap,
      builder: (hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected
              ? WebRootTokens.field
              : (hovered ? WebRootTokens.surfaceAlt : WebRootTokens.surface),
          borderRadius:
              selected ? BorderRadius.circular(_kRadiusField) : null,
          border: Border(
            top: BorderSide(
              color: (showTopBorder && !selected)
                  ? WebRootTokens.line
                  : Colors.transparent,
            ),
          ),
        ),
        foregroundDecoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(_kRadiusField),
                border: Border.all(color: WebRootTokens.ink, width: 1.6),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                      color: WebRootTokens.fg,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: WebRootTokens.fgSoft,
                      ),
                      children: priceSpans,
                    ),
                  ),
                ],
              ),
            ),
            if (plan.featured) ...[
              const SizedBox(width: 12),
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WebRootTokens.accent,
                  borderRadius: BorderRadius.circular(_kRadiusXs),
                ),
                child: Text(
                  popularLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                    color: WebRootTokens.ink,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 16),
            _Radio(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? WebRootTokens.ink : Colors.transparent,
        border: Border.all(
          color: selected ? WebRootTokens.ink : _kLineStrong,
          width: 2,
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: selected ? 9 : 0,
          height: selected ? 9 : 0,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: WebRootTokens.surface,
          ),
        ),
      ),
    );
  }
}

// ── Botão do segmented control ────────────────────────────────────────────────
class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _HoverButton(
        onTap: onTap,
        builder: (hovered) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? WebRootTokens.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(WebRootTokens.radiusPill),
            boxShadow: selected ? WebRootTokens.cardShadow : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? WebRootTokens.ink : WebRootTokens.fgSoft,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: selected ? WebRootTokens.ink : WebRootTokens.fgSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Campo preenchido (input) ──────────────────────────────────────────────────
class _FilledField extends StatelessWidget {
  const _FilledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.leadingIcon,
    this.trailing,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData? leadingIcon;
  final Widget? trailing;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: WebRootTokens.fg,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 15, color: WebRootTokens.fg),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: WebRootTokens.field,
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 15,
              color: WebRootTokens.fgMuted,
            ),
            prefixIcon: leadingIcon == null
                ? null
                : Icon(leadingIcon, size: 20, color: WebRootTokens.ink),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            suffixIcon: trailing,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kRadiusField),
              borderSide: BorderSide.none,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kRadiusField),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_kRadiusField),
              borderSide: BorderSide(
                color: WebRootTokens.ink.withValues(alpha: 0.4),
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Campo "select" estático (País) ────────────────────────────────────────────
class _SelectField extends StatelessWidget {
  const _SelectField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: WebRootTokens.fg,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: WebRootTokens.field,
            borderRadius: BorderRadius.circular(_kRadiusField),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 15, color: WebRootTokens.fg),
                ),
              ),
              const Icon(Icons.expand_more,
                  size: 20, color: WebRootTokens.fgMuted),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Selos de bandeira do cartão ───────────────────────────────────────────────
class _CardBrandChips extends StatelessWidget {
  const _CardBrandChips();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _BrandChip(
            child: Text(
              'VISA',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                color: Color(0xFF1A1F71),
              ),
            ),
          ),
          SizedBox(width: 6),
          _BrandChip(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 20,
              height: 13,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: _McCircle(color: Color(0xFFEB001B)),
                  ),
                  Positioned(
                    left: 7,
                    child: _McCircle(color: Color(0xFFF79E1B)),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 6),
          _BrandChip(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
                children: [
                  TextSpan(text: 'e'),
                  TextSpan(text: 'l', style: TextStyle(color: Color(0xFFF24200))),
                  TextSpan(text: 'o'),
                ],
              ),
            ),
          ),
          SizedBox(width: 6),
          _BrandChip(
            background: Color(0xFF1F72CD),
            borderColor: Color(0xFF1F72CD),
            child: Text(
              'AMEX',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({
    required this.child,
    this.background = Colors.white,
    this.borderColor = WebRootTokens.line,
    this.padding = const EdgeInsets.symmetric(horizontal: 5),
  });

  final Widget child;
  final Color background;
  final Color borderColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      constraints: const BoxConstraints(minWidth: 32),
      padding: padding,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class _McCircle extends StatelessWidget {
  const _McCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── Item de feature (coluna direita) ──────────────────────────────────────────
class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: WebRootTokens.field,
            ),
            child: const Icon(Icons.check, size: 16, color: WebRootTokens.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.4,
                color: WebRootTokens.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wrapper de hover/cursor para áreas clicáveis ──────────────────────────────
class _HoverButton extends StatefulWidget {
  const _HoverButton({required this.onTap, required this.builder});

  final VoidCallback onTap;
  final Widget Function(bool hovered) builder;

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: widget.builder(_hovered),
      ),
    );
  }
}
