---
name: sixapp-web-colors
description: >
  Use quando o pedido mencionar cor, cores, dark mode, contraste, fundo,
  background, surface, modal web muito homogêneo, card sem hierarquia visual,
  input com fill incorreto, borda fraca, texto com contraste ruim ou qualquer
  correção de paleta na versão Flutter Web do SixApp. Aplique
  `WebThemeTokens`, preserve a hierarquia entre `surface`, `surfaceMuted`,
  `surfaceElevated`, `inputBackground` e estados selecionados, elimine
  hardcodes incompatíveis com dark mode e valide com teste web relacionado.
---

# SixApp - Cores web

Use esta skill para corrigir inconsistências de cor na experiência web do SixApp sem alterar a versão mobile.

## Acione esta skill quando o pedido envolver

- dark mode web com telas, modais ou subpainéis no mesmo tom;
- cards, inputs, dropdowns, chips, badges ou rodapés sem separação visual;
- AppBar, título, ações ou ícones com contraste ruim no web;
- `showDialog`, side sheet ou subpainel com `surface` incorreta;
- tela web misturando `Colors.white`, hex fixos ou blocos locais fora do padrão;
- revisão de paleta, contraste e superfícies em páginas, modais e componentes web.

## Leituras mínimas

Leia nesta ordem:

1. `AGENTS.md`;
2. `lib/presentation/theme/web_theme_tokens.dart`;
3. `lib/design_system/helpers/six_theme_resolver.dart`, se a tela depender do tema global;
4. a tela, componente, modal ou subpainel alvo;
5. uma implementação web semelhante já estável;
6. um teste web dark mode semelhante já existente no projeto.

Use também `sixapp-web-ui` quando a correção afetar composição visual, cabeçalho, estrutura de modal, layout, responsividade ou ergonomia além das cores.

## Regras obrigatórias

- Não altere arquivos mobile quando o pedido for web.
- Não crie tema global novo para corrigir uma única tela.
- Para superfícies, bordas, textos, feedbacks e destaques, prefira `WebThemeTokens.of(context)` e `Theme.of(context).colorScheme`.
- Em temas locais de modal/subpainel, preserve hierarquia clara entre shell externo, cards internos, inputs e estados selecionados.
- Não mantenha `Colors.white`, `Color(0xFFF...)`, `Color(0xFFE...)`, `Color(0xFF0...)` e similares em cards, modais, inputs, chips, tooltips, dropdowns ou rodapés se houver equivalente semântico.
- Não use o mesmo token de superfície para frame externo e conteúdo principal quando isso achatar a leitura visual.
- Preserve acentos sem exagero; destaque deve reforçar seleção, foco, progresso, erro ou ação primária, não pintar a tela inteira.
- Quando a tela criar um tema local com `copyWith`, revise `surface`, `surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest`, `outline`, `outlineVariant`, `onSurface` e `onSurfaceVariant`.

## Padrão obrigatório para textfields

- Em formulários web dentro de cards, modais e subpainéis, o `fillColor` de `TextField` e `TextFormField` deve sair de `tokens.inputBackground`, não de `surface` do card.
- `labelStyle` deve usar `tokens.secondaryText`; `floatingLabelStyle` deve usar `tokens.info` ou acento equivalente do fluxo.
- `hintStyle` deve usar `tokens.mutedText`.
- `enabledBorder` deve usar `tokens.cardBorder`.
- `focusedBorder` deve usar `tokens.selectedBorder` ou `tokens.info`, com espessura levemente reforçada.
- `errorBorder` e `focusedErrorBorder` devem usar `tokens.danger`.
- Quando houver ícones de prefixo/sufixo, alinhe `prefixIconColor` e `suffixIconColor` com `tokens.secondaryText`, elevando para `tokens.info` apenas em foco ou seleção quando isso já for padrão local.

## Padrão obrigatório para dropdowns e menus

- O trigger fechado do dropdown deve usar a mesma família visual dos inputs: `tokens.inputBackground` como base, não `surface` do card.
- O trigger em hover ou aberto pode subir para `tokens.surfaceMuted` no light mode e `tokens.surfaceElevated` no dark mode, preservando contraste contra o card pai.
- A borda padrão do trigger deve usar `tokens.cardBorder`; aberto, hover forte ou selecionado deve usar `tokens.selectedBorder`.
- Label do trigger deve usar `tokens.secondaryText`; valor selecionado deve usar `tokens.primaryText`; placeholder deve permanecer em `tokens.secondaryText` ou `tokens.mutedText`.
- Ícone do trigger e chevron devem usar `tokens.secondaryText` em repouso e `tokens.info` quando aberto/ativo.
- Menus de `showMenu` e popups devem usar `tokens.menuBackground` no light mode e `tokens.surfaceElevated` no dark mode.
- O item selecionado no menu deve usar `tokens.selectedBackground` e `tokens.selectedBorder`, evitando alpha arbitrário espalhado por tela.
- O ícone de item selecionado deve usar `tokens.info`; itens não selecionados devem usar `tokens.mutedText`.

## Mapeamento rápido de tokens

- fundo da workspace: `tokens.workspaceBackground`
- fundo de header/sidebar: `tokens.headerBackground`, `tokens.sidebarBackground`
- card/base principal: `tokens.surface` ou `tokens.cardBackground`
- shell elevado, modal ou folha superior: `tokens.surfaceElevated`
- superfície suave/interna: `tokens.surfaceMuted`
- input fill: `tokens.inputBackground`
- menu e popup: `tokens.menuBackground`
- divisória: `tokens.divider`
- hover: `tokens.hoverBackground`
- seleção: `tokens.selectedBackground` e `tokens.selectedBorder`
- texto forte: `tokens.primaryText`
- texto secundário: `tokens.secondaryText`
- texto de apoio: `tokens.mutedText`
- destaque informativo: `tokens.info`
- sucesso: `tokens.success`
- atenção: `tokens.warning`
- erro: `tokens.danger`
- desabilitado: `tokens.disabledBackground` e `tokens.disabledForeground`

## Fluxo de correção

1. Identifique onde a hierarquia de superfícies foi perdida.
2. Separe shell externo, conteúdo principal, blocos suaves, inputs e estados selecionados.
3. Em textfields, confirme diferença perceptível entre card pai e `inputBackground`.
4. Em dropdowns, confirme coerência entre trigger fechado, trigger aberto e menu de opções.
5. Substitua hardcodes por `WebThemeTokens` e `colorScheme`.
6. Revise contraste de textos, ícones, bordas, chips, botões, dropdowns e ações.
7. Revise `showDialog`, `showMenu`, side sheet, tooltip e barra inferior da mesma jornada se compartilharem o problema.
8. Atualize ou adicione teste web relacionado para proteger os tokens esperados.
9. Execute `dart format`, `git diff --check` e ao menos o teste alterado.

## Sinais de implementação correta

- o shell do modal/subpainel usa `surfaceElevated` e o conteúdo interno não repete a mesma superfície sem necessidade;
- cards, blocos de progresso, filtros, inputs e rodapés têm níveis visuais distinguíveis;
- textfields usam `inputBackground`, label/hint coerentes e borda de foco destacada;
- dropdowns usam trigger separado do card, menu coerente com o tema e item selecionado com `selectedBackground`;
- seleção usa `selectedBackground` e `selectedBorder` em vez de alpha arbitrário espalhado;
- texto, ícones e ações mantêm contraste em dark e light mode;
- dropdowns, menus e tooltips seguem a paleta web existente;
- a versão mobile permanece intacta.
