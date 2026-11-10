import 'dart:async';

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
  SubscriptionBillingController({
    String? companyId,
    Uri? selection,
    SubscriptionBillingApi? api,
    BillingAccessApi? accessApi,
  }) : _company = companyId,
       _api = api ?? SubscriptionBillingApi(),
       _access = accessApi ?? BillingAccessApi() {
    selection ??= kIsWeb ? Uri.base : null;
    selectedPlanId = selection?.queryParameters['plan'];
    selectedInterval = selection?.queryParameters['interval'];
    currency = selection?.queryParameters['currency'] ?? 'BRL';
    // Public/login locale must not override the authenticated preference.
    WidgetsBinding.instance.addObserver(this);
  }
  String? _company;
  String? selectedPlanId, selectedInterval;
  String currency = 'BRL', locale = 'pt-BR';
  bool _localeInitialized = false, _reloadPending = false;

  void setEffectiveLocale(Locale? effectiveLocale) {
    final next = switch (effectiveLocale?.languageCode) {
      'en' => 'en-US',
      'es' => 'es-ES',
      _ => 'pt-BR',
    };
    if (_disposed || (_localeInitialized && next == locale)) return;
    _localeInitialized = true;
    locale = next;
    value = null;
    _reloadPending = true;
    // didChangeDependencies may run during build. Notify only after it ends.
    scheduleMicrotask(() {
      if (!_disposed && _reloadPending && !busy) load();
    });
  }

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

  final SubscriptionBillingApi _api;
  final BillingAccessApi _access;
  SubscriptionSummary? value;
  String? error;
  bool busy = false, _disposed = false;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({bool sync = false}) async {
    if (busy || _disposed) return;
    _reloadPending = false;
    final requestedLocale = locale;
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
        locale: requestedLocale,
        currency: currency,
      );
      final access = await _access.load(_company!);
      if (!_disposed && requestedLocale == locale) {
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
      if (requestedLocale == locale) error = e.code;
    } catch (_) {
      if (requestedLocale == locale) error = 'error';
    } finally {
      busy = false;
      _notify();
      if (_reloadPending && !_disposed) unawaited(load());
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
          : await _api.checkout(_company!, offer, locale: locale);
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
      if (_reloadPending && !_disposed) unawaited(load());
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
