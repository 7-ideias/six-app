import 'package:appplanilha/core/services/produto_service.dart';
import 'package:appplanilha/data/models/produto_model.dart';
import 'package:appplanilha/design_system/components/web/sub_painel_web_general.dart';
import 'package:flutter/material.dart';

class SubPainelCadastroProduto extends SubPainelWebGeneral {
  const SubPainelCadastroProduto({
    super.key,
    required super.body,
    required super.textoDaAppBar,
  });
}

void showSubPainelCadastroProduto(BuildContext context, String textoDaAppBar) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return SubPainelCadastroProduto(
        textoDaAppBar: textoDaAppBar,
        body: const CadastroProdutoWebBody(),
      );
    },
  );
}

class CadastroProdutoWebBody extends StatefulWidget {
  const CadastroProdutoWebBody({super.key});

  @override
  State<CadastroProdutoWebBody> createState() => _CadastroProdutoWebBodyState();
}

class _CadastroProdutoWebBodyState extends State<CadastroProdutoWebBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ProdutoService _produtoService = ProdutoService();

  final TextEditingController _codigoBarrasController = TextEditingController();
  final TextEditingController _nomeProdutoController = TextEditingController();
  final TextEditingController _grupoProdutoController = TextEditingController();
  final TextEditingController _tempoGarantiaController =
  TextEditingController(text: 'tempoDaGarantia');
  final TextEditingController _modeloProdutoController =
  TextEditingController(text: 'UNIDADE');
  final TextEditingController _estoqueMaximoController =
  TextEditingController(text: '1000');
  final TextEditingController _estoqueMinimoController =
  TextEditingController(text: '1');
  final TextEditingController _precoVendaController = TextEditingController();
  final TextEditingController _valorComissaoController =
  TextEditingController(text: '10');
  final TextEditingController _quantidadeEntradaController =
  TextEditingController(text: '10');
  final TextEditingController _valorCustoController =
  TextEditingController(text: '10');
  final TextEditingController _valorVendaEntradaController =
  TextEditingController(text: '50');

  bool _ativo = true;
  bool _podeAlterarValorNaHora = false;
  bool _produtoTemComissaoEspecial = false;
  bool _isLoading = false;
  String _tipoSelecionado = 'PRODUTO';

  @override
  void dispose() {
    _codigoBarrasController.dispose();
    _nomeProdutoController.dispose();
    _grupoProdutoController.dispose();
    _tempoGarantiaController.dispose();
    _modeloProdutoController.dispose();
    _estoqueMaximoController.dispose();
    _estoqueMinimoController.dispose();
    _precoVendaController.dispose();
    _valorComissaoController.dispose();
    _quantidadeEntradaController.dispose();
    _valorCustoController.dispose();
    _valorVendaEntradaController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    bool requiredField = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, hintText: hintText),
      validator: requiredField
          ? (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Campo obrigatório';
        }
        return null;
      }
          : null,
    );
  }

  double _toDouble(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '.').trim()) ?? 0.0;
  }

  int _toInt(TextEditingController controller) {
    return int.tryParse(controller.text.trim()) ?? 0;
  }

  ProdutoModel _montarProduto() {
    return ProdutoModel(
      ativo: _ativo,
      codigoDeBarras: _codigoBarrasController.text.trim(),
      nomeProduto: _nomeProdutoController.text.trim(),
      tipoProduto: _tipoSelecionado,
      objAgrupamento: ObjAgrupamento(
        grupoDoProduto: _grupoProdutoController.text.trim().isEmpty
            ? 'grupoDoProduto'
            : _grupoProdutoController.text.trim(),
      ),
      objetoServico: ObjetoServico(
        tempoDaGarantia: _tempoGarantiaController.text.trim().isEmpty
            ? 'tempoDaGarantia'
            : _tempoGarantiaController.text.trim(),
        podeAlterarOValorNaHora: _podeAlterarValorNaHora,
      ),
      modeloProduto: _modeloProdutoController.text.trim().isEmpty
          ? 'UNIDADE'
          : _modeloProdutoController.text.trim(),
      estoqueMaximo: _toInt(_estoqueMaximoController),
      estoqueMinimo: _toInt(_estoqueMinimoController),
      precoVenda: _toDouble(_precoVendaController),
      objComissao: ObjComissao(
        produtoTemComissaoEspecial: _produtoTemComissaoEspecial,
        valorFixoDeComissaoParaEsseProduto: _toDouble(_valorComissaoController),
      ),
      objEntradaSaidaProduto: <ObjEntradaSaidaProduto>[
        ObjEntradaSaidaProduto(
          quantidade: _toDouble(_quantidadeEntradaController),
          valorCusto: _toDouble(_valorCustoController),
          valorDaVenda: _toDouble(_valorVendaEntradaController),
        ),
      ],
    );
  }

  Future<void> _salvarProduto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final produto = _montarProduto();
      final String? idCriado = await _produtoService.cadastrarProduto(produto);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Sucesso'),
            content: Text(
              idCriado != null
                  ? 'Produto cadastrado com sucesso!\n\nID: $idCriado'
                  : 'Produto cadastrado com sucesso!',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Erro ao cadastrar'),
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSecaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool telaGrande = constraints.maxWidth > 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Form(
                key: _formKey,
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                    const Text(
                      'Cadastro de produto',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preencha os dados do produto e envie para o backend já disponível.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildSecaoTitulo('Dados principais'),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: <Widget>[
                        SizedBox(
                          width: telaGrande ? 250 : double.infinity,
                          child: _buildTextField(
                            controller: _codigoBarrasController,
                            label: 'Código de barras',
                            hintText: '1775423038',
                            requiredField: true,
                          ),
                        ),
                        SizedBox(
                          width: telaGrande ? 420 : double.infinity,
                          child: _buildTextField(
                            controller: _nomeProdutoController,
                            label: 'Nome do produto',
                            hintText: 'Bateria Turbo 78370',
                            requiredField: true,
                          ),
                        ),
                        SizedBox(
                          width: telaGrande ? 220 : double.infinity,
                          child: DropdownButtonFormField<String>(
                            value: _tipoSelecionado,
                            decoration: _inputDecoration('Tipo'),
                            items: const <DropdownMenuItem<String>>[
                              DropdownMenuItem(
                                value: 'PRODUTO',
                                child: Text('PRODUTO'),
                              ),
                              DropdownMenuItem(
                                value: 'SERVICO',
                                child: Text('SERVICO'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _tipoSelecionado = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: telaGrande ? 180 : double.infinity,
                          child: _buildTextField(
                            controller: _modeloProdutoController,
                            label: 'Modelo',
                            hintText: 'UNIDADE',
                            requiredField: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    _buildSecaoTitulo('Estoque e preço'),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: <Widget>[
                        SizedBox(
                          width: telaGrande ? 180 : double.infinity,
                          child: _buildTextField(
                            controller: _estoqueMaximoController,
                            label: 'Estoque máximo',
                            keyboardType: TextInputType.number,
                            requiredField: true,
                          ),
                        ),
                        SizedBox(
                          width: telaGrande ? 180 : double.infinity,
                          child: _buildTextField(
                            controller: _estoqueMinimoController,
                            label: 'Estoque mínimo',
                            keyboardType: TextInputType.number,
                            requiredField: true,
                          ),
                        ),
                        SizedBox(
                          width: telaGrande ? 180 : double.infinity,
                          child: _buildTextField(
                            controller: _precoVendaController,
                            label: 'Preço de venda',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            requiredField: true,
                          ),
                        ),
                        SizedBox(
                          width: telaGrande ? 220 : double.infinity,
                          child: _buildTextField(
                            controller: _grupoProdutoController,
                            label: 'Grupo do produto',
                            hintText: 'grupoDoProduto',
                            requiredField: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    _buildSecaoTitulo('Serviço / garantia'),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: <Widget>[
                        SizedBox(
                          width: telaGrande ? 260 : double.infinity,
                          child: _buildTextField(
                            controller: _tempoGarantiaController,
                            label: 'Tempo da garantia',
                            hintText: 'tempoDaGarantia',
                            requiredField: true,
                          ),
                        ),
                        SizedBox(
                          width: telaGrande ? 260 : double.infinity,
                          child: SwitchListTile(
                            value: _podeAlterarValorNaHora,
                            onChanged: (value) {
                              setState(() {
                                _podeAlterarValorNaHora = value;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            title: const Text('Pode alterar valor na hora'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: telaGrande ? 180 : double.infinity,
                          child: SwitchListTile(
                            value: _ativo,
                            onChanged: (value) {
                              setState(() {
                                _ativo = value;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            title: const Text('Ativo'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    _buildSecaoTitulo('Comissão'),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: <Widget>[
                        SizedBox(
                          width: telaGrande ? 280 : double.infinity,
                          child: SwitchListTile(
                            value: _produtoTemComissaoEspecial,
                            onChanged: (value) {
                              setState(() {
                                _produtoTemComissaoEspecial = value;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            title: const Text('Produto tem comissão especial'),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: telaGrande ? 220 : double.infinity,
                          child: _buildTextField(
                            controller: _valorComissaoController,
                            label: 'Valor fixo da comissão',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            requiredField: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    _buildSecaoTitulo('Entrada / saída do produto'),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: <Widget>[
                        SizedBox(
                          width: telaGrande ? 180 : double.infinity,
                          child: _buildTextField(
                            controller: _quantidadeEntradaController,
                            label: 'Quantidade',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            requiredField: true,
                          ),
                        ),
                        SizedBox(
                          width: telaGrande ? 180 : double.infinity,
                          child: _buildTextField(
                            controller: _valorCustoController,
                            label: 'Valor custo',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            requiredField: true,
                          ),
                        ),
                        SizedBox(
                          width: telaGrande ? 180 : double.infinity,
                          child: _buildTextField(
                            controller: _valorVendaEntradaController,
                            label: 'Valor da venda',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            requiredField: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: <Widget>[
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _salvarProduto,
                          icon: _isLoading
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(Icons.save),
                          label: Text(_isLoading ? 'Salvando...' : 'Salvar produto'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 16,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          child: const Text('Cancelar'),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}