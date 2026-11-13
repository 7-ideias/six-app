# UTC e calendário da empresa

## Comportamento

- Novos instantes de criação, edição, recebimento, cancelamento e auditoria usam UTC no backend. O fuso do servidor não define o instante.
- Web e mobile exibem os horários pela configuração da empresa ativa, administrada pelo ADMIN. A preferência individual de idioma não altera o fuso.
- Campos UTC explícitos (`dataOperacaoUtc`, `dataHoraUtc`) são convertidos uma vez pelo `CompanyTime`. Respostas locais de compatibilidade preservam seus componentes e não são convertidas novamente.
- Vencimentos, competências, nascimento, contratação e datas comerciais escolhidas são datas civis. Seus componentes permanecem no calendário da empresa.
- `calendarNow` fornece os componentes do horário da empresa para formulários e filtros. `nowInCompany` preserva o instante; `companyTimeToUtc` interpreta um horário local da empresa para calcular durações.
- Horários antigos não foram corrigidos nem regravados em massa, conforme decisão do usuário para o ambiente de testes. Datas opcionais inválidas/ausentes mantêm fallback; configurações de fuso inválidas não derrubam a formatação.

## Cobertura da ampliação

| Área | Ajustes |
| --- | --- |
| Vendas e recebíveis | Consulta UTC, recebimento total/parcial, calendário de contas a receber, destinos e previsões de recebimento |
| Agenda e financeiro | Formulários, filtros, liquidação/pagamento, cartões e resumo financeiro |
| Caixa | Formatação da abertura, duração pela zona da empresa e filtros de operação |
| Compras | Datas iniciais, duplicação e recebimento, auditoria UTC no backend |
| Assistência técnica | Criação/edição, filtros e horários dos PDFs |
| Estoque e fornecedores | Eventos UTC no backend e formatação da apresentação |
| Cadastros, catálogo e procedimentos | Calendário da empresa, eventos explícitos e eliminação de conversões para o fuso do dispositivo |
| Comunicação | Instantes de notificações/WebSocket explícitos e exibição do chat |
| Administração visual | Exibição do agendamento pelo fuso associado e preservação da hora escolhida enviada junto com a zona IANA |

A fonte compartilhada de formatação continua sendo `LocaleSettingsProvider` + `CompanyTime`. Cada plataforma mantém sua própria interface. Clientes HTTP, autenticação e escopo `idUnicoDaEmpresa` existentes foram preservados; não houve nova dependência ou alteração de esquema SQL.

O backend usa `MongoUtcConfig` para persistir e consultar `LocalDateTime` como UTC, independentemente da JVM. Datas civis `LocalDate` mantêm seu dia. A auditoria SQL usa UTC explícito nas colunas legadas de timestamp. O histórico da agenda grava ISO com `Z` e aceita leitura de formatos anteriores. Mais detalhes em `sixBack/docs/horarios-vendas.md`.

## Validação

- Backend: 478 testes, 476 aprovados, 2 ignorados, zero erros/falhas.
- Flutter: 99 testes da bateria de horários, modelos, regionalização, consultas, agenda web/mobile, compras, atendimento e recebimentos aprovados.
- Rechecagem após ajustes de ciclo de vida: 44 testes de horários, agenda web/mobile e cartão aprovados.
- Análise estática: zero erros e nenhum diagnóstico novo em comparação com o commit anterior `ec5b3ca`. Permanecem avisos/informações já existentes.
- Formatação Dart executada; a formatação de partes antigas foi preservada para reduzir alterações sem relação com a tarefa. `git diff --check` passou.
- Testes cobrem UTC/offset, meia-noite, troca de empresa, horário de verão, Nepal, fallback, duração do caixa, Mongo sob fusos diferentes, callbacks SQL e conteúdo do PDF em UTC+14.

### Falhas preexistentes confirmadas

Duas baterias adicionais reproduzem problemas anteriores de seletores/estilo de widgets, também verificados em checkout separado do commit `ec5b3ca`:

- `workspace_home_web_test.dart`: 10 aprovações e 3 falhas; os testes de horário do caixa passam.
- `financeiro_fluxos_test.dart`: 11 aprovações e 7 falhas; os testes de confirmar/estornar recebíveis passam.

Essas 10 falhas não foram ocultadas ou removidas. Não impedem a análise estática, mas a suíte ampliada do Flutter não está inteiramente verde.

## Limites e conferência no ambiente

Não houve acesso ao banco remoto, correção de histórico, merge ou deploy. A validação de conversão/persistência usa testes automatizados sem Mongo/Postgres reais. Antes do merge, conferir no ambiente conectado uma venda imediata, fiado/parcial, baixa, cancelamento/estorno, compra/recebimento e atendimento/PDF, com o aparelho em fuso diferente da empresa.
