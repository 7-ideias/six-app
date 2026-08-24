import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/utils/produto_cadastro_form_utils.dart';

void main() {
  group('qualidade do cadastro de produto', () {
    test('cadastro resumido pode alcançar 100 por cento', () {
      final QualidadeCadastroProduto qualidade =
          ProdutoCadastroFormUtils.calcularQualidadeCadastro(
            tipoCadastro: 'RESUMIDO',
            entrada: const EntradaQualidadeCadastroProduto(
              nomeInformado: true,
              precoInformado: true,
              categoriaInformada: true,
              identificadorInformado: true,
              organizacaoInformada: true,
              estoqueConfigurado: true,
              possuiImagem: true,
              detalhesInformados: false,
              regrasOperacionaisConfiguradas: false,
              dadosFiscaisInformados: false,
            ),
          );

      expect(qualidade.percentual, 100);
      expect(qualidade.nivel, NivelQualidadeCadastroProduto.excelente);
      expect(qualidade.melhorias, isEmpty);
    });

    test('cadastro completo considera critérios adicionais', () {
      final QualidadeCadastroProduto qualidade =
          ProdutoCadastroFormUtils.calcularQualidadeCadastro(
            tipoCadastro: 'COMPLETO',
            entrada: const EntradaQualidadeCadastroProduto(
              nomeInformado: true,
              precoInformado: true,
              categoriaInformada: true,
              identificadorInformado: false,
              organizacaoInformada: false,
              estoqueConfigurado: true,
              possuiImagem: false,
              detalhesInformados: false,
              regrasOperacionaisConfiguradas: true,
              dadosFiscaisInformados: false,
            ),
          );

      expect(qualidade.percentual, 55);
      expect(qualidade.nivel, NivelQualidadeCadastroProduto.prontoParaVender);
      expect(
        qualidade.melhorias.any(
          (MelhoriaQualidadeCadastroProduto melhoria) =>
              melhoria.criterio ==
                  CriterioQualidadeCadastroProduto.identificador &&
              melhoria.pontos == 10,
        ),
        isTrue,
      );
    });

    test('níveis evoluem sem transformar campos opcionais em bloqueio', () {
      final QualidadeCadastroProduto qualidade =
          ProdutoCadastroFormUtils.calcularQualidadeCadastro(
            tipoCadastro: 'RESUMIDO',
            entrada: const EntradaQualidadeCadastroProduto(
              nomeInformado: true,
              precoInformado: false,
              categoriaInformada: false,
              identificadorInformado: false,
              organizacaoInformada: false,
              estoqueConfigurado: true,
              possuiImagem: false,
              detalhesInformados: false,
              regrasOperacionaisConfiguradas: false,
              dadosFiscaisInformados: false,
            ),
          );

      expect(qualidade.percentual, 35);
      expect(qualidade.nivel, NivelQualidadeCadastroProduto.essencial);
      expect(
        qualidade.melhorias.first.criterio,
        CriterioQualidadeCadastroProduto.preco,
      );
    });
  });
}
