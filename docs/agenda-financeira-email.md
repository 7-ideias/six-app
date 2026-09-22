# Agenda Financeira por e-mail — integração

A feature automática é executada no `sixBack`, na branch
`feat/agenda-financeira-email`. Não depende de o Flutter permanecer aberto.

## Fluxo analisado

- `lib/core/services/agenda_financeira_lancamento_service.dart` compartilha a
  comunicação entre Web e Mobile e consulta agenda/valores confirmados em paralelo.
- `lib/presentation/screens/agenda_financeira_web.dart` e
  `lib/presentation/screens/agenda_financeira_mobile_screen.dart` mantêm interfaces
  próprias e filtros individuais.
- O backend calcula a consulta principal com
  `AgendaFinanceiraRecorrenciaConsultaService`, incluindo recorrências e valores
  em aberto. O e-mail reutiliza seu resumo para o **mês atual**, sem aplicar os
  filtros individuais de cada tela nem representar o painel de valores confirmados.

## Comportamento da primeira versão

Após ativação operacional no backend, o resumo é enviado diariamente às 08h no
fuso do comércio, para o e-mail cadastrado de cada proprietário elegível. Idioma
e moeda usam a regionalização existente. A ativação vem desligada por padrão.
O conteúdo explica que vencidos de outros meses não entram no recorte.

Não há mudança nos contratos atuais, novos campos obrigatórios, credenciais SMTP,
agendamento local ou nova tela nesta etapa. O estado de envio é persistido no
backend; não há endpoint novo de histórico ou edição exposto ao aplicativo.

## Próxima etapa: configuração por interface ou RAG

O backend oferece `ConfiguracaoEnvioAgendaFinanceiraProvider`, inicialmente com
política fixa. Uma implementação persistida poderá ser adotada sem acoplar a
agenda ao provedor de e-mail.

Ao criar a edição, usar um contrato de aplicação autenticado e validado no backend,
compartilhado pelo service Flutter e pela ferramenta de RAG. Implementar telas
específicas para Web e Mobile. O usuário escolhe habilitação, horário e, após
evolução do modelo de ocorrências, frequência. Credenciais SMTP continuam sendo
configuração operacional e nunca passam pelo aplicativo ou pelo RAG.

A documentação operacional, variáveis de ambiente, segurança, migration e
semântica dos status estão em `sixBack/docs/agenda-financeira-email.md`.
