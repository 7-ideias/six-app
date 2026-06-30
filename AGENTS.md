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

## Arquitetura Flutter

* Manter separação entre tela, controller/service, models e componentes reutilizáveis.
* Requests, models, services e clients devem ficar em camada reutilizável.
* Evitar lógica de negócio pesada dentro de widgets.
* Evitar chamadas HTTP diretamente em telas.
* Evitar duplicação de chamadas entre web, Android e iOS.
* Criar componentes reutilizáveis quando houver repetição clara.
* Não transformar correções pontuais em grandes refatorações sem necessidade.

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
