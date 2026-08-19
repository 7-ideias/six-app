---
name: six-web-impact-dialogs
description: "Implementar ou refatorar experiências de confirmação, encerramento, conclusão e ações críticas na versão Flutter Web do SIX seguindo o padrão visual do encerramento de caixa: fundo navy esmaecido com blur, modal focal, ícone com microanimação, resumo contextual e estados assíncronos de revisão, processamento, sucesso e erro. Usar quando o usuário pedir que outra parte do app Web siga esse modelo ou efeito, ou solicitar um modal, diálogo, confirmação impactante ou feedback visual de operação no SIX Web. Não usar para fluxos exclusivamente mobile, alertas triviais ou páginas sem interação modal."
---

# Diálogos de impacto no SIX Web

## Objetivo

Criar uma experiência marcante e coerente com o SIX sem perder clareza operacional. Adaptar o padrão ao contexto da ação; não copiar textos, métricas, ícones ou cores sem avaliar a semântica do novo fluxo.

## Executar o fluxo

### 1. Diagnosticar o ponto de integração

1. Ler as instruções do repositório e inspecionar a tela, serviço, tema, i18n e testes envolvidos.
2. Localizar, quando existirem:
   - `lib/presentation/components/web/six_web_cash_session_close_dialog.dart` como referência canônica de experiência rica;
   - `lib/presentation/components/web/six_web_animated_dialog.dart` como opção para diálogos simples;
   - `WebThemeTokens` e `six_i18n.dart` para tema e traduções.
3. Confirmar quais dados resumem a decisão do usuário e qual callback assíncrono executa a operação.
4. Preservar alterações não relacionadas e manter domínio, serviço e modelos compartilháveis com Mobile.

### 2. Escolher a intensidade correta

- Usar o helper animado existente para confirmação curta, sem progresso próprio ou resumo operacional.
- Criar um componente especializado quando houver ação crítica, chamada assíncrona, resumo de dados ou estados de sucesso e erro.
- Usar âmbar para atenção, azul da marca para ação informativa, verde/teal para sucesso e vermelho apenas como acento localizado de perigo.
- Evitar preencher toda a tela com rosa ou vermelho. Manter o backdrop navy neutro para concentrar a atenção no conteúdo.

Consultar [references/flutter-web-dialog-pattern.md](references/flutter-web-dialog-pattern.md) ao implementar um diálogo especializado ou decidir entre as variantes.

### 3. Compor a experiência visual

1. Aplicar backdrop navy translúcido com blur entre 10 e 14, preservando a percepção da tela anterior.
2. Animar a entrada em 240–360 ms com fade, pequeno deslocamento vertical e escala aproximada de `0.96` para `1.0`.
3. Limitar o modal normalmente a 560–680 px, usar raio de 20–24 px e adaptar o conteúdo para largura reduzida.
4. Exibir um ícone semântico em destaque com uma microanimação curta: pulso, anel, desenho, encaixe ou morph simples.
5. Respeitar `MediaQuery.disableAnimations`; reduzir transições a praticamente zero sem alterar o fluxo.
6. Mostrar de dois a três dados relevantes para a decisão. Priorizar nome/identificador, quantidade e valor ou consequência.
7. Manter hierarquia clara: ação de retorno discreta e ação principal visualmente dominante.

### 4. Implementar o comportamento

1. Criar o componente em `lib/presentation/components/web/` com nome `six_web_<contexto>_dialog.dart`.
2. Expor uma função `show...Dialog` com entradas tipadas e callback `Future<void> Function()` para a operação.
3. Manter a lógica de negócio fora do componente. Executar serviço e recarga por callback fornecido pela tela.
4. Modelar explicitamente os estados `review`, `processing`, `success` e `error` quando a ação for assíncrona.
5. Bloquear cliques duplicados, fechamento pelo teclado e navegação de retorno durante processamento e sucesso.
6. Implementar atalho explícito para `Esc` nos estados interativos, normalmente com `Shortcuts`, `Actions` e `Focus(autofocus: true)`, para fechar o modal como ação de voltar sem depender só do `PopScope`.
7. Garantir que `Esc` funcione em `review` e `error`, mas permaneça inativo em `processing` e `success`.
8. Manter o modal aberto durante a operação, transformar o conteúdo em sucesso e fechar após 600–900 ms.
9. Capturar falhas no diálogo, apresentar mensagem recuperável e permitir tentar novamente ou voltar.
10. Verificar `mounted` antes de atualizar estado ou fechar a rota após um `await`.
11. Usar `context.t(...)` ou o mecanismo i18n vigente. Adicionar chaves equivalentes em português, inglês e espanhol; não inserir novos textos visíveis somente em português.

### 5. Garantir acessibilidade e responsividade

- Definir `barrierLabel`, `Semantics(namesRoute: true)` e rótulo que descreva a ação.
- Preservar foco visível e navegação por teclado.
- Garantir que o modal receba foco inicial suficiente para capturar `Esc` e outros atalhos previstos.
- Não comunicar sucesso, erro ou perigo somente por cor; combinar cor, ícone e texto.
- Evitar overflow em 1024 px e no modo compacto do navegador.
- Não introduzir dependência exclusiva de Web em camadas compartilhadas com Mobile.

### 6. Validar antes de entregar

1. Formatar os arquivos Dart alterados.
2. Executar análise estática nos arquivos afetados.
3. Criar ou atualizar testes de widget cobrindo:
   - backdrop e conteúdo contextual;
   - fechamento com `Esc` em estado interativo;
   - bloqueio de `Esc` durante processamento;
   - bloqueio durante processamento;
   - transição para sucesso;
   - erro recuperável e nova tentativa ou retorno;
   - ausência de exceções e overflow.
4. Revisar o diff para garantir que o fluxo anterior, a integração com o serviço e as traduções foram preservados.
5. Informar claramente qualquer teste não executado e o motivo.

## Critérios de conclusão

Considerar a implementação pronta somente quando:

- a tela anterior permanecer reconhecível, esmaecida e sem tintura agressiva;
- o ícone atrair atenção sem animação excessiva;
- o usuário compreender a consequência antes de confirmar;
- processamento, sucesso e erro tiverem feedback dentro da mesma experiência;
- tema claro/escuro, movimento reduzido, teclado e i18n estiverem contemplados;
- a operação não puder ser disparada duas vezes.
