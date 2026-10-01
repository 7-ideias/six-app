import '../../data/models/perfil_negocio_model.dart';
import '../models/atendimento_mobile_business_assets.dart';

enum AdminVisualAssetStatus { disponivel, planejado }

enum AdminVisualAssetSlot {
  vendas(AtendimentoMobileBusinessAsset.vendas),
  servicos(AtendimentoMobileBusinessAsset.servicos),
  receber(AtendimentoMobileBusinessAsset.receber),
  operacoesCaixa(AtendimentoMobileBusinessAsset.operacoesCaixa),
  devolucao(AtendimentoMobileBusinessAsset.devolucao);

  const AdminVisualAssetSlot(this.asset);
  final AtendimentoMobileBusinessAsset asset;
}

class AdminVisualBusinessContext {
  const AdminVisualBusinessContext({
    required this.segmento,
    this.subsegmento,
  });

  final String segmento;
  final String? subsegmento;

  String get id => '$segmento::${subsegmento ?? 'SEM_SUBSEGMENTO'}';
}

class AdminVisualAssetRecord {
  const AdminVisualAssetRecord({
    required this.contexto,
    required this.slot,
    required this.status,
    required this.profileFolder,
    required this.imageUrl,
    required this.fullCard,
  });

  final AdminVisualBusinessContext contexto;
  final AdminVisualAssetSlot slot;
  final AdminVisualAssetStatus status;
  final String? profileFolder;
  final String? imageUrl;
  final bool fullCard;
}

abstract final class AdminVisualAssetsCatalog {
  static const Map<String, List<String>> segmentos =
      <String, List<String>>{
        'ELETRONICOS': <String>[
          'CELULARES',
          'TV_AUDIO',
          'ELETRODOMESTICOS',
          'ACESSORIOS',
        ],
        'INFORMATICA': <String>[
          'COMPUTADORES',
          'IMPRESSORAS',
          'REDES',
        ],
        'MODA': <String>[
          'ROUPAS',
          'CALCADOS',
          'ACESSORIOS',
          'COSTURA_AJUSTES',
        ],
        'AUTOMOTIVO': <String>['CARROS', 'MOTOS', 'PECAS'],
        'CASA_CONSTRUCAO': <String>[
          'MATERIAIS',
          'MOVEIS',
          'MANUTENCAO_PREDIAL',
        ],
        'BELEZA_ESTETICA': <String>['SALAO', 'ESTETICA', 'COSMETICOS'],
        'LIMPEZA': <String>[
          'PRODUTOS_LIMPEZA',
          'SERVICOS_LIMPEZA',
        ],
        'ALIMENTACAO': <String>[],
        'SERVICOS_PROFISSIONAIS': <String>[],
        'OUTRO': <String>[],
      };

  static List<AdminVisualBusinessContext> get contextos {
    final List<AdminVisualBusinessContext> result =
        <AdminVisualBusinessContext>[];
    for (final MapEntry<String, List<String>> entry in segmentos.entries) {
      result.add(AdminVisualBusinessContext(segmento: entry.key));
      for (final String subsegmento in entry.value) {
        result.add(
          AdminVisualBusinessContext(
            segmento: entry.key,
            subsegmento: subsegmento,
          ),
        );
      }
    }
    return List<AdminVisualBusinessContext>.unmodifiable(result);
  }

  static List<AdminVisualAssetRecord> get records {
    final List<AdminVisualAssetRecord> result = <AdminVisualAssetRecord>[];

    for (final AdminVisualBusinessContext contexto in contextos) {
      final PerfilNegocioModel perfil = PerfilNegocioModel(
        segmentoPrincipal: contexto.segmento,
        subsegmento: contexto.subsegmento,
        atividades: const <String>{
          'VENDA_PRODUTOS',
          'PRESTACAO_SERVICOS',
        },
        objetivoPrincipal: 'GERAL',
      );
      final AtendimentoMobileBusinessAssets? assets =
          AtendimentoMobileBusinessAssets.fromPerfil(perfil);

      for (final AdminVisualAssetSlot slot in AdminVisualAssetSlot.values) {
        result.add(
          AdminVisualAssetRecord(
            contexto: contexto,
            slot: slot,
            status:
                assets == null
                    ? AdminVisualAssetStatus.planejado
                    : AdminVisualAssetStatus.disponivel,
            profileFolder: assets?.profileFolder,
            imageUrl: assets?.url(slot.asset),
            fullCard: assets?.usesFullCard ?? false,
          ),
        );
      }
    }

    return List<AdminVisualAssetRecord>.unmodifiable(result);
  }

  static List<String> subsegmentosDe(String? segmento) {
    if (segmento == null || segmento.isEmpty) return const <String>[];
    return List<String>.unmodifiable(
      segmentos[segmento] ?? const <String>[],
    );
  }
}
