# Tipos de pagamento: mapeamento e edição contextual

Data: 07/10/2026. Branch de trabalho: `feature/20261007-edicao-contextual-pagamentos`.

## Resultado da primeira entrega

A imagem corresponde ao filtro **Tipo de pagamento** da Agenda Financeira Web.
A edição contextual foi implementada nesse filtro e no filtro equivalente Mobile:
lápis por opção, modal Web e bottom sheet Mobile com Salvar/Cancelar, estado de envio,
validação e manutenção do rascunho em erro. O nome atualizado substitui o anterior na
lista sem perder a seleção do código financeiro. Cancelar o filtro não desfaz uma
edição de cadastro já salva; o editor explica que ela vale para o comércio.

Nesta etapa o campo editável é o **nome de exibição**. Natureza, parcelamento, cliente,
ordem, ativo, cor, ícone e identidade `codigoTipo` permanecem preservados.

## Inventário de telas e componentes

Todos os caminhos abaixo são relativos a `lib/` no six-app. Foram rastreados
`TiposRecebimento`, `tiposRecebimento`, as chamadas de informações básicas,
configuração, e os chamadores dos componentes de recebimento.

| Uso | Web | Mobile | Situação |
| --- | --- | --- | --- |
| Cadastro das formas | `presentation/screens/formas_recebimento_configuracao_content.dart` | `presentation/screens/formas_recebimento_configuracao_mobile_screen.dart` | Edição já existente; Mobile reaproveita o editor nativo extraído nesta entrega |
| Entradas para o cadastro | `configuracoes_six_web_page.dart`, `configuracao_secao_web_page.dart` em `presentation/screens/` | `presentation/screens/gestao_mobile_screen.dart` | Navegação para configuração |
| Filtro da Agenda | `presentation/screens/agenda_financeira_web.dart` | `presentation/screens/agenda_financeira_mobile_screen.dart` | **Edição contextual de nome implementada** |
| Criação/edição de lançamento | `sub_painel_lancamento_agenda_financeira_web.dart` | `presentation/screens/agenda_financeira_lancamento_mobile_create_screen.dart`, `agenda_financeira_lancamento_mobile_edit_screen.dart` | Consomem as formas configuradas; próximos candidatos à edição contextual |
| Recebimento reutilizado | `presentation/components/web/six_web_recebimento_dialog.dart` | `presentation/components/mobile/six_mobile_recebimento_bottom_sheet.dart` | Seleção de formas e valores; próximos candidatos |
| PDV | `presentation/screens/pdv_web.dart` | `presentation/screens/pdv_mobile.dart` | Usa o componente de recebimento da respectiva plataforma |
| Recebimento Web complementar | `presentation/screens/recebimento_pagamento_web.dart` | Componente Mobile de recebimento acima | Consome configurações diretamente |
| Vendas a receber | `presentation/screens/vendas_a_receber_web_widget.dart` | `presentation/screens/vendas_nao_liquidadas_mobile_screen.dart` | Usa o componente de recebimento da respectiva plataforma |
| Assistência técnica | `presentation/screens/atendimentos_tecnicos_lista_web_page.dart` | `presentation/screens/atendimentos_tecnicos_mobile_screen.dart` | Usa o componente de recebimento da respectiva plataforma |
| Liquidação na Agenda | `presentation/screens/agenda_financeira_web.dart` | `presentation/screens/agenda_financeira_mobile_screen.dart` | Usa os mesmos componentes de recebimento |
| Caixa: filtros, movimentos e resumo | `presentation/screens/operacoes_caixa_web_page.dart` | `presentation/screens/operacoes_caixa_mobile_screen.dart` | Carrega as formas pelo CaixaService; próximo candidato |
| Consulta de vendas | `presentation/screens/consulta_vendas_web_page.dart` | `presentation/screens/consulta_vendas_mobile_screen.dart` | Exibe dados das operações; não é editor do cadastro |
| Devoluções | `presentation/screens/devolucoes_produtos_jornada.dart` | `presentation/screens/devolucoes_produtos_mobile_screen.dart` | Referências à forma/código da operação; não editor do cadastro |
| Compras demonstrativas | `presentation/screens/compras/compras_web_editor.dart`, `compras_demo_models.dart`, `compras_demo_store.dart` | Sem consumidor correspondente encontrado | Lista local de demonstração; não integrada ao cadastro de recebimento |

A entrega é incremental: não foi inserida edição de cadastro em cada exibição de
uma transação histórica nem em todas as telas mapeadas.

## Integração reutilizada

Web → PaymentNameEditorWeb → CaixaService → HttpCaixaApiClient → backend.
Mobile → PaymentNameEditorMobile → mesmo CaixaService/HttpCaixaApiClient → backend.
As árvores visuais continuam distintas, sem tela Web embrulhada no Mobile.

- Model compartilhado: `data/models/caixa_models.dart`, `TiposRecebimento`.
- Service: `domain/services/caixa/caixa_service.dart`.
- Client: `data/services/caixa/caixa_api_client.dart` (rotas e autenticação preservadas).
- GET `/private/api/caixa/configuracoes/tipos-recebimento`: recarrega o cadastro antes de alterar o nome.
- PUT `/private/api/caixa/configuracoes/tipos-recebimento/{codigoTipo}`: salva pelo contrato existente.
- GET `/private/api/agenda-financeira/formas-recebimento`: retorna também `podeEditarTiposRecebimento`.
- GET `/private/api/caixa/informacoes-basicas`: demais consumidores do catálogo.
- `AuthService` fornece bearer token e `idUnicoDaEmpresa`; widgets não montam headers.
- Backend antigo sem o novo campo: edição contextual fica oculta, mantendo a consulta funcional.

## Permissão e isolamento

`TipoRecebimentoPermissaoService` valida acesso à empresa e vínculo ativo.
ADMIN pode editar sempre dentro do próprio comércio. Colaboradores podem editar
por padrão. A lista de permissões já persistida por vínculo aceita a restrição
`TIPOS_RECEBIMENTO_EDITAR_NEGADO`; ausência da restrição mantém edição liberada.
A futura interface administrativa pode gerenciar essa restrição pelo mecanismo
de permissões existente. Não foi criada uma tela de gestão de permissões nesta entrega.
Vínculo inativo e usuário de outra empresa são recusados. O PUT valida a mesma
regra no servidor; ocultar o lápis é apenas o comportamento visual.
Restaurar todos os padrões permanece uma ação administrativa distinta.

O espaço **PESSOAL** usa formas padrão próprias. Não recebe lápis nesta etapa,
pois não existe persistência de personalização dessas formas. Assim, editar um
filtro pessoal não modifica inadvertidamente a empresa.

## Integridade e apresentação

- A edição preserva códigos, valores e registros de vendas/lançamentos existentes.
- O backend rejeita nomes vazios, acima de 100 caracteres e duplicados no comércio.
- O serviço relê a configuração antes do PUT para não reenviar uma cópia antiga da tela.
  O contrato existente não oferece controle de versão otimista para edições simultâneas.
- Sem confirmação de sucesso da API, o modal/sheet mantém o texto e permite nova tentativa.
- Erros 401/403 possuem mensagens específicas; demais erros exibem falha de salvamento.
- Textos novos em pt-BR/en-US/es-ES; nomes cadastrados não são traduzidos.
- Mobile utiliza `sixMobileColors`, SafeArea, teclado, ação com tooltip e CTA contrastante.
- Animações de abertura permanecem as nativas dos modais/sheets já usados no projeto.

## Base e publicação

Frontend parte do checkout `09916cc3`, que contém o merge do pacote de espaços
financeiros e a correção de dinheiro no caixa. Alterações não commitadas de outras
sessões foram preservadas nos seus diretórios originais.
O checkout backend disponível contém alterações anteriores; os arquivos de domínio
alterados nesta entrega foram confrontados com seu conteúdo atual no GitHub.
Não publicar todo o diff herdado do backend como se pertencesse a esta entrega.
Publicação autorizada pelo usuário em 07/10/2026. Alterações conciliadas com a main atual de ambos os repositórios antes do envio da branch. Não houve implantação.

## Validação desta entrega

- `dart format --language-version 3.7` nos arquivos Dart alterados: executado.
  A versão de linguagem mantém o estilo existente e evita formatação em massa.
- `git diff --check`: sem problemas.
- Backend compilado pelo Maven, incluindo fontes e testes.
- `mvn -o -q -Dtest=TipoRecebimentoPermissaoServiceTest test`: **6 testes, 0 falhas, 0 erros**.
- Nesta máquina, Mockito precisou do mock maker de subclasses no diretório temporário
  `target/test-classes/mockito-extensions/org.mockito.plugins.MockMaker`; não foi
  alterada a configuração global do projeto. Isso evita anexação de agente à JVM.
- Testes Mobile preparados: edição mantém seleção, permissão ausente oculta lápis,
  e teste existente de erro 403/rascunho ajustado à nova mensagem.
- `flutter analyze` e testes de widget **não executados**: a revisão automática
  bloqueou a inicialização do Flutter após tentativa de acesso ao endpoint de
  metadados da infraestrutura `169.254.169.254`. O processo foi interrompido, sem
  contornar o bloqueio. A formatação Dart não substitui essas validações.
- Revisão visual em navegador/aparelho e integração com ambiente autenticado pendentes.

## Patch isolado do backend

`backend-edicao-contextual.patch`, nesta mesma pasta, contém somente os oito arquivos
backend desta entrega (3 existentes, serviço de permissão, teste e 3 traduções).
Foi validado com `git apply --check` contra a base dos arquivos consultados.
Isso permite revisar/aplicar a alteração sem incorporar o restante do checkout
backend herdado de trabalhos anteriores. Publicar o backend antes do frontend
para disponibilizar a autorização no catálogo da Agenda.
