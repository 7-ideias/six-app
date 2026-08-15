# Etiquetas — Lote 0 / Spikes técnicos

Data: 2026-08-15

Branches utilizadas nos dois repositórios:

```text
feature/20260814-melhorias
```

## Escopo

O Lote 0 permanece propositalmente separado do módulo definitivo.

Ele valida:

1. PDF físico 50 × 30 mm e A4 3 × 8 no backend;
2. cobertura de barcode/QR com o OpenPDF atual;
3. editor Flutter Web mínimo com mm → px, seleção, drag e resize.

Não foram incluídos neste lote:

- `Catálogo > Etiquetas` na Sidebar;
- CRUD;
- MongoDB;
- DTO/API de produção;
- permissões de Etiquetas;
- bindings reais de Produto;
- dependência nova de barcode/QR;
- alteração de telas Mobile.

---

# Spike C — editor Flutter Web

Arquivos criados:

```text
lib/presentation/spikes/etiqueta_editor_web_spike.dart
lib/spikes/etiqueta_editor_spike_main.dart
```

O entrypoint é independente do `main.dart` do SixApp.

Executar:

```bash
flutter run -d chrome -t lib/spikes/etiqueta_editor_spike_main.dart
```

## O que validar

O canvas representa uma etiqueta fixa de:

```text
50 × 30 mm
```

Há três elementos de prova:

- texto / nome do produto;
- preço de preview;
- barcode placeholder.

Validar manualmente:

- selecionar cada elemento;
- mover com mouse/trackpad;
- redimensionar pelo handle inferior direito;
- tentar arrastar para fora da etiqueta;
- tentar aumentar o elemento além da borda;
- confirmar que X/Y/Largura/Altura continuam em mm;
- redimensionar a janela e confirmar que a escala px/mm muda sem alterar a geometria em mm;
- Light e Dark Mode via tema do sistema;
- largura desktop e abaixo de 980 px.

## Decisão arquitetural provada pelo spike

A geometria de domínio pode permanecer em milímetros e o Flutter precisa apenas de uma escala transitória:

```text
scale = min(larguraDisponivelPx / 50, alturaDisponivelPx / 30)
```

Movimento:

```text
deltaMm = deltaPx / scale
```

Render:

```text
xPx = xMm * scale
yPx = yMm * scale
widthPx = widthMm * scale
heightPx = heightMm * scale
```

Nenhum pixel é persistido.

---

# Spikes A e B — backend

O backend usa a mesma branch:

```text
7-ideias/sixBack
feature/20260814-melhorias
```

O spike backend foi mantido em `src/test` para não expor endpoint ou componente de runtime.

Executar no backend:

```bash
./mvnw -Dtest=EtiquetaLote0SpikeTest test
```

Artefatos esperados:

```text
target/etiquetas-spike/etiqueta-50x30mm.pdf
target/etiquetas-spike/folha-a4-3x8.pdf
target/etiquetas-spike/barcodes-openpdf-1.3.43.pdf
target/etiquetas-spike/resultado.txt
```

O backend contém documentação detalhada em:

```text
docs/etiquetas-lote0-spike.md
```

## Cobertura descoberta no OpenPDF 1.3.43

A versão já presente cobre nativamente os códigos 1D exercitados no spike:

```text
CODE128
CODE39
EAN13
EAN8
UPCA
ITF
```

A classe `com.lowagie.text.pdf.BarcodeQRCode` não faz parte da versão analisada. Existe `BarcodeDatamatrix`, porém DataMatrix e QR são simbologias diferentes e não devem ser tratados como equivalentes.

Portanto, o Lote 0 não adiciona biblioteca nova. Se QR continuar obrigatório no renderer final, a dependência Java será decidida no Lote 5 depois de um teste explícito de legibilidade/tamanho.

---

# Parte que continua necessariamente manual

O repositório consegue provar o `MediaBox` matemático do PDF, mas não consegue provar sozinho o comportamento físico de navegador, driver e impressora.

Após gerar os PDFs, imprimir com:

```text
100% / tamanho real
sem Fit to page
sem ajuste automático de escala
```

Medir:

- etiqueta 50 × 30 mm;
- quadrado 10 × 10 mm;
- régua 40 mm;
- primeira e última linha/coluna do A4.

Se possível, repetir em duas impressoras/drivers.

---

# Critério para avançar ao Lote 1

Podemos iniciar a fundação definitiva quando:

- o spike Dart compilar/analisar e o drag/resize se comportar corretamente;
- o spike Java compilar e gerar os três PDFs;
- os códigos 1D forem lidos em tamanho útil;
- pelo menos uma medição física do PDF confirmar escala aceitável ou revelar a necessidade de calibração;
- a decisão de QR estiver registrada como dependência futura ou requisito removido.

Até essa validação, nenhuma estrutura Mongo/API definitiva de Etiquetas foi consolidada.
