import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/billing_http_client.dart';
import '../../data/models/subscription_billing.dart';
import '../../data/services/billing_access_api.dart';
import '../../data/services/subscription_billing_api.dart';

class SubscriptionBillingController extends ChangeNotifier
    with WidgetsBindingObserver {
  SubscriptionBillingController({String? companyId, Uri? selection})
    : _company = companyId {
    selection ??= kIsWeb ? Uri.base : null;
    selectedPlanId = selection?.queryParameters['plan'];
    selectedInterval = selection?.queryParameters['interval'];
    currency = selection?.queryParameters['currency'] ?? 'BRL';
    locale = selection?.queryParameters['locale'] ?? 'pt-BR';
    WidgetsBinding.instance.addObserver(this);
  }
  String? _company;
  String? selectedPlanId, selectedInterval;
  String currency = 'BRL', locale = 'pt-BR';
  List<BillingOffer> get visibleOffers {
    final offers = value?.offers ?? const <BillingOffer>[];
    return offers.where((offer) => offer.interval == selectedInterval).toList();
  }

  List<String> get intervals => (value?.offers ?? const <BillingOffer>[])
      .map((offer) => offer.interval)
      .toSet()
      .toList();
  void selectInterval(String interval) {
    selectedInterval = interval;
    _notify();
  }

  final _api = SubscriptionBillingApi();
  final _access = BillingAccessApi();
  SubscriptionSummary? value;
  String? error;
  bool busy = false, _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({bool sync = false}) async {
    if (busy || _disposed) return;
    busy = true;
    error = null;
    _notify();
    try {
      _company ??= await AuthService().getEmpresaId();
      if (_company == null || _company!.isEmpty)
        throw const BillingAccessException('selectCompany');
      final summary = await _api.summary(
        _company!,
        sync: sync && value?.canManage == true,
        locale: locale,
        currency: currency,
      );
      final access = await _access.load(_company!);
      if (!_disposed) {
        value = summary;
        if (!intervals.contains(selectedInterval)) {
          selectedInterval = intervals.isEmpty ? null : intervals.first;
        }
        if (selectedPlanId != null &&
            !summary.offers.any((o) => o.planId == selectedPlanId)) {
          error = 'selectedPlanUnavailable';
        }
        if (access.allowed && paymentRequiredCompany.value == _company)
          paymentRequiredCompany.value = null;
      }
    } on BillingAccessException catch (e) {
      error = e.code;
    } catch (_) {
      error = 'error';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> open({BillingOffer? offer}) async {
    if (busy || value?.canManage != true || _company == null) return;
    busy = true;
    error = null;
    _notify();
    try {
      final uri = offer == null
          ? await _api.portal(_company!)
          : await _api.checkout(_company!, offer);
      if (_disposed) return;
      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      ))
        throw const BillingAccessException('error');
    } on BillingAccessException catch (e) {
      error = e.code;
    } catch (_) {
      error = 'error';
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On web, regaining focus (including from DevTools) happens before the
    // click. Starting a load here disables the checkout button mid-click.
    // Mobile still refreshes when returning from the external payment app.
    if (!kIsWeb && state == AppLifecycleState.resumed) load(sync: true);
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _api.close();
    _access.close();
    super.dispose();
  }
}
