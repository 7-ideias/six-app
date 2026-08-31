---
name: sixapp-push-navigation
description: Use quando o pedido mencionar push notification, FCM, notificacao local/remota, abrir o app por toque na notificacao, deep link interno por payload, direcionar uma mensagem para uma tela especifica do SixApp, criar novo destino de notificacao no mobile, ou ampliar o mapeamento de payload para navegacao. Combine com sixapp-shared-backend-integration se houver contrato/backend e com sixapp-mobile-ui se houver ajuste visual na tela destino.
---

# Push navigation do SixApp

Use esta skill para implementar ou ampliar o roteamento interno de notificacoes no mobile do SixApp.

Ela cobre:

- push remoto via Firebase;
- notificacao local exibida em foreground;
- abertura do app por toque na notificacao;
- mapeamento de payload para tela;
- fila de intencao enquanto a sessao ainda nao terminou de restaurar;
- criacao de novas mensagens que devem abrir uma tela especifica.

Ela nao autoriza reaproveitar tela Web no Mobile nem criar contrato paralelo por plataforma.

Quando o pedido tambem tocar contrato, endpoint, ids tecnicos, parser, sync de notificacao ou backend compartilhado, use junto `sixapp-shared-backend-integration`.

Quando o pedido tambem exigir mudanca visual na tela aberta pela notificacao, use junto `sixapp-mobile-ui`.

## Leia primeiro

- `AGENTS.md`
- `../../../docs/push-notification-screen-routing-plan.md`
- `../../../lib/core/services/firebase_push_notification_service.dart`
- `../../../lib/core/services/notification_service.dart`
- `../../../lib/core/services/notificacao_service.dart`
- `../../../lib/presentation/screens/mobile_main_shell.dart`
- `../../../lib/main.dart`

## Resultado obrigatorio

Toda notificacao que precisar abrir uma tela deve passar por um fluxo unico:

1. capturar o payload;
2. transformar o payload em uma `PushNavigationIntent`;
3. resolver o destino;
4. aguardar sessao e shell mobile, se necessario;
5. navegar uma vez so;
6. cair em fallback seguro quando o payload for insuficiente.

## Dados minimos para uma nova mensagem direcionada

Se o usuario pedir "crie uma nova mensagem e direcione para a tela X", levante ou confirme somente o que faltar:

- tela ou destino funcional;
- entidade tecnica afetada;
- id tecnico estavel da entidade, quando existir;
- comportamento desejado: abrir aba, lista, detalhe ou apenas inbox;
- fallback quando a entidade alvo nao puder ser aberta diretamente.

Nao invente rota textual arbitraria quando o app ainda nao tiver um destino tecnico definido. Prefira chaves estaveis de destino.

## Contrato recomendado do payload

Preserve os campos atuais e adicione apenas o necessario:

```json
{
  "tipoDeEvento": "NOVA_VENDA",
  "titulo": "Nova venda registrada",
  "mensagem": "Venda aguardando recebimento.",
  "destination": "sales.pending",
  "targetTab": "service",
  "entityType": "OPERACAO",
  "entityId": "uuid-da-operacao",
  "numeroOperacao": "12345",
  "routeParams": {
    "filtro": "nao_liquidadas"
  }
}
```

Regras:

- `destination` deve ser tecnico, curto e estavel;
- `entityType`, `entityId` e `routeParams` nao devem conter labels traduzidos;
- `titulo` e `mensagem` podem continuar no formato atual;
- ids antigos do payload devem continuar aceitos para compatibilidade.

## Fluxo de implementacao

1. Investigue o estado atual do push e da tela destino.
2. Localize se a tela mobile ja consegue abrir a entidade diretamente; se nao, entregue primeiro a navegacao ate a tela pai.
3. Centralize a decisao em um resolver de destino; nao espalhe `if` de payload por varias telas.
4. Trate as tres entradas obrigatorias:
   - `onMessageOpenedApp`
   - `getInitialMessage()`
   - toque em notificacao local do `flutter_local_notifications`
5. Use fila de intent pendente para cold start e restauracao de sessao.
6. Navegue pelo shell mobile e por telas mobile reais; nao reaproveite UI web.
7. Adicione ou ajuste testes do resolver e do servico de navegacao.

## Politica de fallback

Quando o payload nao trouxer dados suficientes:

- primeiro tente resolver por `destination`;
- depois por `tipoDeEvento` e ids conhecidos;
- se nao houver alvo confiavel, abra `NotificacoesMobileScreen`;
- nunca cause crash por payload desconhecido.

## Destinos iniciais recomendados

Use estes nomes como base quando fizer sentido ao pedido:

- `notifications.inbox`
- `sales.pending`
- `technical.orders`
- `customers.list`

Se o usuario pedir um novo destino, mantenha a convencao de nomes curta, tecnica e sem idioma de UI.

## Regras de implementacao

- Nao quebrar payload antigo.
- Nao alterar fluxo web sem pedido explicito.
- Nao colocar logica HTTP na tela.
- Nao usar texto traduzido como chave de navegacao.
- Nao disparar multiplas navegacoes para o mesmo tap.
- Nao abrir tela antes de `AuthGateMobile` e `MobileMainShell` estarem prontos.

## Entrega esperada

Ao concluir uma solicitacao com esta skill, entregue:

- destino tecnico escolhido;
- payload exemplo;
- arquivos alterados;
- fallback adotado;
- validacao executada.
