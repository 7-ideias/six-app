import 'package:flutter/material.dart';
import '../../core/services/usuario_service.dart';
import '../../providers/usuario_provider.dart';
import '../../data/models/usuario_model.dart';

class MeuPerfilMobileScreen extends StatefulWidget {
  const MeuPerfilMobileScreen({Key? key}) : super(key: key);

  @override
  State<MeuPerfilMobileScreen> createState() => _MeuPerfilMobileScreenState();
}

class _MeuPerfilMobileScreenState extends State<MeuPerfilMobileScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _sobrenomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _registroController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buscarDados();
    });
  }

  Future<void> _buscarDados() async {
    final provider = UsuarioProvider();
    provider.setLoading(true);
    try {
      await UsuarioService().buscarDadosDoUsuario();
      final usuario = provider.usuario;
      if (usuario != null) {
        _nomeController.text = usuario.nome;
        _sobrenomeController.text = usuario.sobrenome;
        _cpfController.text = usuario.cpf;
        _registroController.text = usuario.registroProfissional;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar dados: $e')),
        );
      }
    } finally {
      provider.setLoading(false);
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _sobrenomeController.dispose();
    _cpfController.dispose();
    _registroController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInput(String hint, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigableTile(
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap ?? () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuarioProvider = UsuarioProvider();
    return ListenableBuilder(
      listenable: usuarioProvider,
      builder: (context, child) {
        if (usuarioProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text("Meu perfil"), leading: BackButton()),
          body: ListView(
            children: [
              _buildSectionTitle("Dados pessoais"),
              _buildInput("Primeiro nome", _nomeController),
              _buildInput("Sobrenome", _sobrenomeController),
              _buildInput("CPF", _cpfController),
              _buildInput("Registro profissional", _registroController),
              const SizedBox(height: 8),
              const Divider(thickness: 1),
              _buildSectionTitle("E-mail e senha"),
              _buildNavigableTile(usuarioProvider.usuario?.email ?? ""),
              const Divider(thickness: 1),
              _buildSectionTitle("Plano"),
              _buildNavigableTile("Meu plano"),
              const SizedBox(height: 32),
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
                onPressed: () async {
                  final provider = UsuarioProvider();
                  final usuarioAtual = provider.usuario;

                  if (usuarioAtual == null) return;

                  final atualizadosDoUsuarioUnico = UsuarioModel(
                    nome: _nomeController.text,
                    sobrenome: _sobrenomeController.text,
                    cpf: _cpfController.text,
                    registroProfissional: _registroController.text,
                    email: usuarioAtual.email,
                    nomeDeGuerra: usuarioAtual.nomeDeGuerra,
                    celular: usuarioAtual.celular,
                    senha: usuarioAtual.senha,
                    salt: usuarioAtual.salt,
                    rg: usuarioAtual.rg,
                    dataNascimento: usuarioAtual.dataNascimento,
                    objEndereco: usuarioAtual.objEndereco,
                  );

                  provider.setLoading(true);
                  try {
                    await UsuarioService().atualizarDadosDoUsuario(atualizadosDoUsuarioUnico);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Perfil atualizado com sucesso!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao atualizar perfil: $e')),
                      );
                    }
                  } finally {
                    provider.setLoading(false);
                  }
                },
                child: const Text(
                  "salvar meu perfil",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
