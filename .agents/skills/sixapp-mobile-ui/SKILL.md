---
name: sixapp-mobile-ui
description: Use ao criar, reformular ou revisar interfaces Flutter mobile do SixApp, especialmente telas `*_mobile_screen.dart`, componentes em `lib/presentation/components/mobile/`, AppBar mobile, cards, estados vazios, FABs, botões, navegação mobile, bottom sheets, Lottie, motion, contraste, status bar, acessibilidade e consistência com `SixMobilePalette`, `SixMobilePageShell` e `NavBarMobile`. Não use para tarefas exclusivamente backend, integrações de API sem mudança visual, mudanças apenas no Flutter Web, regras de negócio sem impacto de UI, banco de dados, refatorações técnicas puras ou documentação administrativa.
---

# UI mobile do SixApp

Use esta Skill para manter a experiência mobile Flutter do SixApp consistente, profissional e separada do Flutter Web.

Quando a tarefa visual mobile também envolver endpoint, contrato, parsing, autenticação, tenant, service ou ApiClient compartilhado, use também a Skill `sixapp-shared-backend-integration`. Esta Skill cuida da UI; a Skill de backend cuida da integração.

## Leituras mínimas

Para tarefa visual mobile, leia:

- `AGENTS.md`;
- `docs/ui/mobile-first-patterns.md`;
- `lib/design_system/themes/six_mobile_palette.dart`;
- `lib/presentation/components/mobile/six_mobile_page_shell.dart`;
- a tela ou componente alvo;
- a tela anterior do fluxo, para continuidade visual.

Leia `references/mobile-design-system.md` quando precisar consultar tokens, shell, motion, Lottie, separação mobile/web ou exemplos. Use `references/implementation-checklist.md` como checklist antes de finalizar.

## Fluxo obrigatório

1. Classifique o escopo: mobile, web, compartilhado, visual, funcional ou visual com backend.
2. Se o pedido for somente mobile, preserve arquivos web e evite tema global.
3. Antes de editar, informe os arquivos que pretende alterar e por que são seguros para mobile.
4. Reutilize `SixMobilePalette`, `SixMobilePageShell`, `NavBarMobile` e componentes mobile existentes antes de criar padrões novos.
5. Implemente com escopo mínimo, sem alterar regras de negócio, contratos de API, autenticação, permissões ou fluxos web.
6. Valide com `dart format <arquivos>`, `git diff --check`, `git diff` e, quando aplicável, `flutter analyze` e testes relacionados.
7. No relato final, informe arquivos alterados, tokens usados, motion aplicado, acessibilidade, validações e confirmação de ausência de impacto web.

## Escopo mobile

Para alterações solicitadas somente no mobile:

- não modifique `PaginaPrincipalWeb`;
- não modifique arquivos `*_web.dart`, `*_web_page.dart` ou `*_web_dialog.dart`;
- não modifique `PdvVisualThemeResolver`;
- não altere `AppTheme`, `ThemeProvider`, `SixThemeResolver` ou `main.dart` sem necessidade técnica comprovada e autorização explícita;
- prefira arquivos `*_mobile_screen.dart`, `lib/presentation/components/mobile/`, `NavBarMobile`, `mobile_motion.dart` e tokens mobile.

## Design System mobile

`SixMobilePalette` é a fonte principal de cores mobile. Não use cor hardcoded quando existir token semântico equivalente.

Incorreto:

```dart
const Color(0xFF2563EB)
```

Correto:

```dart
SixMobilePalette.accent
```

Mesmo que o valor hexadecimal seja igual, use o token para preservar intenção semântica.

Para novos tokens, confirme que o uso é reutilizável, procure usos equivalentes, evite sinônimos visuais, nomeie por finalidade e prefira `SixMobilePalette` somente quando o conceito for realmente mobile e reutilizável. Para componente complexo e específico, considere tokens de componente derivados da paleta mobile.

## Estrutura e navegação

Para telas principais mobile com AppBar e corpo rolável, avalie primeiro `SixMobilePageShell`; ele já trata AppBar consistente, contraste automático, status bar, blur no scroll, fundo animado, `topInset` e integração com `NavBarMobile`.

Não use o shell cegamente. Se a tela exigir `Scaffold` próprio, justifique.

Use `MobileMainShell`, `NavBarMobile` e padrões existentes de navegação mobile. Não copie navegação web nem crie segunda bottom navigation sem necessidade comprovada.

## AppBar, status bar e contraste

Toda AppBar mobile deve manter contraste suficiente, ícones legíveis, `SafeArea`, status bar coerente e labels/semântica nas ações. Evite `foregroundColor: Colors.white` em AppBar transparente quando o fundo real for claro. Verifique se `SixMobilePageShell` já resolve o caso.

## Padrão oficial de cabeçalho mobile

O padrão visual prioritário para cabeçalhos mobile do SixApp é o implementado por meio de `SixMobilePageShell` e dos tokens de `SixMobilePalette`.

A tela mobile de “Balcão de venda” pode ser utilizada como referência visual atual para:

- integração entre status bar e cabeçalho;
- fundo escuro com gradiente;
- contraste de título, botão de retorno e ações;
- altura e espaçamento do cabeçalho;
- transição visual entre cabeçalho e conteúdo;
- tratamento de `SafeArea`;
- comportamento de blur e scroll, quando aplicável.

A tela de referência serve para compreensão do resultado esperado, mas não deve ser usada como fonte de cópia indiscriminada de código.

### Migração de telas antigas

Ao criar, revisar ou reformular uma tela mobile, verifique se o cabeçalho utiliza algum padrão legado, como:

- AppBar com cor sólida independente;
- azul hardcoded;
- gradiente definido diretamente na tela;
- status bar com cor desconectada do cabeçalho;
- título ou ícones com contraste inadequado;
- `Scaffold` e AppBar locais que duplicam recursos do `SixMobilePageShell`;
- implementação visual diferente sem justificativa funcional.

Quando encontrar um padrão legado:

1. localize a implementação atual da tela;
2. localize uma tela equivalente que já utilize `SixMobilePageShell`;
3. compare título, leading, actions, scroll, SafeArea e conteúdo inferior;
4. avalie a migração para `SixMobilePageShell`;
5. preserve todas as ações e comportamentos específicos da tela;
6. utilize tokens existentes de `SixMobilePalette`;
7. evite criar nova variação de cabeçalho;
8. mantenha o escopo restrito ao mobile;
9. não altere regra de negócio, navegação, integração ou estado funcional;
10. informe no plano quais elementos serão preservados e quais serão padronizados.

Se a tela não puder utilizar `SixMobilePageShell`, documente tecnicamente o motivo antes de implementar um `Scaffold` próprio.

### Fonte única do padrão visual

Gradiente, cores, contraste, status bar, blur, espaçamentos e comportamento de scroll devem vir preferencialmente de:

- `SixMobilePageShell`;
- `SixMobilePalette`;
- componentes em `lib/presentation/components/mobile/`;
- tokens ou abstrações já existentes no design system mobile.

É proibido criar, diretamente em uma tela, um gradiente visualmente semelhante ao padrão oficial utilizando novos valores hardcoded.

Mesmo quando a aparência final for igual, a implementação deve reutilizar a fonte oficial para que alterações futuras sejam propagadas de forma consistente.

### Preservação das particularidades da tela

A padronização do cabeçalho não deve remover ou modificar:

- título específico;
- botão de retorno;
- ações da AppBar;
- leitor de QR Code ou código de barras;
- tabs;
- filtros;
- busca;
- conteúdo inferior da AppBar;
- comportamento de seleção;
- scroll;
- navegação;
- estado da tela.

O componente compartilhado deve adaptar-se à tela, e não obrigar a tela a perder funcionalidades para se encaixar no componente.

## Componentes e estados

Cards mobile devem usar superfícies, bordas, sombras e hierarquia coerentes com a paleta mobile. Gradientes e sombras precisam comunicar estado, prioridade ou agrupamento; não devem ser ornamentais.

Estados vazios devem explicar o que acontece, indicar próxima ação, evitar CTA duplicado com FAB e funcionar com animações desabilitadas. Verifique se o estado vazio desaparece ou muda quando o primeiro item é incluído.

Antes de adicionar ou manter FAB, verifique duplicidade com CTA de conteúdo, utilidade por estado da tela, ergonomia e uso de `SixMobilePalette.accent`.

## Motion, Lottie e loading

O movimento deve ser funcional: explicar mudança de estado, orientar atenção, dar feedback e criar continuidade. Priorize recursos existentes: `SixStaggeredEntry`, `SixAnimatedNumberText`, `SixPulsingBadge`, `AnimatedSwitcher`, `AnimatedContainer`, `AnimatedScale`, `FadeTransition`, `SlideTransition`, `TweenAnimationBuilder`, `flutter_animate`, `SixMobileAnimatedGradientBackground`, `SixLottieActionOverlay`, `SixFullScreenLottieLoading` e `SixBackendLoading`.

Não adicione dependência de animação sem justificativa e autorização. Respeite `MediaQuery.disableAnimations` em animações contínuas ou ambiente animado.

Para Lottie, reutilize `SixAnimationAssets` quando possível, registre novos JSONs centralmente, use `assets/animations/`, preserve `Semantics`, forneça fallback visual e não adicione Rive sem decisão explícita.

## Bottom sheets, textos e acessibilidade

Siga `docs/ui/mobile-first-patterns.md`: seletores mobile devem preferir bottom sheets, busca quando necessário, pt-BR ou `AppLocalizations`, `SafeArea`, fechamento previsível e componentes reutilizáveis.

Avalie contraste, tamanho de toque, `Semantics`, labels de ícones, foco quando aplicável, ordem de leitura, conteúdo dinâmico, `liveRegion`, redução de movimento, escala de texto e overflow. Não dependa somente de cor para erro, sucesso ou seleção.

## Proibições

Nunca, em tarefa visual mobile:

- duplicar client HTTP, request, response, parser, mapper ou service;
- alterar contrato de backend para acomodar layout;
- mover regra de negócio para widget;
- introduzir novo gerenciador de estado sem autorização;
- modificar autenticação, tenant, permissões ou parsing sem relação direta com o pedido;
- alterar tema global ou fluxo web como primeira opção;
- fazer refatoração ampla, formatação em massa, commit ou push sem pedido explícito.
