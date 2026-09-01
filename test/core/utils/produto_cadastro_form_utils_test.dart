import 'package:flutter_test/flutter_test.dart';
import 'package:sixpos/core/utils/produto_cadastro_form_utils.dart';

void main() {
  group('ProdutoCadastroFormUtils.tryParseDecimal', () {
    test('interpreta formato pt-BR com separador de milhar', () {
      const ProdutoCadastroNumberFormat format = ProdutoCadastroNumberFormat(
        decimalSeparator: ',',
        thousandSeparator: '.',
      );

      expect(
        ProdutoCadastroFormUtils.tryParseDecimal(
          '1.234,56',
          numberFormat: format,
        ),
        1234.56,
      );
    });

    test('interpreta formato en-US com separador de milhar', () {
      const ProdutoCadastroNumberFormat format = ProdutoCadastroNumberFormat(
        decimalSeparator: '.',
        thousandSeparator: ',',
      );

      expect(
        ProdutoCadastroFormUtils.tryParseDecimal(
          '1,234.56',
          numberFormat: format,
        ),
        1234.56,
      );
    });

    test('distingue valor invalido de zero', () {
      const ProdutoCadastroNumberFormat format = ProdutoCadastroNumberFormat(
        decimalSeparator: ',',
        thousandSeparator: '.',
      );

      expect(
        ProdutoCadastroFormUtils.tryParseDecimal(
          '---',
          numberFormat: format,
        ),
        isNull,
      );
      expect(
        ProdutoCadastroFormUtils.parseDecimal(
          '---',
          numberFormat: format,
        ),
        0,
      );
    });
  });
}
