import 'package:flutter/material.dart';
import 'package:sixpos/presentation/components/instituicao_open_finance_logo.dart';

/// Átomo visual compartilhado. Telas Web e Mobile mantêm composições próprias.
/// Não tenta inferir marcas por nome aqui: recebe uma URL resolvida pelo domínio.
class MarcaFinanceiraAvatar extends StatelessWidget {
  const MarcaFinanceiraAvatar({
    super.key,
    required this.nome,
    required this.tipo,
    this.logotipoUrl,
    this.size = 48,
  });

  final String nome;
  final String tipo;
  final String? logotipoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final temLogo = logotipoUrl != null && logotipoUrl!.trim().isNotEmpty;
    final IconData icon = switch (tipo) {
      'MAQUININHA' => Icons.point_of_sale_outlined,
      'CARTEIRA' => Icons.account_balance_wallet_outlined,
      'CAIXA' => Icons.payments_outlined,
      'BANCO' => Icons.account_balance_outlined,
      _ => Icons.category_outlined,
    };
    return Semantics(
      label: nome,
      image: temLogo,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: colors.primary.withValues(alpha: 0.08),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.55)),
        ),
        child: temLogo
            ? Padding(
                padding: const EdgeInsets.all(5),
                child: InstituicaoOpenFinanceLogo(
                  url: logotipoUrl,
                  nome: nome,
                  size: size - 10,
                ),
              )
            : Icon(icon, size: size * 0.46, color: colors.primary),
      ),
    );
  }
}
