import '../../lib/data/models/recebimento_forma_input.dart';
import '../../lib/data/models/destino_recebimento_draft.dart';
import '../../lib/data/models/operacao_models.dart';
import '../../lib/mappers/operacao_mapper.dart';

void main() {
  var checks = 0;
  void check(bool value, String message) {
    if (!value) throw StateError(message);
    checks++;
  }

  const a = RecebimentoFormaInput(
    codigo: 'TIPO3',
    valor: 400,
    contaFinanceiraId: 'conta-a',
    maquininhaId: 'm-a',
    taxa: 12,
    recebimentoFuturo: true,
    dataPrevista: '2026-10-10',
  );
  const b = RecebimentoFormaInput(
    codigo: 'TIPO3',
    valor: 300,
    contaFinanceiraId: 'conta-b',
    maquininhaId: 'm-b',
  );
  final payload =
      OperacaoRequestMapper()
          .toRequest(
            OperacaoVendaInput(
              descricao: 'Venda',
              idColaborador: 'u',
              nomeColaborador: 'U',
              itens: [
                ItemVendaAtual(
                  idProduto: 'p',
                  nome: 'P',
                  quantidade: 1,
                  valorUnitario: 700,
                ),
              ],
              formasPagamento: [
                FormaPagamentoSelecionada(
                  codigo: a.codigo,
                  valor: a.valor,
                  financeiro: a,
                ),
                FormaPagamentoSelecionada(
                  codigo: b.codigo,
                  valor: b.valor,
                  financeiro: b,
                ),
              ],
            ),
          )
          .toJson();
  final partes = payload['recebimentosFinanceiros'] as List;
  check(partes.length == 2, 'Mesma forma perdeu a separação entre maquininhas');
  check(
    partes[0]['contaFinanceiraId'] == 'conta-a' &&
        partes[1]['contaFinanceiraId'] == 'conta-b',
    'Contas foram agrupadas',
  );
  check(
    partes[0]['taxa'] == 12 && partes[0]['dataPrevista'] == '2026-10-10',
    'Previsão ou taxa perdida',
  );
  final drafts = [DestinoRecebimentoDraft(a), DestinoRecebimentoDraft(b)];
  check(
    distribuicaoFinanceiraValida(drafts, [a, b]),
    'Divisão válida rejeitada',
  );
  drafts[0].valor = 401;
  check(!distribuicaoFinanceiraValida(drafts, [a, b]), 'Soma inválida aceita');
  drafts[0].valor = 400;
  drafts[0].taxa = 400;
  check(
    !distribuicaoFinanceiraValida(drafts, [a, b]),
    'Taxa igual ao bruto aceita',
  );
  drafts[0].taxa = 12;
  drafts[0].contaId = null;
  check(!distribuicaoFinanceiraValida(drafts, [a, b]), 'Conta ausente aceita');
  final other = DestinoRecebimentoDraft(
    const RecebimentoFormaInput(
      codigo: 'TIPO2',
      valor: 300,
      contaFinanceiraId: 'c',
    ),
  );
  check(
    !distribuicaoFinanceiraValida([DestinoRecebimentoDraft(a), other], [a, b]),
    'Troca de forma com mesmo total aceita',
  );
  final cash = DestinoRecebimentoDraft(const RecebimentoFormaInput(
    codigo: 'TIPO1', valor: 100, contaFinanceiraId: 'legada',
    maquininhaId: 'legada', taxa: 5, recebimentoFuturo: true,
    dataPrevista: '2026-10-10',
  ));
  cash.contaId = null;
  check(cash.valido, 'Dinheiro exigiu conta financeira');
  final cashInput = cash.toInput();
  check(cashInput.contaFinanceiraId == null && cashInput.maquininhaId == null,
      'Dinheiro manteve destino financeiro legado');
  check(cashInput.taxa == 0 && !cashInput.recebimentoFuturo && cashInput.dataPrevista == null,
      'Dinheiro manteve taxa ou previsão bancária');
  check(distribuicaoFinanceiraValida([cash, DestinoRecebimentoDraft(a)], [cash.origem, a]),
      'Pagamento misto válido rejeitado');
  print('$checks verificações de maquininhas passaram.');
}
