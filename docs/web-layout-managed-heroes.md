# Layout e cabeçalhos das páginas operacionais Web

Branch nos dois repositórios: `feature/20261005-web-layout-managed-heroes`.

As páginas Vendas, Devoluções e trocas, Caixa, Assistências técnicas, Compras,
Reservas, Produtos e Estoque usam `SixWebPageShell` e `SixManagedWebHero`.
As margens são calculadas sobre a área disponível depois da barra lateral:

| Largura disponível | Margem em cada lado |
| --- | --- |
| Menor que 1200 px | 16 px |
| De 1200 até 1599 px | 24 px |
| A partir de 1600 px | 32 px |

O conteúdo ocupa até 1680 px, centralizado, com margem vertical de 20 px.
O cabeçalho tem altura mínima de 196 px, ou 180 px abaixo de 760 px de largura.
Textos e ações podem aumentar sua altura. O layout mobile das devoluções mantém
seu cabeçalho e suas margens anteriores.

## Imagens e atualização de contexto

O Flutter solicita
`GET /private/api/web-header/assets?incluirOperacionais=true`, com autenticação
e o cabeçalho `idUnicoDaEmpresa`. A resposta inclui os dez códigos de páginas,
quando há uma imagem resolvida. Sem a opção, o backend mantém os três códigos
originais para clientes anteriores.

Os novos slots aparecem no painel de assets visuais do administrador, com nomes
em português, inglês e espanhol. Eles permitem upload e agendamento pelos
fluxos existentes. A dimensão recomendada é 1800 × 560 px. Até haver arte própria,
o backend reaproveita assets genéricos já publicados; não é necessário publicar
arquivos novos para o primeiro teste.

Ao trocar empresa ou perfil de negócio, o controlador limpa a imagem, mostra
shimmer e busca o catálogo do novo contexto. Respostas atrasadas são descartadas.
Eventos de versão dos assets também recarregam o catálogo; a versão global é
incluída na URL para invalidar o cache. Falhas de rede mantêm o cabeçalho legível
com o fundo do tema.

## Teste local

1. Faça checkout da mesma branch em `six-app` e `sixBack`.
2. Inicie o backend com a configuração local existente na porta 8082.
3. No Flutter, execute:

   ```bash
   flutter pub get
   API_BASE_URL=http://localhost:8082 bash scripts/dev_web_hot_reload.sh
   ```

4. Entre pela rota `http://localhost:39441/login/flutter`.
5. Confira as oito páginas com barra lateral aberta e recolhida, em larguras
   menores e maiores, nos temas claro e escuro. Verifique o alinhamento das
   bordas dos cabeçalhos, filtros, indicadores e listas.
6. Troque de empresa e de segmento/subsegmento. Confira o shimmer, a nova imagem
   e a ausência de imagens do contexto anterior.
7. Como administrador autorizado, confira os sete slots adicionais, publique
   uma imagem por um fluxo já existente e force a atualização de versão.
   Confira também um agendamento vigente no ambiente local.
8. Exercite as ações existentes de cada página, inclusive devoluções, caixa,
   filtros e navegação para cadastros. Compras continua sendo um protótipo com
   dados em memória.

Os testes de API não substituem essa revisão autenticada com os dados locais.

## Verificações executadas

- Build Web release com Flutter 3.41.4 / Dart 3.11.1: concluído.
- Análise dos arquivos alterados: sem erros novos; os seis apontamentos também
  ocorrem na `main` usada como base. Os componentes novos não têm apontamentos.
- Testes selecionados do Flutter: 18 passaram. Três verificações de texto-fonte
  já falham na `main`: a de modais de Assistências e duas de tema do catálogo
  (`tokens.workspaceBackground` e `tokens.stockWarning`).
- Backend: compilação concluída e nove testes de cabeçalhos, ambiente e versão
  passaram, incluindo a resposta legada de três páginas.

Comando do build local:

```bash
flutter build web --dart-define=API_BASE_URL=http://localhost:8082
```

As telas autenticadas com a base local ainda devem ser revisadas pelo roteiro
acima antes dos PRs. As verificações foram feitas sem alterar dependências ou
configurações de ambiente versionadas.
