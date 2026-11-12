# Cartões no mobile — validação

Branch: feature/20261112-cartoes-cadastro-web. Backend: mesma branch, com migrações V25–V29. Não executar os testes com contas reais sem intenção de registrar os movimentos; usar dados identificados como TESTE.

## Entradas
- Financeiro > escolher Empresa ou Pessoal > Cartões de crédito: cadastro e faturas.
- Financeiro > Gastos por categoria: herda espaço e intervalo inicial do resumo.
- Agenda > Novo lançamento > A pagar > espaço > Cartão de crédito: compra. Pagamento direto mantém a jornada existente.
- Tocar numa fatura da agenda abre sua tela própria. A baixa comum/parcial não deve ser usada para faturas.

## Roteiro funcional
1. Criar cartão TESTE Nubank, fechamento 3 e vencimento 10, conta prevista opcional. Reabrir e editar nome/conta/dias. Conferir a mesma informação na Web.
2. Criar outro cartão no outro espaço. Confirmar que Empresa e Pessoal não misturam cartões, contas, compras e faturas.
3. Criar compra única Netflix, valor 50, categoria Assinaturas. Revisar vencimento e confirmar uma vez. Deve aparecer uma compra e uma obrigação da fatura na agenda.
4. Criar segunda compra de 30 na mesma fatura. Total esperado: 80, com dois itens. Conferir também na Web.
5. Editar a compra de 30 para 40 e depois excluir essa compra. Total esperado: 90 após edição e 50 após exclusão. Confirmar que o resumo/agenda reflete a atualização.
6. Criar recorrência mensal de 20. Ver previsões nas próximas faturas. Editar somente uma ocorrência; as demais preservam valor. Editar esta e próximas para 25; anteriores e pagas ficam preservadas. Encerrar após uma ocorrência: mantém esta e anteriores, remove próximas não pagas.
7. Criar compra parcelada de 100 em 3 vezes. A prévia deve somar exatamente 100; as faturas devem receber as parcelas 1/3, 2/3 e 3/3. Editar descrição/categoria de uma parcela; valor, data e cartão devem ficar protegidos.
8. Pagar uma fatura sem previsões futuras, escolhendo conta, forma e data efetiva. Deve ficar paga e não oferecer edição/exclusão das compras. Na agenda/confirmados, conferir o valor e a data de pagamento, mesmo se o vencimento for de outro dia.
9. Abrir Gastos por categoria e escolher período que inclua o pagamento. Realizado deve contar as compras pagas uma vez, sem somar a própria fatura outra vez. Previsto deve mostrar as compras de faturas abertas. Testar filtros e abrir a fatura pelo detalhe.
10. Inativar um cartão: continua consultável, mas indisponível para novas compras. Tentar criar compra sem cartões: deve existir acesso ao cadastro.

## Falhas e proteção
- Sem rede ao consultar: mensagem e tentar novamente, nunca lista vazia falsa. Dados anteriores podem permanecer identificados como desatualizados, com ações bloqueadas.
- Sem rede ou timeout ao salvar/pagar: preservar preenchimento; repetir usa o mesmo ID e payload. Conferir no backend que existe apenas um registro. Se sair após resposta incerta, conferir a lista antes de iniciar outro comando.
- Editar na Web enquanto o mobile está aberto: versão antiga deve resultar em conflito, exigindo voltar/atualizar. Não sobrescrever a mudança silenciosamente.
- Usuário sem edição: consulta permitida quando autorizada, sem botões de manutenção ou pagamento. Sem leitura: erro de permissão, sem dados antigos expostos.
- Fatura com ocorrência futura prevista: pagamento bloqueado. Fatura paga: manutenção financeira bloqueada; encerrar recorrência ativa continua preservando o histórico.

## Apresentação e regressão
- Testar telefone estreito, tema claro/escuro, teclado aberto e fontes ampliadas.
- Seletores de cartão, categoria, conta, forma e datas devem abrir bottom sheets.
- Testar pt/en/es e moeda/regionalização configurada.
- Voltar entre passos do lançamento direto preserva dados. Recebimentos continuam sem opções de cartão de despesa.
- Smoke test da Web: lançar compra, consultar faturas e pagar. APIs/modelos são compartilhados; telas mobile são independentes.
- CI valida Dart, widgets, build Web e workflow de agenda compila Android debug. iOS requer execução no ambiente Apple/dispositivo de teste.
