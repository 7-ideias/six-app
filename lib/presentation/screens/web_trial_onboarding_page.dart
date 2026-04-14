import 'dart:convert';

import 'package:appplanilha/presentation/screens/web_marketing_localization.dart';
import 'package:appplanilha/providers/locale_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebTrialOnboardingPage extends StatefulWidget {
  const WebTrialOnboardingPage({super.key, this.initialUri});

  static const String routeName = '/onboarding';

  final Uri? initialUri;

  @override
  State<WebTrialOnboardingPage> createState() => _WebTrialOnboardingPageState();
}

class _WebTrialOnboardingPageState extends State<WebTrialOnboardingPage> {
  final TextEditingController _businessNameController = TextEditingController();
  bool _defaultSelectionsApplied = false;

  final Map<String, dynamic> _answers = {
    'businessModel': <String>{},
    'segments': <String>{},
    'channels': <String>{},
    'modules': <String>{},
    'aiFocus': <String>{},
    'teamSize': 3,
  };

  @override
  void initState() {
    super.initState();
    _prefillFromQuery();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_defaultSelectionsApplied) {
      return;
    }

    final copy = WebMarketingLocalizer.of(context);
    final business = copy.list('businessModels');
    final modules = copy.list('modules');

    final businessSet = _answers['businessModel'] as Set<String>;
    final modulesSet = _answers['modules'] as Set<String>;

    if (businessSet.isEmpty && business.isNotEmpty) {
      businessSet.add(business.first);
    }
    if (modulesSet.isEmpty && modules.isNotEmpty) {
      modulesSet.add(modules.first);
    }

    _defaultSelectionsApplied = true;
  }

  void _prefillFromQuery() {
    final company = widget.initialUri?.queryParameters['company'];
    if (company == null || company.trim().isEmpty) {
      return;
    }
    _businessNameController.text = company.trim();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = WebMarketingLocalizer.of(context);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/web/atendente_login_web.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.70),
                    const Color(0xFF09131A).withValues(alpha: 0.90),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _OnboardingTopBar(copy: copy),
                      const SizedBox(height: 20),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final compact = constraints.maxWidth < 980;
                          return Flex(
                            direction:
                                compact ? Axis.vertical : Axis.horizontal,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: compact ? 0 : 7,
                                child: _buildQuestionnaire(context, copy)
                                    .animate()
                                    .fadeIn(duration: 380.ms)
                                    .slideY(begin: 0.04, end: 0),
                              ),
                              if (!compact) const SizedBox(width: 16),
                              Expanded(
                                flex: compact ? 0 : 5,
                                child: _buildAiPreview(context, copy)
                                    .animate(delay: 120.ms)
                                    .fadeIn(duration: 380.ms)
                                    .slideY(begin: 0.06, end: 0),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaire(BuildContext context, WebMarketingLocalizer copy) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.t('onboarding.title'),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            copy.t('onboarding.subtitle'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 20),
          _buildMultiChoiceBlock(
            title: copy.t('onboarding.stepBusiness'),
            options: copy.list('businessModels'),
            keyName: 'businessModel',
            minSelection: 1,
            icon: Icons.storefront_rounded,
          ),
          _buildMultiChoiceBlock(
            title: copy.t('onboarding.stepSegments'),
            options: copy.list('segments'),
            keyName: 'segments',
            icon: Icons.category_rounded,
          ),
          _buildMultiChoiceBlock(
            title: copy.t('onboarding.stepChannels'),
            options: copy.list('channels'),
            keyName: 'channels',
            icon: Icons.language_rounded,
          ),
          _buildMultiChoiceBlock(
            title: copy.t('onboarding.stepModules'),
            options: copy.list('modules'),
            keyName: 'modules',
            minSelection: 1,
            icon: Icons.widgets_rounded,
          ),
          _buildMultiChoiceBlock(
            title: copy.t('onboarding.stepAi'),
            options: copy.list('aiFocus'),
            keyName: 'aiFocus',
            icon: Icons.auto_awesome_rounded,
          ),
          _buildTeamSlider(copy),
          const SizedBox(height: 14),
          TextField(
            controller: _businessNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: copy.t('onboarding.businessName'),
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.20),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.20),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF4CC9FF)),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _finishOnboarding,
              icon: const Icon(Icons.rocket_launch_rounded),
              label: Text(copy.t('onboarding.finish')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiChoiceBlock({
    required String title,
    required List<String> options,
    required String keyName,
    required IconData icon,
    int minSelection = 0,
  }) {
    final selected = _answers[keyName] as Set<String>;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF73D9FF)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                options.map((option) {
                  final isSelected = selected.contains(option);
                  return FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    selectedColor: const Color(
                      0xFF0B72FF,
                    ).withValues(alpha: 0.32),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color:
                          isSelected
                              ? const Color(0xFF4CC9FF)
                              : Colors.white.withValues(alpha: 0.16),
                    ),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          selected.add(option);
                        } else if (selected.length > minSelection) {
                          selected.remove(option);
                        }

                        if (selected.isEmpty &&
                            options.isNotEmpty &&
                            minSelection > 0) {
                          selected.add(options.first);
                        }
                      });
                    },
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSlider(WebMarketingLocalizer copy) {
    final teamSize = (_answers['teamSize'] as int).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            copy.t('onboarding.stepTeam'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF4CC9FF),
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.20),
                    thumbColor: const Color(0xFF4CC9FF),
                  ),
                  child: Slider(
                    value: teamSize,
                    min: 1,
                    max: 200,
                    divisions: 199,
                    label: '${teamSize.toInt()}',
                    onChanged: (value) {
                      setState(() {
                        _answers['teamSize'] = value.toInt();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_answers['teamSize']} ${copy.t('onboarding.teamLabel')}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiPreview(BuildContext context, WebMarketingLocalizer copy) {
    final theme = Theme.of(context);
    final recommendations = _buildRecommendations(copy);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B72FF).withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF8DE2FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  copy.t('onboarding.aiPreview'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            copy.t('onboarding.aiPreviewSubtitle'),
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          ...recommendations.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2636),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle,
                        color: Color(0xFF6CF0B6),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            WebMarketingLocalizer.demoYoutubeUrl,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/checkout'),
            icon: const Icon(Icons.shopping_cart_checkout_rounded),
            label: Text(copy.t('nav.buy')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _buildRecommendations(WebMarketingLocalizer copy) {
    final recommendations = <String>[...copy.list('aiRecommendationsBase')];

    final selectedModules = _answers['modules'] as Set<String>;
    final selectedChannels = _answers['channels'] as Set<String>;
    final selectedAiFocus = _answers['aiFocus'] as Set<String>;
    final normalizedChannels =
        selectedChannels.map((item) => item.toLowerCase()).toSet();

    if (selectedModules.isNotEmpty) {
      recommendations.add(
        _localizedMessage(
          copy.languageCode,
          pt:
              'Ativar ${selectedModules.take(3).join(', ')} com templates de processo e IA contextual.',
          en:
              'Enable ${selectedModules.take(3).join(', ')} with process templates and contextual AI.',
          es:
              'Activar ${selectedModules.take(3).join(', ')} con plantillas de proceso e IA contextual.',
        ),
      );
    }

    if (normalizedChannels.any(
      (channel) =>
          channel.contains('whatsapp') ||
          channel.contains('commerce') ||
          channel.contains('market'),
    )) {
      recommendations.add(
        _localizedMessage(
          copy.languageCode,
          pt:
              'Configurar funis omnichannel com resposta assistida por IA e recomendacao de produtos.',
          en:
              'Configure omnichannel funnels with AI-assisted responses and product recommendations.',
          es:
              'Configurar embudos omnicanal con respuestas asistidas por IA y recomendacion de productos.',
        ),
      );
    }

    if (selectedAiFocus.isNotEmpty) {
      recommendations.add(
        _localizedMessage(
          copy.languageCode,
          pt:
              'Priorizar ${selectedAiFocus.take(2).join(' + ')} nas primeiras automacoes.',
          en:
              'Prioritize ${selectedAiFocus.take(2).join(' + ')} in the first automations.',
          es:
              'Priorizar ${selectedAiFocus.take(2).join(' + ')} en las primeras automatizaciones.',
        ),
      );
    }

    final teamSize = _answers['teamSize'] as int;
    if (teamSize > 20) {
      recommendations.add(
        _localizedMessage(
          copy.languageCode,
          pt:
              'Habilitar trilhas por perfil de usuario e trilhas de aprovacao para manter governanca.',
          en:
              'Enable role-based tracks and approval flows to maintain governance.',
          es:
              'Habilitar rutas por perfil y flujos de aprobacion para mantener gobernanza.',
        ),
      );
    }

    return recommendations;
  }

  String _localizedMessage(
    String languageCode, {
    required String pt,
    required String en,
    required String es,
  }) {
    if (languageCode == 'pt') {
      return pt;
    }
    if (languageCode == 'es') {
      return es;
    }
    return en;
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    final payload = <String, dynamic>{
      'businessName': _businessNameController.text.trim(),
      'teamSize': _answers['teamSize'],
      'businessModel': (_answers['businessModel'] as Set<String>).toList(),
      'segments': (_answers['segments'] as Set<String>).toList(),
      'channels': (_answers['channels'] as Set<String>).toList(),
      'modules': (_answers['modules'] as Set<String>).toList(),
      'aiFocus': (_answers['aiFocus'] as Set<String>).toList(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString('web_trial_onboarding_profile', jsonEncode(payload));

    if (!mounted) {
      return;
    }

    final copy = WebMarketingLocalizer.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(copy.t('onboarding.saved'))));

    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) {
      return;
    }
    Navigator.pushReplacementNamed(context, '/login?source=trial');
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({required this.copy});

  final WebMarketingLocalizer copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Home'),
          ),
          Wrap(
            spacing: 10,
            children: [
              _LanguageDropdown(copy: copy),
              FilledButton.tonal(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: Text(copy.t('nav.login')),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/checkout'),
                icon: const Icon(Icons.shopping_cart_checkout_rounded),
                label: Text(copy.t('nav.buy')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({required this.copy});

  final WebMarketingLocalizer copy;

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleSettingsProvider>();
    final selected = localeProvider.currentLocale;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: _normalize(selected),
          dropdownColor: const Color(0xFF123047),
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
          onChanged: (locale) {
            if (locale == null) {
              return;
            }
            context.read<LocaleSettingsProvider>().setUserLocale(locale);
          },
          items: [
            DropdownMenuItem(
              value: const Locale('pt', 'BR'),
              child: Text(copy.t('language.pt')),
            ),
            DropdownMenuItem(
              value: const Locale('en', 'US'),
              child: Text(copy.t('language.en')),
            ),
            DropdownMenuItem(
              value: const Locale('es', 'ES'),
              child: Text(copy.t('language.es')),
            ),
          ],
        ),
      ),
    );
  }

  Locale _normalize(Locale locale) {
    if (locale.languageCode == 'pt') {
      return const Locale('pt', 'BR');
    }
    if (locale.languageCode == 'es') {
      return const Locale('es', 'ES');
    }
    return const Locale('en', 'US');
  }
}
