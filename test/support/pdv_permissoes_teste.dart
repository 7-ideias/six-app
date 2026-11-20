import 'package:sixpos/providers/colaborador_autorizacoes_provider.dart';

class PermissoesPdvTeste extends ColaboradorAutorizacoesProvider {
  PermissoesPdvTeste({this.receber = true});
  final bool receber;

  @override
  bool get podeFazerVenda => true;

  @override
  bool get podeReceberNoCaixa => receber;
}
