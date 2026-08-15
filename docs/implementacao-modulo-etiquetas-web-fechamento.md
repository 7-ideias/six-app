# Fechamento — módulo de Etiquetas Web

Data: 2026-08-15

Branch em app e backend:

```text
feature/20260814-melhorias
```

Este documento complementa `docs/implementacao-modulo-etiquetas-web.md` com os últimos ajustes de fechamento.

## Gestão de acesso por colaborador concluída na Web

Além do backend tenant-scoped, a experiência Web agora permite que o ADMIN controle o acesso ao módulo de Etiquetas.

### Novo convite de colaborador

A tela Web de convite ganhou a permissão:

```text
Etiquetas
ETIQUETAS_GERENCIAR
```

Quando habilitada, a permissão é enviada junto das permissões do convite e fica vinculada ao colaborador dentro do comércio correspondente.

### Colaboradores existentes

A listagem Web de colaboradores ganhou a ação:

```text
Etiquetas
```

A ação abre um controle simples onde o ADMIN pode conceder ou remover o acesso ao módulo para aquele colaborador no comércio atual.

A UI utiliza os endpoints compartilhados:

```text
GET /private/api/etiquetas/permissoes/colaboradores/{idUnicoDoUsuario}
PUT /private/api/etiquetas/permissoes/colaboradores/{idUnicoDoUsuario}
```

A permissão não é tratada como global da pessoa. Ela pertence ao vínculo:

```text
usuário × comércio
```

## Mobile preservado também em comportamento

`ColaboradorAutorizacoesProvider` é compartilhado por Web e Mobile. Por isso, foi aplicada uma proteção explícita:

```text
somente Web consulta automaticamente GET /private/api/etiquetas/acesso
```

Android/iOS não passam a fazer essa chamada extra nesta implementação.

Consequências:

- nenhuma tela Mobile nova;
- nenhum botão Mobile novo;
- nenhuma navegação Mobile nova;
- nenhuma chamada automática adicional de Etiquetas no Mobile;
- models, ApiClient e service continuam compartilháveis para uma implementação Mobile futura.

## Estado final do fluxo

```text
ADMIN
  ↓
Catálogo > Etiquetas
  ↓
cria modelo visual
  ↓
configura papel / grade / margens / elementos
  ↓
salva no MongoDB por comércio
  ↓
reutiliza modelo
  ↓
seleciona produtos
  ↓
define quantidade de etiquetas por produto
  ↓
backend busca os produtos reais do comércio
  ↓
resolve nome / preço / barcode / empresa
  ↓
gera PDF físico
  ↓
Web inicia download
```

Para colaboradores:

```text
ADMIN concede ETIQUETAS_GERENCIAR
  ↓
GET /etiquetas/acesso retorna permitido
  ↓
Sidebar Web passa a exibir Catálogo > Etiquetas
  ↓
backend continua validando a permissão em todas as operações
```

## Validação Web

O primeiro commit funcional completo do módulo passou no build Vercel da branch.

Os ajustes finais de permissão Web também passam pelo mesmo pipeline de build da branch antes do fechamento definitivo.

## Backend

O `pom.xml` foi revisado após a implementação para preservar o arquivo original e introduzir somente a nova dependência necessária ao QR Code:

```xml
<dependency>
    <groupId>com.google.zxing</groupId>
    <artifactId>core</artifactId>
    <version>3.5.3</version>
</dependency>
```

Não houve refatoração ampla de dependências.
