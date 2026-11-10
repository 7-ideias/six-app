# MVP 4 — contratação Stripe

- Web: menu do usuário → **Planos e pagamento**, ou `/app/assinatura`.
- Mobile: Configurações → **Planos e pagamento**.
- Tela de bloqueio: contratação/regularização incorporada, sem exigir acesso às operações do comércio.
- Mensal recorrente ou anual antecipado (10 mensalidades por 12 meses), valores e permissões vindos do backend. PT/EN/ES; formatação local mantendo a moeda BRL da oferta.
- Pagamento e cancelamento abrem Stripe no navegador. No retorno, **Já paguei / atualizar pagamento** consulta o backend; voltar à tela sozinho não concede acesso.
- Checkout público e fallback Flutter deixam de simular cobrança e encaminham à assinatura autenticada. Não há campos próprios de cartão.
- Portal disponível para assinatura existente; colaborador recebe orientação para o administrador. Erros e conflitos permitem atualizar sem criar outra cobrança.
- Backend precisa configurar Stripe Test Mode, webhook versão 2025-06-30.basil e Customer Portal. Consulte `sixBack/docs/billing-mvp4-stripe.md`.

Validação pendente antes do merge: build web/Android/iOS e roteiro de pagamento em Test Mode. Execução Flutter local não foi possível no ambiente de implementação; formatação Dart e modelo foram verificados. Não houve deploy nem cobrança real.
