# Checklist de implementação mobile

Use este checklist antes de finalizar criação, alteração ou revisão de UI mobile.

## Escopo

- [ ] A tarefa foi classificada como mobile, web ou compartilhada.
- [ ] O pedido explicitamente mobile não altera arquivos web.
- [ ] Arquivos globais de tema foram evitados ou justificados.
- [ ] Regra de negócio e backend permanecem preservados.
- [ ] Quando houve backend compartilhado, a Skill `sixapp-shared-backend-integration` também foi considerada.

## Design System

- [ ] `SixMobilePalette` foi consultada.
- [ ] Não há cor hardcoded com token equivalente.
- [ ] Novos tokens foram justificados semanticamente.
- [ ] Superfícies, bordas, textos e ações seguem a paleta mobile.
- [ ] A tela mantém continuidade com o fluxo anterior.
- [ ] Gradientes e sombras têm finalidade clara.

## Estrutura

- [ ] `SixMobilePageShell` foi avaliado.
- [ ] AppBar e status bar têm contraste correto.
- [ ] `SafeArea`, notches e navigation bar foram considerados.
- [ ] Teclado e altura disponível foram considerados.
- [ ] Navegação principal não foi duplicada.
- [ ] Layout usa scroll, `Expanded`, `Flexible`, `Wrap` ou `LayoutBuilder` quando necessário.

## Motion

- [ ] A animação tem propósito funcional.
- [ ] Recursos existentes foram priorizados.
- [ ] Nenhuma dependência nova foi adicionada sem autorização.
- [ ] `MediaQuery.disableAnimations` foi considerado.
- [ ] Loops contínuos e excesso de movimento foram evitados.
- [ ] Lottie, se usado, possui fallback e semântica.

## UX

- [ ] Estado vazio explica a próxima ação.
- [ ] Não há CTA duplicado sem justificativa.
- [ ] FAB foi avaliado conforme estado da tela.
- [ ] Textos estão em pt-BR ou `AppLocalizations`.
- [ ] Componentes genéricos foram substituídos quando destoavam do padrão mobile.
- [ ] Bottom sheets e seletores seguem `docs/ui/mobile-first-patterns.md`.

## Acessibilidade

- [ ] Contraste foi avaliado.
- [ ] Tamanhos de toque são adequados.
- [ ] Ícones relevantes possuem semântica, tooltip ou label.
- [ ] Estados não dependem somente de cor.
- [ ] Escala de texto e overflow foram considerados.
- [ ] Conteúdo dinâmico relevante usa semântica adequada ou `liveRegion`.

## Validação

- [ ] `dart format` foi executado nos arquivos alterados.
- [ ] `flutter analyze` foi executado ou a ausência foi justificada.
- [ ] Testes relevantes foram executados ou a ausência foi justificada.
- [ ] `git diff --check` foi executado.
- [ ] O diff final foi revisado.
- [ ] Foi confirmado que o fluxo web não foi alterado.
