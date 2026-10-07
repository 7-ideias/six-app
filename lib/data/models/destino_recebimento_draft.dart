import 'recebimento_forma_input.dart';

class DestinoRecebimentoDraft {
  DestinoRecebimentoDraft(this.origem)
    : contaId = origem.contaFinanceiraId,
      maquininhaId = origem.maquininhaId,
      futuro =
          origem.recebimentoFuturo ||
          ['tipo3', 'tipo4'].contains(origem.codigo.toLowerCase()),
      data = DateTime.tryParse(origem.dataPrevista ?? '') ?? DateTime.now(),
      taxa = origem.taxa,
      valor = origem.valor;
  final RecebimentoFormaInput origem;
  bool get dinheiro => origem.codigo.trim().toLowerCase() == 'tipo1';

  String? contaId, maquininhaId;
  bool futuro;
  DateTime data;
  double taxa, valor;
  RecebimentoFormaInput toInput() => RecebimentoFormaInput(
    codigo: origem.codigo,
    descricao: origem.descricao,
    valor: valor,
    contaFinanceiraId: dinheiro ? null : contaId,
    maquininhaId: dinheiro ? null : maquininhaId,
    recebimentoFuturo: !dinheiro && futuro,
    taxa: dinheiro ? 0 : taxa,
    dataPrevista: !dinheiro && futuro ? data.toIso8601String().split('T').first : null,
  );
  bool get valido => valor > 0 && (dinheiro || (contaId != null && taxa >= 0 && taxa < valor));
}

bool distribuicaoFinanceiraValida(
  List<DestinoRecebimentoDraft> drafts,
  List<RecebimentoFormaInput> originais,
) {
  if (drafts.isEmpty || !drafts.every((d) => d.valido)) return false;
  final original = <String, int>{}, atual = <String, int>{};
  for (final forma in originais) {
    original.update(
      forma.codigo,
      (v) => v + (forma.valor * 100).round(),
      ifAbsent: () => (forma.valor * 100).round(),
    );
  }
  for (final d in drafts) {
    atual.update(
      d.origem.codigo,
      (v) => v + (d.valor * 100).round(),
      ifAbsent: () => (d.valor * 100).round(),
    );
  }
  return original.length == atual.length &&
      original.entries.every((e) => atual[e.key] == e.value);
}
