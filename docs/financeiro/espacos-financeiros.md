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
- Cada confirmação guarda a conta no histórico. Uma confirmação com várias formas utiliza a mesma conta; contas distintas exigem confirmações parciais distintas.
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
