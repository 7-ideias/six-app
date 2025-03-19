import 'package:flutter/material.dart';

class WidgetCatalog extends StatefulWidget {
  const WidgetCatalog({Key? key}) : super(key: key);

  @override
  _WidgetCatalogState createState() => _WidgetCatalogState();
}

class _WidgetCatalogState extends State<WidgetCatalog> {
  bool _switchValue = false;
  double _sliderValue = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Widgets'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Botão Elevado', style: Theme.of(context).textTheme.titleLarge),
          ElevatedButton(
              onPressed: () {},
              child: const Text('Clique-me')
          ),
          Divider(),
          Text('Switch', style: Theme.of(context).textTheme.titleLarge),
          Switch(
            value: _switchValue,
            onChanged: (bool value) {
              setState(() {
                _switchValue = value;
              });
            },
          ),
          Divider(),
          Text('Slider', style: Theme.of(context).textTheme.titleLarge),
          Slider(
            value: _sliderValue,
            min: 0,
            max: 100,
            divisions: 5,
            label: _sliderValue.round().toString(),
            onChanged: (double value) {
              setState(() {
                _sliderValue = value;
              });
            },
          ),
          Divider(),
          Text('Checkbox', style: Theme.of(context).textTheme.titleLarge),
          CheckboxListTile(
            title: const Text('Selecionar'),
            value: _switchValue,
            onChanged: (bool? value) {
              setState(() {
                _switchValue = value ?? false;
              });
            },
          ),
          // Adicione mais widgets conforme necessário
        ],
      ),
    );
  }
}
