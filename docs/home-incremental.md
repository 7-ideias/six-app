# Home incremental — web e mobile

A home ganha o painel **Meu dia**, com dados do comércio ativo. Os banners,
seções operacionais, filtros, gráficos, ações e a aba Desempenho existentes
continuam disponíveis. O painel de infraestrutura SUPER permanece na área exclusiva
introduzida na main, com sua navegação própria na web e no mobile.
O usuário SUPER também tem acesso ao Meu dia do comércio ativo, com
as mesmas consultas segmentadas da home do administrador.

## Experiência

- Web: cartões responsivos com elevação no hover e acesso aos módulos.
- Mobile: financeiro em destaque, prioridades em linhas, atalhos para nova venda,
  novo serviço e recebimento. As operações usam os procedimentos existentes.
- Financeiro: valores de hoje e atrasados separados.
- Serviços: atrasados, aprovação, retirada e em andamento.
- Caixa: aberto ou fechado; estoque: mínimo, zerado e negativo.
- Reservas: recebidas e em análise. No mobile, este bloco apresenta o resumo;
  a gestão de reservas continua na interface web existente.
- O painel antigo do administrador no mobile continua presente e é identificado
  como demonstrativo, pois sua origem já era `DashboardInicioMock`.
- Colaboradores mantêm o painel pessoal e as permissões existentes. Os grupos
  de vendas, serviços e reservas passam a aparecer conforme suas consultas terminam.

## Carregamento

`WorkspaceHomeProvider` consulta até três grupos simultaneamente e publica cada
resultado imediatamente. O resumo antigo da web usa os mesmos resultados após
concluir a primeira carga, evitando duplicar consultas.

Cada bloco distingue carregamento, indisponibilidade, falha e dados recebidos.
Atualizações preservam os valores anteriores com indicação da última consulta.
Uma falha oferece tentativa individual; 401/403 descartam valores privados.
Respostas de um contexto anterior não atualizam o estado após troca de empresa,
usuário, limpeza do provider ou descarte da tela. Cada chamada tem timeout de 20 s.

O `await` continua assíncrono no Flutter. O backend mantém Spring MVC; não houve
migração para WebFlux nem promessa de redução de tempo de processamento no servidor.
Os testes verificam isolamento e apresentação progressiva; latência e fluidez em
dispositivos reais ainda devem ser medidas em ambiente integrado.

## Contrato e entrega

Implantar o backend antes do frontend, pois as consultas segmentadas são novas:

`GET /private/api/workspace/home/{section}`

Valores: `FINANCIAL`, `TECHNICAL_SERVICES`, `CASH`, `STOCK`, `RESERVATIONS`.
JWT e `idUnicoDaEmpresa` são obrigatórios. O servidor verifica vínculo e autorização
por bloco. Respostas privadas usam `Cache-Control: no-store`.

O endpoint agregado `GET /private/api/web/workspace/home` permanece disponível.
As traduções novas estão em `common.json` (pt-BR, en-US, es-ES) e têm fallbacks
locais. Datas, números e moedas seguem `LocaleSettingsProvider`.

## Revisão manual

1. Abrir a home como administrador na web e no mobile; verificar os elementos
   antigos abaixo do novo painel e o rótulo de demonstração no mobile.
2. Atrasar ou falhar uma consulta: as outras devem aparecer; tentar novamente
   apenas o bloco com falha.
3. Atualizar e trocar de empresa durante uma consulta: nenhum dado anterior deve
   substituir o contexto atual.
4. Abrir venda/serviço/recebimento no mobile e voltar: os grupos relacionados
   devem ser atualizados.
5. Conferir colaboradores com permissões diferentes e o SUPER com Meu dia na home
   e os blocos de infraestrutura preservados no painel exclusivo.
6. Conferir tema escuro, texto ampliado e idiomas/moedas diferentes.

## Validação realizada

- Análise estática dos arquivos alterados: sem erros ou avisos.
- Testes Flutter do novo painel, modelo, transporte e carregamento: 24 casos.
- Testes Java do resumo e autorização dos endpoints: 15 casos.
- Build web release concluído (`--no-wasm-dry-run`).
- Empacotamento Maven concluído.
- O pacote Android não foi gerado: este ambiente não tem Android SDK.
  Os componentes mobile foram testados em claro/escuro e escala de texto 1×/2×.
- A suíte antiga `workspace_home_web_test.dart` tem três falhas também
  reproduzidas na main `526eaa0`: permissões das ações rápidas, cor do botão
  nos alertas escuros e tipo do botão nas ações rápidas. Esses testes e as
  seções antigas correspondentes foram preservados.

## Correção de visibilidade do SUPER

O acesso ao Meu dia considera ADMIN **ou** SUPER na web e no mobile. A exclusão
solicitada se aplica aos dados de infraestrutura dentro do novo painel, e não
à possibilidade de o SUPER visualizar o painel do comércio. O carregamento
inicial e a atualização manual seguem essa mesma regra.

Foram adicionados quatro cenários de regressão de exibição (ADMIN/SUPER) à suíte
web. A execução desta correção ficou pendente porque o SDK Flutter não está
mais disponível no ambiente; os resultados anteriores acima se referem ao
incremento original.

## Integração com o painel SUPER separado

A branch incorpora a main `f1f941a`, que moveu a infraestrutura para um painel
exclusivo. O refresh da home mobile continua atualizando o Meu dia para ADMIN
ou SUPER, sem consultar a infraestrutura nessa tela. O teste de acesso web
verifica a presença do Meu dia e a ausência do antigo Bloco SUPER na home.
O diff foi revisado e validado com `git diff --check`; análise estática, formatação
automática e testes Flutter desta integração permanecem pendentes por ausência
do SDK no ambiente.
