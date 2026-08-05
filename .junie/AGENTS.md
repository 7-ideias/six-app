# AGENTS.md - SixApp Flutter

Este arquivo deve orientar respostas rápidas e eficientes no frontend Flutter do SixApp. Os detalhes vivos ficam nas skills locais em `.agents/skills`; este arquivo serve como roteador e checklist curto.

## Contexto

SixApp e o frontend Flutter do Six, usado em Web, Android e iOS. O backend principal fica no projeto `sixBack` e usa Java/Spring Boot.

O app atende comercios de assistencia tecnica, vendas, orcamentos, estoque, financeiro, atendimento, configuracoes e relatorios. O frontend melhora a experiencia, mas o backend continua sendo a fonte de verdade para regras sensiveis, permissoes, tenant, status, financeiro, autenticacao e contratos.

## Skills obrigatorias

Leia a skill certa antes de implementar. Nao copie todo o conteudo para ca; use a skill como fonte de verdade.

- Mobile visual: `.agents/skills/sixapp-mobile-ui/SKILL.md`
- Web visual: `.agents/skills/sixapp-web-ui/SKILL.md`
- Backend compartilhado Flutter: `.agents/skills/sixapp-shared-backend-integration/SKILL.md`
- Textos, idioma, moeda, datas e numeros: `.agents/skills/sixapp-regionalization/SKILL.md`

Use combinacoes quando o pedido tocar mais de uma area:

- Tela mobile com endpoint, service, DTO, provider ou chamada HTTP: `sixapp-mobile-ui` + `sixapp-shared-backend-integration`.
- Tela web com endpoint, service, DTO, provider ou chamada HTTP: `sixapp-web-ui` + `sixapp-shared-backend-integration`.
- Qualquer UI com textos, mensagens, status, moeda, data, hora, numero, percentual ou configuracao de comercio: adicione `sixapp-regionalization`.
- Pedido com arquivo mobile e arquivo web: use as skills de Web e Mobile, mas compartilhe somente backend, dominio, models, mappers, services e providers sem responsabilidade visual.

## Regra principal

Web e Mobile podem compartilhar integracao, dominio e estado nao visual. Nao podem compartilhar tela, dashboard, formulario grande, modal, side sheet, bottom sheet, conteudo principal de jornada ou arvore visual por wrapper.

Permitido compartilhar:

- endpoint e parametros tecnicos;
- ApiClient, request, response, `fromJson`, `toJson`;
- model, mapper, service e interpretacao semantica;
- provider/controller sem responsabilidade visual, quando fizer sentido;
- helpers de formatacao e utilitarios neutros.

Nao permitido:

- tela Web dentro de Mobile, ou Mobile dentro de Web;
- `embedded`, `isMobile`, `isWeb`, `platform`, `compact` ou condicionais equivalentes para transformar a mesma UI principal em duas experiencias;
- HTTP, token, headers ou parsing JSON dentro de widgets;
- payload adaptado diretamente na tela;
- contrato duplicado por plataforma para o mesmo endpoint.

## Fluxo de trabalho

1. Identifique o escopo real: Web, Mobile, compartilhado, backend, visual, funcional ou regionalizacao.
2. Leia o arquivo citado pelo usuario e busque implementacoes proximas com `rg`.
3. Trace o fluxo atual antes de editar: `UI -> estado/provider -> service -> ApiClient -> endpoint -> response`.
4. Verifique se ja existe endpoint, DTO, model, mapper, service ou provider reutilizavel.
5. Se houver UI Web e Mobile, mantenha composicoes proprias e compartilhe apenas a camada correta.
6. Faca a menor alteracao completa possivel. Nao misture refatoracao grande com feature ou correcao pontual.
7. Preserve contratos, rotas, autenticacao, tenant, permissoes e regras de negocio, salvo pedido explicito.
8. Formate, valide e revise o diff antes de responder.

Quando houver impacto em mais de uma camada, apresente plano curto antes de editar. Para ajustes pequenos e claros, implemente direto.

## Padrao de integracao

Para chamadas ao backend, prefira a arquitetura real existente no projeto. O caminho comum e:

```text
Tela Web --------\
                  -> provider/controller de apresentacao -> service compartilhado -> ApiClient -> DTO/model compartilhado
Tela Mobile -----/
```

Referencias boas para consultar quando aplicavel:

- `lib/domain/services/atendimento_tecnico/atendimento_tecnico_service.dart`
- `lib/data/services/atendimento_tecnico/atendimento_tecnico_api_client.dart`
- `lib/data/models/atendimento_tecnico_models.dart`
- `lib/domain/services/regionalizacao/regionalizacao_service.dart`
- `lib/providers/locale_settings_provider.dart`
- `lib/core/services/auth_service.dart`
- `lib/core/services/http_client_factory.dart`

Convencao recomendada para integracoes novas, quando o modulo justificar:

```text
lib/data/models/<dominio>_models.dart
lib/data/services/<dominio>/<dominio>_api_client.dart
lib/domain/models/<dominio>_models.dart
lib/mappers/<dominio>_mapper.dart
lib/domain/services/<dominio>/<dominio>_service.dart
lib/core/di/<dominio>_module.dart
```

Nao introduza Repository, DI nova, gerenciador de estado novo ou pacote novo sem necessidade real e autorizacao.

## UI Web

Para telas, modais, subpaineis, dashboards, listas, filtros e formularios Web, siga `sixapp-web-ui`.

Direcao pratica:

- use componentes e padroes Web existentes antes de criar estilo local;
- consulte a tela de Produtos e `web_dashboard_widgets` como referencia de hierarquia;
- prefira cabecalho unico, area de contexto, filtros organizados, cards compactos e acoes proporcionais;
- evite `ListTile` cru, tabela improvisada, card grande generico e sombra pesada em subpainel importante;
- use `LayoutBuilder`, `Wrap`, `Expanded`, `Flexible`, `ConstrainedBox`, scroll e `TextOverflow.ellipsis`;
- trate loading, vazio, erro, sucesso, bloqueio e sem permissao;
- use `SixBackendLoading` quando backend ainda estiver carregando mensagens, eventos ou configuracoes;
- use motion curta e funcional: fade, leve deslocamento, `AnimatedSwitcher`, `TweenAnimationBuilder`, `AnimatedContainer`;
- em KPIs, dashboards e totalizadores, anime numeros importantes mantendo valor bruto numerico ate o render.

Pedido somente Web nao deve alterar telas `*_mobile_screen.dart`, componentes mobile, `SixMobilePalette`, `SixMobilePageShell`, `NavBarMobile` ou tema global sem motivo tecnico claro.

## UI Mobile

Para telas `*_mobile_screen.dart`, AppBar, cards, FAB, bottom sheets, seletores, estados vazios, loading, Lottie, motion e acessibilidade mobile, siga `sixapp-mobile-ui`.

Direcao pratica:

- use `SixMobilePalette`, `SixMobilePageShell`, `NavBarMobile` e componentes em `lib/presentation/components/mobile/`;
- preserve uma experiencia mobile-first para uso rapido em atendimento, balcao e acompanhamento;
- nao copie navegacao, cabecalho, modal ou formulario Web;
- prefira bottom sheets customizados para seletores de cliente, produto, servico, tecnico, forma de pagamento, status, filtros e datas;
- evite `DropdownButtonFormField`, `DropdownMenu`, `showDatePicker` e dialogs genericos quando destoarem do padrao mobile;
- mantenha estrutura conhecida durante loading sempre que possivel, com skeleton nos dados dinamicos;
- use `SafeArea`, toque confortavel, contraste, `Semantics`, labels em icones e suporte a texto grande;
- use motion funcional curta e respeite `MediaQuery.disableAnimations` e `accessibleNavigation`.

Pedido somente Mobile nao deve alterar Web, `PaginaPrincipalWeb`, arquivos `*_web.dart`, tema global ou contratos de API sem necessidade comprovada.

## Regionalizacao e i18n

Use `sixapp-regionalization` sempre que houver texto visivel, status, mensagem, moeda, valor, data, hora, numero, percentual, medida, idioma, pais, timezone ou configuracao do comercio.

Classifique o conteudo antes de implementar:

- A: texto estatico da interface, como labels, botoes, placeholders, tooltips e validacoes.
- B: texto configuravel pelo comercio ou tenant.
- C: texto de dominio ou mensagem dinamica do backend, como status, motivos e codigos de erro.
- D: dado regionalizavel, como moeda, data, hora, numero, percentual, medida e timezone.

Regras:

- nao hardcode `R$`, `BRL`, `pt_BR`, `dd/MM/yyyy`, separador decimal, timezone ou labels traduzidos no payload;
- use `context.t('chave', fallback: 'Texto em pt-BR')` ou o mecanismo de i18n ja usado pela tela;
- use `LocaleSettingsProvider` via `context.watch`, `context.read` ou `context.select`;
- nao instancie `LocaleSettingsProvider()` manualmente;
- mantenha dinheiro, numeros e datas como valores estruturados e formate apenas na apresentacao;
- envie ao backend codigos tecnicos, nunca labels traduzidos;
- conteudo cadastrado pelo usuario ou texto livre retornado pelo backend deve ser exibido como veio.

## Permissoes, tenant e seguranca

Toda operacao deve respeitar a empresa atual (`idUnicoDaEmpresa`) e as permissoes disponiveis. O frontend pode esconder acoes para melhorar UX, mas o backend precisa autorizar.

Nao faca:

- regra sensivel apenas no widget;
- bypass de login ou permissao;
- log de token, senha, cookie, headers sensiveis ou body sensivel;
- endpoint, segredo ou credencial hardcoded;
- alteracao financeira, cancelamento, exclusao, permissao, estoque ou relatorio sensivel sem considerar perfil e tenant.

## Textos e UX

O usuario final e de comercio. Use linguagem objetiva e operacional.

Prefira termos claros:

- `Assistencia` ou `Ordem de servico`, nao `OT` quando o contexto for usuario final;
- `Atendimento`, nao `Operacao` quando o contexto for venda, orcamento ou assistencia.

Todas as telas relevantes devem tratar loading, vazio, erro, sucesso, bloqueio/sem permissao e sessao expirada quando aplicavel. Como o app e online-only, falha de conexao precisa ter mensagem clara.

## Validacao antes de finalizar

Sempre que editar Dart:

```bash
dart format <arquivos alterados>
git diff --check
git diff -- <arquivos alterados>
```

Execute `flutter analyze` para alteracoes relevantes. Execute testes somente quando forem pertinentes ao risco ou quando o usuario pedir; nao crie testes unitarios automaticamente para correcao pontual.

Antes da resposta final, confirme:

- arquivos alterados;
- skills usadas;
- caminho compartilhado de backend, quando houver;
- se Web e Mobile continuam com UI propria;
- se textos e dados regionalizaveis foram tratados;
- comandos executados e qualquer validacao nao executada.

Nao faca commit, branch, build completo, troca de dependencia ou mudanca em backend sem pedido explicito.
