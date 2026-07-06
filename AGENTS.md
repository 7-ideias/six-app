# Instruções para desenvolvimento assistido por IA — Six Frontend

## Contexto do projeto

Este projeto faz parte do app Six, um CRM Freemium para comércios de assistência técnica, vendas, orçamento, estoque, financeiro e atendimento.

Frontend:

* Flutter
* Web, Android e iOS
* Projeto chamado `sixapp`

Backend:

* Java 17
* Spring Boot 3.0.2
* Projeto chamado `sixback`

## Regras gerais

* Sempre preservar compatibilidade com multi-idiomas.
* Não hardcodar textos no frontend quando eles devem vir do backend ou dos arquivos de tradução.
* Não alterar contratos de API sem necessidade.
* Não quebrar fluxos existentes ao corrigir um fluxo específico.
* Priorizar código simples, limpo e sustentável.
* Não misturar refatorações grandes com correções pontuais.
* Como Flutter Web, Android e iOS compartilham a mesma base, requests, models, services e clients devem ficar em camada reutilizável.
* Evitar lógica HTTP diretamente dentro de telas.
* Evitar duplicar chamadas entre web e mobile.
* Movimento deve comunicar estado, prioridade, feedback de ação ou descoberta de conteúdo escondido, como listas horizontais roláveis.

## Arquitetura Flutter

* Manter separação entre tela, controller/service, models e componentes reutilizáveis.
* Requests, models, services e clients devem ficar em camada reutilizável.
* Evitar lógica de negócio pesada dentro de widgets.
* Evitar chamadas HTTP diretamente em telas.
* Evitar duplicação de chamadas entre web, Android e iOS.
* Criar componentes reutilizáveis quando houver repetição clara.
* Não transformar correções pontuais em grandes refatorações sem necessidade.

## Padrão visual Web — Six

- Telas web de listagem devem seguir visual profissional, leve e elegante.
- Evitar listas com cards genéricos grandes, sombra pesada, ícones enormes ou botões desproporcionais.
- Preferir estrutura com:
  - card superior de contexto/resumo;
  - busca e filtros dentro de uma área organizada;
  - lista com cards compactos, bem espaçados e com hierarquia clara;
  - ações alinhadas e proporcionais;
  - barra inferior discreta para contagem, atualizar e ações secundárias.
- Cards de listagem devem exibir as informações principais em camadas:
  - título forte;
  - metadados em chips discretos;
  - valores importantes em pequenos blocos;
  - ação principal à direita no desktop e abaixo no layout compacto.
- Usar bordas sutis, sombras leves, cantos arredondados e fundo claro.
- Evitar aparência de tabela improvisada ou lista “crua” com `ListTile` simples quando a tela for um subpainel web importante.
- Quando houver imagem do item, usar thumbnail discreto; quando não houver, usar ícone dentro de bloco visual neutro.
- Botões flutuantes só devem ser usados quando fizerem sentido na experiência. Em subpainéis web, preferir botões fixos e bem integrados ao layout.
- Sempre validar mentalmente desktop largo, notebook e layout compacto, usando `LayoutBuilder`, `Wrap`, `Expanded` e `TextOverflow.ellipsis` para evitar overflow.
- Usar microinteração sutil em listas importantes, como entrada com `fade + leve deslocamento`, sem animação contínua ou decorativa.

## Movimento e microinterações no Web

* Usar movimento de forma sutil, profissional e funcional, com o mesmo cuidado aplicado ao mobile.
* Ao carregar dashboards e subpainéis web, preferir entrada progressiva por prioridade: KPIs primeiro, gráficos depois, listas e alertas em seguida.
* Cards importantes podem entrar com `fade + leve deslocamento de baixo para cima`, usando pequenos atrasos entre blocos para criar leitura guiada.
* Gráficos não devem ficar estáticos quando a tela abre: barras podem crescer de zero até o valor real e gráficos de pizza/rosca podem revelar setores suavemente.
* Skeleton loading é preferível a spinner central em telas executivas que dependem de dados do backend.
* `AnimatedSwitcher`, `TweenAnimationBuilder`, `AnimatedContainer`, `FadeTransition` e `SlideTransition` são boas opções para transições curtas.
* Hover em cards e botões pode usar mudança discreta de borda, elevação ou fundo, sem parecer efeito decorativo exagerado.
* Evitar animação contínua em dashboards; o movimento deve acontecer na entrada, atualização, mudança de estado ou feedback de ação.
* Não sacrificar leitura, acessibilidade, performance ou estabilidade de layout para adicionar movimento.

### Loading de mensagens do backend

* Para estados onde mensagens, notificações ou eventos ainda estão sendo carregados do backend, usar o componente reutilizável `SixBackendLoading`.
* O componente fica em `lib/presentation/components/six_backend_loading.dart`.
* Evitar criar loading local com `CircularProgressIndicator` solto em telas de negócio.
* Preferir:
  * `SixBackendLoading.messages()` para carregamento padrão de mensagens/eventos;
  * `compact: true` em cards mobile ou áreas pequenas;
  * `animation: SixBackendLoadingAnimation.skeletonPulse` para telas executivas;
  * `animation: SixBackendLoadingAnimation.waveDots` para cards compactos;
  * `animation: SixBackendLoadingAnimation.progressSweep` quando a tela precisar comunicar sincronização linear.
* Para trocar globalmente a animação padrão, alterar apenas `SixBackendLoadingDefaults.messageLoadingAnimation`.
* O loading deve ser usado apenas enquanto o backend ainda não respondeu ou a sincronização inicial ainda está acontecendo. Depois disso, exibir estado vazio real, erro ou dados carregados.

### Gráficos animados e interativos no Web

* Em dashboards web, gráficos devem parecer vivos e responsivos, nunca meramente estáticos quando houver dados carregados.
* Para gráficos de barras, preferir crescimento sequencial com pequeno atraso entre itens. O movimento deve partir de zero até o valor real e ajudar o usuário a perceber ranking, comparação e relevância.
* Para gráficos de pizza ou rosca, revelar os setores progressivamente, mantendo início visual consistente e sem saltos bruscos.
* Ao passar o mouse ou tocar em uma barra, destacar a barra ativa e reduzir a opacidade das demais. O destaque pode usar leve aumento de largura, raio ou intensidade visual.
* Ao passar o mouse ou tocar em um setor de pizza/rosca, expandir discretamente o setor ativo e reduzir a opacidade dos demais.
* Estados de destaque de gráficos devem ser resetados ao atualizar dados, trocar filtros ou recarregar a tela.
* Quando os dados mudarem, usar chaves estáveis baseadas nos valores exibidos para permitir que a animação rode novamente sem depender de hacks ou rebuilds desnecessários.
* Em telas que carregam dados do backend, combinar skeleton loading, entrada progressiva dos cards e animação própria dos gráficos.
* Usar callbacks de interação do componente de gráfico, como `BarTouchData` e `PieTouchData` no `fl_chart`, para hover/toque quando disponível.
* Manter cada gráfico com estado de interação separado para evitar que o hover de um gráfico altere outro indevidamente.
* Limitar a quantidade de itens visíveis quando necessário para preservar leitura e performance; categorias excedentes devem ser tratadas de forma clara, como agrupamento ou lista complementar.
* Não usar animação contínua em gráfico executivo. Depois da entrada, o gráfico deve ficar estável e só reagir a hover, toque, atualização ou mudança de dados.
* Validar labels longos, valores grandes, layout compacto e responsividade para evitar overflow em português, inglês e espanhol.

## Padrão visual Mobile — Six

* A experiência mobile deve ser orientada a ação rápida, acompanhamento e gestão simples.
* Não copiar a navegação web 1:1 para o mobile; adaptar para uso em balcão, atendimento e operação rápida.
* Usar a estrutura principal:
  * `Início`: visão geral, busca, indicadores, notificações e ações rápidas.
  * `Atendimento`: nova venda, novo orçamento, nova assistência técnica e acompanhamento dos atendimentos.
  * `Gestão`: cadastros, catálogo, financeiro, relatórios, configurações e integrações.
* Evitar telas mobile com aparência infantil, excesso de cores fortes ou cards grandes coloridos sem hierarquia.
* Preferir visual profissional com:
  * fundo claro;
  * AppBar escura;
  * cards brancos;
  * bordas discretas;
  * sombras leves;
  * ícones pequenos e consistentes;
  * textos objetivos;
  * números em destaque apenas quando forem indicadores.
* Cards de dashboard devem ter título, subtítulo, número/estado e ação clara.
* Evitar termos técnicos na UI principal quando houver alternativa mais clara para o usuário final.
  * Preferir `Assistência` ou `Ordem de serviço` em vez de `OT`.
  * Preferir `Atendimento` em vez de `Operação` quando o contexto for venda/orçamento/assistência.
* Telas mobile devem priorizar `ListView`, `Wrap`, `LayoutBuilder`, `SafeArea`, `Expanded` e `TextOverflow.ellipsis` para evitar overflow.
* A navegação mobile deve ser clara e curta; evitar mais de 3 ou 4 destinos principais no menu inferior.

## Movimento e microinterações no Mobile

* Usar movimento de forma sutil, profissional e funcional.
* Evitar animações decorativas exageradas ou ícones se movimentando continuamente sem necessidade.
* Preferir animações curtas com:
  * `FadeTransition`;
  * `SlideTransition`;
  * `TweenAnimationBuilder`;
  * `AnimatedContainer`;
  * `AnimatedSwitcher`;
  * `AnimatedScale`.
* Cards importantes podem entrar com `fade + leve deslocamento de baixo para cima`.
* Indicadores numéricos podem usar animação de contagem curta.
* Badges de notificações podem usar `pulse` discreto quando houver mensagens não lidas.
* A troca de abas pode usar transição curta com fade.
* O item ativo do menu inferior pode ter leve escala/subida para reforçar o estado atual.
* Skeleton loading é preferível a spinner central quando a tela depende de dados do backend.
* Movimento deve comunicar estado, prioridade ou feedback de ação.
* Não usar animação que prejudique leitura, acessibilidade ou performance em aparelhos simples.

### Indicadores numéricos animados no Web e Mobile

* Em cards de resumo, KPIs e dashboards, animar números importantes quando a tela carregar ou quando os dados forem atualizados.
* A animação deve contar de zero até o valor final, com duração curta e curva suave, semelhante ao comportamento da Agenda Financeira.
* Usar `TweenAnimationBuilder<double>` ou componente reutilizável equivalente para valores monetários, quantidades, percentuais e saldos.
* O formatter deve respeitar o tipo do número: moeda, quantidade inteira, quantidade decimal ou percentual.
* Para valores monetários, preservar locale e símbolo corretos; para percentuais, preservar casas decimais definidas pela tela.
* Usar chaves estáveis baseadas no identificador do indicador e no valor final para que a animação rode novamente quando o dado mudar, sem reiniciar em rebuilds irrelevantes.
* Combinar animação numérica com skeleton loading e entrada progressiva do card quando a tela depender do backend.
* Aplicar apenas em indicadores que representam resumo, totalizador, saldo, contagem ou métrica executiva. Evitar em textos comuns, listas longas ou tabelas densas.
* Garantir `TextOverflow.ellipsis`, `maxLines` e responsividade para números grandes e traduções maiores.
* Não exagerar na duração nem criar efeito contínuo; depois de atingir o valor final, o número deve permanecer estável.

## Regionalização, moeda e formatação global

* Configurações de regionalização da empresa devem ser tratadas como estado global do app, não como dado isolado de uma tela.
* Usar `LocaleSettingsProvider` como fonte principal para idioma, país, moeda, fuso horário, formatos de data/hora, separadores numéricos, casas decimais, múltiplas moedas e arredondamento financeiro.
* Não instanciar `LocaleSettingsProvider()` manualmente dentro de telas, services ou helpers. Consumir sempre via `context.watch`, `context.read` ou `context.select`.
* Não criar providers paralelos para os mesmos dados de idioma/regionalização sem integrar claramente com o provider global existente.
* Para valores monetários na UI, não hardcodar `R$`, `BRL`, `USD`, separador decimal, separador de milhar ou casas decimais diretamente na tela.
* Preferir `regionalizacao.formatCurrency(valor)` ou helper centralizado equivalente que consuma `LocaleSettingsProvider`.
* Para indicadores monetários animados com `TweenAnimationBuilder<double>`, manter o valor bruto como `num/double` durante a animação e aplicar `formatCurrency(animatedValue)` apenas no momento de renderizar o texto.
* Não misturar valor numérico e valor já formatado no mesmo campo de mapa/lista usado por cards. Se houver animação, o campo deve continuar numérico.
* Ao salvar regionalização, enviar ao backend apenas códigos técnicos, como `BRL`, `USD`, `MONDAY`, `pt`, `BR`, e nunca labels traduzidos.
* Após salvar regionalização, atualizar o provider global com a configuração persistida ou recarregada do backend antes de depender do novo valor em outras telas.
* Quando uma tela precisar apenas ler a moeda atual, preferir `context.select<LocaleSettingsProvider, String>((p) => p.currencyCode)` para evitar rebuilds desnecessários.
* Quando uma função de ação precisar formatar um valor fora do build, usar `context.read<LocaleSettingsProvider>()`.
* Se uma tela ainda possuir método local como `_formatarMoeda`, ele deve delegar para o provider global ou para helper centralizado. Não manter implementação local fixa com símbolo ou separadores hardcoded.
* Para datas e horas exibidas ao usuário, preferir helpers do provider global ou helper centralizado que respeite `dateFormat`, `timeFormat` e `timeZone`.
* Alterações de regionalização não devem implementar automaticamente regras de negócio complexas, como venda multi-moeda, a menos que a tarefa peça explicitamente. A primeira responsabilidade é persistir, expor e formatar corretamente.
* Ao testar moeda, validar o fluxo completo: salvar `currencyCode`, recarregar a tela, confirmar o valor no provider e verificar se os textos monetários exibem a nova moeda.

## Responsividade

* Evitar overflow em web e mobile.
* Usar layouts responsivos.
* Toda tela nova ou ajustada deve ser validada mentalmente para web desktop, tablet e mobile.
* Usar `Expanded`, `Flexible`, `Wrap`, `SingleChildScrollView`, `LayoutBuilder` ou componentes responsivos quando necessário.
* Evitar `Row` com textos longos sem `Expanded`, `Flexible`, `Wrap` ou scroll adequado.
* Componentes de formulário devem lidar bem com textos longos e traduções maiores.
* Dropdowns, botões, cards, tabelas e filtros devem funcionar bem em português, inglês e espanhol.
* Telas web não devem assumir largura infinita.
* Telas mobile não devem depender de elementos largos sem scroll ou quebra adequada.

## Multi-idiomas

* Nunca usar enum diretamente como texto final para usuário.
* O backend pode enviar código, enum ou chave técnica.
* O frontend deve resolver o label conforme idioma quando o texto for de domínio conhecido.
* Quando o texto vier do backend como conteúdo cadastrado ou configurado pelo usuário, respeitar o valor retornado.
* Pensar sempre em português, inglês e espanhol no mínimo.
* Textos de enum devem ser exibidos via mapa/tradução, mas o valor enviado ao backend deve continuar sendo o enum original.
* Não hardcodar textos visíveis ao usuário dentro das telas quando eles pertencerem ao app.
* Preferir arquivos de tradução, mapas de label ou estruturas reutilizáveis de internacionalização.
* Componentes devem suportar traduções maiores sem quebrar layout.

### Dica visual para listas horizontais no mobile

Quando houver menus, filtros, abas ou listas horizontais com opções que podem ficar escondidas fora da tela, aplicar uma microinteração discreta para indicar ao usuário que existe conteúdo rolável.

Padrão recomendado:
- Usar `ScrollController` no componente horizontal.
- Após o primeiro render, executar um pequeno deslocamento automático para a direita e retornar suavemente para o início.
- Usar movimento curto, sutil e funcional, apenas como dica visual.
- Evitar animação contínua ou exagerada.
- Complementar, quando fizer sentido, com um fade/gradiente lateral e uma seta discreta indicando continuidade.
- Não aplicar em listas verticais nem em componentes onde todas as opções já aparecem visíveis.
- O movimento deve ocorrer uma única vez ao abrir a tela ou ao montar o componente, sem atrapalhar o toque do usuário.

Exemplo de intenção:
- filtros horizontais de período;
- abas horizontais;
- chips de categorias;
- menus de ações rápidas;
- carrosséis de opções.

## Integração com backend

* Não alterar contratos de API sem necessidade.
* O valor enviado ao backend deve manter o código técnico esperado pela API.
* Não enviar label traduzido no lugar de enum/código original.
* Quando o backend retornar código de erro estável, o frontend deve resolver a mensagem conforme idioma sempre que aplicável.
* Quando o backend retornar texto cadastrado pelo usuário, exibir o texto retornado.
* Evitar adaptar payload diretamente em tela; preferir models, mappers ou services.

## Multi-tenant e permissões

* Toda operação deve respeitar o comércio atual selecionado/autorizado.
* Não assumir que o usuário possui acesso total apenas por estar autenticado.
* Exibir ou ocultar ações conforme permissões do usuário quando essa informação estiver disponível.
* Não permitir ações sensíveis no frontend sem considerar o perfil do usuário.
* Exemplos de ações sensíveis: venda, cancelamento, alteração financeira, exclusão, alteração de estoque, cadastro de colaborador, alteração de permissões e geração de relatórios.
* O ADMIN possui acesso total dentro da própria conta, mas colaboradores devem respeitar permissões configuradas.

## Formulários e validações

* Validar campos obrigatórios antes de enviar ao backend quando fizer sentido para a experiência do usuário.
* Não depender apenas do backend para erros simples de preenchimento.
* Mensagens de validação devem respeitar multi-idiomas.
* Evitar permitir cadastro incompleto quando o campo for obrigatório no domínio.
* Quando houver erro do backend, exibir mensagem clara e útil para o usuário.
* Evitar exibir stack trace, mensagem técnica ou erro cru de API para o usuário final.

## Modelos de etiqueta

* O editor de etiquetas deve trabalhar com medidas configuráveis em milímetros.
* Deve suportar preview, campos dinâmicos, código de barras, QR Code, margem, espaçamento, largura, altura, colunas e linhas.
* O modelo salvo deve ser neutro e independente de impressora.
* A primeira versão deve priorizar geração em PDF.
* Não acoplar o editor diretamente a ZPL, TSPL, ESC/POS ou linguagem específica de impressora.
* Textos fixos do editor devem respeitar arquivos de tradução.
* Campos dinâmicos devem manter chaves técnicas, não textos hardcoded.
* O preview deve representar visualmente a etiqueta de forma fiel o suficiente para configuração pelo usuário.
* O editor deve evitar overflow e funcionar em web desktop, tablet e mobile sempre que possível.
* Configurações como largura, altura, margens, espaçamentos, colunas e linhas devem ser salvas no modelo.
* Código de barras e QR Code devem ser tratados como elementos configuráveis do modelo.

## Relatórios, PDFs e compartilhamento

* Relatórios e comprovantes devem respeitar multi-idiomas quando aplicável.
* O frontend deve permitir compartilhamento quando a plataforma suportar.
* A visualização de PDFs deve funcionar de forma adequada em web, Android e iOS.
* Evitar lógica duplicada para geração, download, preview ou compartilhamento.
* Quando o PDF vier do backend, respeitar o conteúdo retornado.
* Quando o frontend apenas acionar geração, manter service reutilizável.

## Testes e validação

* Não criar testes unitários automaticamente.
* Não alterar ou remover testes existentes sem necessidade.
* Quando o usuário pedir execução direta, priorizar correção objetiva e validação prática.
* Quando possível, executar validações simples do fluxo alterado.
* Quando possível, executar `flutter analyze` para alterações relevantes.
* Se não for possível validar, informar claramente o motivo.
* Não bloquear correções pontuais por falta de teste unitário quando o usuário não solicitou testes.

## Commits e branches

* Trabalhar sempre na branch informada pelo usuário.
* Não misturar refatorações grandes com correções pontuais.
* Antes de commitar, revisar arquivos alterados.
* Commits devem ser objetivos e seguir o padrão:

    * `feat:`
    * `fix:`
    * `refactor:`
    * `docs:`
    * `test:`
    * `chore:`

Exemplos:

* `feat(cliente): ajuste na tela de clientes`
* `fix(colaborador): correção de bug na validação do campo email`
* `fix(venda): ajuste na identificação do cliente`
* `fix(layout): correção de overflow no formulário`
* `feat(etiqueta): criação do editor de modelos de etiqueta`

## Estilo de resposta esperado

* Quando encontrar problema, apontar direto a causa provável.
* Sugerir alteração prática.
* Evitar explicação longa quando o usuário pedir execução.
* Quando possível, entregar patch/código pronto.
* Não explicar conceitos básicos quando o usuário pediu ajuste direto.
* Ser objetivo, mas sem omitir riscos importantes.
