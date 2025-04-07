import 'package:appplanilha/core/enums/tipo_cadastro_enum.dart';
import 'package:flutter/material.dart';

class MobileGeneralScreen extends StatefulWidget {
  final Widget body;
  final String textoDaAppBar;
  final TipoCadastroEnum tipoCadastroEnum;
  final void Function(String)? onOptionSelected;

  const MobileGeneralScreen({
    super.key,
    required this.body,
    required this.textoDaAppBar,
    required this.tipoCadastroEnum,
    this.onOptionSelected,
  });

  @override
  State<MobileGeneralScreen> createState() => _MobileGeneralScreenState();
}

class _MobileGeneralScreenState extends State<MobileGeneralScreen> {
  TipoCadastroEnum selected = TipoCadastroEnum.PRODUTOS;
  bool _fabAberto = false;

  void _toggleFab() {
    setState(() => _fabAberto = !_fabAberto);
  }

  void _cadastrarProduto() {
    print('Cadastrar produto');
    setState(() => _fabAberto = false);
  }

  void _cadastrarServico() {
    print('Cadastrar serviço');
    setState(() => _fabAberto = false);
  }

  Widget buildFloatingActionButton_Produtos() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Positioned(
          bottom: 150,
          right: 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: _fabAberto ? Offset.zero : const Offset(0, 1),
            child: AnimatedOpacity(
              opacity: _fabAberto ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: FloatingActionButton.extended(
                heroTag: 'produto',
                onPressed: _cadastrarProduto,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Produto'),
                backgroundColor: Colors.blue,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 90,
          right: 0,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: _fabAberto ? Offset.zero : const Offset(0, 1),
            child: AnimatedOpacity(
              opacity: _fabAberto ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: FloatingActionButton.extended(
                heroTag: 'servico',
                onPressed: _cadastrarServico,
                icon: const Icon(Icons.build),
                label: const Text('Serviço'),
                backgroundColor: Colors.blue,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 0,
          child: FloatingActionButton(
            heroTag: 'main',
            onPressed: _toggleFab,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  RotationTransition(turns: anim, child: child),
              child: Icon(
                _fabAberto ? Icons.close : Icons.add,
                key: ValueKey(_fabAberto),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final temaDaAplicacao = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(widget.textoDaAppBar),
            backgroundColor: temaDaAplicacao.appBarTheme.backgroundColor,
            leading: const BackButton(),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() =>
                            selected = TipoCadastroEnum.PRODUTOS);
                            widget.onOptionSelected?.call(
                                TipoCadastroEnum.PRODUTOS.toString());
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected == TipoCadastroEnum.PRODUTOS
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                'PRODUTOS',
                                style: TextStyle(
                                  color: selected == TipoCadastroEnum.PRODUTOS
                                      ? Colors.blue
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() =>
                            selected = TipoCadastroEnum.SERVICOS);
                            widget.onOptionSelected?.call(
                                TipoCadastroEnum.SERVICOS.toString());
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected == TipoCadastroEnum.SERVICOS
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                'SERVIÇOS',
                                style: TextStyle(
                                  color: selected == TipoCadastroEnum.SERVICOS
                                      ? Colors.blue
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: widget.body,
          floatingActionButton: widget.tipoCadastroEnum ==
              TipoCadastroEnum.PRODUTOS_E_OU_SERVICOS
              ? buildFloatingActionButton_Produtos()
              : null,
        ),
      ],
    );
  }

}
