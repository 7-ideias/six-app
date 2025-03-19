import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class NewScreen extends StatefulWidget {
  const NewScreen({Key? key}) : super(key: key);

  @override
  _NewScreenState createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen> {
  String _statusCode = 'Aguardando resposta...';
  bool _isLoaded = false;
  Map<String, dynamic> _characterData = {};

  Future<void> fetchCharacter() async {
    var client = http.Client();

    try {
      // Desativação de SSL para ambiente de desenvolvimento
      HttpOverrides.global = MyHttpOverrides();

      final response = await client.get(Uri.parse('https://rickandmortyapi.com/api/character/74'));

      if (response.statusCode == 200) {
        setState(() {
          _isLoaded = true;
          _characterData = jsonDecode(response.body);
          _statusCode = 'Status Code: ${response.statusCode}';
        });
      } else {
        print('Falha ao carregar dados com status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao fazer a chamada HTTP: $e');
      setState(() {
        _statusCode = 'Erro ao fazer a chamada HTTP: $e';
      });
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rick and Morty Character'),
      ),
      body: Center(
        child: _isLoaded ? buildCharacterInfo() : buildLoadingScreen(),
      ),
    );
  }

  Widget buildCharacterInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        FadeInImage.assetNetwork(
          placeholder: 'assets/placeholder.png', // Adicione uma imagem de placeholder no diretório de assets
          image: _characterData['image'],
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 300),
        ),
        Text(
          _characterData['name'],
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text('Status: ${_characterData['status']}'),
        Text('Species: ${_characterData['species']}'),
        Text('Gender: ${_characterData['gender']}'),
        Text('Location: ${_characterData['location']['name']}'),
        ElevatedButton(
          onPressed: fetchCharacter,
          child: const Text('Refresh'),
        ),
      ],
    );
  }

  Widget buildLoadingScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text(
          _statusCode,
          style: TextStyle(fontSize: 20, color: Colors.red),
        ),
        ElevatedButton(
          onPressed: fetchCharacter,
          child: const Text('Carregar Personagem'),
        ),
      ],
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
