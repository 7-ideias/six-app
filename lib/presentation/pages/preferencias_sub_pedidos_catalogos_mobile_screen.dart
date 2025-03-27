import 'package:appplanilha/presentation/pages/preferencias_sub_pedidos_catalogos_sub_01_campos_principais_pedidos_mobile_screen.dart';
import 'package:appplanilha/presentation/pages/preferencias_sub_pedidos_catalogos_sub_02_campos_especificos_segmento_mobile_screen.dart';
import 'package:appplanilha/presentation/pages/preferencias_sub_pedidos_catalogos_sub_03_situacao_do_pedido_mobile_screen.dart';
import 'package:appplanilha/presentation/pages/preferencias_sub_pedidos_catalogos_sub_04_catalogos_mobile_screen.dart';
import 'package:appplanilha/presentation/pages/preferencias_sub_pedidos_catalogos_sub_05_materiais_mobile_screen.dart';
import 'package:appplanilha/presentation/pages/preferencias_sub_pedidos_catalogos_sub_06_estoque_mobile_screen.dart';
import 'package:appplanilha/presentation/pages/preferencias_sub_pedidos_catalogos_sub_07_unidades_medida_mobile_screen.dart';
import 'package:flutter/material.dart';

class PersonalizarPedidosCatalogosScreen extends StatefulWidget {
  const PersonalizarPedidosCatalogosScreen({Key? key}) : super(key: key);

  @override
  State<PersonalizarPedidosCatalogosScreen> createState() =>
      _PersonalizarPedidosCatalogosScreenState();
}

class _PersonalizarPedidosCatalogosScreenState
    extends State<PersonalizarPedidosCatalogosScreen> {
  final List<_PersonalizacaoItem> _items = [
    _PersonalizacaoItem(
      title: 'Campos principais dos pedidos',
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CamposPrincipaisPedidosScreen(),
          ),
        );
      },
    ),
    _PersonalizacaoItem(
      title: 'Campos específicos pro seu segmento',
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CamposEspecificosSegmentoScreen(),
          ),
        );
      },
    ),
    _PersonalizacaoItem(
      title: 'Situação do pedido',
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const SituacaoDoPedidoMobileScreen(),
          ),
        );
      },
    ),
    _PersonalizacaoItem(
      title: 'Catálogos',
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CatalogosMobileScreen()),
        );
      },
    ),
    _PersonalizacaoItem(
      title: 'Materiais, produtos ou peças',
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MateriaisMobileScreen()),
        );
      },
    ),
    _PersonalizacaoItem(
      title: 'Estoque de Peças',
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EstoqueMobileScreen()),
        );
      },
    ),
    _PersonalizacaoItem(
      title: 'Unidades de medida',
      onTap: (context) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UnidadesMedidaMobileScreen()),
        );
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personalizar pedidos e catálogos"),
        leading: const BackButton(),
      ),
      body: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            title: Text(item.title),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => item.onTap(context),
          );
        },
      ),
    );
  }
}

class _PersonalizacaoItem {
  final String title;
  final void Function(BuildContext context) onTap;

  _PersonalizacaoItem({required this.title, required this.onTap});
}
