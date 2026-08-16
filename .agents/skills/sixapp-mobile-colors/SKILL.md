---
name: sixapp-mobile-colors
description: >
  Use quando o pedido mencionar cor, cores, dark mode, modo escuro, contraste,
  fundo, background, surface, card claro no mobile, AppBar mobile ilegível,
  bottom sheet com cor errada, input com fill incorreto ou qualquer correção
  visual de paleta na versão mobile do SixApp. Aplique os tokens de
  SixMobilePalette e SixMobileColorScheme, preserve SixMobilePageShell,
  elimine superfícies hardcoded incompatíveis com dark mode e valide com teste
  de widget quando a tela tiver risco de regressão.
---

# SixApp - Cores mobile

Use esta skill para corrigir inconsistências de cor na experiência mobile do SixApp sem alterar a versão web.

## Acione esta skill quando o pedido envolver

- fundo dark que não aplica direito;
- cards, inputs, chips ou badges claros demais no modo escuro;
- AppBar, título, ícones ou ações com contraste ruim;
- bottom sheet mobile com superfície errada;
- tela mobile misturando `Colors.white`, hex claros fixos ou gradientes locais fora do padrão;
- revisão de paleta, contraste e superfícies em `*_mobile_screen.dart` ou `lib/presentation/components/mobile/`.

## Leituras mínimas

Leia nesta ordem:

1. `AGENTS.md`;
2. `lib/design_system/themes/six_mobile_palette.dart`;
3. `lib/design_system/themes/six_mobile_color_scheme.dart`;
4. `lib/presentation/components/mobile/six_mobile_page_shell.dart`;
5. a tela ou componente alvo;
6. um teste mobile dark mode semelhante já existente no projeto.

Use também `sixapp-mobile-ui` quando a correção afetar composição visual, navegação, AppBar ou estados mobile além das cores.

## Regras obrigatórias

- Não altere arquivos web quando o pedido for mobile.
- Não crie tema global novo para corrigir uma única tela.
- Para superfícies, bordas, textos e acentos, prefira `context.sixMobileColors` dentro da tela.
- Use `SixMobilePalette` apenas quando o token precisar ser acessado fora do fluxo contextual ou quando já for o padrão local do componente.
- Não mantenha `Colors.white`, `Color(0xFFF...)`, `Color(0xFFE...)` e similares em cards, inputs, chips, empty states, handles, contadores ou sheets mobile se houver equivalente semântico.
- Preserve branco apenas quando ele for intencional sobre hero/gradiente escuro e com contraste claro.
- Não use `foregroundColor: Colors.white` em botão com `accent` dark quando `onAccent` existir.
- Para bottom sheets, prefira raiz em `surface` e campos internos em `softSurface` ou `surfaceElevated`, conforme hierarquia.

## Mapeamento rápido de tokens

- fundo da tela: `colors.background`
- card principal: `colors.surface`
- card elevado ou sheet interno: `colors.surfaceElevated`
- input fill neutro: `colors.softSurface`
- bloco/acento suave: `colors.softAccentSurface`
- superfície de ícone: `colors.iconSurface`
- borda padrão: `colors.border`
- borda mais forte/handle: `colors.strongBorder`
- destaque: `colors.accent`
- texto forte: `colors.titleText`
- texto secundário: `colors.mutedText`
- texto sobre accent: `colors.onAccent`
- erro: `colors.error` e `colors.errorBorder`

## Fluxo de correção

1. Identifique todos os hardcodes claros e separa o que é hero intencional do que é superfície indevida.
2. Verifique se a tela já usa `SixMobilePageShell`; se usar, mantenha shell, gradiente e status bar.
3. Substitua superfícies por tokens semânticos.
4. Revise contraste de textos, ícones, chips, botões e AppBar.
5. Revise bottom sheets, campos, handles e estados vazios da mesma jornada se compartilharem o problema.
6. Adicione ou atualize teste de widget dark mode para scaffold e superfícies principais.
7. Execute `dart format`, `git diff --check` e ao menos o teste relacionado alterado.

## Sinais de implementação correta

- `Scaffold` mobile usa `SixMobileColorScheme.dark.background` no dark mode;
- cards e containers de conteúdo não ficam brancos no dark mode;
- inputs e busca usam `softSurface` ou `surfaceElevated` coerentes;
- contadores, chips e badges não usam fundo claro fixo;
- hero pode continuar com branco apenas dentro do gradiente escuro;
- a versão web permanece intacta.
