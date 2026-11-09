# Armazenamento — fase 1

## Onde acessar

- Web: Configurações → Armazenamento (também disponível no painel de configurações rápidas).
- Mobile: Configurações → Armazenamento.
- SUPER, Web e Mobile: Usuários do Sixo → detalhe do usuário → Ver armazenamento, por comércio vinculado.

## Integração

As duas composições visuais usam `StorageUsageController` → `StorageUsageApiClient` → `StorageUsage`. O client compartilha autenticação, tenant, parsing e erros. O SUPER passa o comércio explicitamente para a rota administrativa, sem trocar a sessão/empresa ativa.

O backend é implantado primeiro. Endpoints e metodologia estão em `sixBack/docs/storage-visibility-mvp1.md`.

Mostra dados e arquivos separadamente; sem percentual ou “ilimitado” quando não há franquia. Valores nulos mostram “Aguardando medição”. Estados pendente, processamento, parcial, erro, sessão expirada e acesso negado têm mensagens próprias. Após erro da medição, valores anteriores continuam com a data original. Erro de autorização limpa os valores.

Durante a primeira medição há até 12 consultas automáticas a cada 10 segundos; o botão Atualizar continua disponível. Consultas são canceladas logicamente por geração para evitar respostas antigas. O ciclo de vida encerra timers e client.

Textos em PT/EN/ES no namespace backend `storage` e fallback localizado do frontend. Unidades decimais (KB=1000 bytes). Datas usam o formato regional e indicam explicitamente UTC. UI Mobile própria com cores semânticas e shell mobile; UI Web própria com componentes de dashboard existentes.

## Aceite visual e funcional

- Abrir Web largo e estreito, Mobile claro e escuro, texto ampliado.
- Confirmar estados pendente, zero real, dados carregados, parcial, falha e retry.
- Alternar comércio: nunca renderizar resposta atrasada do comércio anterior.
- SUPER com vários comércios: escolher pelo nome e conferir resultado separado.
- Nenhum upload, cadastro, venda ou atendimento é bloqueado.

## Verificações desta entrega

Os arquivos Dart novos passaram pelo formatter e os cenários do modelo (pendente, zero medido e resposta inválida) foram executados com Dart puro. Os testes Flutter adicionados, análise estática, build e aceite visual ainda não foram executados: a revisão automática bloqueou a inicialização do Flutter ao detectar uma tentativa de acesso ao endpoint de metadados da infraestrutura. Não houve tentativa de contornar esse bloqueio.
