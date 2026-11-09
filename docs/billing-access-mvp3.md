# MVP 3 — acesso por comércio

## Comportamento

- SUPER_USER validado pelo JWT não sofre bloqueio financeiro. Permissões normais dos módulos continuam aplicáveis.
- Comércio existente sem período pago, teste válido ou liberação manual fica bloqueado para usuários comuns, incluindo o ADMIN. Não existe grandfathering nem migração automática para trial.
- Novo comércio recebe 7 dias de teste sem cartão, iniciados no cadastro. Consulta e login nunca reiniciam o prazo.
- Expiração é avaliada em UTC em cada operação, sem carência e sem depender de cron.
- SUPER encontra **Assinatura e acesso** nos detalhes do usuário, por comércio, tanto na Web quanto no Mobile.
- Liberação manual é concedida até revogação pela interface. A API também aceita expiresAt futuro. Motivo obrigatório, ator extraído do JWT, versionamento otimista e histórico auditado no mesmo documento da atualização.
- Revogar a exceção volta a avaliar pagamento e trial; não cancela um pagamento vigente.
- Nenhum dado é excluído. Franquias de armazenamento continuam informativas e independentes.

## Persistência e contrato

Nova coleção Mongo `billing_access`, chave única nativa `_id = idUnicoDaEmpresa`. Campos opcionais: trialUntil, paidUntil, manualRelease, manualUntil, version, audit. Sem reescrita das coleções de clientes, produtos ou imagens. Registros ausentes são bloqueados, não são interpretados como gratuitos. Cadastro cria trial com `$setOnInsert`, sem reiniciar prazo já existente.

- GET `/private/api/assinatura/acesso`: vínculo ativo/legado validado, estado do comércio selecionado.
- GET `/private/api/admin/assinatura/{companyId}/acesso`: somente SUPER.
- PUT `/private/api/admin/assinatura/{companyId}/liberacao`: `{enabled, expiresAt, reason, expectedVersion}`, somente SUPER.
- Operação bloqueada: HTTP 402, código `PAYMENT_REQUIRED`. Não é 401; não renovar token, repetir escrita ou encerrar sessão por esse código.
- Todos os requests operacionais autenticados exigem `idUnicoDaEmpresa`. O client compartilhado adiciona o contexto ausente apenas para a própria API. Contextos explícitos no body/query divergentes são rejeitados.
- Login, bootstrap, listagem de vínculos, leitura mínima de configuração e consulta da assinatura permanecem acessíveis; escritas operacionais não entram nessa exceção. Suporte continua disponível no backend.
- Eventos de empresa por WebSocket são verificados tanto na inscrição quanto na entrega, inclusive depois de uma revogação.

## Limites deste MVP

Stripe Checkout, Portal, webhooks, planos mensal/anual e atualização de `paidUntil` pertencem ao MVP 4. Nenhuma interface pode marcar pagamento neste MVP. O estado PAID está preparado para sincronização futura validada no backend.

**Ao implantar o backend, usuários comuns de comércios existentes sem liberação serão bloqueados imediatamente.** Publicar a interface compatível antes do backend. O SUPER deve conceder previamente as exceções desejadas após a publicação. Não há cobrança nem bloqueio de produção realizado pela criação do PR.

A tela de bloqueio permite verificar novamente após regularização e sair. Enquanto Stripe não está integrado, a regularização ocorre com a administração. O endpoint de vínculos permanece disponível; a expansão do seletor de múltiplos comércios não faz parte desta entrega.

Rotas legadas de operações passaram a validar administração e propriedade do registro antes de exclusão; listagem passou a consultar por comércio. O endpoint legado `/public/api/login/lista-colaboradores`, cujo retorno não é segregado por comércio, agora exige autenticação e SUPER. Clientes operacionais devem usar `/private/api/colaborador/listar`.

## Validação

22 testes Java do núcleo executados em projeto isolado com Java 17 e Spring Boot 3.0.2: fronteiras exatas de expiração, legado bloqueado, permissão SUPER, vínculo inativo, trial insert-only, auditoria, conflito de versão, proteção HTTP, body/query divergentes e revogação em socket ativo.

Esse conjunto não equivale ao build integral do repositório: hooks de cadastro, controllers legados e integração completa precisam passar no CI do projeto. Dart format executado; teste puro do model executado. Testes Flutter adicionados para 402 sem replay, resposta tardia de outro comércio e ausência de vazamento de contexto para terceiros; execução Flutter, análise e validação visual ainda pendentes neste ambiente.

Antes de merge: validar SUPER liberar/revogar em Web e Mobile; usuário existente bloqueado; novo cadastro e trial; mudança de comércio; sessão expirada; conexão interrompida; usuário com API antiga; confirmar CI completo dos dois repositórios.
