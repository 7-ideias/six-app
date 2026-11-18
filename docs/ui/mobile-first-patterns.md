# Padrões mobile-first do SixApp

Este documento define padrões obrigatórios para telas mobile do SixApp.

## Princípio principal

A versão mobile não deve ser apenas uma adaptação visual da web. Ela deve ter componentes, transições e fluxos adequados ao uso com toque, tela pequena e contexto operacional rápido.

A versão mobile também não deve ser um wrapper de tela ou conteúdo Web. Reaproveite integração com backend, models, services, mappers, providers/controladores sem responsabilidade visual e helpers. Não reaproveite telas completas, formulários grandes, dashboards, modais Web ou conteúdo principal usando `embedded`, `isMobile`, `isWeb`, `LayoutBuilder` ou condicionais equivalentes.

O layout mobile deve transmitir:

- fluidez;
- clareza;
- estabilidade visual;
- aparência premium;
- baixa fricção;
- consistência com a identidade do Six.

## Seletores de entidade e data

Consulte a [skill de seleção](../../.agents/skills/sixapp-dropdown-pattern/SKILL.md) para escolher o campo, a lista ou o calendário e definir quando confirmar o valor.

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

Evitar bottom sheets excessivamente baixos em fluxos de negócio, configuração,
seleção ou formulário, pois deixam uma grande área escurecida e vazia da tela
base acima do modal. Nesses casos, definir uma altura mínima proporcional ao
viewport, preferencialmente com `DraggableScrollableSheet` ou constraints
responsivas, mantendo o conteúdo alinhado ao topo e rolável quando necessário.
Também evitar o extremo oposto: não criar sheet alto com grande vazio interno
abaixo do conteúdo; a altura deve parecer intencional e ocupada.

## Estados vazios

Sempre que uma busca ou lista não tiver resultado, exibir estado vazio com:

- ícone discreto;
- título curto;
- texto auxiliar objetivo;
- sem ocupar espaço exagerado.

## Idioma

Use o mecanismo de i18n do app para títulos, ações, busca, estados vazios e rótulos de calendário. Exiba datas conforme o idioma e o formato configurados para a empresa. Use português como fallback quando faltar tradução ou configuração.

## Reutilização

Consulte os componentes Flutter indicados na skill de seleção antes de introduzir um novo seletor.

Evitar duplicação de lógica visual dentro de telas grandes quando o componente for pequeno, neutro e claramente mobile. Não extrair uma tela inteira ou formulário principal para ser compartilhado com Web. Para funcionalidades que existem nas duas plataformas, crie telas e composições separadas consumindo a mesma camada de backend/domínio.

## Checklist de aceite mobile

Uma implementação mobile só deve ser considerada pronta se:

- respeita o layout mobile-first;
- não usa componente padrão com aparência desalinhada;
- não quebra cards durante interações;
- não reutiliza tela web indevidamente;
- não usa wrapper sobre conteúdo visual principal Web;
- mantém regra de negócio original;
- usa componentes reutilizáveis quando aplicável;
- está formatada com `dart format`;
- possui diff claro.
