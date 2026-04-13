import 'package:flutter/material.dart';

class PlanosCarrosselScreen extends StatefulWidget {
  const PlanosCarrosselScreen({Key? key}) : super(key: key);

  @override
  State<PlanosCarrosselScreen> createState() => _PlanosCarrosselScreenState();
}

class _PlanosCarrosselScreenState extends State<PlanosCarrosselScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Widget> _planos = [
    PlanoWidget(
      plano: 'TOP',
      corIcone: Colors.deepPurple,
      corBotao: Colors.deepPurple,
      precoMensal: 'R\$ 49,90',
      precoAnual: 'R\$ 359,90',
      descricao: 'Nosso plano mais avançado!',
      features: [
        [
          'Funcionalidades exclusivas TOP',
          'Funcionalidades exclusivas para quem deseja ainda mais praticidade',
        ],
        [
          'Agenda Boa pra PC',
          'Use a Agenda Boa no celular e no computador, assim vc organiza seu negócio no dispositivo que preferir',
        ],
        [
          'Teste primeiro as novidades do app',
          'Receba antes de todo mundo atualizações importantes!',
        ],
        [
          'Suporte excelente',
          'Precisa de ajuda? É só nos enviar uma mensagem!',
        ],
      ],
    ),
    PlanoWidget(
      plano: 'POP',
      corIcone: Colors.cyan,
      corBotao: Colors.deepPurple,
      precoMensal: 'R\$ 12,90',
      precoAnual: 'R\$ 99,90',
      descricao: 'Nosso plano mais baratinho. Dica: confira nosso plano Pro!',
      features: [
        [
          'Funcionalidades exclusivas POP',
          'Funcionalidades exclusivas pra quem quer economizar e ganhar tempo',
        ],
        [
          'Agenda Boa pra PC',
          'Use a Agenda Boa no celular e no computador, assim vc organiza seu negócio no dispositivo que preferir',
        ],
        [
          'Suporte excelente',
          'Precisa de ajuda? É só nos enviar uma mensagem!',
        ],
      ],
    ),
    PlanoWidget(
      plano: 'PRO',
      corIcone: Colors.purple,
      corBotao: Colors.deepPurple,
      precoMensal: 'R\$ 24,90',
      precoAnual: 'R\$ 179,90',
      destaqueAnual: '40% de desconto!',
      descricao:
          'Coloque logo e assinatura nos seus documentos, impressione seus clientes e evolua seu negócio!',
      features: [
        [
          'Funcionalidades exclusivas PRO',
          'Funcionalidades exclusivas pro seu negócio continuar evoluindo!',
        ],
        [
          'Agenda Boa pra PC',
          'Use a Agenda Boa no celular e no computador, assim vc organiza seu negócio no dispositivo que preferir',
        ],
        [
          'Suporte excelente',
          'Precisa de ajuda? É só nos enviar uma mensagem!',
        ],
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nossos planos'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _planos.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) => _planos[index],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _planos.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.all(4),
                width: _currentIndex == index ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      _currentIndex == index ? Colors.deepPurple : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class PlanoWidget extends StatelessWidget {
  final String plano;
  final String descricao;
  final List<List<String>> features;
  final String precoMensal;
  final String precoAnual;
  final String? destaqueAnual;
  final Color corIcone;
  final Color corBotao;

  const PlanoWidget({
    super.key,
    required this.plano,
    required this.descricao,
    required this.features,
    required this.precoMensal,
    required this.precoAnual,
    this.destaqueAnual,
    required this.corIcone,
    required this.corBotao,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Text(
            'PLANO $plano',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Center(child: Text(descricao, textAlign: TextAlign.center)),
        const SizedBox(height: 24),
        ...features.map(
          (f) => Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(Icons.info_outline, color: corIcone),
              title: Text(
                f[0],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(f[1]),
              trailing: const Icon(Icons.info_outline),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Preços",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildPreco("Mensal", precoMensal, "por mês"),
        const SizedBox(height: 8),
        _buildPreco("Anual", precoAnual, "por ano", destaque: destaqueAnual),
        const SizedBox(height: 24),
        Text.rich(
          TextSpan(
            text: 'Seu teste grátis do plano $plano\n',
            style: const TextStyle(fontSize: 14),
            children: const [
              TextSpan(
                text: 'termina em 02/04/2025',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: corBotao,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {},
            child: Text(
              "Contratar plano $plano!",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            "detalhes dos testes grátis e assinaturas",
            style: TextStyle(color: Colors.deepPurple),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPreco(
    String tipo,
    String preco,
    String detalhe, {
    String? destaque,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(tipo, style: const TextStyle(fontSize: 16)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(preco, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(detalhe, style: const TextStyle(fontSize: 12)),
              if (destaque != null)
                Text(
                  destaque,
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
