# Imagens da gestão do catálogo Web

Quatro ilustrações WebP, 1200 × 800: Produtos, Serviços, Categorias e Etiquetas.

## Instalação na VPS

Extraia o ZIP preservando a estrutura web/catalogo dentro de /opt/sixapp/assets:

```bash
sudo unzip -n sixo-catalogo-web-v1.zip 'web/*' -d /opt/sixapp/assets
```

As URLs esperadas são:
- https://assets.sixappback.com/web/catalogo/produtos-v1.webp
- https://assets.sixappback.com/web/catalogo/servicos-v1.webp
- https://assets.sixappback.com/web/catalogo/categorias-v1.webp
- https://assets.sixappback.com/web/catalogo/etiquetas-v1.webp

Publique os arquivos antes de reiniciar o backend atualizado e atualizar o Web.
O backend registra os quatro padrões globais no painel SUPER na inicialização.
Depois disso, substituições, agendamentos e imagens por segmento/especialidade usam o controle visual existente. Ao apagar uma personalização, vale o padrão global.
O ZIP não é um pacote de deploy de código. Nenhuma mudança na VPS foi executada automaticamente.
O card Catálogo virtual não recebeu nova imagem nesta entrega de quatro artes.

## Integração

A chamada /web-header/assets aceita incluirCatalogo=true e acrescenta quatro códigos CATALOGO_* com modo FULL_CARD. Sem essa opção, a resposta anterior é preservada. O perfil continua sendo autorizado pelo serviço existente.
Os slots CATALOGO_WEB_* são separados do cabeçalho de Produtos. O catálogo web/catalogo-assets.json faz a carga idempotente dos padrões globais, preservando uploads existentes.
A seção Web compartilha um controlador entre os cards e acompanha alterações de empresa, perfil e versão por WebSocket. URLs com versão usam o cache persistente existente. Durante a troca de contexto, as imagens anteriores são removidas e exibimos shimmer.

## Verificação local

1. Conferir no painel SUPER os quatro slots Catálogo Web (etiqueta Web).
2. Abrir Produtos e conferir os quatro cards; abrir cada ação para conferir navegação e permissões.
3. Substituir uma imagem no segmento atual e confirmar atualização sem reiniciar o Web.
4. Trocar empresa e segmento: não deve permanecer a imagem do contexto anterior.
5. Agendar uma imagem e, após ativação, conferir a atualização.
6. Apagar uma personalização e confirmar o retorno ao padrão global.
7. Conferir temas claro/escuro e larguras de 480, 900 e 1440 pixels.

Nesta sessão não foi possível executar Flutter analyze/build nem o build Java por ausência dos compiladores. A validação executada cobre arquivos WebP/ZIP, contrato dos quatro slots e revisão estática do diff.
