# Padrões mobile-first do SixApp

Este documento define padrões obrigatórios para telas mobile do SixApp.

## Princípio principal

A versão mobile não deve ser apenas uma adaptação visual da web. Ela deve ter componentes, transições e fluxos adequados ao uso com toque, tela pequena e contexto operacional rápido.

O layout mobile deve transmitir:

- fluidez;
- clareza;
- estabilidade visual;
- aparência premium;
- baixa fricção;
- consistência com a identidade do Six.

## Seletores de entidade

Entidades como cliente, fornecedor, produto, serviço, colaborador, técnico, categoria e forma de pagamento não devem usar dropdown padrão quando a lista puder crescer ou quando a abertura da lista quebrar o card atual.

### Padrão recomendado

Usar campo read-only/clicável na tela principal e abrir a seleção em Bottom Sheet.

O campo deve conter:

- label;
- ícone à esquerda;
- valor selecionado ou placeholder;
- ícone de ação à direita;
- aparência de input do sistema.

O Bottom Sheet deve conter:

- handle superior;
- título claro;
- campo de busca;
- lista confortável;
- destaque do item selecionado;
- estado vazio elegante;
- fechamento ao selecionar.

## Seletores de data

Evitar uso direto de `showDatePicker` padrão em telas mobile com layout customizado.

### Padrão recomendado

Usar Bottom Sheet customizado com:

- título;
- data selecionada em formato brasileiro;
- dia da semana;
- atalhos rápidos;
- calendário compacto;
- ação de aplicar;
- ação de cancelar.

A data original só deve ser alterada após confirmação do usuário.

## Bottom Sheets

Bottom Sheets mobile devem seguir este padrão:

- `showModalBottomSheet`;
- `isScrollControlled: true` quando necessário;
- `backgroundColor: Colors.transparent`;
- `useSafeArea: true`;
- `barrierColor` escuro e suave;
- cantos superiores arredondados;
- altura proporcional ao conteúdo;
- `DraggableScrollableSheet` quando houver lista ou calendário;
- nada deve deslocar ou quebrar a tela de fundo.

## Estados vazios

Sempre que uma busca ou lista não tiver resultado, exibir estado vazio com:

- ícone discreto;
- título curto;
- texto auxiliar objetivo;
- sem ocupar espaço exagerado.

## Idioma

Todos os textos visíveis ao usuário devem estar em pt-BR, salvo telas já internacionalizadas por mecanismo próprio.

Evitar textos nativos em inglês vindos de componentes padrão, como:

- Cancel;
- OK;
- Tue, Jul 14;
- Search;
- No results.

## Reutilização

Antes de implementar um seletor novo, verificar se já existe componente equivalente.

Preferir componentes genéricos e reutilizáveis quando possível:

- `EntitySelectorMobileBottomSheet`;
- `DateSelectorMobileBottomSheet`;
- `QuickActionBottomSheet`;
- `MobileSearchableSelector`.

Evitar duplicação de lógica visual dentro de telas grandes.

## Checklist de aceite mobile

Uma implementação mobile só deve ser considerada pronta se:

- respeita o layout mobile-first;
- não usa componente padrão com aparência desalinhada;
- não quebra cards durante interações;
- não reutiliza tela web indevidamente;
- mantém regra de negócio original;
- usa componentes reutilizáveis quando aplicável;
- está formatada com `dart format`;
- possui diff claro.