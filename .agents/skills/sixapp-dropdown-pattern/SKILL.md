---
name: sixapp-dropdown-pattern
description: Use quando o pedido mencionar ajustar dropdown, select, seletor, combobox, menu de opções, filtro com seleção única ou multi-seleção no SixApp. Se o usuário pedir para "ajustar o dropdown" sem outro padrão explícito, aplique o padrão oficial descrito nesta própria skill. Para Web, use trigger compacto com label e valor, ícone à esquerda, chevron animado, hover/aberto com destaque sutil e menu customizado ancorado ao campo. Para Mobile, preserve a regra mobile-first com campo clicável + bottom sheet, sem reutilizar a árvore visual Web. Combine com `sixapp-web-ui`, `sixapp-mobile-ui` e `sixapp-regionalization` quando houver impacto correspondente.
---

# Dropdowns do SixApp

Esta Skill define o padrão default para pedidos de ajuste de dropdown no SixApp.

Se o usuário disser apenas algo como "ajustar o dropdown", "melhorar esse select", "trocar esse dropdown" ou equivalente, trate como instrução para aplicar o padrão visual e comportamental descrito nesta Skill, sem inventar uma nova variação.

## Padrão oficial

Para Web, o dropdown default do SixApp deve ter:

- trigger compacto com duas linhas:
  - label pequena acima;
  - valor selecionado em destaque abaixo;
- ícone semântico à esquerda;
- chevron à direita com rotação curta ao abrir;
- área clicável inteira, não apenas o ícone;
- cantos entre 16 e 18;
- altura compacta, sem aparência de campo de formulário genérico;
- `AnimatedContainer` para transição de hover, foco visual e estado aberto;
- borda sutil no estado normal;
- fundo levemente destacado e sombra discreta no hover ou aberto;
- valor e itens com `TextOverflow.ellipsis`;
- `Tooltip` e `Semantics` preservados;
- menu aberto logo abaixo do trigger;
- menu com largura alinhada ao trigger;
- menu com fundo, borda e elevação coerentes com o design system Web;
- item selecionado com fundo destacado e ícone de confirmação;
- item não selecionado com ícone neutro/direcional;
- multi-seleção com ações explícitas como `Cancelar`, `Limpar` e `Aplicar` quando necessário.

Para Mobile, o dropdown default do SixApp deve ter:

- campo visual read-only/clicável;
- hierarquia clara entre label e valor;
- ícone semântico quando fizer sentido;
- abertura em `showModalBottomSheet`;
- `SafeArea`, cantos superiores arredondados e fechamento previsível;
- lista confortável, com busca local quando a lista for média ou grande;
- confirmação explícita em multi-seleção, período ou filtro composto;
- preservação do valor original até a confirmação quando a troca não for imediata;
- sem copiar popup, layout ou árvore visual Web.

## Origem do padrão

O padrão nasceu da Agenda Financeira, mas esta Skill já deve ser suficiente sozinha. Leia a implementação de origem apenas se precisar conferir detalhe fino de comportamento ou reaproveitar componente já existente.

## Leituras mínimas

Antes de editar:

- `AGENTS.md`;
- o arquivo alvo;
- uma implementação semelhante na mesma plataforma;
- `sixapp-web-ui` quando o alvo for Web;
- `sixapp-mobile-ui` quando o alvo for Mobile;
- `sixapp-regionalization` quando houver texto visível, moeda, data, número ou percentual.

## Fluxo obrigatório

1. Identifique a plataforma real do alvo: Web ou Mobile.
2. Se o pedido for genérico e o alvo for Web, aplique o padrão oficial descrito nesta Skill.
3. Se o pedido for genérico e o alvo for Mobile, não use `DropdownButtonFormField` cru e não copie a árvore visual Web; use campo clicável + `showModalBottomSheet`, mantendo a linguagem do SixApp.
4. Procure primeiro se já existe componente reutilizável adequado antes de criar mais uma versão local.
5. Se o mesmo padrão for necessário em mais de uma tela Web, extraia componente reutilizável em vez de duplicar o bloco inteiro.
6. Preserve contratos, services, providers e regras de negócio existentes.
7. Não transformar ajuste de dropdown em refatoração ampla.

## Regra objetiva para Web

Quando o alvo for Web, o dropdown deve seguir esta especificação como default:

- `InkWell` ou superfície clicável equivalente;
- `AnimatedContainer` para estado normal, hover e aberto;
- raio entre 16 e 18;
- label pequena e valor forte;
- ícone à esquerda e chevron à direita;
- `showMenu` posicionado a partir do `RenderBox` do trigger;
- menu com fundo, borda e elevação consistentes com tokens Web;
- item selecionado destacado visualmente;
- largura consistente com o trigger;
- multi-seleção com ações explícitas como `Cancelar`, `Limpar` e `Aplicar` quando aplicável.

Evite como solução final em Web importante:

- `DropdownButtonFormField` cru;
- `DropdownMenu` padrão sem customização;
- popup desalinhado com o trigger;
- menu sem estado visual claro para item selecionado;
- texto truncando sem `ellipsis`;
- variação nova quando a tela pode usar o padrão oficial desta Skill.

## Regra objetiva para Mobile

Quando o alvo for Mobile:

- preserve a regra mobile-first do projeto;
- use campo visual read-only/clicável;
- abra seleção em `showModalBottomSheet`;
- mantenha `SafeArea`, cantos superiores arredondados e fechamento previsível;
- use busca local quando a lista for média ou grande;
- preserve o estado original até confirmação quando houver multi-seleção, período ou filtro composto.

Se o usuário pedir explicitamente o "modelo da Agenda Financeira" para Mobile, interprete isso como:

- mesma hierarquia visual de label, valor e ícone no campo de entrada, quando fizer sentido;
- mesma sobriedade visual;
- não reutilizar popup Web dentro de Mobile, salvo pedido explícito em sentido contrário.

## Extração e reutilização

Extraia componente reutilizável quando houver repetição clara em mais de um ponto da plataforma:

- Web: componente de dropdown/filtro customizado;
- Mobile: selector tile + bottom sheet específico ou genérico.

Não crie componente compartilhado de tela inteira entre Web e Mobile.

## Validação antes de finalizar

- `dart format` nos arquivos alterados;
- `git diff --check`;
- revisar `git diff`;
- confirmar ausência de impacto indevido na outra plataforma;
- confirmar que textos continuam compatíveis com i18n/regionalização;
- confirmar que o dropdown final está visualmente alinhado com o padrão oficial desta Skill quando o alvo for Web.
