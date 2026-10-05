import 'package:flutter/material.dart';
import '../../core/services/admin_visual_assets_service.dart';
import '../../data/models/web_hero_appearance.dart';
import '../components/web/six_web_hero_gradient.dart';
import '../theme/web_theme_tokens.dart';
import 'admin_visual_asset_settings_texts.dart';

class AdminWebHeroAppearanceCard extends StatefulWidget {
  const AdminWebHeroAppearanceCard({
    super.key,
    required this.service,
    this.imageUrl,
  });
  final AdminVisualAssetsService service;
  final String? imageUrl;
  @override
  State<AdminWebHeroAppearanceCard> createState() =>
      _AdminWebHeroAppearanceCardState();
}

class _AdminWebHeroAppearanceCardState
    extends State<AdminWebHeroAppearanceCard> {
  WebHeroAppearance _value = const WebHeroAppearance();
  bool _loading = true,
      _saving = false,
      _dirty = false,
      _error = false,
      _compact = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final value = await widget.service.appearance();
      if (mounted) {
        setState(() {
          _value = value;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = false;
    });
    try {
      final saved = await widget.service.saveAppearance(_value);
      if (!mounted) return;
      setState(() {
        _value = saved;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AdminVisualAssetSettingsTexts(context).saved)),
      );
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AdminVisualAssetSettingsTexts(context);
    final tokens = WebThemeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.cardBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(t.description),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: LinearProgressIndicator(),
            )
          else ...[
            if (_error)
              Row(
                children: [
                  Expanded(child: Text(t.error)),
                  TextButton(
                    onPressed: _saving ? null : (_dirty ? _save : _load),
                    child: Text(t.retry),
                  ),
                ],
              ),
            if (!_error || _dirty) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.compact),
                value: _compact,
                onChanged: (v) => setState(() => _compact = v),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width =
                      constraints.maxWidth < 900
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 2;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final dark in [false, true])
                        SizedBox(width: width, child: _themeEditor(dark, t)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: _saving || !_dirty ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? t.saving : t.save),
                  ),
                  TextButton(
                    onPressed:
                        _saving
                            ? null
                            : () => setState(() {
                              _value = const WebHeroAppearance();
                              _dirty = true;
                            }),
                    child: Text(t.reset),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _themeEditor(bool dark, AdminVisualAssetSettingsTexts t) {
    final fade = dark ? _value.dark : _value.light;
    final scheme = Theme.of(context).colorScheme;
    final tokens =
        dark ? WebThemeTokens.dark(scheme) : WebThemeTokens.light(scheme);
    void update(WebHeroFade next) => setState(() {
      _value = WebHeroAppearance(
        light: dark ? _value.light : next,
        dark: dark ? next : _value.dark,
      );
      _dirty = true;
    });
    Widget slider(String label, double value, ValueChanged<double> onChanged) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label · ${(value * 100).round()}%'),
            Slider(
              value: value,
              divisions: 100,
              label: '${(value * 100).round()}%',
              semanticFormatterCallback: (v) => '$label ${(v * 100).round()}%',
              onChanged: _saving ? null : onChanged,
            ),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dark ? t.dark : t.light,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: tokens.surfaceMuted),
                if (widget.imageUrl != null)
                  Image.network(
                    widget.imageUrl!,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: sixWebHeroGradient(
                      tokens.surface,
                      fade,
                      compact: _compact,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.preview,
                            style: TextStyle(
                              color: tokens.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t.previewText,
                            style: TextStyle(color: tokens.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        slider(
          t.intensity,
          fade.intensity,
          (v) => update(WebHeroFade(intensity: v, extent: fade.extent)),
        ),
        slider(
          t.extent,
          fade.extent,
          (v) => update(WebHeroFade(intensity: fade.intensity, extent: v)),
        ),
      ],
    );
  }
}
