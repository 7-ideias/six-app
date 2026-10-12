# Fornecedores — Fase 1: identidade por conta e autorizacoes

## Escopo implementado
- Fornecedores sao compartilhados entre comércios cujas entidades em MongoDB (`empresas`) possuam **exatamente o mesmo proprietario unico** (`idsDonosDaEmpresa`, Keycloak ID).
- A identidade canonica é **derivada no backend**: `ADMIN:<ownerKeycloakId>`. Não é aceita via body/header.
- Comercios com coproprietarios, nenhum proprietario, ou divergencia no cadastro nao são unidos automaticamente: `EMPRESA:<idUnicoDaEmpresa>`. Esses casos devem ser reconciliados administrativamente em fase futura.
- Não há compartilhamento entre contas distintas apenas porque o mesmo colaborador trabalha nelas.
- Fornecedores mantêm `idUnicoDaEmpresa` para auditoria da loja de origem, mas consulta/edicao utilizam o escopo da conta.
- Compras, estoque e financeiro **não foram alterados**.

## Autorizacoes
- `FORNECEDORES_CONSULTAR`
- `FORNECEDORES_CADASTRAR`
- `FORNECEDORES_EDITAR`
- `FORNECEDORES_INATIVAR`

Permissoes ficam no vínculo ativo do colaborador com a empresa em `usuarios-empresas-vinculos.permissoes`. Administradores têm todas as permissoes do módulo. Colaboradores não recebem autorizacao ao herdar `CLIENTES_EDITAR`. O controle é feito no backend por operação e por empresa selecionada.

O frontend usa `GET /private/api/fornecedores/acesso` para ações e sidebar, e oferece autorização por comércio na área de colaboradores convidados e no editor específico de permissões de fornecedores.

## Endpoints de fornecedores
Todos exigem JWT e header `idUnicoDaEmpresa`.

| Metodo | Caminho | Regra |
| --- | --- | --- |
| GET | `/private/api/fornecedores/acesso` | Vinculo ativo com empresa |
| GET | `/private/api/fornecedores` | CONSULTAR |
| GET | `/private/api/fornecedores/{id}` | CONSULTAR |
| POST | `/private/api/fornecedores` | CADASTRAR |
| PUT | `/private/api/fornecedores/{id}` | EDITAR; INATIVAR se alterar status |
| GET | `/private/api/fornecedores/permissoes-colaboradores` | ADMIN |
| PUT | `/private/api/fornecedores/permissoes-colaboradores/{vinculoId}` | ADMIN |
| GET | `/private/api/fornecedores/migracao` | ADMIN; simulacao sem escrita |
| POST | `/private/api/fornecedores/migracao` | ADMIN; aplica migracao |

## Migracao dos fornecedores legados
Documentos antigos continuam visíveis enquanto `contaAdministradoraId` estiver nulo; busca pelo conjunto **explicitamente permitido** de comércios do mesmo proprietário. Ao editar, o cadastro legado assume o escopo e preserva seu ID. Nenhuma migração automática indiscriminada roda no startup.

Procedimento de migração:
1. Fazer backup/export de `fornecedor` e `empresas`.
2. Validar que `idsDonosDaEmpresa` reflete a identidade correta de cada comercio.
3. Executar `GET /private/api/fornecedores/migracao` por administrador para analisar os elegiveis e conflitos; repetir para cada conta isolada.
4. Identificar documentos equivalentes com mesmo documento normalizado; **nao fundir automaticamente IDs** (compras e contas futuras podem referenciá-los).
5. Resolver duplicidades manualmente, preservando referencias; executar `POST /private/api/fornecedores/migracao` apenas apos essa revisao.
6. Reexecutar a simulacao para confirmar que somente conflitos conhecidos restaram.
7. Confirmar existencia/ativacao do indice parcial unico `uniq_fornecedor_conta_documento` em `fornecedor` antes de liberar escrita concorrente. Conferir logs e comportamento do mecanismo de criacao de indices do ambiente.

Regras de dados:
- `documentoNormalizado` remove pontuacao e preserva caracteres alfanumericos Unicode, em caixa alta; documento ausente permanece null.
- A unicidade é `(contaAdministradoraId, documentoNormalizado)` somente quando ambos forem strings.
- Duplicidades legadas são reportadas, não apagadas; seu cadastro permanece visível na conta correta enquanto a migração for concluída.
- Códigos de conflito: HTTP 409; acesso sem vinculo ou sem permissão: HTTP 403; recurso fora do escopo: HTTP 404.

## Testes e operação
Cobertura adicionada para multiempresa com mesmo proprietário, coproprietários não fundidos, escopo inconsistente, permissões segregadas, acesso por ID, conflito entre lojas, dry-run, migração efetiva e autorizações dos colaboradores.

Ainda é necessário executar Maven/Flutter em ambiente com SDK, homologar uso simultâneo por multiplos administradores e validar o índice Mongo na VPS. Estas verificacoes nao sao substituidas pelo commit.
