import 'package:flutter/material.dart';

import '../../core/state/loading_do_mobile_comunicando_com_backend_controller.dart';
import '../../data/models/venda_nao_liquidada_models.dart';
import '../../l10n/six_i18n.dart';
import '../components/mobile/sixoapp_mobile_loading_scene.dart';
import '../coordinators/operational_procedure_flow_coordinator.dart';
import 'pdv_mobile.dart' as base;

/// Mantém o PDV original isolado e adiciona feedback visual reutilizável para
/// as chamadas de finalização e liquidação de venda.
class PdvMobileScreen extends StatelessWidget {
  const PdvMobileScreen({
    super.key,
    this.vendaNaoLiquidada,
    this.procedureCoordinator,
  });

  final VendaNaoLiquidadaModel? vendaNaoLiquidada;
  final OperationalProcedureFlowCoordinator? procedureCoordinator;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable:
          LoadingDoMobileComunicandoComBackendController.activeOperations,
      child: base.PdvMobileScreen(
        vendaNaoLiquidada: vendaNaoLiquidada,
        procedureCoordinator: procedureCoordinator,
      ),
      builder: (BuildContext context, int activeOperations, Widget? child) {
        return SixoAppMobileLoadingOverlay(
          isLoading: activeOperations > 0,
          blockBackNavigation: true,
          message: context.t(
            'pdv.mobile.finalizingSale',
            fallback: 'Finalizando sua venda...',
          ),
          semanticLabel: context.t(
            'pdv.mobile.finalizingSaleSemantics',
            fallback: 'SixoApp finalizando sua venda',
          ),
          child: child!,
        );
      },
    );
  }
}
