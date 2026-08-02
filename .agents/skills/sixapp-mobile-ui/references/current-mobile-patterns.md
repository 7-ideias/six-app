# Padrões mobile atuais confirmados

Use esta referência curta antes de criar ou reformular UI mobile. Ela resume padrões encontrados no projeto real; para detalhes, leia `mobile-design-system.md`.

## Fontes principais

- `lib/design_system/themes/six_mobile_palette.dart`: tokens semânticos de cor mobile.
- `lib/design_system/themes/six_mobile_typography.dart`: tipografia aplicada pelo `ThemeProvider` quando `!kIsWeb`.
- `lib/presentation/components/mobile/six_mobile_page_shell.dart`: shell preferencial para telas principais com AppBar, fundo, status bar e scroll.
- `lib/presentation/components/nav_bar_mobile.dart`: navegação principal mobile com três destinos: `Gestão`, `Início` e `Atendimento`.
- `lib/presentation/components/mobile_motion.dart`: entrada progressiva, número animado e badge com pulso discreto.
- `lib/presentation/components/six_backend_loading.dart`: loading reutilizável para mensagens, eventos e configurações carregadas do backend.
- `docs/ui/mobile-first-patterns.md`: orientação de seleção via bottom sheets e fluxo mobile-first.

## Decisões visuais recorrentes

- Fundo claro com cards brancos, bordas sutis e sombras leves.
- AppBar escura ou integrada ao `SixMobilePageShell`, com contraste e status bar coerentes.
- Ícones pequenos e consistentes, sem blocos coloridos exagerados.
- Cards orientados a ação rápida, com título, subtítulo, estado/número e ação clara.
- Uso de `ListView`, `Wrap`, `LayoutBuilder`, `Expanded`, `Flexible`, `SafeArea` e `TextOverflow.ellipsis` para evitar overflow.
- Motion curto e funcional: fade com leve deslocamento, `AnimatedSwitcher`, `AnimatedScale`, `TweenAnimationBuilder` e `SixStaggeredEntry`.
- Skeleton ou layout estrutural durante loading quando a tela já conhece cards, ícones e categorias antes da resposta.

## Seletores e bottom sheets

Para cliente, fornecedor, produto, serviço, técnico, forma de pagamento, categoria, status, filtro e data, trate dropdown/dialog genérico como legado quando destoar da tela.

Padrão preferido:

- campo read-only/clicável na tela base;
- `showModalBottomSheet` customizado com `SafeArea`, cantos superiores arredondados, handle e fechamento previsível;
- busca local quando a lista carregada for média/grande;
- item confortável com ícone/avatar, título, subtítulo opcional e estado selecionado;
- botão `Aplicar` quando a seleção não deve alterar estado antes da confirmação.

## Regionalização mobile

Quando a tela exibir texto, moeda, data, hora, número, percentual ou mensagem do backend, use `sixapp-regionalization`.

No frontend atual:

- textos estáticos do app devem ir para i18n, geralmente via `context.t` e pacote de traduções do backend em telas Web/configuradas, ou ARB/AppLocalizations onde a tela já segue esse padrão;
- moeda, data e hora devem delegar para `LocaleSettingsProvider`;
- códigos técnicos enviados ao backend devem continuar como código, não label traduzido.

## Alertas

- `pdv_mobile_screen_base.dart` mostra pontos legados: cores locais próximas aos tokens, AppBar transparente com contraste frágil e FAB por valor hardcoded. Use como alerta para migração, não como padrão novo.
- Não use arquivos Web, `SixThemeResolver`, `AppTheme`, `main.dart` ou providers globais em tarefa somente mobile sem justificar impacto.
- Não trate arquivos não rastreados ou experimentais como padrão consolidado.
