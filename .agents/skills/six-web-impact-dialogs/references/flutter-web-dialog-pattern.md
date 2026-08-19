# Padrão de diálogo Flutter Web do SIX

## Índice

1. Decisão de arquitetura
2. Anatomia visual
3. Máquina de estados
4. Estrutura recomendada
5. Paleta semântica
6. Tempos e movimento
7. Matriz mínima de testes

## 1. Decisão de arquitetura

| Situação | Solução preferida |
|---|---|
| Confirmação simples, sem progresso e sem resumo | Reutilizar `showSixWebAnimatedDialog` |
| Ação assíncrona com loading, sucesso e erro | Criar diálogo especializado |
| Ação crítica com valores ou consequências | Criar diálogo especializado com resumo |
| Mensagem transitória sem decisão | Usar toast, banner ou snackbar, não modal |
| Fluxo exclusivamente Mobile | Seguir o padrão Mobile correspondente |

Usar `showGeneralDialog` no componente especializado para controlar backdrop, transição, semântica e bloqueio de saída. Manter o callback de domínio injetado pela tela.

## 2. Anatomia visual

Compor o diálogo nesta ordem:

1. backdrop navy translúcido e `BackdropFilter`;
2. entrada por fade, deslocamento vertical curto e escala suave;
3. superfície elevada com raio de 20–24 px;
4. acento superior fino ou halo na cor semântica;
5. ícone animado, título e consequência;
6. resumo com dois ou três indicadores;
7. feedback de erro, quando aplicável;
8. ação secundária e ação principal.

Evitar confete, bounce intenso, loops rápidos e grandes áreas vermelhas. O impacto deve vir do foco, da transição e da mudança de estado.

## 3. Máquina de estados

Usar uma enumeração local quando o fluxo for assíncrono:

```dart
enum _DialogState { review, processing, success, error }
```

Aplicar as transições:

```text
review -> processing -> success -> fechar(true)
review -> processing -> error -> processing
review -> voltar -> fechar(false)
```

Tratar `processing` e `success` como estados ocupados. Impedir novo submit e retorno nesses estados.

## 4. Estrutura recomendada

Expor uma API pequena e específica:

```dart
Future<bool> showSixWebFeatureDialog({
  required BuildContext context,
  required String subjectName,
  required int itemCount,
  required String amount,
  required Future<void> Function() onConfirm,
});
```

Separar responsabilidades:

- função `show...Dialog`: criar rota, backdrop e transição;
- widget stateful: controlar estado visual e prevenir duplicidade;
- tela chamadora: executar serviço, atualizar dados e reagir ao resultado;
- i18n: fornecer todo texto visível;
- tema: fornecer superfícies, bordas e cores de texto.

Usar este esqueleto para a confirmação:

```dart
Future<void> _confirm() async {
  if (_isBusy) return;
  setState(() => _state = _DialogState.processing);

  try {
    await widget.onConfirm();
    if (!mounted) return;
    setState(() => _state = _DialogState.success);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.of(context).pop(true);
  } catch (_) {
    if (!mounted) return;
    setState(() => _state = _DialogState.error);
  }
}
```

Envolver o conteúdo em:

```dart
PopScope(
  canPop: !_isBusy,
  child: Semantics(
    namesRoute: true,
    label: title,
    child: dialog,
  ),
)
```

Não guardar `BuildContext` além da vida da rota nem chamar `setState` na tela como forma de exibir o progresso interno do modal.

## 5. Paleta semântica

| Papel | Direção visual |
|---|---|
| Backdrop | Navy profundo com opacidade aproximada de 70–78% |
| Atenção | Âmbar (`#F59E0B` claro, `#FBBF24` escuro) |
| Informativo | Azul primário do tema |
| Sucesso | Verde ou teal do tema |
| Perigo | Vermelho apenas no ícone, faixa ou botão principal |
| Superfície | `WebThemeTokens.surfaceElevated` ou equivalente |

Preferir tokens do tema. Usar valores fixos somente como fallback visual consciente e conferir contraste nos temas claro e escuro.

## 6. Tempos e movimento

| Elemento | Duração sugerida |
|---|---:|
| Entrada da rota | 240–360 ms |
| Microanimação do ícone | 600–800 ms |
| Troca de conteúdo | 200–260 ms |
| Confirmação visual de sucesso | 600–900 ms |
| Movimento reduzido | 1 ms ou conteúdo estático |

Usar curvas `easeOutCubic` na entrada e `easeInCubic` na saída. Permitir loop apenas durante processamento e mantê-lo lento e discreto.

## 7. Matriz mínima de testes

| Caso | Verificação |
|---|---|
| Abertura | Título, resumo, botões e backdrop presentes |
| Confirmação | Callback chamado uma única vez |
| Processamento | Botões bloqueados e modal permanece aberto |
| Sucesso | Conteúdo muda e retorna `true` após breve feedback |
| Erro | Mensagem aparece e usuário pode tentar novamente ou voltar |
| Cancelamento | Retorna `false` sem chamar o callback |
| Responsividade | Sem overflow na largura compacta |
| Acessibilidade | Semântica e movimento reduzido não geram exceções |
