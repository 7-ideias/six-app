import 'package:appplanilha/data/models/imagem_sugestao_model.dart';
import 'package:flutter/material.dart';

class ImagemSugestoesSection extends StatelessWidget {
  const ImagemSugestoesSection({
    super.key,
    required this.isLoading,
    required this.hasSearched,
    required this.canGenerate,
    required this.sugestoes,
    required this.onGerarSugestoes,
    required this.onSelecionarSugestao,
    this.errorMessage,
    this.usedSuggestionIds = const <int>{},
  });

  final bool isLoading;
  final bool hasSearched;
  final bool canGenerate;
  final List<ImagemSugestao> sugestoes;
  final VoidCallback onGerarSugestoes;
  final ValueChanged<ImagemSugestao> onSelecionarSugestao;
  final String? errorMessage;
  final Set<int> usedSuggestionIds;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Imagens sugeridas por IA',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.icon(
              onPressed: canGenerate && !isLoading ? onGerarSugestoes : null,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Gerar sugestões'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (!canGenerate)
          Text(
            'Preencha ao menos título e tipo para gerar sugestões.',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.62),
              fontSize: 12,
            ),
          ),
        if (isLoading) ...<Widget>[
          const SizedBox(height: 14),
          Row(
            children: const <Widget>[
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Buscando sugestões de imagem...'),
            ],
          ),
        ] else if ((errorMessage ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Container(
            key: const Key('sugestoes-error'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.error.withOpacity(0.3)),
            ),
            child: Text(errorMessage!),
          ),
        ] else if (hasSearched && sugestoes.isEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Container(
            key: const Key('sugestoes-empty'),
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Não encontramos sugestões para este item agora. Ajuste o título/categoria e tente novamente.',
            ),
          ),
        ] else if (sugestoes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sugestoes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (BuildContext context, int index) {
              final ImagemSugestao sugestao = sugestoes[index];
              final bool isSelected = usedSuggestionIds.contains(sugestao.id);

              return InkWell(
                key: Key('sugestao-card-${sugestao.id}'),
                onTap: () => onSelecionarSugestao(sugestao),
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(13),
                              ),
                              child: Image.network(
                                sugestao.urlMiniatura,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                  color: colorScheme.surfaceVariant,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Score: ${(sugestao.score * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sugestao.motivo,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface
                                        .withOpacity(0.72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Usada',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
