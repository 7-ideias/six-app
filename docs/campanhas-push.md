# Painel de campanhas de push

Acesso principal: `/app` → Campanhas de push (abaixo de Planos), exclusivo do SUPER. Link direto: `/app/campanhas-push`. O acesso legado em `/admin/campanhas-push` continua disponível.

Fluxo: público filtrado e seleção múltipla → texto por idioma → prévia → revisão no backend → confirmação → histórico. O SUPER escreve todas as versões. A confirmação informa quantidade de ADMINs, ausência de dispositivos e empresa/idioma de destino. Um teste é uma campanha para exatamente um ADMIN, com identificação no histórico.

A tela não traduz conteúdo nem cria ofertas comerciais. O destino inicial é a assinatura. O serviço compartilhado encapsula HTTP; o backend autoriza todas as operações e determina os destinatários elegíveis. O UUID é preservado ao repetir uma confirmação cuja resposta foi perdida.

No mobile, o destino `billing.subscription` usa a navegação de push existente, incluindo a intenção pendente até a autenticação. A tela de pagamento consulta `/private/api/assinatura/campanha` para resolver empresa, idioma e moeda no servidor. Quando já há bloqueio por assinatura, a campanha é encaminhada para essa tela. As telas web e mobile continuam separadas; compartilham apenas serviço/controlador.

Na web, `/app/assinatura?campaignId=...` preserva o contexto da campanha através da rota autenticada. O Firebase Web Push não é habilitado por esta entrega; o painel web dispara pelos dispositivos já registrados na infraestrutura móvel.

Estados do histórico distinguem processamento, aceitação pelo provedor, falha, ausência de dispositivo e interrupção. Aceitação não comprova entrega ou leitura. O histórico atualiza automaticamente enquanto existem campanhas pendentes/em processamento na página atual.

## Validação desta entrega

- Build Flutter Web release e script de empacotamento web com páginas públicas.
- 18 testes focados aprovados: campanha, navegação de push, assinatura e painel em 1280/600 px.
- Suíte geral: 872 aprovados, 148 falhas, 1 ignorado na execução registrada. Na main limpa `3054dfea`: 870 aprovados, as mesmas 148 falhas e 1 ignorado. A comparação dos nomes dos testes com falha não encontrou diferenças entre branch e main. Os novos testes de controlador/painel acrescentados posteriormente também passaram no conjunto focado final.
- Análise estática sem erros de compilação; existem avisos/informações preexistentes na base.
- APK/IPA e entrega real em dispositivo não foram validados neste ambiente. Nenhuma campanha foi enviada a clientes.
