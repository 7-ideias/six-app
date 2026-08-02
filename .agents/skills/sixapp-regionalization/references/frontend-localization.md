# Frontend localization e regionalização

Esta referência descreve a infraestrutura atual do Flutter SixApp para idioma, traduções remotas, locale e formatação regional.

## Arquitetura atual

- `l10n.yaml` mantém suporte ARB com `lib/l10n/app_*.arb` e `AppLocalizations`.
- `lib/data/services/i18n/web_i18n_api_client.dart` expõe `SixI18nApiClient` e alias `WebI18nApiClient`.
- `SixI18nApiClient` busca `GET /public/api/i18n/{locale}` no backend, normaliza `pt-BR`, `en-US` e `es-ES`, usa ETag/`If-None-Match` e cache por locale em `SharedPreferences`.
- `lib/l10n/web_i18n_store.dart` expõe `SixI18nStore` e alias `WebI18nStore`, com mensagens ativas por idioma.
- `lib/l10n/six_i18n.dart` adiciona `context.t('chave', fallback: '...')` e fallback local para chaves comuns.
- `lib/presentation/components/web_root/web_i18n_gate.dart` inicializa pacote remoto antes de renderizar o app Web/root.
- `lib/providers/locale_settings_provider.dart` centraliza idioma, país, moeda, timezone, formatos e carregamento do pacote i18n.

## Provider global

`LocaleSettingsProvider` é a fonte principal de regionalização no Flutter.

Use:

- `context.watch<LocaleSettingsProvider>()` quando a UI inteira depender da configuração;
- `context.select<LocaleSettingsProvider, T>((p) => ...)` para reduzir rebuilds;
- `context.read<LocaleSettingsProvider>()` em handlers ou helpers chamados fora do `build`;
- `formatCurrency`, `formatDate`, `formatTime` e `formatDecimal` para apresentação.

Não use:

- `LocaleSettingsProvider()` instanciado manualmente em telas, services ou helpers;
- `NumberFormat.currency(locale: 'pt_BR', symbol: 'R$')` em UI;
- `DateFormat('dd/MM/yyyy', 'pt_BR')` ou separadores fixos em tela;
- string formatada como valor de domínio quando ainda haverá cálculo, animação ou envio ao backend.

## Contrato Flutter de regionalização

Arquivos atuais:

- `lib/data/services/regionalizacao/regionalizacao_api_client.dart`;
- `lib/data/models/regionalizacao_models.dart`;
- `lib/domain/models/regionalizacao_models.dart`;
- `lib/domain/services/regionalizacao/regionalizacao_service.dart`;
- `lib/mappers/configuracao_regionalizacao_mapper.dart`;
- `lib/providers/locale_settings_provider.dart`.

Endpoint consumido:

- `GET /private/api/caixa/configuracoes/regionalizacao`;
- `PUT /private/api/caixa/configuracoes/regionalizacao`.

Header de tenant:

- `idUnicoDaEmpresa`.

Payload técnico atual:

- `languageCode`;
- `countryCode`;
- `currencyCode`;
- `timeZone`;
- `dateFormat`;
- `timeFormat`;
- `decimalSeparator`;
- `thousandSeparator`;
- `firstDayOfWeek`;
- `numberPattern`;
- `decimalPlaces`;
- `allowMultipleCurrencies`;
- `applyFinancialRounding`.

`GET /private/api/caixa/informacoes-basicas` também pode trazer `regionalizacao` embutida em `InformacoesBasicasCaixaResponse`.

## Regras de uso

- Salve no backend apenas códigos técnicos, nunca labels traduzidos.
- Após salvar regionalização, atualize ou recarregue o provider global antes de depender da nova configuração em outra tela.
- Para moeda, preserve o valor bruto como `num`/`double` e formate apenas no render.
- Para animação numérica, use `TweenAnimationBuilder<double>` com chave estável baseada no indicador e no valor final.
- Para status/enum conhecido, mantenha o enum/código no contrato e resolva o label por i18n no frontend quando esse for o padrão do domínio.
- Para conteúdo cadastrado pelo usuário, exiba o texto retornado sem tradução automática.

## Pontos legados encontrados

- Algumas telas Web ainda usam strings fixas, `R$`, `pt_BR` e formatadores locais.
- `RegionalizacaoConfiguracaoContent` possui formatter local de preview semelhante ao provider; mantenha se for apenas preview local, mas centralize se o padrão se repetir.
- `ConfiguracoesSixWebPage` mistura labels e estados locais antigos com salvamento de regionalização; não trate como padrão novo sem validar.
- `lib/data/models/caixa_models.dart` possui dependência de presentation, já registrada como dívida arquitetural.
- Web e Mobile compartilham o provider/serviço de regionalização; novas implementações não devem criar infraestrutura paralela.
