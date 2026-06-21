# AGENTS.md — Flutter

## Contexto do projeto

Este repositório contém o frontend Flutter do Six, um app SaaS/CRM Freemium para comércios que prestam serviço técnico, como assistências de celular, eletrônicos, informática e lojas que também vendem produtos e serviços.

O app deve funcionar em:

- Web
- Android
- iOS

O app funciona apenas com internet.

O backend é responsável pelas regras de negócio, autenticação, autorização, permissões, dados financeiros, relatórios, notificações e operações sensíveis.

## Stack atual

- Flutter
- Dart SDK conforme `pubspec.yaml`
- Provider como gerenciamento de estado já utilizado no projeto
- `http` e `http_interceptor` para comunicação HTTP
- `shared_preferences` para preferências locais simples
- `flutter_localizations` e `intl` para internacionalização
- `fl_chart` para gráficos
- `stomp_dart_client` para comunicação WebSocket/STOMP quando aplicável
- `flutter_local_notifications` para notificações locais
- `signature` para captura de assinatura

Não adicionar pacotes novos sem justificar a necessidade, compatibilidade com Web/Android/iOS e impacto no projeto.

## Objetivo do frontend

O Flutter deve entregar uma experiência simples, moderna e produtiva para:

- ADMIN
- colaboradores
- técnicos
- atendentes
- usuários de loja

O app deve facilitar a rotina diária do comércio:

- abrir atendimento
- criar ordem de serviço
- consultar cliente
- registrar equipamento
- gerar orçamento
- acompanhar execução do serviço
- vender produto ou serviço
- receber pagamento
- gerar comprovante
- compartilhar PDF
- acompanhar financeiro
- visualizar indicadores
- configurar loja e permissões

## Princípio principal

O frontend melhora a experiência do usuário, mas não é a fonte de verdade de regras sensíveis.

Não duplicar no Flutter regras críticas que pertencem ao backend.

O Flutter pode validar campos, melhorar usabilidade e evitar erros simples, mas o backend sempre deve validar:

- permissões
- vínculo com comércio
- preço final
- desconto
- status
- transição de ordem de serviço
- dados financeiros
- geração de relatório
- cancelamentos
- ações administrativas

## Navegação web

A versão web deve usar navegação adequada para desktop, preferencialmente com menu lateral nas áreas autenticadas.

Menu principal recomendado:

- Dashboard
- Atendimentos
- Vendas
- Clientes
- Catálogo
- Financeiro
- Relatórios
- Equipe
- Configurações

A loja/comércio atual deve aparecer como seletor global, preferencialmente no topo da tela.

Exemplo:

- Loja atual: Assistência Centro

O usuário precisa saber claramente em qual comércio está operando.

## Navegação mobile

A versão mobile não deve copiar o menu lateral completo da web.

Usar navegação inferior com poucos itens principais.

Sugestão:

- Início
- Atendimentos
- Vendas
- Clientes
- Mais

Dentro de "Mais":

- Catálogo
- Financeiro
- Relatórios
- Equipe
- Configurações

Web e mobile devem ter aderência funcional, mas não precisam ter layout idêntico.

## Rotas e estrutura existente

O projeto já possui rotas web tratadas no `main.dart`, incluindo fluxos como login, registro, onboarding, checkout, app autenticado e rotas públicas de ordem de serviço e auto cadastro de cliente.

Antes de alterar rotas:

- verificar o fluxo atual em `main.dart`
- evitar quebrar deep links existentes
- manter compatibilidade com web usando path URL strategy
- testar acesso direto por URL quando alterar rota web
- evitar criar rotas duplicadas para o mesmo conceito

## Responsividade

Construir telas considerando:

- desktop
- tablet
- smartphone

Evitar telas que dependam de largura fixa.

Preferir componentes adaptáveis:

- menu lateral no web
- bottom navigation no mobile
- cards responsivos
- tabelas com alternativa mobile
- formulários quebrados em seções
- ações principais sempre visíveis

Tabelas grandes no mobile devem virar cards, listas resumidas ou telas de detalhe.

## Estrutura recomendada

Seguir a estrutura existente do projeto.

Quando não houver padrão definido, preferir separação por feature.

Exemplo conceitual:

- `features/dashboard`
- `features/attendance`
- `features/sales`
- `features/customers`
- `features/catalog`
- `features/financial`
- `features/reports`
- `features/team`
- `features/settings`
- `core`
- `shared`

Dentro de cada feature, separar responsabilidades:

- pages/screens
- widgets
- controllers/viewmodels/providers
- services
- models/dtos
- repositories
- routes

Não colocar regra de negócio complexa diretamente em widgets.

## Estado da aplicação

Usar o padrão de gerenciamento de estado já definido no projeto.

O projeto já utiliza `provider`, então não introduzir Riverpod, Bloc, GetX, MobX ou outro gerenciador sem autorização explícita.

Separar:

- estado de tela
- estado de sessão
- estado de autenticação
- estado do comércio selecionado
- dados carregados da API
- filtros e paginação

## Autenticação

A autenticação deve seguir a arquitetura definida para o projeto.

O Flutter deve:

- permitir login
- manter sessão conforme estratégia definida
- tratar expiração de token
- fazer logout seguro
- não expor tokens em logs
- não salvar segredos no código
- não guardar credenciais fixas
- não simular usuário autenticado em código de produção

Qualquer token ou informação sensível deve ser tratado com cuidado.

## Comércio selecionado

Como um ADMIN pode ter mais de um comércio, o app deve manter o contexto da loja atual.

O comércio selecionado influencia:

- dashboard
- clientes
- produtos
- serviços
- estoque
- vendas
- ordens de serviço
- financeiro
- relatórios
- colaboradores
- configurações

A troca de comércio deve recarregar os dados do contexto atual.

Nunca presumir que dados de uma loja valem para outra.

## Permissões no frontend

O frontend pode esconder botões e menus conforme permissões do usuário, mas isso é apenas melhoria de experiência.

O backend continua sendo responsável por autorizar a operação.

Exemplos de ações que podem ser ocultadas no frontend:

- cancelar venda
- excluir ordem de serviço
- acessar financeiro
- alterar permissões
- gerar relatório financeiro
- configurar loja
- alterar plano
- aplicar desconto
- alterar preço

Não criar regra de permissão apenas no Flutter.

## Módulos do app

### Dashboard

Mostrar visão geral da loja:

- vendas do dia
- ordens de serviço abertas
- orçamentos pendentes
- contas a receber
- contas a pagar
- serviços atrasados
- faturamento mensal
- indicadores principais

### Atendimentos

Fluxo principal da assistência técnica:

- nova ordem de serviço
- ordens de serviço
- orçamentos
- serviços em andamento
- aguardando aprovação
- aguardando peças
- finalizados
- garantias/retornos

### Vendas

Fluxo de venda direta:

- nova venda
- vendas realizadas
- orçamentos de venda
- devoluções/cancelamentos

### Clientes

Cadastro e visão do cliente:

- lista de clientes
- dados do cliente
- equipamentos
- histórico
- ordens de serviço
- vendas
- comprovantes
- comunicações

### Catálogo

Produtos e serviços:

- produtos
- serviços
- categorias
- tabela de preços
- estoque

### Financeiro

Área com permissão sensível:

- caixa
- contas a receber
- contas a pagar
- recebimentos
- despesas
- fluxo de caixa

### Relatórios

Relatórios e exportações:

- vendas
- serviços
- financeiro
- estoque
- clientes
- comprovantes

### Equipe

Gestão de pessoas internas e fornecedores:

- colaboradores
- técnicos
- fornecedores
- permissões
- convites

### Configurações

Configurações gerais:

- dados da loja
- usuários
- perfis de acesso
- idioma
- moeda
- fuso horário
- status personalizados
- numeração de ordem de serviço
- PDFs e comprovantes
- modelos de mensagem
- integrações
- plano e assinatura
- auditoria

## Internacionalização

O app deve ser preparado para múltiplos idiomas.

Não hardcodar textos exibidos ao usuário quando a tela for parte do produto final.

Textos de tela, botões, mensagens de erro, labels e menus devem ser preparados para i18n.

Considerar que o app pode operar em países diferentes, com:

- idioma diferente
- moeda diferente
- formato de data diferente
- fuso horário diferente
- formato de telefone diferente
- documentos diferentes

## Design system

Evitar componentes visuais soltos e repetidos.

Preferir:

- tema centralizado
- cores centralizadas
- tipografia centralizada
- espaçamentos reutilizáveis
- componentes compartilhados
- botões padronizados
- cards padronizados
- campos de formulário padronizados
- estados de loading, empty e error padronizados

Não criar visual inconsistente entre módulos.

## Experiência do usuário

A aplicação deve ser simples para usuário de loja.

Priorizar:

- ações claras
- botões objetivos
- fluxo rápido de atendimento
- baixa fricção
- telas limpas
- busca fácil
- filtros úteis
- confirmação para ações destrutivas
- feedback visual após salvar, cancelar, enviar ou concluir

Evitar telas técnicas demais para usuário final.

## Estados de tela

Toda tela que carrega dados deve tratar:

- loading
- sucesso
- vazio
- erro
- sem permissão
- sem internet
- sessão expirada

Como o app é online-only, queda de internet deve gerar mensagem clara.

Não deixar tela quebrada ou carregando indefinidamente.

## Formulários

Formulários devem:

- validar campos obrigatórios
- mostrar mensagens claras
- evitar perda acidental de dados
- permitir cancelar
- mostrar confirmação em ações críticas
- usar máscaras quando fizer sentido
- respeitar idioma/região
- não enviar dados incompletos quando houver validação local possível

Validação local não substitui validação do backend.

## Integração com API

Centralizar chamadas HTTP.

Evitar chamadas diretas espalhadas dentro de widgets.

Tratar:

- token expirado
- erro 400
- erro 401
- erro 403
- erro 404
- erro 409
- erro 500
- timeout
- sem conexão

DTOs do frontend devem refletir contratos da API.

Não inventar campos sem alinhar com backend.

## PDF e compartilhamento

O app pode permitir:

- gerar PDF
- visualizar PDF
- baixar PDF
- compartilhar por WhatsApp
- enviar por e-mail
- compartilhar por outros canais disponíveis

Os dados do PDF devem vir do backend ou de endpoint próprio validado.

Não gerar comprovante sensível apenas com dados manipuláveis do frontend, salvo se a arquitetura do projeto definir isso explicitamente.

## Notificações

O app deve permitir configurar ou visualizar notificações relacionadas às etapas da assistência técnica.

Eventos possíveis:

- orçamento criado
- orçamento aprovado
- serviço iniciado
- aguardando peça
- serviço finalizado
- equipamento pronto para retirada
- pagamento pendente

O envio real deve ser controlado pelo backend.

## Segurança no frontend

Não fazer:

- logar token
- logar dados sensíveis
- salvar senha
- expor segredo em arquivo Dart
- deixar endpoint interno hardcoded sem configuração
- criar bypass de login
- esconder regra sensível apenas no frontend
- confiar em permissões manipuláveis localmente
- deixar tela administrativa acessível sem validação de sessão/permissão

## Testes

Adicionar ou ajustar testes quando alterar:

- navegação
- regras de exibição por permissão
- componentes compartilhados
- formatação de dados
- validações de formulário
- integração com camada de API
- estado de loading/erro/vazio
- fluxo de login/logout
- seleção de comércio

Usar os padrões de teste já existentes no projeto.

## Comandos úteis

Antes de finalizar alterações relevantes, considerar executar:

```bash
flutter pub get
flutter gen-l10n
flutter test
flutter analyze
```

Para build web, conforme README atual:

```bash
flutter build web
```

## O que não fazer

Não fazer:

- regra de negócio crítica em widget
- duplicação de regra do backend
- hardcode de textos, cores e endpoints
- layout fixo apenas para desktop
- tela web impossível de usar no mobile
- tela mobile sem aderência funcional com web
- chamadas HTTP espalhadas em widgets
- código de autenticação temporário em produção
- dependência nova sem necessidade
- componente visual duplicado sem motivo
- alteração grande sem plano

## Fluxo de trabalho para o agente

Antes de implementar uma tarefa relevante:

1. Ler este arquivo.
2. Identificar se a alteração afeta web, mobile ou ambos.
3. Verificar impacto na navegação.
4. Verificar impacto em i18n.
5. Verificar impacto em permissões.
6. Criar plano breve.
7. Implementar somente o escopo pedido.
8. Reutilizar componentes existentes.
9. Adicionar ou ajustar testes quando necessário.
10. Resumir arquivos alterados, decisões e pendências.

## Definição de pronto

Uma tarefa só está pronta quando:

- funciona em web e mobile, quando aplicável
- respeita a navegação definida
- não duplica regra sensível do backend
- trata loading, erro e estado vazio
- respeita permissões na experiência visual
- não expõe dados sensíveis
- não introduz textos hardcoded desnecessários
- segue o padrão visual do projeto
- mantém aderência entre web e mobile
- testes foram adicionados ou ajustados quando necessário
