# Fase 2 — Compras persistentes (sem efeitos operacionais)

## Pré-condições verificadas em 29/10/2026
- Fase 1 mergeada: PR #324 (six-app) e #170 (sixBack), ambos em 17/10/2026.
- Nenhum PR aberto em nenhum repositório no instante da verificação.
- Implementação desta fase em branch nova derivada da main.

## Escopo
- Persistir compras em MongoDB `compras`, escopo imutável `idUnicoDaEmpresa`.
- Registrar snapshot de fornecedor compartilhado da conta do administrador, não permitir fornecedor de conta externa ou inativo.
- Armazenar itens e quantidades, custos, descontos, frete, documento, moeda, cotação, previsão de recebimento e condições financeiras previstas.
- Rascunho → confirmado/cancelado, com histórico auditável, `@Version` e IDs por UUID.
- Número sequencial de confirmação por empresa em `compras_sequencias`.
- A confirmação não movimenta estoque nem cria contas a pagar. As opções financeiras são somente previsão persistida até a Fase 3.
- Listas e cadastro Web usam API `/private/api/compras` e fornecedores/produtos reais. Protótipos de produtos fictícios e anexos simulados deixam de ser acionáveis.

## Contratos backend
Todos exigem JWT e `idUnicoDaEmpresa`:
- GET `/private/api/compras`: listagem por comércio
- GET `/private/api/compras/{id}`: detalhe por comércio
- POST `/private/api/compras`: novo rascunho
- PUT `/private/api/compras/{id}`: editar rascunho
- POST `/private/api/compras/{id}/confirmar`: confirmar com validações
- POST `/private/api/compras/{id}/cancelar`: cancelar com motivo
- GET `/private/api/compras/acesso`: permissões por comércio

Permissões: `COMPRAS_CONSULTAR`, `COMPRAS_CRIAR`, `COMPRAS_EDITAR`, `COMPRAS_CONFIRMAR`, `COMPRAS_CANCELAR`, além de administradores.

## Invariantes
- Nunca confiar no ID da empresa do payload; derivar exclusivamente do header autenticado e validar vínculo.
- Somente pedidos no mesmo comércio aparecem na consulta; fornecedores podem ser compartilhados na mesma conta.
- Rascunhos incompletos podem ser salvos; confirmação exige fornecedor, documento, itens e total positivo.
- Custo e total calculados no servidor e nunca aceitos do cliente.
- Produtos estocáveis requerem ID existente na empresa compradora. O estoque ainda não é movimentado.
- Confirmação repetida de compra confirmada retorna o mesmo documento, sem criar novos efeitos.
- Cancelamento conserva histórico e justificativa.
- Sem anexos fictícios persistidos.
- Moeda estrangeira exige moeda contábil e cotação explícita; não atualizar automaticamente taxas históricas.

## Próximas fases
Fase 3 gerará títulos a pagar na confirmação com Outbox/idempotência e reconciliação. Fase 4 registrará entradas somente no recebimento físico, inclusive parcial, com estornos auditáveis.

## Validação
- Testes Java e Flutter criados, mas ainda precisam ser executados em ambiente Maven/Flutter configurado.
- Testar concorrência de confirmação/edição e trocas de empresa em Web/Mobile.
- Testar MongoDB `@Version`, índices e sequência em ambiente de homologação.
- Confirmar controle de permissões por colaborador antes de disponibilizar o menu a não administradores.
