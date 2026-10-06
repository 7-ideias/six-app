# Gestão Mobile — cards editoriais

A tela principal de Gestão usa quatro cards em duas colunas, com reordenação por toque prolongado e persistência da preferência existente. O cabeçalho passa a ser textual, seguindo Atendimento. As páginas internas e as rotas continuam iguais.

## Publicação das imagens

Atualize primeiro o backend da branch `feature/20261005-web-layout-managed-heroes`. Os quatro slots agora recomendam e processam imagens de 1024 × 1536 pixels, em vez de 1200 × 800.

No painel SUPER de imagens, filtre por Mobile e Gestão e envie os arquivos do ZIP:

| Arquivo | Slot |
| --- | --- |
| catalogo.webp | GESTAO_CATALOGO |
| pessoas.webp | GESTAO_PESSOAS |
| financeiro.webp | GESTAO_FINANCEIRO |
| configuracoes.webp | GESTAO_CONFIGURACOES |

Publique no ambiente consumido pelo mobile. Use padrão global para imagens genéricas ou o segmento/especialidade desejado para imagens específicas. Uma imagem contextual existente mantém prioridade sobre o padrão global.

Não é necessário um novo arquivo para GESTAO_HERO: o banner foi substituído pelo cabeçalho textual nesta versão. O slot antigo permanece disponível para compatibilidade com versões anteriores do app.

Os arquivos existentes não são reprocessados automaticamente. Faça novo upload dos WebPs originais após atualizar o backend; reutilizar uma versão antiga do histórico não recupera recortes anteriores.

O ZIP contém imagens, instruções e os prompts usados na geração. A criação do ZIP não publica as imagens no servidor.

## Validação local

- Abrir Gestão em light e dark, conferir os quatro cards e suas rotas.
- Arrastar cada card e reabrir a tela para conferir a ordem persistida.
- Publicar cada imagem no painel e verificar a atualização no mesmo ambiente do mobile.
- Conferir texto ampliado e carregamento das imagens.

Diff revisado estaticamente. Flutter/Dart não disponíveis no ambiente de implementação; formatação, análise e teste no dispositivo devem ser executados localmente.
