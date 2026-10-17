# Próxima etapa — Fornecedores com Compras, Estoque e Agenda Financeira

## Situação de partida
- Cadastro, listagem, consulta e edição/inativação na API `/private/api/fornecedores`.
- Frontend Web/Mobile compartilha contrato; dados persistidos por `idUnicoDaEmpresa`.
- Compras Web ainda é um protótipo em memória (`_ComprasDemoStore`).
- Movimentações de estoque e Agenda Financeira já possuem APIs próprias. Nenhuma integração com o novo cadastro foi conectada nesta entrega.

## Plano técnico sugerido
1. **Contrato e permissões**: definir quem pode consultar/editar fornecedores, identidade por comércio e estados ativo/inativo. Incluir contratos API versionados e índices Mongo com estratégia de migração dos documentos legados.
2. **Compras**: substituir `_FornecedorDemo` pelo cadastro real; consultar fornecedores ativos, permitir cadastro rápido via mesmo serviço; registrar `fornecedorId`, snapshot de nome/documento e histórico por comércio. Criar API de compra persistente e estados rascunho, confirmada, cancelada.
3. **Estoque**: ao receber itens da compra confirmada, emitir operação idempotente de entrada vinculada à compra e aos itens; controlar custo unitário, frete, desconto e impostos; impedir duplicação em reprocessamentos. Não movimentar por mero rascunho.
4. **Agenda Financeira**: gerar títulos a pagar apenas na transição definida pelo negócio (compra confirmada ou mercadoria recebida); vincular `fornecedorId`, `compraId`, parcelamento e referência fiscal; reaproveitar espaços financeiros, contas e mecanismos de liquidação já existentes.
5. **Estornos/retornos**: desenhar cancelamento e devoluções com lançamento compensatório/estorno rastreável, em vez de apagar movimentações ou pagamentos.
6. **Qualidade**: testes de integração multicomércio, autorização, concorrência, compras parceladas, idempotência, devoluções, moeda e separação Empresa/Pessoal; jornada E2E em Web e Mobile.

## Dúvidas de negócio a decidir antes da etapa
1. **Fornecedor compartilhado?** Um fornecedor cadastrado em um comércio deve ser visível aos outros comércios do mesmo administrador, ou exclusivamente ao comércio atual? O cadastro atual usa isolamento por comércio.
2. **Momento da entrada e da dívida**: confirmar compra já aumenta estoque e gera contas a pagar, ou ambas ocorrem somente no recebimento de mercadoria/NF? Recomendo separar pedido, recebimento e financeiro.
3. **Compras parciais e pagamentos**: uma compra poderá chegar em remessas parciais, com notas diferentes e vencimentos parcelados? Recomendo sim.
4. **Permissões e identidade**: colaboradores que podem gerenciar clientes também poderão gerenciar fornecedores, ou haverá permissões próprias de leitura, cadastro e edição? Hoje a navegação Web reutiliza a permissão de clientes; o backend protege por vínculo com empresa.
5. **Globalização fiscal**: CPF/CNPJ, VAT/Tax ID, países, moedas e impostos serão campos regionais adaptados à empresa? O cadastro aceita documento livre; a integração fiscal exige regras específicas.

## Limites da entrega atual
- Não há exclusão física; fornecedor pode ser inativado para preservar referência histórica.
- Unicidade de documento é validada no serviço dentro de um comércio; reforçar a proteção contra gravações simultâneas com índice/migração.
- Antes de disponibilizar globalmente, extrair novas mensagens de fornecedores para PT/EN/ES e revisar a permissão específica.
- Esta etapa não altera o módulo Compras nem os lançamentos financeiros/estoque.
