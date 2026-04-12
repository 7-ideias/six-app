import 'package:appplanilha/core/services/empresa_service.dart';
import 'package:appplanilha/data/models/empresa_model.dart';
import 'package:appplanilha/presentation/screens/assinatura_mobile_screen.dart';
import 'package:appplanilha/presentation/screens/seguimento_mobile_screen.dart';
import 'package:appplanilha/providers/empresa_provider.dart';
import 'package:flutter/material.dart';

class PerfilDoMeuNegocioMobileScreen extends StatefulWidget {
  const PerfilDoMeuNegocioMobileScreen({super.key});

  @override
  _PerfilDoMeuNegocioMobileScreenState createState() =>
      _PerfilDoMeuNegocioMobileScreenState();
}

class _PerfilDoMeuNegocioMobileScreenState
    extends State<PerfilDoMeuNegocioMobileScreen> {
  late TextEditingController _nomeEmpresaController;
  late TextEditingController _cnpjController;
  late TextEditingController _razaoSocialController;

  @override
  void initState() {
    super.initState();

    final empresaProvider = EmpresaProvider();
    final empresa = empresaProvider.empresa;


    _nomeEmpresaController =
        TextEditingController(text: empresa?.nomeEmpresa ?? '');
    _cnpjController =
        TextEditingController(text: empresa?.documentoNoBrasilCNPJ ?? '');
    _razaoSocialController =
        TextEditingController(text: empresa?.nomeFantasia ?? '');

    _carregarDadosDaEmpresa();
  }

  Future<void> _carregarDadosDaEmpresa() async {
    final empresaService = EmpresaService();

    try {
      await empresaService.buscarDadosDaEmpresa();
      if (mounted) {
        final empresa = EmpresaProvider().empresa;
        if (empresa != null) {
          setState(() {
            _nomeEmpresaController.text = empresa.nomeEmpresa;
            _cnpjController.text = empresa.documentoNoBrasilCNPJ;
            _razaoSocialController.text = empresa.nomeFantasia;
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar dados da empresa na inicialização: $e');
    }
  }

  @override
  void dispose() {
    _nomeEmpresaController.dispose();
    _cnpjController.dispose();
    _razaoSocialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do meu negócio'),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Escolha seu segmento',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: const Text('Segmento'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SeguimentoMobileScreen(),
                ),
              );
            },
          ),
          const Divider(),

          const Text(
            'Perfil do meu negócio',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.deepPurple),
              borderRadius: BorderRadius.circular(8),
              color: Colors.deepPurple.withOpacity(0.05),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.image, size: 40, color: Colors.deepPurple),
                  SizedBox(height: 8),
                  Text(
                    'Insira aqui o logotipo da sua empresa',
                    style: TextStyle(color: Colors.deepPurple),
                  ),
                  Text(
                    'Apenas pra usuários Pro e Top',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nomeEmpresaController,
            decoration: const InputDecoration(labelText: 'Nome da empresa'),
          ),
          TextField(
            controller: _cnpjController,
            decoration: const InputDecoration(labelText: 'CNPJ'),
          ),
          TextField(
            controller: _razaoSocialController,
            decoration: const InputDecoration(labelText: 'Razão social'),
          ),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Telefone e endereço'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Redes sociais'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const Divider(),

          const Text(
            'Detalhes do meu negócio',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Qual é o slogan da sua empresa?',
            ),
          ),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText:
                  'Qual é a história da sua empresa? O que a torna especial?',
            ),
          ),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Qual é a sua mensagem de agradecimento?',
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Minha assinatura nos documentos',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Container(
          //   height: 120,
          //   decoration: BoxDecoration(
          //     border: Border.all(color: Colors.deepPurple),
          //     borderRadius: BorderRadius.circular(8),
          //     color: Colors.deepPurple.withOpacity(0.05),
          //   ),
          //   child: Center(
          //     child: Column(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: const [
          //         Icon(Icons.draw_rounded, size: 40, color: Colors.deepPurple),
          //         SizedBox(height: 8),
          //         Text('Coloque sua assinatura aqui', style: TextStyle(color: Colors.deepPurple)),
          //         Text(
          //           'A assinatura que você salvar aqui será inserida nos documentos (ex.: orçamentos) que você gerar no app.',
          //           style: TextStyle(fontSize: 12, color: Colors.grey),
          //           textAlign: TextAlign.center,
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AssinaturaMobileScreen(),
                ),
              );
            },
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.deepPurple),
                borderRadius: BorderRadius.circular(8),
                color: Colors.deepPurple.withOpacity(0.05),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.draw_rounded,
                      size: 40,
                      color: Colors.deepPurple,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Coloque sua assinatura aqui',
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                    Text(
                      'A assinatura que você salvar aqui será inserida nos documentos (ex.: orçamentos) que você gerar no app.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final empresaService = EmpresaService();

              final novaEmpresa = EmpresaModel(
                nomeEmpresa: _nomeEmpresaController.text,
                nomeFantasia: _razaoSocialController.text,
                documentoNoBrasilCNPJ: _cnpjController.text,
              );

              try {
                await empresaService.atualizarDadosDaEmpresa(novaEmpresa);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Perfil atualizado com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao atualizar: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'salvar perfil do negócio',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
