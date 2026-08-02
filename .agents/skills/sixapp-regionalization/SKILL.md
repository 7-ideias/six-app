---
name: sixapp-regionalization
description: Use quando uma implementação SixApp envolver textos apresentados ao usuário, títulos, botões, validações, estados, tooltips, mensagens configuráveis por comércio/tenant, mensagens dinâmicas do backend, moedas, valores monetários, datas, horários, números, percentuais, medidas, idioma, país, locale, timezone ou o endpoint de configurações do backend. Aplica-se a Flutter Web, Flutter Mobile e backend Java/Spring Boot para manter frontend, contrato, persistência, internacionalização e regionalização alinhados.
---

# Regionalização do SixApp

Use esta Skill como análise transversal sempre que uma mudança Web, Mobile ou backend puder afetar texto, idioma, moeda, data, hora, número, percentual, medida, configuração de comércio ou contrato de mensagens.

Combine com `sixapp-web-ui` para telas Web, `sixapp-mobile-ui` para telas Mobile e `sixapp-shared-backend-integration` para comunicação compartilhada. Ao editar o backend `sixBack`, siga também as instruções locais desse repositório.

## Leituras Mínimas

Leia:

- `AGENTS.md` do frontend e, quando backend estiver envolvido, `../sixBack/AGENTS.md`;
- `.junie/AGENTS.md` existente no frontend ou backend aplicável;
- a tela, componente, provider, service, DTO/modelo e client afetados;
- `references/frontend-localization.md`;
- `references/backend-configuration-contract.md`.

Quando a mudança envolver recurso compartilhado entre Web e Mobile, confirme se ambos usam a mesma infraestrutura de client, DTO/modelo, mapper, service e interpretação de resposta.

## Fluxo Obrigatório

1. Leia o arquivo citado pelo usuário.
2. Identifique se a mudança é Web, Mobile, backend ou compartilhada.
3. Localize componentes, controllers/providers, services, clients, DTOs/modelos e persistência relacionados.
4. Inspecione implementações semelhantes antes de escolher o padrão.
5. Mapeie todos os textos e dados regionalizáveis afetados.
6. Verifique endpoint, contrato e payload do backend quando houver dado fornecido, persistido ou configurável.
7. Classifique cada conteúdo nas categorias A, B, C ou D.
8. Defina impacto em frontend, contrato, backend, persistência, i18n, regionalização e testes.
9. Apresente plano curto antes de implementar quando mais de uma camada for impactada.
10. Implemente dentro do escopo, preservando compatibilidade e códigos técnicos.
11. Valide formatação, análise estática, testes aplicáveis e diff.
12. Informe o que mudou em cada camada e registre duplicidades ou resíduos encontrados.

## Classificação Obrigatória

### A. Texto Estático Da Interface

Use para labels fixos como "Salvar", "Cancelar", títulos de tela, mensagens fixas de validação, placeholders e tooltips.

Coloque no mecanismo de internacionalização adotado pelo projeto. No SixApp atual, investigue primeiro `context.t`, `SixI18nStore` e os pacotes JSON do backend; use ARB/AppLocalizations apenas quando a tela já seguir esse padrão ou a arquitetura exigir. Não deixe texto literal novo espalhado em widgets.

### B. Texto Configurável Pelo Comércio/Tenant

Use para mensagens personalizadas, instruções operacionais, textos comerciais, termos alteráveis por administrador e conteúdo específico do estabelecimento.

Use endpoint/payload de configurações existente ou evolua o backend com compatibilidade. Não mova texto puramente estático do app para o backend sem avaliar responsabilidade. Não traduza conteúdo cadastrado pelo usuário.

### C. Texto De Domínio Ou Mensagem Dinâmica Do Backend

Use para status, motivos, códigos de erro, mensagens baseadas em regra de negócio e conteúdo composto com dados da operação.

Investigue o padrão atual antes de decidir entre backend devolver código/chave, texto localizado ou dados estruturados para composição no frontend. Preserve o padrão predominante. Quando houver inconsistência, registre o problema e prefira menor acoplamento, mantendo códigos técnicos no contrato.

### D. Dados Regionalizáveis

Use para moeda, valor monetário, data, hora, número decimal, percentual, medida, timezone, idioma e país.

Mantenha valores de domínio estruturados. Não trafegue dinheiro, datas ou números apenas como strings formatadas, salvo contrato legado justificado. Aplique formatação na camada de apresentação com locale, `currencyCode`, timezone, configurações do comércio e preferências do usuário quando existirem.

Nunca assuma `BRL`, `R$`, português, vírgula decimal, `dd/MM/yyyy` ou `America/Sao_Paulo` como padrão universal.

## Frontend Flutter

Consuma `LocaleSettingsProvider` via `context.watch`, `context.read` ou `context.select`. Não instancie `LocaleSettingsProvider()` manualmente.

Para valores monetários animados, mantenha `num`/`double` durante a animação e chame `formatCurrency(animatedValue)` somente ao renderizar. Para datas, horas, números e percentuais, use helper centralizado ou provider global.

Não misture valor numérico bruto e string formatada no mesmo campo de mapa/lista usado por cards. Se o backend retornar código ou enum conhecido, traduza label na camada de apresentação sem alterar o valor enviado de volta.

## Backend E Contrato

Antes de criar campo, endpoint ou payload novo, localize controller, request, response, service, document/entity, repository, cache/fallback e validação de tenant existentes.

Preserve códigos técnicos em requests e responses (`BRL`, `USD`, `MONDAY`, `pt`, `BR`, status/enums). Não envie labels traduzidos ao backend. Ao salvar configuração regional, atualize ou recarregue o provider global antes de depender da nova configuração em outra tela.

Se Web e Mobile consomem o mesmo recurso, reutilize a mesma infraestrutura de comunicação. Se houver duplicidade existente, não faça grande refatoração silenciosa; documente e proponha evolução incremental.

## Validação

Antes de finalizar:

- confirme que textos novos foram classificados em A/B/C/D;
- confirme que valores regionalizáveis não usam formatação hardcoded;
- confira se o contrato backend mantém compatibilidade;
- valide se Web e Mobile continuam semanticamente alinhados;
- execute `dart format` para arquivos Flutter alterados, validação Java/Gradle quando backend for alterado, `git diff --check` e testes/análise aplicáveis;
- relate limitações, duplicidades e decisões arquiteturais pendentes.
