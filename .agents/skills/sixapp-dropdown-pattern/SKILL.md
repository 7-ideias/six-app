---
name: sixapp-dropdown-pattern
description: >
  Aplicar o padrão de seleção do SixApp quando uma tela, modal, cadastro ou
  filtro Web ou Mobile oferecer opções, mesmo que o pedido descreva apenas
  a funcionalidade. Abrange seleção simples, múltipla, de entidade ou período.
  Orientar o uso dos campos Web ancorados e dos bottom sheets mobile.
---

# Seletores do SixApp

Identifique a plataforma e os valores que o usuário precisa escolher. Consulte o `AGENTS.md` da raiz e as skills de UI, cores e regionalização aplicáveis. Reaproveite o componente da plataforma antes de criar uma variante. Preserve a composição própria de Web e Mobile.

## Web

| Uso | Componente |
| --- | --- |
| Uma opção | [SixWebSelectField](../../../lib/presentation/components/web/six_web_select_field.dart) |
| Várias opções | [SixWebMultiSelectField](../../../lib/presentation/components/web/six_web_multi_select_field.dart) |

Preserve o comportamento dos campos usados na Agenda Financeira:

- Toda a área do campo abre o menu. Use label pequena acima do valor, ícone semântico à esquerda, chevron animado à direita, cantos de 16–18 e altura compacta.
- Use o estado animado do campo para hover, foco e abertura. O menu abre ancorado ao campo, com largura alinhada, borda e elevação. Aplique os [tokens de cores Web](../sixapp-web-colors/SKILL.md) ao campo, menu e item selecionado.
- Destaque a seleção com fundo e check. Preserve ícones neutros nos demais itens, `TextOverflow.ellipsis`, tooltip e semântica.
- Na seleção múltipla, mantenha as ações de cancelar, limpar e aplicar conforme o fluxo. Preserve a seleção anterior ao cancelar.
- Se faltar uma capacidade, examine os usos existentes antes de estender o componente. Preserve estados vazio, desabilitado e de erro quando aplicáveis. Evite substituir o seletor por um dropdown Material genérico.

## Mobile

| Uso | Componente |
| --- | --- |
| Abrir e exibir seleção | [SixMobileSelectionField](../../../lib/presentation/components/mobile/six_mobile_selection_sheet.dart) |
| Seleção simples ou múltipla | `showSixMobileSelectionSheet<T>` ou `showSixMobileMultiSelectionSheet<T>` no mesmo arquivo |
| Seleção de data | [DateSelectorMobileBottomSheet](../../../lib/presentation/components/date_selector_mobile_bottom_sheet.dart) |

- Use campo clicável com label, valor, área de toque confortável e ícone. Abra a seleção em bottom sheet com `SafeArea`, cantos superiores arredondados e fechamento previsível. Mantenha a tela de fundo estável.
- Em listas médias ou grandes já carregadas, habilite busca local. Identifique cada opção por título e, quando ajudar a distinguir itens, por ícone, avatar ou subtítulo. Sinalize a seleção também por semântica e ícone.
- Na seleção simples e reversível, permita concluir ao tocar no item. Para múltipla seleção, período ou filtro composto, preserve o valor anterior até aplicar.
- Para datas, use calendário compacto, atalhos pertinentes e ações de aplicar e cancelar. Formate datas, dias da semana, ações e rótulos conforme a regionalização da empresa. Português é o fallback.
- Use as [cores mobile](../sixapp-mobile-colors/SKILL.md), foco previsível, texto escalável e movimento compatível com as preferências de acessibilidade.

## Validação

Nos temas claro e escuro, confira o campo fechado, o menu ou sheet aberto e o item selecionado. Verifique legibilidade, contraste de seleção e se aplicar ou cancelar produz o valor esperado. Na Web, confira também hover, foco e alinhamento do menu. Rode os testes de widget pertinentes, formate o Dart alterado e revise o diff.
