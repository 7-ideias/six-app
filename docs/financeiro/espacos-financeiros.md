# Espaços financeiros — primeira entrega

Branch: `feature/20261006-espacos-financeiros`.

## Escopo e acesso

O header `espacoFinanceiro` aceita `EMPRESA` (padrão compatível com clientes anteriores) ou `PESSOAL`.
O backend deriva o espaço pessoal exclusivamente do subject do JWT, sem aceitar outro titular no payload.
No espaço empresarial, valida vínculo e permissão financeira: consulta e escrita são avaliadas separadamente.
Cada espaço possui contas, categorias e centros de custos próprios. Categorias podem continuar sendo digitadas livremente no lançamento; o catálogo fornece sugestões do espaço.

## Dados e compatibilidade

A migration V22 preenche o espaço dos lançamentos, centros e séries existentes com a empresa atual.
Os registros pessoais têm `id_unico_da_empresa` nulo e uma chave de espaço própria. Consultas empresariais, e-mails existentes e integrações de vendas não selecionam esses registros.
Contas bancárias, carteiras e caixas são identificações manuais: não há integração bancária, conciliação automática ou reconstrução de saldo inicial.
Cadastros podem ser desativados, mantendo seus vínculos históricos. Não existe movimentação de lançamentos entre espaços.
O espaço pessoal é único por usuário; o seletor abre inicialmente em Empresa.

## API

- Rotas existentes de consulta, detalhe, criação, edição, liquidação, parcial e exclusão recebem o header do espaço.
- Centros continuam em `/private/api/agenda-financeira/centros-custo`, agora filtrados pelo espaço.
- GET/POST `/private/api/agenda-financeira/configuracoes/{grupo}` e PUT `/{id}`, grupos `CONTAS` e `CATEGORIAS`.
- Campos de configuração: `nome`, `instituicao` opcional, `tipo`, `ativo`.
- Tipos de conta: `BANCO`, `CARTEIRA`, `CAIXA`. Categorias: `RECEITA`, `DESPESA`, `AMBOS`.
- `contaFinanceiraId` no lançamento identifica a conta prevista. `atualizarContaFinanceira` permite limpar explicitamente a previsão sem apagar dados enviados por clientes anteriores.
- `contaFinanceiraId` na liquidação/parcial identifica a conta efetiva e é obrigatório para novas confirmações; a conta deve estar ativa e pertencer ao espaço.
- Cada confirmação guarda a conta no histórico. Lançamentos manuais mantêm uma conta por confirmação. Vendas podem informar conta e maquininha por parte do pagamento, inclusive repetindo a mesma forma.
- Recebimentos em banco/carteira não criam movimento no caixa operacional. Contas empresariais do tipo Caixa mantêm essa integração.
- As formas de recebimento do pessoal partem dos padrões do sistema, sem copiar nomes personalizados da empresa.

## Web e Mobile

Agenda → Pessoal/Empresa → ícone de contas para configurar o espaço.
Composições visuais separadas por plataforma, consumindo os mesmos serviços.
Os formulários oferecem conta prevista e sugestões de categorias próprias; na confirmação, solicita-se a conta efetiva.
A troca de espaço limpa os dados anteriores e recarrega a agenda e seus filtros.

## Publicação e validação

Publicar backend/migration e frontend de maneira coordenada: clientes antigos não enviam conta nas liquidações e receberão erro de validação após a nova exigência.
Não fazer rollback do schema eliminando colunas depois que houver dados pessoais.

Validações executadas: sintaxe Java 17, formatação/sintaxe Dart, diff e 40 verificações executáveis de contrato, recorrência, status, liquidação e centros de custos.
Testes adicionados: isolamento de titular, permissões de leitura/escrita, conta de outro espaço e tema escuro mobile.
Backend: `Maven Verify` passou no GitHub Actions (execução 37523411459, job build-test). A migration ainda precisa ser exercitada em banco de homologação. Flutter analyze/widget tests/build não executados: preparação das dependências bloqueada pela revisão automática do ambiente.

Antes do merge, validar em ambiente integrado:
1. Usuário A cria salário pessoal; usuário B e administradores de empresas não o consultam nem alteram por ID.
2. Trocar de empresa mantém o mesmo pessoal e muda somente o espaço empresarial.
3. Contas e centros de um espaço são rejeitados no outro.
4. Leitor financeiro consulta empresa, mas não altera configurações ou lançamentos.
5. Previsto sem conta; confirmação sem conta rejeitada; banco/carteira confirmam sem sessão de caixa.
6. Conta desativada permanece no histórico e não aceita novas confirmações.
7. Recorrência e edição/exclusão de futuras ocorrências preservam o espaço.
8. Cadastros empresariais antigos, vendas, relatórios e e-mails continuam sem dados pessoais.
9. Abrir Web e Mobile em tema claro/escuro; criar, editar, cancelar e tratar falha de rede.

Cartões de crédito, parcelas de fatura e pagamento de faturas ficam fora desta entrega.


## Pacote de maquininhas e recebíveis de vendas

- Configuração: Agenda → Empresa → configurações do espaço → Maquininhas. Cada cadastro guarda nome, operadora, conta padrão e ativo/inativo. Alterar o padrão não altera pagamentos existentes.
- Recebimento: PDV Web, PDV Mobile, vendas a receber e recebimento de venda pela agenda usam os mesmos DTOs financeiros. Uma etapa própria em cada plataforma informa conta, maquininha, taxa em valor e data prevista. A ação Dividir permite duas maquininhas na mesma forma, preservando os totais por código.
- A venda é quitada pelo valor bruto pago pelo cliente. O recebível acompanha separadamente o depósito líquido na conta. Confirmação bancária não cria uma segunda venda nem uma nova receita na operação.
- Cartão sugere recebimento futuro; previsão/taxa são manuais. Pix/dinheiro podem ser imediatos. Selecionar maquininha sugere sua conta padrão e previsão, que o operador revisa.
- Agenda → Empresa → Recebíveis de vendas abre os depósitos previstos, recebidos e cancelados. Confirmação registra data e valor efetivos. Estornar depósito volta a previsto sem reabrir dívida do cliente. Remover o pagamento na agenda cancela o recebível correspondente e reabre o saldo da venda. Cancelamento pelo caixa cancela os recebíveis vinculados.
- Conta do tipo Caixa exige sessão aberta e cria movimento físico. Banco/carteira não geram movimento físico de caixa.
- Histórico registra snapshots da conta/maquininha, bruto/taxa/líquido e transições do depósito, com usuário e horário. O código da venda é preservado para identificação sem UUID na UI.
- Dados anteriores permanecem no fluxo legado; não há backfill inventando contas, maquininhas, taxas ou datas desconhecidas.

### Contratos

- Grupo `MAQUININHAS` em `/private/api/agenda-financeira/configuracoes/{grupo}`; `tipo=MAQUININHA`, `instituicao` identifica operadora e `contaDestinoId` identifica conta padrão.
- `RecebimentoFormaInput`/`RecebimentoFormaRequest`: `codigo`, `descricao`, `valor`, `contaFinanceiraId`, `maquininhaId`, `recebimentoFuturo`, `dataPrevista`, `taxa`.
- Inserção de venda adiciona `recebimentosFinanceiros`, preservando `objRecebimentosList` para compatibilidade e validando que ambos somam os mesmos valores por forma.
- `GET /private/api/agenda-financeira/recebiveis-vendas`; `POST /{id}/confirmar` com `dataRecebimento` e `valorRecebido`; `POST /{id}/estornar`. Backend valida empresa e permissão financeira; ações de escrita usam locks e versão.
- V23 cria recebíveis e adiciona conta padrão da maquininha; publicar backend com V22/V23 e traduções antes do novo frontend.

### Validação do pacote

48 verificações Dart executadas (36 existentes + 4 de espaços + 8 de divisão/contrato). Sintaxe Java 17 e `dart format` aprovados. Adicionados 7 testes backend para previsão, taxas, conta padrão, isolamento, confirmação duplicada e estorno. Validar as migrations e os fluxos completos em homologação; Flutter analyze, widget tests e build não executados neste ambiente por falta das dependências já bloqueadas na etapa anterior.

Taxas automáticas, antecipação, agenda de parcelas da operadora, conciliação bancária e integração com adquirentes continuam fora deste pacote. A visão de recebíveis é separada dos totais brutos de vendas da agenda; não soma novamente esses valores à receita. Faturas dos cartões usados para compras pessoais/empresariais também ficam fora deste pacote.
