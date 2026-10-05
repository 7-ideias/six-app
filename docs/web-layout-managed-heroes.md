# Layout e cabeçalhos das páginas operacionais Web

Branch nos dois repositórios: `feature/20261005-web-layout-managed-heroes`.

As páginas Vendas, Devoluções e trocas, Caixa, Assistências técnicas, Compras,
Reservas, Produtos, Estoque, Clientes, Colaboradores, Desempenho, Agenda financeira
e Usuários do Sixo, além da tela inicial, usam
`SixWebPageShell` e `SixManagedWebHero`.
As margens são calculadas sobre a área disponível depois da barra lateral:

| Largura disponível | Margem em cada lado |
| --- | --- |
| Menor que 1200 px | 16 px |
| De 1200 até 1599 px | 24 px |
| A partir de 1600 px | 32 px |

O conteúdo ocupa até 1680 px, centralizado, com margem vertical de 20 px.
O cabeçalho tem altura mínima de 196 px, ou 180 px abaixo de 760 px de largura.
Textos e ações podem aumentar sua altura. Indicadores, filtros e listas usam a
mesma largura externa; no Caixa, os quatro indicadores dividem toda a largura
disponível, sem o antigo limite de 360 px por card. O layout mobile das devoluções mantém
seu cabeçalho e suas margens anteriores.

## Espaçamento único das 15 telas

As quatorze páginas acima e o painel de imagens do administrador usam a mesma
regra de margem externa. O painel aplica o shell tanto dentro da navegação
principal quanto no portal administrativo independente, sem duplicar margens.

| Elemento | Medida compartilhada |
| --- | --- |
| Margem vertical externa | 20 px |
| Cabeçalho até o primeiro bloco | 16 px |
| Intervalo entre seções principais | 16 px |
| Intervalo entre colunas e indicadores principais | 16 px |
| Recuo inferior das áreas de rolagem | 12 px |

Essas medidas ficam em `SixWebPageShell`. `SixWebPageBody` aplica o intervalo
após cabeçalhos fixos antes da troca de estado: dados, carregamento, vazio e
erro recebem o mesmo recuo. Nas páginas com cabeçalho rolável, o intervalo usa
`sectionGap` ou `sectionPadding`. Os painéis operacional e de desempenho da
Home também usam os mesmos intervalos de seção. Grades recalculam a largura
dos cards considerando o espaçamento, para preservar alinhamento e evitar
estouro nas colunas.

Espaços internos de textos, ícones, botões e linhas de listas continuam seguindo
a hierarquia de cada componente; não são margens externas ou intervalos entre
seções. As medidas mobile da jornada de devoluções são preservadas.

## Imagens e atualização de contexto

O Flutter solicita
`GET /private/api/web-header/assets?incluirOperacionais=true`, com autenticação
e o cabeçalho `idUnicoDaEmpresa`. A resposta inclui os quatorze códigos de páginas,
quando há uma imagem resolvida. Sem a opção, o backend mantém os três códigos
originais para clientes anteriores.

Os novos slots aparecem no painel de assets visuais do administrador, com nomes
em português, inglês e espanhol. Eles permitem upload e agendamento pelos
fluxos existentes. A dimensão recomendada é 1800 × 560 px. Até haver arte própria,
o backend reaproveita assets genéricos já publicados; não é necessário publicar
arquivos novos para o primeiro teste.

Ao trocar empresa ou perfil de negócio, o controlador limpa a imagem, mostra
shimmer e busca o catálogo do novo contexto. Respostas atrasadas são descartadas.
Eventos de versão dos assets também recarregam o catálogo; a versão global é
incluída na URL para invalidar o cache. Falhas de rede mantêm o cabeçalho legível
com o fundo do tema.

## Teste local

1. Faça checkout da mesma branch em `six-app` e `sixBack`.
2. Inicie o backend com a configuração local existente na porta 8082.
3. No Flutter, execute:

   ```bash
   flutter pub get
   API_BASE_URL=http://localhost:8082 bash scripts/dev_web_hot_reload.sh
   ```

4. Entre pela rota `http://localhost:39441/login/flutter`.
5. Confira as quatorze páginas com barra lateral aberta e recolhida, em larguras
   menores e maiores, nos temas claro e escuro. Verifique o alinhamento das
   bordas dos cabeçalhos, filtros, indicadores e listas.
6. Troque de empresa e de segmento/subsegmento. Confira o shimmer, a nova imagem
   e a ausência de imagens do contexto anterior.
7. Como administrador autorizado, confira os onze slots adicionais, publique
   uma imagem por um fluxo já existente e force a atualização de versão.
   Confira também um agendamento vigente no ambiente local.
8. Exercite as ações existentes de cada página, inclusive devoluções, caixa,
   filtros e navegação para cadastros. Compras continua sendo um protótipo com
   dados em memória.

Os testes de API não substituem essa revisão autenticada com os dados locais.

## Verificações executadas na entrega inicial

- Build Web release com Flutter 3.41.4 / Dart 3.11.1: concluído.
- Análise dos arquivos alterados: sem erros novos; os seis apontamentos também
  ocorrem na `main` usada como base. Os componentes novos não têm apontamentos.
- Testes selecionados do Flutter: 18 passaram. Três verificações de texto-fonte
  já falham na `main`: a de modais de Assistências e duas de tema do catálogo
  (`tokens.workspaceBackground` e `tokens.stockWarning`).
- Backend: compilação concluída e nove testes de cabeçalhos, ambiente e versão
  passaram, incluindo a resposta legada de três páginas.

Comando do build local:

```bash
flutter build web --dart-define=API_BASE_URL=http://localhost:8082
```

As telas autenticadas com a base local ainda devem ser revisadas pelo roteiro
acima antes dos PRs. As verificações foram feitas sem alterar dependências ou
configurações de ambiente versionadas.

## Complemento: Caixa, Clientes, Colaboradores e Desempenho

Clientes e Colaboradores passaram a usar o mesmo cabeçalho, incluindo shimmer,
invalidação de cache e troca de contexto. Seus indicadores, filtros e listas
ficam alinhados ao cabeçalho também durante o carregamento. Desempenho ganhou
o mesmo shell e o slot `WEB_DESEMPENHO_HEADER`, gerenciável no painel SUPER.
Até a publicação de uma arte própria, o backend pode reaproveitar o slot de
Colaboradores ou uma imagem genérica já publicada.

Para conferir as imagens de Caixa e Desempenho, execute também o backend desta
branch atualizado. A resposta sem `incluirOperacionais=true` continua limitada
aos três códigos originais.

Verificações deste complemento: build Web release concluído; análise sem erros
novos (três apontamentos anteriores no painel administrativo); nove testes
backend e quinze testes Flutter passaram. Duas falhas nos testes mobile de
Colaboradores (superfícies dark e texto do estado vazio) foram reproduzidas na
`main` original. Nenhum arquivo de tela mobile foi alterado neste complemento.

## Complemento: Agenda financeira e Usuários do Sixo

As duas páginas usam o mesmo shell e cabeçalho gerenciado. Na Agenda, os cards
não acrescentam margem externa ao shell e as ações continuam disponíveis no
cabeçalho, incluindo atualização, novo lançamento e fechamento quando aplicável.
A indicação de última atualização respeita o formato de hora global da empresa.
Em Usuários do Sixo, indicadores, busca e lista usam a largura comum de até
1680 px, sem o limite anterior de 1360 px e sem margem horizontal duplicada.
O acesso SUPER e a navegação para detalhes foram preservados.

Os slots `WEB_AGENDA_FINANCEIRA_HEADER` e `WEB_USUARIOS_SIXO_HEADER` aparecem
no painel de imagens. Agenda pode reaproveitar o slot de Caixa; Usuários do Sixo,
o de Colaboradores. Ambos também têm fallback genérico publicado. Atualize os
dois repositórios antes do teste local.

Verificações deste complemento: build Web release concluído; análise dos
arquivos alterados sem erros novos
(três apontamentos anteriores no painel administrativo); nove testes backend e
19 testes Flutter passaram. Três falhas foram reproduzidas na `main`: uma
verificação de texto-fonte no modal de lançamento e duas verificações de textos
nos estados financeiros/erro da Agenda mobile. Nenhuma tela mobile foi alterada.

## Complemento: tela inicial Web

A Home usa `SixWebPageShell`, com largura máxima de 1680 px e as mesmas margens
calculadas depois da barra lateral. O limite anterior de 1280 px foi removido.
O cabeçalho usa `SixManagedWebHero` e o slot `WEB_INICIO_HEADER`, preservando a
saudação, o nome do comércio, a data operacional e a ação de atualizar.
O rótulo “Meu dia no SixoApp” continua acima da saudação. Os painéis operacional,
de desempenho e de infraestrutura SUPER mantêm suas regras e navegação.

O slot pode ser publicado e agendado no painel de imagens. Sem imagem própria,
o backend pode reaproveitar o slot de Vendas ou sua imagem genérica publicada.
A troca de empresa/perfil e os eventos de versão usam o mesmo shimmer e a mesma
invalidação de cache dos demais cabeçalhos. Os banners “Para o seu negócio”
continuam usando o catálogo existente, separados do slot do cabeçalho.

Atualize frontend e backend na mesma branch antes de testar a Home. Confira
ADMIN, COLABORADOR e SUPER, temas claro/escuro e barra lateral aberta/recolhida.

Verificações da Home: build Web release concluído; nove testes backend e
21 testes Flutter passaram, incluindo
largura/alinhamento em cinco tamanhos de tela, temas claro/escuro, navegação,
traduções e troca de tema sem recarregar os dados. Duas falhas existentes foram
reproduzidas na `main`: texto da abertura do caixa e localização das ações
rápidas no cenário de permissões do teste. A análise não encontrou erros novos;
os três apontamentos anteriores continuam no painel administrativo.

## Verificações da padronização de espaçamento

A auditoria confirmou o shell compartilhado nas 15 telas e o recuo comum nos
oito layouts com cabeçalho fixo. O teste existente da Home agora mede margem
superior, distância do cabeçalho ao carrossel e intervalo entre indicadores em
1024, 1280, 1366, 1440 e 1920 px. Essas medições passaram, junto aos testes de
temas e navegação selecionados. Build Web release concluído.

Na seleção executada, 22 testes Flutter passaram e as duas falhas anteriores
da Home permaneceram (data do caixa e ações rápidas/permissões). A análise dos
arquivos alterados não encontrou erros novos; os apontamentos existentes de
imports, finally, parâmetro opcional, campos depreciados e chaves de if continuam
nos arquivos anteriores. Os testes autenticados locais seguem o roteiro acima.

## Esmaecimento e exclusão no painel de imagens

O painel SUPER possui uma configuração global de esmaecimento por ambiente,
com intensidade e alcance independentes para os temas claro e escuro. A prévia
usa o mesmo gradiente do `SixManagedWebHero`, incluindo a simulação compacta.
Os valores originais (intensidade 100%, alcance 42%) continuam valendo em
instalações sem configuração. Intensidade zero remove a sobreposição.

Os valores são carregados e salvos em `GET/PUT /private/api/admin/visual-assets/web-hero-appearance`.
O manifesto de cabeçalhos inclui `appearance`; a publicação usa a versão e o
WebSocket existentes para invalidar os caches e atualizar as telas abertas.

Em um segmento ou especialidade, “Apagar imagem” remove somente o vínculo
selecionado da imagem atual. O backend exige acesso SUPER, propriedade do
ambiente e um padrão global cadastrado para a posição. Outras especialidades
que compartilham o cadastro são preservadas. Um marcador interno direciona a
resolução ao padrão global, inclusive em DEV quando existe uma imagem
contextual herdada de LIVE. O painel mostra o padrão global após a exclusão.
Novos uploads podem substituir esse marcador. Agendamentos já existentes
mantêm suas datas e são informados na confirmação. Exclusão e arquivamento
continuam sendo ações distintas; a imagem excluída não aparece no histórico.

Para validar localmente, atualize frontend e backend desta branch:

1. No painel, ajuste um tema, salve e reabra; confirme que o outro tema manteve
   seus valores e que Home e as demais telas refletem a mudança.
2. Confira intensidade zero e 100%, além da prévia compacta.
3. Cadastre um padrão global e uma imagem específica, exclua a específica e
   confira o padrão global no painel e na tela operacional.
4. Em imagens com múltiplas especialidades, confirme que as demais continuam
   usando a imagem original; confira também DEV/LIVE e a ativação agendada.
