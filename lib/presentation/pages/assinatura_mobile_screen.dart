import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

class AssinaturaMobileScreen extends StatefulWidget {
  const AssinaturaMobileScreen({Key? key}) : super(key: key);

  @override
  State<AssinaturaMobileScreen> createState() => _AssinaturaMobileScreenState();
}

class _AssinaturaMobileScreenState extends State<AssinaturaMobileScreen> {
  late SignatureController _controller;
  final List<Color> _cores = [
    Colors.lightBlue,
    Colors.indigo[900]!,
    Colors.black,
  ];
  int _corSelecionadaIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 2,
      penColor: _cores[_corSelecionadaIndex],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _trocarCor(int index) {
    setState(() {
      _corSelecionadaIndex = index;
      _controller.clear();
      _controller.dispose();
      // Criar novo controller com a nova cor
      _controller = SignatureController(
        penStrokeWidth: 2,
        penColor: _cores[index],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assine com seu dedo no espaço abaixo'),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF8F8F8),
                ),
                child: Stack(
                  children: [
                    Signature(
                      controller: _controller,
                      backgroundColor: Colors.transparent,
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cor',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          ..._cores.asMap().entries.map((entry) {
                            final index = entry.key;
                            final cor = entry.value;
                            return GestureDetector(
                              onTap: () => _trocarCor(index),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: cor,
                                  shape: BoxShape.circle,
                                  border:
                                      _corSelecionadaIndex == index
                                          ? Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          )
                                          : null,
                                ),
                                child:
                                    _corSelecionadaIndex == index
                                        ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                        : null,
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _controller.clear(),
                    child: const Text('limpar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    onPressed: () async {
                      if (_controller.isNotEmpty) {
                        final signature = await _controller.toPngBytes();
                        // TODO: Salvar assinatura
                      }
                    },
                    child: const Text('salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
