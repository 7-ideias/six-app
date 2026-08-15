# Implementação do módulo de Etiquetas Web

Data: 2026-08-15

## Status

**IMPLEMENTADO NA BRANCH DE FEATURE**

Branch utilizada em ambos os repositórios:

```text
feature/20260814-melhorias
```

Frontend:

```text
7-ideias/six-app
```

Backend:

```text
7-ideias/sixBack
```

## Regra de plataforma respeitada

A interface visual do módulo foi implementada **somente no Flutter Web**.

Não foram criados ou alterados:

- telas Mobile de Etiquetas;
- botões Mobile de Etiquetas;
- navegação Mobile para Etiquetas;
- componentes visuais Android/iOS para Etiquetas.

As camadas não visuais foram deliberadamente separadas para permitir reutilização futura no Mobile:

```text
models
ApiClient
service
contratos HTTP
DTOs backend
persistência
validações
renderização PDF
```

Assim, uma futura implementação Mobile poderá criar sua própria jornada visual consumindo os mesmos endpoints e models, sem reutilizar a UI Web.

---

# Experiência final implementada

## 1. Entrada pelo Catálogo

Na navegação Web autenticada:

```text
Catálogo
 ├── Produtos
 ├── Serviços
 ├── Estoque
 ├── Etiquetas
 └── Categorias
```

O item utiliza:

```text
Icons.local_offer_outlined
```

A página é integrada ao `AuthenticatedWebShell` e não cria uma segunda Sidebar ou uma estratégia paralela de navegação.

## 2. Página inicial de Etiquetas

O usuário encontra:

- seus modelos salvos;
- busca por nome, descrição ou formato;
- ação `Criar modelo`;
- ação `Imprimir etiquetas`;
- editar modelo;
- duplicar modelo;
- excluir modelo;
- imprimir diretamente a partir de um modelo salvo.

Estados tratados:

- loading;
- vazio;
- busca sem resultados;
- erro;
- operação em andamento.

## 3. Editor visual de etiquetas

O editor Web permite configurar:

### Papel

Presets iniciais:

```text
A4
Carta
40 × 30 mm
50 × 30 mm
60 × 40 mm
100 × 50 mm
Personalizado
```

Também permite:

- orientação;
- largura do papel;
- altura do papel.

### Grade

Permite configurar:

- colunas;
- linhas;
- largura da etiqueta;
- altura da etiqueta;
- margem superior;
- margem inferior;
- margem esquerda;
- margem direita;
- gap horizontal;
- gap vertical.

Todas as medidas persistidas são físicas e expressas em milímetros.

### Elementos do modelo

Elementos disponíveis inicialmente:

```text
nome do produto
preço do produto
código de barras
QR Code
código interno
nome do comércio
texto livre
```

O editor permite:

- adicionar elemento;
- selecionar;
- arrastar;
- redimensionar;
- excluir;
- editar X/Y/largura/altura;
- configurar texto;
- configurar fonte;
- negrito;
- alinhamento;
- configurar simbologia de barcode;
- exibir/ocultar valor abaixo do barcode.

### Barcode

Simbologias iniciais:

```text
CODE128
CODE39
EAN13
EAN8
UPCA
ITF
```

### QR

QR Code foi implementado no renderer backend com ZXing.

### Preview

Existem dois níveis de preview no editor:

1. canvas de uma etiqueta;
2. preview proporcional da folha/grade.

A geometria do domínio continua em milímetros. Pixels existem somente no render do Flutter Web.

---

# Persistência

Os modelos são persistidos no backend em MongoDB.

Coleção:

```text
modelos_etiqueta
```

Cada documento pertence explicitamente a:

```text
idUnicoDaEmpresa
```

Principais dados persistidos:

```text
id
idUnicoDaEmpresa
nome
descricao
ativo
papel
grade
etiqueta
elementos
criadoEm
atualizadoEm
criadoPor
atualizadoPor
```

A configuração dos elementos usa estrutura flexível com:

```text
tipo
bindingKey
xMm
yMm
larguraMm
alturaMm
zIndex
propriedades
```

Valores de preview não são persistidos como dados reais do produto.

---

# Bindings

Bindings iniciais suportados:

```text
PRODUCT_NAME
PRODUCT_PRICE
PRODUCT_BARCODE
PRODUCT_INTERNAL_CODE
COMPANY_NAME
FREE_TEXT
```

A arquitetura não depende diretamente de `ProdutoModel` dentro do template.

Isso deixa o motor preparado para bindings futuros como:

```text
CUSTOMER_NAME
SERVICE_ORDER_NUMBER
IMEI
SERIAL_NUMBER
SUPPLIER_NAME
LOT
EXPIRATION_DATE
```

sem precisar redesenhar o formato do modelo.

---

# Fluxo de impressão

A jornada implementada é:

```text
Etiquetas
   ↓
Selecionar modelo salvo
   ↓
Selecionar produtos
   ↓
Informar quantidade de etiquetas por produto
   ↓
Resumo de produtos / etiquetas / páginas
   ↓
Gerar PDF
   ↓
Download do PDF no Web
```

## Seleção de produtos

Foi reutilizada a infraestrutura Web já existente de produtos:

```dart
SubPainelWebProdutoLista(
  isSelecao: true,
  permitirSelecaoMultipla: true,
  tipoInicial: 'PRODUTO',
)
```

A infraestrutura existente já controla quantidade por item. O módulo agrega o retorno por produto e permite reajustar a quantidade antes da geração.

O usuário visualiza, entre outros dados:

- nome;
- preço regionalizado;
- código de barras quando disponível;
- quantidade de etiquetas solicitada.

---

# Segurança do PDF

O frontend NÃO envia nome, preço ou barcode como autoridade para a geração.

Payload conceitual:

```json
{
  "templateId": "...",
  "sourceType": "PRODUCT",
  "items": [
    {
      "sourceId": "produto-1",
      "quantidade": 3
    }
  ]
}
```

O backend:

1. valida o usuário;
2. valida o comércio;
3. busca o template dentro do comércio;
4. busca cada produto dentro do comércio;
5. resolve os bindings usando os dados reais do backend;
6. gera o PDF.

Isso impede que o navegador altere preço/nome/barcode no payload para produzir um documento inconsistente com a fonte de verdade.

---

# PDF físico

O PDF final é gerado em Java com OpenPDF.

Conversão:

```text
1 mm = 72 / 25.4 pt
```

O renderer usa:

- dimensões físicas do papel;
- margens;
- gaps;
- linhas;
- colunas;
- dimensão real da etiqueta;
- coordenadas físicas dos elementos.

O preview Flutter não é usado como fonte do PDF.

---

# Regionalização

Preço do produto é resolvido no backend de acordo com a configuração regional do comércio.

São considerados:

```text
languageCode
countryCode
currencyCode
decimalPlaces
```

No Flutter, valores exibidos durante seleção/preview utilizam `LocaleSettingsProvider`.

As novas telas de Etiquetas possuem fallbacks em:

```text
português
inglês
espanhol
```

e continuam usando `context.t(...)` como mecanismo principal, permitindo que o pacote de traduções do backend prevaleça quando as chaves forem cadastradas.

---

# API implementada

Base:

```text
/private/api/etiquetas
```

Endpoints:

```text
GET    /acesso

GET    /modelos
GET    /modelos/{id}
POST   /modelos
PUT    /modelos/{id}
POST   /modelos/{id}/duplicar
DELETE /modelos/{id}

POST   /impressao/pdf

GET    /permissoes/colaboradores/{idUnicoDoUsuario}
PUT    /permissoes/colaboradores/{idUnicoDoUsuario}
```

Todos os endpoints operacionais são protegidos por usuário autenticado + comércio atual.

---

# Multi-comércio

Toda operação do módulo usa:

```text
idUnicoDaEmpresa
```

O repository de templates possui consulta tenant-scoped:

```text
id + idUnicoDaEmpresa
```

Não é feito `findById` isolado para entregar/alterar/excluir um template operacional.

O mesmo princípio é aplicado ao produto utilizado na impressão.

---

# Permissão

Foi criada a permissão técnica:

```text
ETIQUETAS_GERENCIAR
```

Ela pertence ao vínculo usuário × comércio, permitindo que o mesmo colaborador tenha acesso a Etiquetas em um comércio e não tenha em outro.

ADMIN continua com acesso completo.

O frontend consulta:

```text
GET /private/api/etiquetas/acesso
```

para decidir a visibilidade do destino Web para colaboradores.

Os endpoints de leitura/alteração da permissão de colaborador ficaram disponíveis para a evolução da experiência de gestão de permissões Web sem criar contrato específico de Mobile.

---

# Arquivos principais — frontend

Novos:

```text
lib/data/models/etiqueta_models.dart
lib/data/services/etiqueta/etiqueta_api_client.dart
lib/domain/services/etiqueta/etiqueta_service.dart
lib/presentation/screens/etiqueta_web_i18n.dart
lib/presentation/screens/etiquetas_web_page.dart
lib/presentation/screens/etiqueta_editor_web_page.dart
lib/presentation/screens/etiqueta_impressao_web_page.dart
```

Integrações Web alteradas:

```text
lib/presentation/navigation/web_navigation_item.dart
lib/presentation/navigation/web_navigation_registry.dart
lib/presentation/navigation/web_navigation_permission_adapter.dart
lib/presentation/navigation/web_navigation_destination_resolver.dart
lib/presentation/layouts/authenticated_web_shell.dart
lib/presentation/components/web_dashboard_widgets.dart
lib/providers/colaborador_autorizacoes_provider.dart
```

Nenhum arquivo de tela Mobile foi alterado.

---

# Arquivos principais — backend

```text
controller/etiqueta/EtiquetaController.java

document/etiqueta/EtiquetaModeloDocument.java

dto/etiqueta/EtiquetaModeloDto.java
dto/etiqueta/EtiquetaImpressaoRequest.java
dto/etiqueta/EtiquetaPdfResponse.java
dto/etiqueta/EtiquetaAcessoResponse.java
dto/etiqueta/EtiquetaPermissaoRequest.java
dto/etiqueta/EtiquetaPermissaoResponse.java

repository/EtiquetaModeloRepository.java

service/etiqueta/EtiquetaModeloService.java
service/etiqueta/EtiquetaValidacaoService.java
service/etiqueta/EtiquetaPdfService.java
service/etiqueta/EtiquetaPermissaoService.java
```

Também foi estendido:

```text
ValidadorAcessoEmpresaDoUsuario
```

---

# Dependência nova

Foi adicionada somente no backend:

```xml
<dependency>
    <groupId>com.google.zxing</groupId>
    <artifactId>core</artifactId>
    <version>3.5.3</version>
</dependency>
```

Motivo:

```text
QR Code real no PDF
```

OpenPDF continua sendo o renderer de PDF e dos códigos 1D.

Não foi adicionada biblioteca Flutter de barcode/PDF.

---

# Limites de segurança e validação

Entre as validações aplicadas:

- dimensões > 0;
- linhas/colunas > 0;
- margens/gaps não negativos;
- grade precisa caber no papel;
- elemento precisa caber na etiqueta;
- máximo de 50 elementos por modelo;
- limites de linhas/colunas/slots;
- máximo de 1000 etiquetas por item;
- máximo de 5000 etiquetas por PDF;
- barcode precisa ser compatível com a simbologia;
- EAN/UPC possuem validação de check digit;
- ITF precisa ser numérico com quantidade par de dígitos;
- produto da impressão precisa pertencer ao comércio atual.

---

# Validação executada

## Frontend

O commit de implementação Web foi submetido ao build da Vercel da branch e o status retornou:

```text
SUCCESS
```

Isso valida a compilação Web utilizada pelo deploy atual do projeto.

O diff da implementação também foi revisado e não contém arquivos Mobile.

## Backend

A branch do backend não executa automaticamente o workflow Maven em push — o workflow atual está configurado para `main` e PR para `main`.

Por decisão do usuário, a implementação continuou sem exigir teste local intermediário.

A estrutura foi revisada estaticamente contra as APIs/classes reais do projeto e o `pom.xml` foi preservado, adicionando somente a dependência necessária ao QR.

---

# Evolução futura Mobile

Nenhuma UI Mobile foi criada.

Quando o módulo for levado ao Mobile, a implementação deve criar:

```text
screens/widgets próprios Mobile
```

reutilizando:

```text
EtiquetaModelo
EtiquetaApiClient
EtiquetaService
endpoints
validações backend
PDF backend
```

Não reutilizar `EtiquetasWebPage`, `EtiquetaEditorWebPage` ou `EtiquetaImpressaoWebPage` como wrappers Mobile.

---

# Evoluções futuras já permitidas pela arquitetura

Sem alterar o formato base do template, será possível evoluir para:

```text
etiquetas de clientes
etiquetas de atendimento técnico
etiquetas de ordem de serviço
etiquetas de equipamento
IMEI
serial
patrimônio
lote
validade
fornecedor
```

Também continuam possíveis:

```text
calibração X/Y
configuração por impressora
histórico de impressão
ZPL
EPL
agente local de impressão
```

---

# Veredito

O fluxo principal solicitado está implementado:

```text
configurar etiqueta personalizada
        ↓
salvar em banco
        ↓
reutilizar posteriormente
        ↓
selecionar produtos
        ↓
definir quantidade por produto
        ↓
gerar PDF físico de impressão
```

A UI do módulo permanece exclusivamente Web, enquanto a integração foi desenhada como camada compartilhável para uma futura experiência Mobile independente.
