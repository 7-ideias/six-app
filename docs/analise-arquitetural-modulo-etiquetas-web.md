# Análise arquitetural — módulo de Etiquetas Web

Data da análise: 2026-08-15

## 0. Escopo, branch e limitações da análise

Esta etapa é exclusivamente de análise e planejamento. **Nenhum código-fonte do módulo de Etiquetas foi implementado.** O único arquivo criado por esta tarefa é este relatório.

### Frontend analisado

- Repositório: `7-ideias/six-app`
- Branch solicitada: `feature/20260814-melhorias`
- HEAD observado imediatamente antes da criação deste relatório: `b1403b81bdf4bdc8e047f062326d11d6093a7e3c`
- O relatório ainda não existia na branch no início da análise.

### Backend analisado somente como referência

- Repositório: `7-ideias/sixBack`
- A branch `feature/20260814-melhorias` **não existe** no backend.
- Referência analisada: `main`
- HEAD observado: `f22bb1b8060627fd7abd20d7d1ac81f63e1808dc`
- Nenhuma alteração foi feita no backend.

### Limitação importante do conector GitHub

O conector GitHub enxerga o estado versionado remoto, mas não o worktree local do desenvolvedor. Portanto, não é possível executar ou afirmar o resultado de `git status --short` do diretório local. A garantia desta tarefa é: **nenhum arquivo-fonte remoto foi alterado e nenhuma alteração backend foi feita; somente este Markdown foi criado na branch solicitada do frontend.**

---

# 1. Resumo executivo

O módulo de Etiquetas é tecnicamente viável e se encaixa bem na arquitetura atual. A localização proposta está correta:

```text
Catálogo
 ├── Produtos
 ├── Serviços
 ├── Estoque
 ├── Etiquetas
 └── Categorias
```

A navegação Web já é declarativa e possui exatamente o grupo `Catálogo` com `Produtos`, `Serviços`, `Estoque` e `Categorias`, o que torna a inclusão de `Etiquetas` um ajuste pequeno e previsível.

A recomendação principal é separar claramente quatro responsabilidades:

1. **modelo de etiqueta** — configuração persistida e reutilizável;
2. **editor/preview Web** — representação visual em Flutter, trabalhando com dimensões físicas convertidas para pixels somente na camada de apresentação;
3. **dados da impressão** — produtos ou outras entidades escolhidas no momento da impressão;
4. **renderização final** — PDF gerado no backend, reaproveitando o padrão já existente com OpenPDF e resposta base64.

O módulo não deve ser acoplado somente a Produtos. A estrutura deve trabalhar com `bindingKey`/origem de dados, permitindo evoluir para cliente, atendimento técnico, equipamento, patrimônio, fornecedor, lote e validade.

Para persistência, **MongoDB é a opção mais aderente ao estado atual do backend**, especialmente porque o projeto já usa documentos Mongo para configurações flexíveis e Produtos também é Mongo. Recomenda-se coleção própria de templates, em vez de inserir uma lista crescente dentro de `configuracoes_empresa`.

O maior risco não está no CRUD nem na sidebar. Os pontos que exigem prova técnica são:

- precisão física de impressão em 100%/tamanho real;
- códigos de barras/QR e cobertura das simbologias necessárias;
- consistência entre preview Flutter e PDF final;
- autorização por comércio em todas as operações.

---

# 2. Estado atual do projeto

## 2.1 Frontend

O frontend é Flutter e a branch analisada possui arquitetura organizada em `core`, `data`, `domain`, `presentation`, `providers`, `design_system` e `l10n`.

O `pubspec.yaml` atual declara, entre outras dependências:

- `http`;
- `provider`;
- `shared_preferences`;
- `flutter_localizations`;
- `intl`;
- `share_plus`;
- `mobile_scanner`.

Não foi encontrada dependência Flutter dedicada atualmente à **renderização** de barcode/QR ou à **geração de PDF**. `mobile_scanner` atende leitura/scaneamento, não o designer de etiquetas.

## 2.2 Backend

O backend remoto atual (`sixBack/main`) está em:

- Java 17;
- Spring Boot **3.2.5** no `pom.xml` observado;
- Spring Data MongoDB;
- Spring Data JPA;
- PostgreSQL runtime;
- Flyway;
- OAuth2 Resource Server;
- OpenPDF `1.3.43`.

Observação: o `pom.xml` atual diverge de documentação histórica que mencionava Spring Boot 3.0.2. Para qualquer implementação nova deve prevalecer a versão real do repositório no momento do desenvolvimento.

---

# 3. Sidebar e navegação Web

## 3.1 Fonte de definição

Arquivos principais:

- `lib/presentation/navigation/web_navigation_registry.dart`
- `lib/presentation/navigation/web_navigation_item.dart`
- `lib/presentation/navigation/web_navigation_permission_adapter.dart`
- `lib/presentation/navigation/web_navigation_destination_resolver.dart`
- `lib/presentation/navigation/web_navigation_destination_mapper.dart`
- `lib/presentation/navigation/pagina_principal_web_navigation_actions.dart`
- `lib/presentation/navigation/modulo_central_pdv.dart`
- `lib/presentation/navigation/web_sidebar_navigation.dart`
- `lib/presentation/layouts/authenticated_web_shell.dart`
- `lib/pagina_principal_web.dart`

O registry atual possui IDs declarativos:

```text
catalog
catalog.products
catalog.services
catalog.stock
catalog.categories
```

E o grupo Catálogo está hoje, na ordem:

1. Produtos
2. Serviços
3. Estoque
4. Categorias

Portanto, inserir `catalog.labels` entre `catalog.stock` e `catalog.categories` é aderente e não exige redesenhar a Sidebar.

## 3.2 Como a navegação funciona

A navegação autenticada atual não depende de uma rota Web independente para cada item. O fluxo observado é:

```text
WebNavigationRegistry
        ↓
WebNavigationPermissionAdapter
        ↓
AuthenticatedWebShell
        ↓
WebSidebarNavigation
        ↓
WebNavigationDestinationResolver
        ↓
PaginaPrincipalWebNavigationActions
        ↓
ModuloCentralPDV
        ↓
conteúdo central em PaginaPrincipalWeb
```

`PaginaPrincipalWeb` já constrói os itens através de `WebNavigationRegistry.activeItemsForPermissions(...)` e entrega a lista ao `AuthenticatedWebShell`. Portanto, o registry **já participa do runtime atual**.

Há uma pequena inconsistência documental: o comentário de `web_navigation_registry.dart` ainda diz que o menu atual não estaria conectado ao registry, mas o shell, `PaginaPrincipalWeb` e os testes demonstram que essa conexão já existe. Isso é apenas dívida documental e não deve gerar uma arquitetura paralela para Etiquetas.

## 3.3 Alterações futuras necessárias para incluir Etiquetas

Sem implementar agora, o caminho correto será adicionar conceitualmente:

```text
WebNavigationIds.catalogLabels
WebNavigationDestination.catalogLabels
ModuloCentralPDV.etiquetas
WebNavigationPermission.podeAcessarEtiquetas
```

E mapear o destino através dos adapters/resolver já existentes.

O ícone `Icons.local_offer_outlined` é coerente com o Material usado no registry e é uma escolha adequada para a primeira versão, desde que validado visualmente com a Sidebar.

## 3.4 Testes existentes que devem ser estendidos

O projeto já possui cobertura do shell em:

- `test/presentation/layouts/authenticated_web_shell_test.dart`

O teste valida:

- grupos visíveis;
- navegação para filhos;
- Sidebar expandida/recolhida;
- larguras de referência;
- seleção ativa;
- Light/Dark Mode.

Também existem testes de mapper/actions da navegação. A inclusão de Etiquetas deve seguir esse padrão, não criar um teste isolado de Sidebar sem integrar o destino real.

---

# 4. Produtos e Estoque — o que pode ser reaproveitado

## 4.1 Modelo atual

`lib/data/models/produto_model.dart` possui hoje, entre outros:

```text
id
ativo
codigoDeBarras
nomeProduto
tipoProduto
modeloProduto
estoqueMaximo
estoqueMinimo
precoVenda
objEntradaSaidaProduto
imagens
```

No backend, `ProdutoRequest` usa `UUID id`, `BigDecimal` para valores/estoques e mantém `codigoDeBarras`, `nomeProduto` e `precoVenda`.

### Lacunas para Etiquetas

Não existe, nos modelos analisados, campo explícito chamado:

- `sku`;
- `precoPromocional`.

Logo, o designer pode nascer preparado para bindings como `PRODUCT_SKU` ou `PRODUCT_PROMOTIONAL_PRICE`, mas esses bindings **não devem ser anunciados como dados reais disponíveis** até que o contrato de Produto possua uma fonte correspondente.

O `codigoDeBarras` atual pode atender o primeiro binding de barcode.

## 4.2 Seleção múltipla Web

`lib/presentation/screens/produto_lista_sub_painel_web.dart` já possui suporte explícito a:

```dart
permitirSelecaoMultipla
```

A tela também mantém mapa de itens selecionados e quantidade por item. Isso é muito aderente ao futuro fluxo:

```text
Produto A  → 3 etiquetas
Produto B  → 1 etiqueta
Produto C  → 10 etiquetas
```

Recomendação: reaproveitar a infraestrutura de busca/listagem/serviço e, quando possível, um componente Web de seleção. Evitar acoplar Etiquetas a tipos privados como `_ProdutoSelecionadoWeb`; se esse comportamento precisar ser compartilhado entre duas telas Web, extrair somente o contrato/componente Web necessário com escopo pequeno.

A Skill Web do projeto proíbe reutilizar UI principal Mobile em Web. Portanto, a nova experiência de Etiquetas deve possuir composição visual Web própria, compartilhando apenas models, services, providers e regras sem responsabilidade visual.

## 4.3 ProdutoService

`lib/core/services/produto_service.dart` já centraliza:

- listagem;
- cadastro;
- atualização;
- dashboard de produtos;
- dashboard de estoque;
- dashboard de serviços;
- relatório PDF de produtos.

Ele também já lê JWT e `idUnicoDaEmpresa` do `AuthService` para endpoints autenticados.

Não deve ser criada uma segunda camada HTTP de Produtos dentro do módulo de Etiquetas.

---

# 5. PDF — infraestrutura existente e recomendação

## 5.1 Padrão atual

Já existe um padrão claro de geração de PDF no backend e consumo no Flutter.

Exemplos:

### Atendimento técnico

- `AtendimentoTecnicoService.gerarPdf(...)`
- GET `${AppConfig.baseUrl}/atendimentos-tecnicos/{id}/pdf`
- backend retorna objeto com PDF em base64.

### Produtos

- `ProdutoService.gerarRelatorioListagemPdf()`
- GET `/private/api/produto/relatorio/listagem/pdf`
- backend retorna `arquivoBase64`, `nomeArquivo` e `mimeType`.

### Compartilhamento/download

- `lib/core/services/pdf_file_share_service.dart`
- `lib/core/utils/pdf_download.dart`

`PdfFileShareService` valida MIME, base64 e assinatura `%PDF`, e utiliza `share_plus`, com fallback de download no Web.

## 5.2 Backend atual

`RelatorioProdutoService` usa OpenPDF `1.3.43` e gera o documento em memória com `ByteArrayOutputStream`, devolvendo base64.

Isso torna desnecessário introduzir uma segunda estratégia de PDF no Flutter apenas para Etiquetas.

## 5.3 Recomendação

Arquitetura recomendada:

```text
Flutter Web
  ├── editor visual
  ├── preview proporcional
  └── seleção de produtos
          ↓
Backend Java
  ├── valida template
  ├── resolve dados reais
  ├── aplica regionalização
  └── gera PDF físico final
          ↓
Flutter Web
  ├── preview/download
  └── impressão pelo navegador
```

Portanto:

- **preview interativo**: Flutter Web;
- **PDF final para impressão**: backend Java/OpenPDF;
- **download/compartilhamento**: reaproveitar infraestrutura Flutter existente.

Essa abordagem reduz duplicação arquitetural e permite no futuro reutilizar o mesmo renderer para email, WhatsApp, jobs ou geração server-side.

---

# 6. Estratégia milímetros → pixels

O domínio deve persistir medidas físicas, não pixels.

Unidade canônica recomendada:

```text
milímetros
```

No backend, usar `BigDecimal` para dimensões e espaçamentos evita acumular erro binário em cálculos de grade.

No Flutter, `double` é adequado para renderização visual.

## 6.1 Preview do papel

Calcular uma escala visual conforme o espaço disponível:

```text
scaleX = larguraDisponivelPx / larguraPapelMm
scaleY = alturaDisponivelPx / alturaPapelMm
scale  = min(scaleX, scaleY)
```

E então:

```text
xPx      = xMm * scale
 yPx      = yMm * scale
larguraPx = larguraMm * scale
alturaPx  = alturaMm * scale
```

A mesma ideia serve para o canvas de uma única etiqueta.

Nenhuma coordenada em pixels deve ser persistida.

---

# 7. Estratégia milímetros → PDF

PDF usa pontos como unidade física. A conversão canônica é:

```text
1 inch = 25,4 mm
1 inch = 72 pt
1 mm   = 72 / 25,4 pt
```

Logo:

```text
points = millimeters * 72 / 25.4
```

Para uma etiqueta de 50 × 30 mm, por exemplo, o renderer final deve construir página/célula usando as dimensões convertidas em pontos, e não pixels ou DPI de tela.

## 7.1 Validação física obrigatória

Mesmo com PDF correto, navegador/driver pode aplicar:

- `Fit to page`;
- `Ajustar à página`;
- margens automáticas;
- escala diferente de 100%.

A UX deve orientar:

```text
Tamanho real / Escala 100%
```

E o produto deve posteriormente oferecer calibração X/Y.

## 7.2 Protótipo obrigatório antes do fechamento do renderer

Validar fisicamente pelo menos:

1. página térmica 50 × 30 mm;
2. A4 com várias linhas/colunas;
3. impressão em 100%;
4. acumulação de erro após a última linha/coluna;
5. pelo menos dois drivers/impressoras diferentes se disponíveis.

---

# 8. Barcode e QR Code

## 8.1 Estado atual Flutter

`pubspec.yaml` possui `mobile_scanner`, mas não foi encontrada dependência destinada a renderizar:

- CODE 128;
- CODE 39;
- EAN-13;
- EAN-8;
- UPC-A;
- ITF;
- QR Code.

Também não foi encontrado uso de `BarcodeWidget`, `QrImage` ou equivalente no código analisado.

## 8.2 Estado atual backend

OpenPDF já está disponível, porém não foi encontrado uso existente de classes de barcode/QR no backend.

Antes de adicionar biblioteca, executar um spike para verificar exatamente quais simbologias são cobertas de forma satisfatória pelo OpenPDF presente. Se a cobertura for insuficiente, avaliar biblioteca dedicada, como ZXing, somente no lote de renderização.

## 8.3 Recomendação

- definir um enum de simbologias no contrato;
- validar comprimento/check digit conforme a simbologia;
- não aceitar silenciosamente valor inválido;
- usar preview Flutter apenas como representação visual;
- backend continua sendo autoridade do PDF final.

---

# 9. Backend — ponto correto de integração

O padrão atual de recursos possui:

- Controller;
- Service;
- DTO;
- Repository;
- documentos/entities;
- validação de vínculo usuário × empresa;
- JWT em `@AuthenticationPrincipal`;
- `idUnicoDaEmpresa` em header.

A implementação futura deve seguir esse padrão, sem criar um micro-backend ou persistência paralela.

Sugestão conceitual de pacotes/classes no backend:

```text
controller/etiqueta/
  EtiquetaModeloController

dto/etiqueta/
  EtiquetaModeloRequest
  EtiquetaModeloResponse
  EtiquetaImpressaoRequest
  EtiquetaPdfResponse

document/etiqueta/
  EtiquetaModeloDocument
  EtiquetaPapelDocument
  EtiquetaGradeDocument
  EtiquetaElementoDocument

repository/
  EtiquetaModeloRepository

service/
  EtiquetaModeloService
  EtiquetaValidacaoService
  EtiquetaPdfService
```

Os nomes podem ser ajustados às convenções do backend no lote de implementação.

---

# 10. Persistência

## 10.1 MongoDB × PostgreSQL

O backend possui ambos, mas para Etiquetas o MongoDB é mais aderente por três motivos concretos:

1. Produtos já são `@Document("produtos")`;
2. configurações de empresa já usam `@Document(collection = "configuracoes_empresa")`;
3. um template contém árvore flexível de papel, grade e múltiplos elementos com propriedades específicas por tipo.

## 10.2 Coleção própria

Recomendação:

```text
modelos_etiqueta
```

ou nomenclatura equivalente existente.

Não embutir todos os templates dentro de `ConfiguracaoEmpresaDocument`, pois o ciclo de vida do template é próprio: listar, criar, editar, duplicar, excluir e futuramente versionar.

## 10.3 Escopo por comércio

Cada template personalizado deve ter um único:

```text
idUnicoDaEmpresa
```

indexado.

O template não deve aceitar `idUnicoDaEmpresa` do body como autoridade. O comércio vem do contexto/header autenticado e deve ser validado contra o usuário.

---

# 11. Multi-comércio e segurança

## 11.1 Padrão existente

No Flutter, `AuthService` persiste `idUnicoDaEmpresa` e diversos clients enviam:

```text
Authorization: Bearer ...
idUnicoDaEmpresa: ...
```

No backend, `ValidadorAcessoEmpresaDoUsuario.possuiVinculoComEmpresa(...)` valida o vínculo usando usuário autenticado e empresa.

`ProdutoController` aplica essa validação em listagem, detalhe, cadastro, atualização e dashboards.

## 11.2 Alerta encontrado

O endpoint atual de exclusão de Produto (`/apagar/{idProduto}`) não mostra, no controller analisado, a mesma validação JWT + empresa usada nos demais endpoints.

Isso **não deve ser copiado** para Etiquetas.

## 11.3 Regra obrigatória para Etiquetas

Todas as operações abaixo devem validar vínculo e escopo no backend:

```text
LIST
GET
CREATE
UPDATE
DELETE
DUPLICATE
PRINT
```

Além disso, repository/service devem buscar sempre por combinação equivalente a:

```text
id do template + idUnicoDaEmpresa
```

Nunca fazer `findById(id)` e somente depois confiar no frontend para esconder o template.

---

# 12. Permissões

## 12.1 Frontend atual

`ColaboradorAutorizacoesProvider` expõe permissões como:

```text
podeFazerVenda
podeLancarAssistenciaTecnica
podeEditarCliente
podeCadastrarProduto
podeEditarProduto
podeVerEstoqueDeProduto
podeGerarRelatorio
podeReceberNoCaixa
podeVerQuantoVendeu
```

`WebNavigationPermissionAdapter` converte essas permissões para `WebNavigationPermission` e ADMIN recebe todas as permissões declaradas no enum.

## 12.2 Backend atual

`ValidadorAcessoEmpresaDoUsuario` já lida com permissões textuais e reconhece, no fluxo de assistência técnica:

```text
TODAS
ADMINISTRADOR
ASSISTENCIA_TECNICA_CRIAR
```

## 12.3 Proposta para Etiquetas

Seguindo o padrão textual uppercase atual, considerar:

```text
ETIQUETAS_VISUALIZAR
ETIQUETAS_CRIAR
ETIQUETAS_EDITAR
ETIQUETAS_EXCLUIR
ETIQUETAS_IMPRIMIR
```

No frontend, evitar cinco regras de visibilidade na Sidebar. A Sidebar pode usar uma capacidade agregada como `podeAcessarEtiquetas`, verdadeira se houver pelo menos visualizar/criar/editar/imprimir, e a própria tela restringe ações específicas.

A autorização final deve ocorrer também no backend.

---

# 13. Internacionalização e regionalização

## 13.1 Mecanismo atual

O projeto usa `context.t(...)` em `lib/l10n/six_i18n.dart`.

O comentário da extensão confirma que o valor preferencial vem do pacote de traduções carregado do backend, com fallback local durante migração.

A navegação já usa chaves como:

```text
web.navigation.catalog
web.navigation.catalog.products
web.navigation.catalog.services
web.navigation.catalog.stock
web.navigation.catalog.categories
```

Portanto, Etiquetas deve introduzir chave equivalente:

```text
web.navigation.catalog.labels
```

E chaves próprias para editor, papel, layout, elementos e erros.

## 13.2 Medidas e moeda

Internamente, milímetros são uma boa unidade canônica mundial para persistência e cálculo.

Para distribuição internacional, a UI pode futuramente oferecer exibição em `mm` ou `in` conforme preferência/região, convertendo somente na apresentação. A persistência continua em mm.

Preço deve usar `LocaleSettingsProvider`/infraestrutura regionalizada existente e nunca hardcode `R$` no novo módulo.

O backend também deve respeitar configurações regionais do comércio ao resolver valores impressos.

---

# 14. Modelo de domínio proposto

## 14.1 Entidades conceituais

```text
LabelTemplate
 ├── LabelPaper
 ├── LabelGrid
 ├── LabelSize
 └── List<LabelElement>

LabelPrintRequest
 └── List<LabelPrintItem>
```

No código Java/Dart, decidir no lote de implementação se os nomes permanecerão em inglês ou serão traduzidos para o padrão predominante do módulo. A arquitetura importa mais do que o nome.

## 14.2 Template

Campos sugeridos:

```text
id
idUnicoDaEmpresa
nome
descricao
ativo
paper
grid
label
elements
createdAt
updatedAt
createdBy
updatedBy
```

## 14.3 Papel

```text
preset: A4 | LETTER | CUSTOM | ...
widthMm
heightMm
orientation: PORTRAIT | LANDSCAPE
```

## 14.4 Grade

```text
columns
rows
marginTopMm
marginBottomMm
marginLeftMm
marginRightMm
horizontalGapMm
verticalGapMm
```

## 14.5 Dimensão da etiqueta

```text
widthMm
heightMm
```

## 14.6 Elemento

Campos comuns:

```text
id local do elemento
type
bindingKey
xMm
yMm
widthMm
heightMm
zIndex
properties
```

`properties` deve conter somente propriedades específicas do tipo. Exemplo:

```json
{
  "type": "BARCODE",
  "bindingKey": "PRODUCT_BARCODE",
  "xMm": 3,
  "yMm": 17,
  "widthMm": 55,
  "heightMm": 10,
  "properties": {
    "barcodeType": "CODE128",
    "showText": true
  }
}
```

Para texto livre:

```json
{
  "type": "FREE_TEXT",
  "properties": {
    "text": "Oferta"
  }
}
```

Não persistir valores de preview como `Fone Bluetooth XYZ` ou `R$ 129,90` quando o elemento representar dado dinâmico.

---

# 15. Binding de dados e extensibilidade

O elemento não deve conhecer diretamente `ProdutoModel`.

Usar chaves de binding conceituais, por exemplo:

```text
PRODUCT_NAME
PRODUCT_PRICE
PRODUCT_BARCODE
PRODUCT_INTERNAL_CODE
COMPANY_NAME
FREE_TEXT
```

Futuramente:

```text
CUSTOMER_NAME
SERVICE_ORDER_NUMBER
IMEI
SERIAL_NUMBER
SUPPLIER_NAME
LOT
EXPIRATION_DATE
```

Uma camada resolver no backend transforma o binding em valor real para cada item de impressão.

Isso permite que o mesmo renderer seja usado para vários domínios sem transformar `LabelElement` em uma entidade com dezenas de campos opcionais.

---

# 16. Validação geométrica

A grade deve ser validada no backend e pode ser validada preventivamente no Flutter.

Horizontal:

```text
marginLeft
+ (columns * labelWidth)
+ ((columns - 1) * horizontalGap)
+ marginRight
<= paperWidth
```

Vertical:

```text
marginTop
+ (rows * labelHeight)
+ ((rows - 1) * verticalGap)
+ marginBottom
<= paperHeight
```

Também validar:

- dimensões > 0;
- rows/columns > 0;
- margens/gaps >= 0;
- elemento contido dentro da etiqueta;
- barcode/QR válido para a simbologia;
- texto livre com limites razoáveis;
- limite máximo de elementos por template para evitar payloads abusivos.

---

# 17. API proposta

Mantendo o prefixo privado atual, proposta inicial:

```text
GET    /private/api/etiquetas/modelos
GET    /private/api/etiquetas/modelos/{id}
POST   /private/api/etiquetas/modelos
PUT    /private/api/etiquetas/modelos/{id}
POST   /private/api/etiquetas/modelos/{id}/duplicar
DELETE /private/api/etiquetas/modelos/{id}
POST   /private/api/etiquetas/impressao/pdf
```

Todos com JWT e `idUnicoDaEmpresa` obrigatório.

## 17.1 Impressão

Payload conceitual:

```json
{
  "templateId": "...",
  "sourceType": "PRODUCT",
  "items": [
    {"sourceId": "produto-1", "quantity": 3},
    {"sourceId": "produto-2", "quantity": 1}
  ]
}
```

O backend deve buscar os produtos pelos IDs dentro do comércio atual. Não receber nome/preço/barcode como autoridade do frontend.

Resposta deve preferencialmente reaproveitar formato já conhecido:

```json
{
  "arquivoBase64": "...",
  "nomeArquivo": "etiquetas-20260815-132000.pdf",
  "mimeType": "application/pdf"
}
```

---

# 18. Templates de sistema × templates do comércio

Existem duas estratégias possíveis.

## Opção recomendada para o primeiro ciclo

Manter presets de papel/layout básicos como definições do sistema e, ao usuário escolher personalizar, criar uma cópia pertencente ao comércio.

Isso reduz complexidade de autorização.

Exemplos:

```text
A4 — 30 etiquetas
A4 — 21 etiquetas
40 × 30 mm
50 × 30 mm
60 × 40 mm
100 × 50 mm
```

Se futuramente templates de sistema precisarem ser administrados remotamente, adicionar `scope = SYSTEM | COMMERCE` com regras explícitas de imutabilidade e acesso.

---

# 19. Estratégia do editor Flutter Web

A Skill Web do projeto determina UI Web própria e reutilização apenas de camadas não visuais compartilhadas.

## 19.1 Estrutura sugerida

Desktop largo:

```text
┌──────────────────────────────────────────────────────────────┐
│ Etiquetas > Editar modelo                  [Salvar modelo]   │
├───────────────┬────────────────────────┬─────────────────────┤
│ Configuração  │                        │ Propriedades        │
│               │       ETIQUETA         │                     │
│ Papel         │                        │ Fonte               │
│ Grade         │ Nome do produto        │ Tamanho             │
│ Margens       │ R$ 129,90              │ Alinhamento         │
│               │ |||||||||||||||||||    │ Código              │
│ Elementos     │                        │                     │
├───────────────┴────────────────────────┴─────────────────────┤
│                    Preview da folha                         │
└──────────────────────────────────────────────────────────────┘
```

## 19.2 Widgets recomendados

Primeira versão:

- `LayoutBuilder` para escala e responsividade;
- `Stack` + `Positioned` para elementos;
- `GestureDetector`/eventos de ponteiro para mover/redimensionar;
- `AnimatedContainer`/`AnimatedSwitcher` para estados;
- `CustomPainter` somente se grade/régua/snap justificar.

Não há necessidade de adotar um framework de canvas complexo no primeiro lote.

## 19.3 Carga cognitiva

Agrupar configurações em seções progressivas:

```text
Papel
Layout
Conteúdo
Código
Preview
```

O usuário iniciante deve conseguir começar por preset; o modo personalizado expõe medidas avançadas.

---

# 20. Página inicial do módulo

Referências de linguagem visual:

- `lib/presentation/screens/produto_dashboard_web_page.dart`
- `lib/presentation/components/web_dashboard_widgets.dart`
- `lib/presentation/theme/web_theme_tokens.dart`
- componentes e regras da Skill `sixapp-web-ui`.

Primeira tela sugerida:

```text
Etiquetas

[ + Criar modelo ]                         [ Imprimir etiquetas ]

Seus modelos

┌────────────────────────┐
│ Etiqueta padrão        │
│ 50 × 30 mm             │
│ A4 / 3 × 8             │
│                        │
│ Editar      Imprimir   │
└────────────────────────┘
```

Estados obrigatórios:

- loading;
- vazio;
- erro;
- sem permissão;
- sucesso de exclusão/duplicação.

---

# 21. Componentes e infraestrutura reutilizáveis

| Área | Evidência atual | Reuso recomendado |
|---|---|---|
| Sidebar | `WebNavigationRegistry` + `WebSidebarNavigation` | adicionar filho declarativo |
| Shell | `AuthenticatedWebShell` | manter layout e responsividade |
| Permissões | `ColaboradorAutorizacoesProvider` + adapter | estender capacidades existentes |
| Tenant | `AuthService.getEmpresaId()` | mesmo header/contexto |
| Produto | `ProdutoService` / `ProdutoModel` | resolver dados e selecionar produtos |
| Seleção múltipla | `SubPainelWebProdutoLista` | reaproveitar padrão Web, sem depender de tipos privados |
| PDF server-side | `RelatorioProdutoService` + OpenPDF | base para renderer físico |
| Share PDF | `PdfFileShareService` | compartilhar/baixar resposta |
| Download Web | `pdf_download.dart` | download explícito |
| i18n | `context.t(...)` | todas as strings novas |
| Regionalização | `LocaleSettingsProvider` | moeda/números/unidades de exibição |
| Tema | `WebThemeTokens` | editor/lista coerentes com Light/Dark |

---

# 22. Dependências existentes relevantes

## Flutter

```text
provider
http
http_interceptor
intl
share_plus
mobile_scanner
flutter_localizations
```

Nenhuma dependência atual identificada para desenho de barcode/QR ou criação de PDF no Flutter.

## Backend

```text
spring-boot-starter-web
spring-boot-starter-data-mongodb
spring-boot-starter-data-jpa
postgresql
openpdf 1.3.43
spring-security oauth2 resource server
```

---

# 23. Dependências potencialmente necessárias — não instalar agora

Somente após spike:

- biblioteca Flutter de barcode/QR para o preview do editor, se necessário;
- biblioteca Java dedicada a barcode/QR, como ZXing, se OpenPDF não cobrir adequadamente todas as simbologias.

Evitar adicionar package antes de confirmar cobertura técnica.

---

# 24. Riscos técnicos

## Alto

### 24.1 Precisão física da impressão

PDF pode estar matematicamente correto e ainda ser escalado pelo navegador/driver.

### 24.2 Segurança multi-comércio

Template é configuração operacional do comércio. Qualquer `findById` sem escopo de empresa cria risco de vazamento/alteração cross-tenant.

### 24.3 Divergência preview × impressão

Flutter e Java usarão engines de layout diferentes. O preview deve ser proporcional e confiável, mas a autoridade física será o PDF server-side.

## Médio

### 24.4 Barcode/QR

Cobertura de simbologias ainda não provada no stack atual.

### 24.5 Drag/resize

Precisa boa UX com mouse, touchpad, teclado e limites físicos.

### 24.6 Campos de Produto

SKU e preço promocional não estão presentes nos contratos analisados.

### 24.7 Internacionalização de unidades

Persistir mm é simples; exibir polegadas futuramente exige conversão e arredondamento consistente.

## Baixo

### 24.8 Inclusão na Sidebar

O registry já possui o ponto exato de inserção.

### 24.9 CRUD básico

Mongo/Spring e padrões de API já existem no projeto.

---

# 25. Decisões que precisam de protótipo

## Spike A — PDF físico

Gerar:

- 50 × 30 mm;
- A4 com grade 3 × 8;
- margens/gaps conhecidos.

Imprimir e medir fisicamente.

## Spike B — barcode

Testar no renderer backend:

```text
CODE128
CODE39
EAN13
EAN8
UPCA
ITF
QR
```

Confirmar qualidade de leitura em tamanhos pequenos.

## Spike C — editor

Protótipo Flutter Web com 3 elementos dentro de uma etiqueta:

- texto;
- preço;
- barcode placeholder.

Validar mover, selecionar, redimensionar e converter mm ↔ px sem persistência.

---

# 26. Roadmap recomendado

## Lote 0 — spikes técnicos

- precisão física do PDF;
- barcode/QR;
- protótipo simples de drag/resize.

Objetivo: eliminar riscos antes de consolidar contratos de renderização.

## Lote 1 — fundação backend

- documento Mongo do template;
- repository tenant-scoped;
- DTOs;
- validação geométrica;
- CRUD;
- duplicação;
- permissões;
- testes de isolamento entre empresas.

## Lote 2 — entrada Web e CRUD

- `Catálogo > Etiquetas`;
- destino/resolver;
- página Web própria;
- listagem;
- criar/renomear/duplicar/excluir;
- i18n;
- testes de navegação e permissão.

## Lote 3 — editor visual

- presets de papel;
- medidas;
- grade;
- elementos;
- painel de propriedades;
- preview da etiqueta;
- preview da folha.

## Lote 4 — seleção de produtos

- busca/listagem existente;
- seleção múltipla;
- quantidade de etiquetas por produto;
- bindings reais disponíveis.

## Lote 5 — PDF final

- renderer backend;
- barcode/QR;
- response base64;
- download/preview/print;
- testes físicos.

## Lote 6 — evolução

- calibração X/Y;
- histórico de impressão;
- configuração por impressora;
- ZPL/EPL;
- agente local;
- novos domínios de bindings.

---

# 27. Arquivos que provavelmente serão alterados no frontend

Sem alterar agora, a implementação deve afetar principalmente:

```text
lib/presentation/navigation/web_navigation_registry.dart
lib/presentation/navigation/web_navigation_item.dart
lib/presentation/navigation/web_navigation_destination_resolver.dart
lib/presentation/navigation/web_navigation_destination_mapper.dart
lib/presentation/navigation/modulo_central_pdv.dart
lib/presentation/navigation/pagina_principal_web_navigation_actions.dart
lib/pagina_principal_web.dart
lib/providers/colaborador_autorizacoes_provider.dart
lib/data/models/colaborador_autorizacoes_model.dart
lib/l10n/six_i18n.dart
```

Novos arquivos esperados, nomes ainda conceituais:

```text
lib/presentation/screens/etiquetas_web_page.dart
lib/presentation/screens/etiqueta_editor_web_page.dart
lib/data/models/etiqueta_model.dart
lib/data/services/etiqueta/etiqueta_api_client.dart
lib/domain/services/etiqueta/etiqueta_service.dart
```

Testes prováveis:

```text
test/presentation/layouts/authenticated_web_shell_test.dart
test/presentation/navigation/web_navigation_destination_mapper_test.dart
test/presentation/navigation/pagina_principal_web_navigation_actions_test.dart
novos testes do módulo Etiquetas
```

Nenhum arquivo Mobile deve ser alterado para criar a UI Web.

---

# 28. Arquivos/classes que provavelmente serão criados ou alterados no backend

A implementação backend deve ocorrer em branch própria do repositório `sixBack`; **não escrever diretamente em `main`**.

Possíveis novos arquivos:

```text
controller/etiqueta/EtiquetaModeloController.java
dto/etiqueta/...
document/etiqueta/EtiquetaModeloDocument.java
repository/EtiquetaModeloRepository.java
service/EtiquetaModeloService.java
service/EtiquetaValidacaoService.java
service/EtiquetaPdfService.java
```

Possíveis alterações:

- estrutura de autorizações do colaborador;
- serviço/validador de permissões;
- `pom.xml` somente se spike provar necessidade de biblioteca barcode/QR.

Não alterar Produto para encaixar Etiquetas artificialmente.

---

# 29. Estratégia de testes

## Frontend

- ordem `Estoque → Etiquetas → Categorias`;
- visibilidade conforme permissão;
- ADMIN com acesso;
- resolver do destino;
- item ativo no shell;
- Sidebar expandida/recolhida;
- Light/Dark;
- larguras 920/1024/1280/1366/1440/1920;
- mm → px;
- seleção e movimentação de elemento;
- estado vazio/loading/erro;
- i18n sem strings novas críticas hardcoded.

## Backend

- CRUD;
- template de empresa A invisível para empresa B;
- GET/PUT/DELETE/DUPLICATE/PRINT tenant-scoped;
- permissões por operação;
- validação geométrica horizontal/vertical;
- elementos fora da etiqueta;
- barcode inválido;
- duplicação cria novo ID e mantém escopo;
- geração PDF com MediaBox/tamanho físico esperado;
- quantidade correta de etiquetas;
- produto solicitado pertencente ao comércio atual.

---

# 30. Veredito final

## Onde Etiquetas deve ficar?

**Dentro de Catálogo, imediatamente depois de Estoque e antes de Categorias.** A arquitetura atual confirma que esse é o ponto natural e de baixo impacto.

## Como integrar a navegação?

Pelo `WebNavigationRegistry` e cadeia `Destination → Resolver → Actions → ModuloCentralPDV` já existente. Não criar segunda Sidebar nem nova estratégia de roteamento somente para Etiquetas.

## Onde persistir?

**MongoDB, coleção própria de modelos de etiqueta**, com `idUnicoDaEmpresa` indexado e estrutura aninhada para papel, grade e elementos.

## Quem deve gerar o PDF?

**Backend Java**, reaproveitando o padrão já existente de OpenPDF + resposta base64. Flutter Web deve ser responsável pelo editor/preview e consumo do PDF.

## Como representar medidas?

Persistir em **milímetros**, usando `BigDecimal` no backend. Converter para pixels somente no preview e para points somente no PDF.

## Como representar conteúdo dinâmico?

Por bindings (`PRODUCT_NAME`, `PRODUCT_PRICE`, `PRODUCT_BARCODE`, etc.), não por campos específicos espalhados pelo template e não salvando dados de preview.

## Principais riscos

1. escala física real da impressão;
2. autorização cross-tenant;
3. barcode/QR e simbologias;
4. divergência entre preview visual e renderer final;
5. bindings que ainda não existem no Produto, especialmente SKU/preço promocional.

## Próxima etapa recomendada

Antes do CRUD completo, executar o **Lote 0 técnico** de maneira pequena e descartável/controlada para validar:

- PDF 50 × 30 mm e A4 em escala real;
- cobertura de barcode/QR;
- drag/resize básico em Flutter Web.

Depois disso, seguir para o **Lote 1 — fundação backend e contratos**, em branch própria do `sixBack`, mantendo a branch `feature/20260814-melhorias` do `six-app` para a evolução Web correspondente.

---

# 31. Evidências principais consultadas

Frontend `six-app`:

```text
AGENTS.md
.agents/skills/sixapp-web-ui/SKILL.md
pubspec.yaml
lib/pagina_principal_web.dart
lib/presentation/layouts/authenticated_web_shell.dart
lib/presentation/navigation/web_sidebar_navigation.dart
lib/presentation/navigation/web_navigation_registry.dart
lib/presentation/navigation/web_navigation_item.dart
lib/presentation/navigation/web_navigation_permission_adapter.dart
lib/presentation/navigation/web_navigation_destination_resolver.dart
lib/presentation/navigation/web_navigation_destination_mapper.dart
lib/presentation/navigation/pagina_principal_web_navigation_actions.dart
lib/presentation/navigation/modulo_central_pdv.dart
lib/data/models/produto_model.dart
lib/core/services/produto_service.dart
lib/presentation/screens/produto_lista_sub_painel_web.dart
lib/core/services/pdf_file_share_service.dart
lib/core/utils/pdf_download.dart
lib/data/services/atendimento_tecnico/atendimento_tecnico_api_client.dart
lib/domain/services/atendimento_tecnico/atendimento_tecnico_service.dart
lib/providers/colaborador_autorizacoes_provider.dart
lib/providers/empresa_provider.dart
lib/core/services/auth_service.dart
lib/l10n/six_i18n.dart
test/presentation/layouts/authenticated_web_shell_test.dart
```

Backend `sixBack/main` — somente leitura:

```text
pom.xml
src/main/java/br/com/seteideias/sixback/dto/produto/ProdutoRequest.java
src/main/java/br/com/seteideias/sixback/repository/entity/ProdutosEntity.java
src/main/java/br/com/seteideias/sixback/controller/produto/ProdutoController.java
src/main/java/br/com/seteideias/sixback/service/RelatorioProdutoService.java
src/main/java/br/com/seteideias/sixback/service/ValidadorAcessoEmpresaDoUsuario.java
src/main/java/br/com/seteideias/sixback/document/configuracao/ConfiguracaoEmpresaDocument.java
```

**Fim da análise. Nenhuma implementação do módulo foi iniciada nesta etapa.**