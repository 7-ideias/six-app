# MVP 2 — Franquias informativas por plano

## Operação

1. No painel SUPER Web, abrir Planos → Gerenciar planos e franquias.
2. Configurar dados, total de fotos/arquivos e tamanho por arquivo, em MB decimais (1 MB = 1.000.000 bytes). Valores vazios significam **não configurado**, não ilimitado. Até seis casas decimais; usar o separador decimal regional e não separadores de milhar.
3. Em Usuários do Sixo → detalhe → Armazenamento do comércio → Gerenciar planos e franquias, selecionar um plano publicado e salvar o vínculo. Esse fluxo existe em Web e Mobile; Mobile permite editar as franquias dos planos já cadastrados. Criação/edição comercial de planos permanece no painel Web existente.
4. Abrir Configurações → Armazenamento do comércio: consumo, franquia, percentual e avisos são atualizados na consulta seguinte. A medida de consumo mantém o ciclo periódico do MVP 1.

Sem franquias ou vínculos comerciais inventados. Sem vínculo automático de usuários existentes. Somente SUPER pode listar/configurar franquias ou mudar o vínculo; acesso ao consumo mantém as autorizações do MVP 1. Vincular um plano não cria assinatura, teste grátis, pagamento ou liberação de acesso.

## API

- `GET /private/api/admin/armazenamento/planos`: catálogo existente com nomes localizados e franquias.
- `PUT /private/api/admin/armazenamento/planos/{planId}`: `{databaseLimitBytes, fileLimitBytes, maxUploadBytes, expectedVersion}`. Bytes positivos inteiros até 10^15; null remove a configuração. O tamanho por arquivo não pode exceder a franquia de arquivos quando ambos estiverem configurados.
- `PUT /private/api/admin/armazenamento/{companyId}/plano`: `{planId, expectedVersion}`. `planId: null` desvincula; um novo vínculo exige plano PUBLICADO. Um plano arquivado mantém os vínculos/franquias existentes.
- Consultas de armazenamento atuais recebem campo aditivo `plan`: identificação/nome do plano, `assignmentVersion`, `limits` com `version` e `mode: INFORMATIVO`.
- Versionamento independente por configuração e vínculo: iniciar em 0; cada gravação aumenta a versão; conflito retorna 409, exige recarga e nova revisão. Sem retry automático de gravações.

## Persistência e compatibilidade

As collections adicionais `storage_plan_quotas` e `storage_company_plans` usam `_id` único como chave de plano/comércio. Criação sob demanda por insert validado; não exigem backfill. Dados comerciais de `planos_publicos` e `empresas` não são regravados pela funcionalidade. Isso evita que clientes antigos apaguem franquias ao salvar um plano sem conhecer os campos novos.

Cada alteração grava ator extraído do JWT, data, versão e histórico das últimas 100 alterações no mesmo documento e na mesma operação atômica. Concorrência é controlada por versão e `_id`; o histórico não é uma auditoria imutável de longo prazo. Planos Mongo com `_id` ObjectId e String são reconhecidos.

Franquias são resolvidas em cada consulta, sem copiar valores para os snapshots e sem esperar nova medição para refletir uma configuração. Mudanças afetam todos os comércios vinculados; o formulário informa esse alcance. Mensal/anual continuam periodicidades do catálogo, não novas franquias de armazenamento.

## Comunicação

- Sem limite: “Franquia não configurada”, sem barra/percentual.
- Sem medição: “Aguardando medição”, sem zero artificial.
- A partir de 80%: próximo da franquia.
- Em 100%: franquia atingida; acima: ultrapassada. A barra satura em 100%, mas o percentual e consumo real permanecem visíveis acima de 100%.
- Medição parcial é indicada e pode aumentar após uma medição completa.
- Limites são apenas informativos: não bloqueiam cadastros, vendas, atendimento nem uploads. Restrições técnicas preexistentes de upload continuam valendo. Não existe botão de compra sem fluxo funcional.
- Valores de arquivos continuam representando bytes originais, não o tamanho físico/Base64 do Mongo; índices, backups e dados excluídos pelo MVP 1 permanecem fora da métrica.
- PT/EN/ES, nomes comerciais preservados, números/percentuais regionais. UI Web/Mobile independente com modelo, API e controller compartilhados.

## Verificações

24 testes Java passaram em compilação isolada Java 17/Spring Boot 3.0.2 (10 novos cobrem permissões SUPER, validação de franquia, ausência de vínculo, plano arquivado, conflitos e auditoria). Análise estática dos modelos Dart sem problemas; execução Dart pura validou contrato antigo, limiares, conversão decimal exata e versões. Testes Flutter de modelo, HTTP e superfície mobile dark foram adicionados, mas não executados.

Build integral, integração com Mongo real, análise Flutter e validação visual permanecem para CI/homologação. Não foi retomada a inicialização do Flutter bloqueada anteriormente pela revisão automática ao detectar acesso ao endpoint de metadados da infraestrutura. Nenhum deploy, cobrança ou alteração em dados da VPS foi executado.

## Roteiro de homologação

- Comércio sem plano e plano sem franquias; quota abaixo/acima do consumo já medido.
- Configurar plano publicado, vincular comércio A; confirmar comércio B inalterado até vinculá-lo.
- Alterar franquia global do plano e conferir os comércios vinculados na próxima consulta.
- Verificar 79%, 80%, 100% e 125%, dados desconhecidos, medição parcial e erro preservando data anterior.
- Testar dois SUPER editando a mesma configuração: segunda gravação desatualizada retorna conflito.
- Usuário ADMIN/colaborador deve receber 403 nas três operações administrativas.
- Arquivar plano: vínculo existente preservado, novo vínculo impedido; desvincular comércio explicitamente.
- PT/EN/ES, decimal com vírgula/ponto, dark/light, texto ampliado e navegação por teclado.
