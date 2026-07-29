# Design System mobile do SixApp

Use esta referência em tarefas visuais mobile quando precisar consultar tokens, shell, motion, Lottie, separação web/mobile e riscos de impacto global.

## Arquitetura visual mobile atual

O mobile usa a mesma base Flutter do web, mas a experiência visual mobile tem peças próprias:

- `SixMobilePalette`: cores mobile oficiais;
- `SixMobileTypography`: tipografia mobile aplicada por `ThemeProvider` quando `!kIsWeb`;
- `SixMobilePageShell`: shell de tela mobile com AppBar, fundo, blur, status bar e `topInset`;
- `MobileMainShell`: shell de navegação mobile com `IndexedStack`;
- `NavBarMobile`: navegação inferior principal;
- `mobile_motion.dart`: entrada progressiva, número animado e badge pulsante;
- `SixMobileAnimatedGradientBackground`: fundo ambiente animado do shell;
- componentes Lottie/loading reutilizáveis.

O tema global (`AppTheme`, `ThemeProvider`, `SixThemeResolver`) é compartilhado entre web e mobile. Alterá-lo pode afetar Flutter Web.

## Tokens de `SixMobilePalette`

| Token | Finalidade |
|---|---|
| `primary` | Identidade principal mobile, AppBar/hero escuros e textos ativos de navegação. |
| `secondary` | Apoio visual, fundos ou elementos secundários. |
| `accent` | Ação principal, ícones ativos, FABs, destaques e feedback positivo de interação. |
| `background` | Fundo base de telas mobile. |
| `surface` | Cards, bottom nav, bottom sheets e superfícies principais. |
| `border` | Bordas padrão de cards, navegação e inputs visuais. |
| `softAccentSurface` | Fundo sutil para estado ativo/acento. |
| `softNeutralSurface` | Fundo neutro de blocos e áreas internas. |
| `titleText` | Títulos e textos de alta hierarquia. |
| `mutedText` | Subtítulos, descrições e metadados. |
| `onPrimary` | Conteúdo sobre fundos escuros ou acentuados. |
| `heroSupportingText` | Texto auxiliar sobre hero escuro. |
| `heroLabelText` | Labels discretos sobre hero escuro. |
| `notificationBadge` | Badge de notificações. |
| `activeBorder` | Borda ativa discreta. |
| `highlightedBorder` | Borda destacada. |
| `error` | Texto/ícone de erro. |
| `errorBorder` | Borda de erro. |
| `heroShadow` | Sombra ligada a hero. |
| `navigationShadow` | Sombra da navegação inferior. |

Regra: use o token mesmo quando a cor local tiver o mesmo hexadecimal.

## Exemplos de cor

Incorreto:

```dart
static const Color _accentColor = Color(0xFF2563EB);
```

Correto:

```dart
static const Color _accentColor = SixMobilePalette.accent;
```

Incorreto:

```dart
Container(color: Colors.white)
```

Correto, quando for superfície mobile:

```dart
Container(color: SixMobilePalette.surface)
```

## Novos tokens

Antes de criar token:

1. confirme que o uso não é local ou temporário;
2. procure usos equivalentes no mobile;
3. evite sinônimos visuais de tokens existentes;
4. nomeie pela finalidade, não pela aparência;
5. explique por que tokens existentes não atendem.

Evite nomes como `blue1`, `darkBlue`, `cardColor`, `myColor`. Prefira nomes semânticos como `selectionSurface`, `criticalBorder` ou `pendingBackground`, quando forem realmente reutilizáveis.

Tokens genéricos e reutilizáveis devem ir preferencialmente em `SixMobilePalette`. Tokens exclusivos de componente complexo podem viver em uma classe de tokens do componente derivada da paleta.

## `SixMobilePageShell`

Avalie este shell para telas principais mobile com AppBar e corpo rolável.

Ele entrega:

- `Scaffold` com `extendBodyBehindAppBar`;
- AppBar transparente com contraste calculado;
- `SystemUiOverlayStyle` coerente;
- blur e superfície no topo durante scroll;
- cálculo de `topInset`;
- `ScrollController` interno ou externo;
- fundo via `SixMobileAnimatedGradientBackground`;
- suporte a drawer, leading, actions e `bottomNavigationBar`.

Use `backgroundColor`, `primaryColor`, `secondaryColor` e `accentColor` com `SixMobilePalette`. Se a tela precisar de `Scaffold` próprio, justifique o motivo.

## AppBar e status bar

Checklist para AppBar mobile:

- contraste entre fundo, título e ícones;
- `SystemUiOverlayStyle` coerente com o fundo real;
- `SafeArea` e notch considerados;
- ações com `tooltip`/semântica;
- texto não estoura com escala de fonte;
- comportamento claro sobre fundos transparentes, claros, escuros ou animados.

Evite `foregroundColor: Colors.white` sobre AppBar transparente quando o conteúdo atrás é claro. `SixMobilePageShell` já calcula contraste usando o fundo efetivo.

## `NavBarMobile`

Navegação inferior principal mobile:

- três destinos atuais: `Gestão`, `Início`, `Atendimento`;
- usa `MobileNavigationScope` quando disponível;
- faz `pushReplacement` quando usada sem controller;
- tokens: `surface`, `border`, `navigationShadow`, `softAccentSurface`, `accent`, `mutedText`, `primary`;
- `_NavItem` privado usa `Semantics`.

Não crie segunda navegação inferior paralela sem necessidade comprovada. Não copie navegação web para mobile.

## Cards, estados vazios, FABs e botões

Cards:

- use `SixMobilePalette.surface`, `border`, textos e sombras da paleta;
- mantenha raios e espaçamento compatíveis com telas existentes;
- use `TextOverflow.ellipsis`, `maxLines`, `Expanded`, `Flexible`, `Wrap`, `LayoutBuilder` conforme necessário;
- gradientes e sombras devem comunicar hierarquia, agrupamento ou feedback, não decoração.

Estados vazios:

- explique o estado e a próxima ação;
- mantenha CTA claro;
- evite duplicar CTA de conteúdo e FAB;
- confirme como o estado muda após o primeiro item;
- use ícone/animação só se ajudar a compreensão.

FAB:

- use `SixMobilePalette.accent`;
- avalie se há ação primária duplicada;
- esconda ou altere por estado quando deixar de ser útil;
- preserve ergonomia e fluxo de toque.

Botões:

- use temas/componentes existentes;
- mantenha hierarquia primária/secundária;
- trate loading, disabled e erro;
- não mude regra de negócio por decisão visual.

## Motion e animações

Preferir:

- `SixStaggeredEntry` para entrada com fade + leve deslocamento;
- `SixAnimatedNumberText` para contagens simples;
- `SixPulsingBadge` para badge com novidade;
- `AnimatedSwitcher`, `AnimatedContainer`, `AnimatedScale`;
- `FadeTransition`, `SlideTransition`, `TweenAnimationBuilder`;
- `flutter_animate` quando já estiver no padrão da tela;
- `SixMobileAnimatedGradientBackground` para fundo do shell.

Princípios:

- movimento comunica estado, prioridade, descoberta ou feedback;
- durações curtas e curvas suaves;
- evite múltiplas animações concorrentes;
- evite loops contínuos cansativos;
- respeite `MediaQuery.disableAnimations` para animações contínuas ou ambiente animado.

## Lottie e loading

Dependências atuais:

- `lottie: ^1.4.0`;
- `flutter_animate: ^4.2.0`;
- Rive e `animations` package não estão no `pubspec.yaml`.

Assets centralizados:

- `SixAnimationAssets.saleProcessing`;
- `SixAnimationAssets.productCatalogLoading`.

Componentes:

- `SixLottieActionOverlay`: bloqueia ação assíncrona com blur, `AnimatedSwitcher`, `Lottie.asset`, `Semantics(liveRegion: true)`;
- `SixFullScreenLottieLoading`: loading full screen com `AbsorbPointer`, `AnimatedSwitcher`, `Semantics`;
- `SixBackendLoading`: loading de mensagens/eventos do backend com `skeletonPulse`, `waveDots` ou `progressSweep`.

Registre novos JSONs em `assets/animations/`, atualize `pubspec.yaml` somente se necessário e autorizado, e centralize nomes em `SixAnimationAssets`. Não use Lottie como decoração sem significado.

## Bottom sheets e seletores

Siga `docs/ui/mobile-first-patterns.md`.

Para seleção mobile:

- preferir campo read-only/clicável + `showModalBottomSheet`;
- usar busca para listas médias/grandes;
- `backgroundColor: Colors.transparent`;
- `useSafeArea: true`;
- `isScrollControlled: true` quando necessário;
- `DraggableScrollableSheet` para lista/calendário;
- handle, título claro, seleção destacada, estado vazio e fechamento previsível;
- pt-BR ou `AppLocalizations`.

Evite `DropdownButtonFormField`, `DropdownMenu`, `showDatePicker` e dialogs grandes quando destoarem da experiência customizada.

## Separação mobile/web

Seguro para mudanças somente mobile:

- arquivos `*_mobile_screen.dart`;
- `lib/presentation/components/mobile/`;
- `lib/presentation/components/mobile_motion.dart`;
- `lib/presentation/components/nav_bar_mobile.dart`;
- `lib/design_system/themes/six_mobile_palette.dart`, quando novo token mobile for reutilizável;
- `lib/design_system/themes/six_mobile_typography.dart`, quando for tipografia mobile.

Alto risco para tarefa somente mobile:

- `lib/design_system/themes/app_theme.dart`;
- `lib/providers/theme_provider.dart`;
- `lib/design_system/helpers/six_theme_resolver.dart`;
- `lib/main.dart`;
- `PaginaPrincipalWeb`;
- arquivos `*_web.dart`, `*_web_page.dart`, `*_web_dialog.dart`;
- `PdvVisualThemeResolver`.

## PDV mobile como alerta

O PDV mobile (`pdv_mobile_screen_base.dart`) é exemplo de tela que não deve continuar como ilha visual: possui cores locais próximas aos tokens mobile, AppBar transparente com foreground branco sobre fundo claro e FAB hardcoded por valor. Uma futura reformulação deve aproximá-lo de `SixMobilePalette`, `SixMobilePageShell`, padrões de estado vazio e CTA/FAB sem afetar o PDV web.
