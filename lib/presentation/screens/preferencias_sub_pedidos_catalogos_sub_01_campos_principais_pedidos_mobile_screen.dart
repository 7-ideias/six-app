import 'package:flutter/material.dart';

class CamposPrincipaisPedidosScreen extends StatefulWidget {
  const CamposPrincipaisPedidosScreen({Key? key}) : super(key: key);

  @override
  State<CamposPrincipaisPedidosScreen> createState() =>
      _CamposPrincipaisPedidosScreenState();
}

class _CamposPrincipaisPedidosScreenState
    extends State<CamposPrincipaisPedidosScreen> {
  final Map<String, bool> campos = {
    'Cliente': true,
    'Referência': true,
    'Serviços': true,
    'Peças': true,
    'Desconto': true,
    'Taxa de entrega': true,
    'Frete': false,
    'Outras taxas': true,
    'Tributos': false, // Desabilitado visualmente
    'Condições de pagamento': true,
    'Meio de pagamento': true,
    'Garantia': true,
    'Cláusulas contratuais': true,
    'Informações adicionais': true,
    'Relatório': true,
    'Membros da equipe': true,
    'Fotos': true,
    'Arquivos': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Campos principais dos pedidos"),
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Você pode simplificar o app selecionando apenas os campos que você realmente vai usar.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          ...campos.entries.map((entry) {
            final isDisabled = entry.key == 'Tributos';
            return CheckboxListTile(
              value: entry.value,
              onChanged:
                  isDisabled
                      ? null
                      : (val) {
                        setState(() {
                          campos[entry.key] = val ?? false;
                        });
                      },
              title: Text(
                entry.key,
                style:
                    isDisabled
                        ? const TextStyle(color: Colors.grey)
                        : const TextStyle(),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: Colors.deepPurple,
            );
          }).toList(),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // TODO: salvar campos selecionados
            },
            child: const Text(
              "salvar campos",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
