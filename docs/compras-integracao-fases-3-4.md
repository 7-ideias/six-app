# Compras — Fases 3 + 4 integradas

## Regras confirmadas
- Compra confirmada → gera contas a pagar por parcela na Agenda Financeira do comércio (PostgreSQL), sem alteração imediata de estoque.
- Recebimento físico → registra só o produto recebido, total ou parcialmente, em movimentos vinculados no MongoDB.
- Financeiro e recebimento físico não são o mesmo evento. Uma compra pode estar paga e pendente de entrega.
- Somente fornecedores previamente autorizados no comércio podem estar vinculados.
- Moeda original e cotação explícita da compra são preservadas; títulos gerados em moeda contábil.
- Cancelamentos com estoque já recebido ou pagamento parcial/total exigem procedimento de estorno/compensação. Nenhum histórico é apagado.

## Persistência e idempotência
### Financeiro
- `integracaoFinanceiraStatus`: `PENDENTE`, `CONCLUIDA`, `ERRO`, `NAO_APLICAVEL`.
- Compra persistida como `CONFIRMADA` com estado `PENDENTE` antes de chamar a Agenda Financeira.
- Parcela identificada por UUID determinístico de compra+número.
- Índice parcial único no PostgreSQL: `V24__compra_parcela_idempotencia.sql`.
- Reconciliador periódico de pendências, com histórico e alerta em status. Compras antigas confirmadas com status nulo não são recriadas automaticamente.
- Cancelamento de títulos **não liquidados** marca a operação como `CANCELADA`. Se houver liquidação, retorno HTTP 409, exigindo regularização explícita.

### Estoque
- Novo `POST /private/api/compras/{id}/recebimentos` com `chaveIdempotencia`, lista de `itemId` e `quantidade` e observações.
- Compra reserva saldo solicitado com `@Version`, impedindo exceder quantidade contratada mesmo em solicitações simultâneas.
- Cada entrega é armazenada com status `PENDENTE`, `CONCLUIDO`, `ERRO`, usuário e horário.
- Serviço existente `MovimentacaoEstoqueService.registrarVinculada` grava origem `COMPRA` e ID de referência determinístico; consulta Mongo atômica impede repetição.
- Retry automático para entregas pendentes após queda de conexão; estoques/valores só confirmados após movimento efetivo.

## Implantação segura
1. Publicar somente após testes Java CI / Flutter Web build / validação Web e Mobile em homologação.
2. Aplicar Flyway V24 em PostgreSQL antes de expor a confirmação com integração.
3. Validar cenário de falha: PostgreSQL indisponível após confirmar compra; retry deve gerar parcelas sem duplicar.
4. Validar cenário de falha: entrada de estoque gravada e resposta perdida; retry deve retornar a mesma entrada, sem dupla movimentação.
5. Simular recebimentos parciais, cancelamentos após liquidação e troca de comércio.
6. Manter o usuário informado de status pendente/erro, sem afirmar que integrações não realizadas foram concluídas.
7. Não reprocessar automaticamente compras da Fase 2 anteriores a esta versão.
8. Aplicar backend antes do frontend; monitorar logs de reconciliadores.

## Pendências de maturidade operacional
- Estorno de uma compra com mercadoria recebida ou pagamento efetuado exige fluxo de devolução/compensação documentado, com autorização específica e auditoria; não é criado automaticamente por este PR.
- Custo do estoque usa custo unitário convertido por cotação; política fiscal detalhada de rateio de frete/tributos será refinada.
- Garantir que não sejam tratados como quitados títulos ainda sem baixa financeira.
