import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/auth_service.dart';
import '../../core/services/billing_http_client.dart';
import '../../core/services/billing_return_service.dart';
import '../../data/models/subscription_billing.dart';
import '../../data/services/billing_access_api.dart';
import '../../data/services/subscription_billing_api.dart';

class SubscriptionBillingController extends ChangeNotifier
    with WidgetsBindingObserver {
  SubscriptionBillingController({
    String? companyId,
    Uri? selection,
    BillingReturn? initialReturn,
    SubscriptionBillingApi? api,
    BillingAccessApi? accessApi,
  }) : _company = companyId,
       _pendingReturn = initialReturn,
       _api = api ?? SubscriptionBillingApi(),
       _access = accessApi ?? BillingAccessApi() {
    selection ??= kIsWeb ? Uri.base : null;
    selectedPlanId = selection?.queryParameters['plan'];
    selectedInterval = selection?.queryParameters['interval'];
    currency = selection?.queryParameters['currency'] ?? 'BRL';
    // Public/login locale must not override the authenticated preference.
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      BillingReturnService.instance.addListener(_onReturn);
      _onReturn();
    }
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
  bool _busy = false, _disposed = false, _reconciling = false;
  bool _checkoutOpened = false, _foreground = true;
  bool get busy => _busy || _reconciling;
  BillingReturn? _pendingReturn;
  String? returnMessage;

  void _onReturn() {
    final result = BillingReturnService.instance.take();
    if (result == null) return;
    _pendingReturn = result;
    if (!_busy && !_reconciling && value != null) unawaited(_reconcile());
  }

  Future<void> _reconcile() async {
    if (_disposed || _busy || _reconciling) return;
    _reconciling = true;
    final result = _pendingReturn;
    _pendingReturn = null;
    try {
      _company ??= await AuthService().getEmpresaId();
      if (_disposed) return;
      if (result != null && result.company != _company) {
        returnMessage = 'returnOtherCompany';
        return;
      }
      final canceled = result?.outcome == 'cancelado';
      final portal =
          result?.outcome == 'portal' || (result == null && !_checkoutOpened);
      if (result != null) _checkoutOpened = !canceled && !portal;
      returnMessage = canceled
          ? 'checkoutCanceled'
          : portal
          ? null
          : 'paymentConfirming';
      _notify();
      for (var attempt = 0; attempt < (canceled || portal ? 1 : 6); attempt++) {
        if (_disposed || !_foreground) return;
        await load(sync: true);
        if (_disposed) return;
        final paidUntil = value?.paidUntil;
        if (!canceled &&
            !portal &&
            error == null &&
            value?.status == 'active' &&
            paidUntil != null &&
            paidUntil.isAfter(DateTime.now())) {
          returnMessage = 'paymentConfirmed';
          _checkoutOpened = false;
          return;
        }
        if (canceled || portal || error != null) break;
        if (attempt < 5) await Future<void>.delayed(const Duration(seconds: 3));
      }
      if (!canceled && !portal) returnMessage = 'paymentStillPending';
      if (canceled) _checkoutOpened = false;
    } finally {
      _reconciling = false;
      _notify();
      if (!_disposed && _pendingReturn != null) unawaited(_reconcile());
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({bool sync = false}) async {
    if (_busy || _disposed) return;
    _reloadPending = false;
    final requestedLocale = locale;
    _busy = true;
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
        if (returnMessage == 'paymentStillPending' &&
            summary.status == 'active' &&
            summary.paidUntil?.isAfter(DateTime.now()) == true) {
          returnMessage = 'paymentConfirmed';
          _checkoutOpened = false;
        }
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
      _busy = false;
      _notify();
      if (_reloadPending && !_disposed) unawaited(load());
      if (!_disposed && !_reconciling && _pendingReturn != null) {
        unawaited(_reconcile());
      }
    }
  }

  Future<void> open({BillingOffer? offer}) async {
    if (busy || value?.canManage != true || _company == null) return;
    _busy = true;
    error = null;
    _notify();
    try {
      final uri = offer == null
          ? await _api.portal(_company!, mobile: !kIsWeb)
          : await _api.checkout(
              _company!,
              offer,
              locale: locale,
              mobile: !kIsWeb,
            );
      if (_disposed) return;
      _checkoutOpened = offer != null;
      returnMessage = null;
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
      _busy = false;
      _notify();
      if (_reloadPending && !_disposed) unawaited(load());
      if (!_disposed && !_reconciling && _pendingReturn != null) {
        unawaited(_reconcile());
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On web, regaining focus (including from DevTools) happens before the
    // click. Starting a load here disables the checkout button mid-click.
    // Mobile still refreshes when returning from the external payment app.
    if (kIsWeb) return;
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      if (_checkoutOpened || _pendingReturn != null) {
        unawaited(_reconcile());
      } else {
        unawaited(load(sync: true));
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    if (!kIsWeb) BillingReturnService.instance.removeListener(_onReturn);
    _api.close();
    _access.close();
    super.dispose();
  }
}
