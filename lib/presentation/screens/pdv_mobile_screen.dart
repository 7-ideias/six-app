import 'package:flutter/material.dart';

import '../../core/state/loading_do_mobile_comunicando_com_backend_controller.dart';
import '../../data/models/venda_nao_liquidada_models.dart';
import '../../l10n/six_i18n.dart';
import '../components/mobile/sixoapp_mobile_loading_scene.dart';
import '../coordinators/operational_procedure_flow_coordinator.dart';
import 'pdv_mobile.dart' as base;

/// Mantém o PDV original isolado e adiciona feedback visual reutilizável para
/// as chamadas de finalização e liquidação de venda.
class PdvMobileScreen extends StatefulWidget {
  const PdvMobileScreen({
    super.key,
    this.vendaNaoLiquidada,
    this.procedureCoordinator,
  });

  final VendaNaoLiquidadaModel? vendaNaoLiquidada;
  final OperationalProcedureFlowCoordinator? procedureCoordinator;

  @override
  State<PdvMobileScreen> createState() => _PdvMobileScreenState();
}

class _PdvMobileScreenState extends State<PdvMobileScreen> {
  bool _showSuccess = false;

  Future<void> _showSaleCompletedFeedback() async {
    if (!mounted) return;
    setState(() => _showSuccess = true);

    final bool reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    await Future<void>.delayed(
      reduceMotion
          ? const Duration(milliseconds: 180)
          : const Duration(milliseconds: 420),
    );

    if (!mounted) return;
    setState(() => _showSuccess = false);
    if (!reduceMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable:
          LoadingDoMobileComunicandoComBackendController.activeOperations,
      child: base.PdvMobileScreen(
        vendaNaoLiquidada: widget.vendaNaoLiquidada,
        procedureCoordinator: widget.procedureCoordinator,
        onSaleCompleted: _showSaleCompletedFeedback,
      ),
      builder: (BuildContext context, int activeOperations, Widget? child) {
        return SixoAppMobileLoadingOverlay(
          isLoading: activeOperations > 0,
          blockBackNavigation: true,
          message: context.t('pdv.mobile.finalizingSale'),
          semanticLabel: context.t('pdv.mobile.finalizingSaleSemantics'),
          isSuccess: _showSuccess,
          successMessage: context.t('pdv.mobile.saleCompleted'),
          successSemanticLabel: context.t(
            'pdv.mobile.saleCompletedSemantics',
          ),
          child: child!,
        );
      },
    );
  }
}
