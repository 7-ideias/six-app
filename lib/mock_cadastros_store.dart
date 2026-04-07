import 'package:flutter/material.dart';

class ClienteMock {
  const ClienteMock({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.email,
    required this.documento,
    required this.observacoes,
  });

  final String id;
  final String nome;
  final String telefone;
  final String email;
  final String documento;
  final String observacoes;
}

class ColaboradorMock {
  const ColaboradorMock({
    required this.id,
    required this.nome,
    required this.telefone,
    required this.email,
    required this.documento,
    required this.cargo,
    required this.perfil,
    required this.ativo,
  });

  final String id;
  final String nome;
  final String telefone;
  final String email;
  final String documento;
  final String cargo;
  final String perfil;
  final bool ativo;
}

class MockCadastrosStore {
  MockCadastrosStore._();

  static final List<ClienteMock> _clientes = <ClienteMock>[
    const ClienteMock(
      id: 'cli-001',
      nome: 'Marina Oliveira',
      telefone: '(47) 99999-0001',
      email: 'marina.oliveira@email.com',
      documento: '123.456.789-00',
      observacoes: 'Prefere receber atualizações por WhatsApp.',
    ),
    const ClienteMock(
      id: 'cli-002',
      nome: 'Ricardo Gomes',
      telefone: '(47) 98888-2200',
      email: 'ricardo.gomes@email.com',
      documento: '987.654.321-00',
      observacoes: 'Cliente corporativo com alta recorrência.',
    ),
    const ClienteMock(
      id: 'cli-003',
      nome: 'Aline Martins',
      telefone: '(47) 99123-4567',
      email: 'aline.martins@email.com',
      documento: '456.123.789-55',
      observacoes: 'Autoriza orçamento e resumo por e-mail.',
    ),
  ];

  static final List<ColaboradorMock> _colaboradores = <ColaboradorMock>[
    const ColaboradorMock(
      id: 'col-001',
      nome: 'André Souza',
      telefone: '(47) 99911-2200',
      email: 'andre.souza@sixapp.local',
      documento: '111.222.333-44',
      cargo: 'Técnico líder',
      perfil: 'TÉCNICO',
      ativo: true,
    ),
    const ColaboradorMock(
      id: 'col-002',
      nome: 'Marcos Lima',
      telefone: '(47) 99811-0002',
      email: 'marcos.lima@sixapp.local',
      documento: '222.333.444-55',
      cargo: 'Técnico de bancada',
      perfil: 'TÉCNICO',
      ativo: true,
    ),
    const ColaboradorMock(
      id: 'col-003',
      nome: 'Juliana Rocha',
      telefone: '(47) 99771-1000',
      email: 'juliana.rocha@sixapp.local',
      documento: '333.444.555-66',
      cargo: 'Atendimento comercial',
      perfil: 'ATENDENTE',
      ativo: true,
    ),
  ];

  static List<ClienteMock> listarClientes() {
    return List<ClienteMock>.unmodifiable(_clientes);
  }

  static List<ColaboradorMock> listarColaboradores() {
    return List<ColaboradorMock>.unmodifiable(_colaboradores);
  }

  static List<ColaboradorMock> listarColaboradoresAtivos() {
    return _colaboradores.where((ColaboradorMock c) => c.ativo).toList(growable: false);
  }

  static void adicionarCliente(ClienteMock cliente) {
    _clientes.insert(0, cliente);
  }

  static void adicionarColaborador(ColaboradorMock colaborador) {
    _colaboradores.insert(0, colaborador);
  }

  static String proximoClienteId() {
    return 'cli-${(_clientes.length + 1).toString().padLeft(3, '0')}';
  }

  static String proximoColaboradorId() {
    return 'col-${(_colaboradores.length + 1).toString().padLeft(3, '0')}';
  }
}

Future<ClienteMock?> showSelecaoClienteDialog(BuildContext context) {
  final List<ClienteMock> clientes = MockCadastrosStore.listarClientes();

  return showDialog<ClienteMock>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Selecionar cliente'),
        content: SizedBox(
          width: 560,
          child: clientes.isEmpty
              ? const Text('Nenhum cliente cadastrado no mock local.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: clientes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, int index) {
                    final ClienteMock cliente = clientes[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(dialogContext).pop(cliente),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              cliente.nome,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text('${cliente.telefone} • ${cliente.email}'),
                            const SizedBox(height: 4),
                            Text(cliente.documento),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}

Future<ColaboradorMock?> showSelecaoColaboradorDialog(
  BuildContext context, {
  String titulo = 'Selecionar colaborador',
  bool apenasAtivos = true,
}) {
  final List<ColaboradorMock> colaboradores = apenasAtivos
      ? MockCadastrosStore.listarColaboradoresAtivos()
      : MockCadastrosStore.listarColaboradores();

  return showDialog<ColaboradorMock>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 560,
          child: colaboradores.isEmpty
              ? const Text('Nenhum colaborador cadastrado no mock local.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: colaboradores.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, int index) {
                    final ColaboradorMock colaborador = colaboradores[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(dialogContext).pop(colaborador),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Text(
                                    colaborador.nome,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colaborador.ativo
                                        ? Colors.green.withOpacity(0.12)
                                        : Colors.red.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    colaborador.ativo ? 'Ativo' : 'Inativo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: colaborador.ativo ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${colaborador.cargo} • ${colaborador.perfil}'),
                            const SizedBox(height: 4),
                            Text('${colaborador.telefone} • ${colaborador.email}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
    },
  );
}
