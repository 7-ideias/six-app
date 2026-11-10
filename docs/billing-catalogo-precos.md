# Catálogo do SUPER e cobrança Stripe

## Fonte de preço

O cadastro existente em `planos_publicos` permanece a fonte dos três planos.
Mensal e anual são preços independentes: a chave de cada preço é moeda +
periodicidade. Salvar dois preços da mesma moeda e periodicidade gera erro,
em vez de sobrescrever silenciosamente. Não há migração nem alteração dos
preços existentes.

Um anual de R$ 499 cobra R$ 499 por ano. Um anual de R$ 1 cobra R$ 1 por ano.
Não existe multiplicação automática por dez. A mensagem fixa de dois meses
grátis foi removida; descontos devem corresponder aos valores cadastrados.

O endpoint público mantém `preco` por compatibilidade e acrescenta `precos`
com as opções da moeda resolvida. A home continua exibindo os mesmos cards
e oferece a seleção dos períodos cadastrados em cada um.

## Contratação

O site envia ID do plano, período, moeda e locale para a rota autenticada.
O login e o cadastro preservam a seleção. A página de assinatura destaca o
plano e exige confirmação antes de abrir a Stripe. O preço da URL nunca é
aceito como cobrança; o backend lê o catálogo e compara o valor esperado
mostrado na tela. Preço alterado exige atualização e nova confirmação.

Permissões do comércio, idempotência, assinatura dos webhooks, bloqueio,
liberação SUPER e aplicação das franquias permanecem na integração existente.
Uma sessão de checkout já emitida pela Stripe conserva seu preço; mudar o
catálogo não altera contratos existentes. Se houver sessão pendente de outro
valor, aguardar a expiração antes de iniciar outro preço. Não reabrimos uma
sessão cujo preço já diverge do catálogo.

## Moedas e idiomas

A entrada direta usa PT-BR/BRL. O contrato separa locale, moeda e período.
O fluxo público preserva os preços BRL e USD já cadastrados e suas traduções;
não há conversão cambial. Moedas ainda não suportadas não são cobradas por
fallback. Alterar idioma não muda uma assinatura existente.

O checkout recorrente aceita MENSAL e ANUAL com valor válido para pagamento.
Entradas legadas GRATUITO, UNICO ou valor zero não criam assinatura paga.
Elas não são alteradas automaticamente: o SUPER deve editar os planos que
deseja oferecer como pagos. O teste local de sete dias continua independente.

## Aceite

1. Editar um dos planos existentes, mantendo nome, benefícios e franquias.
2. Salvar BRL/MENSAL e BRL/ANUAL no mesmo plano; recarregar e conferir ambos.
3. Abrir a home: selecionar anual, clicar em assinar, fazer login/cadastro.
4. Conferir plano destacado e valor; abrir Stripe e verificar período e moeda.
5. Alterar preço no SUPER e tentar contratar com a tela antiga: deve pedir
   atualização antes de cobrar.
6. Conferir plano somente anual e também contratação pelo mobile.
7. Confirmar pagamento e entrega do webhook no ambiente apropriado; em
   produção, concluir o checkout gera cobrança real.

Publicar o backend antes do frontend. Os secrets Stripe existentes não mudam.
