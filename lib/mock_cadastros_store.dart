import 'package:flutter/material.dart';

class ClienteMock {
  const ClienteMock({
    required this.id,
    required this.idExterno,
    required this.dataCadastro,
    required this.nome,
    required this.nomeFantasia,
    required this.tipoPessoa,
    required this.telefone,
    required this.whatsapp,
    required this.email,
    required this.documento,
    required this.inscricaoEstadual,
    required this.dataNascimentoFundacao,
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.complemento,
    required this.bairro,
    required this.cidade,
    required this.uf,
    required this.pais,
    required this.limiteCredito,
    required this.prazoPagamentoDias,
    required this.descontoPadrao,
    required this.scoreCredito,
    required this.clienteAtivo,
    required this.autorizaContato,
    required this.aceitaWhatsapp,
    required this.aceitaEmail,
    required this.permiteCompraPrazo,
    required this.bloqueadoInadimplencia,
    required this.linkAutoCadastro,
    required this.observacoes,
  });

  final String id;
  final String idExterno;
  final String dataCadastro;
  final String nome;
  final String nomeFantasia;
  final String tipoPessoa;
  final String telefone;
  final String whatsapp;
  final String email;
  final String documento;
  final String inscricaoEstadual;
  final String dataNascimentoFundacao;
  final String cep;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final String pais;
  final double limiteCredito;
  final int prazoPagamentoDias;
  final double descontoPadrao;
  final int scoreCredito;
  final bool clienteAtivo;
  final bool autorizaContato;
  final bool aceitaWhatsapp;
  final bool aceitaEmail;
  final bool permiteCompraPrazo;
  final bool bloqueadoInadimplencia;
  final String linkAutoCadastro;
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
      idExterno: 'CLI-0001',
      dataCadastro: '2026-01-12T09:15:00',
      nome: 'Marina Oliveira',
      nomeFantasia: 'Marina',
      tipoPessoa: 'PF',
      telefone: '(47) 99999-0001',
      whatsapp: '(47) 99999-0001',
      email: 'marina.oliveira@email.com',
      documento: '123.456.789-00',
      inscricaoEstadual: '',
      dataNascimentoFundacao: '1992-04-18',
      cep: '89010-100',
      logradouro: 'Rua XV de Novembro',
      numero: '120',
      complemento: 'Apto 301',
      bairro: 'Centro',
      cidade: 'Blumenau',
      uf: 'SC',
      pais: 'BR',
      limiteCredito: 3500.00,
      prazoPagamentoDias: 30,
      descontoPadrao: 3.0,
      scoreCredito: 720,
      clienteAtivo: true,
      autorizaContato: true,
      aceitaWhatsapp: true,
      aceitaEmail: true,
      permiteCompraPrazo: true,
      bloqueadoInadimplencia: false,
      linkAutoCadastro:
          'https://sixapp.local/cliente/auto-cadastro?token=cli001',
      observacoes: 'Prefere receber atualizações por WhatsApp.',
    ),
    const ClienteMock(
      id: 'cli-002',
      idExterno: 'CLI-0002',
      dataCadastro: '2026-02-03T14:02:00',
      nome: 'Ricardo Gomes',
      nomeFantasia: 'RG Tech',
      tipoPessoa: 'PJ',
      telefone: '(47) 98888-2200',
      whatsapp: '(47) 98888-2200',
      email: 'ricardo.gomes@email.com',
      documento: '987.654.321-00',
      inscricaoEstadual: '254.772.180',
      dataNascimentoFundacao: '2018-08-23',
      cep: '89020-350',
      logradouro: 'Rua São Paulo',
      numero: '890',
      complemento: 'Sala 2',
      bairro: 'Victor Konder',
      cidade: 'Blumenau',
      uf: 'SC',
      pais: 'BR',
      limiteCredito: 12000.00,
      prazoPagamentoDias: 21,
      descontoPadrao: 5.0,
      scoreCredito: 780,
      clienteAtivo: true,
      autorizaContato: true,
      aceitaWhatsapp: true,
      aceitaEmail: true,
      permiteCompraPrazo: true,
      bloqueadoInadimplencia: false,
      linkAutoCadastro:
          'https://sixapp.local/cliente/auto-cadastro?token=cli002',
      observacoes: 'Cliente corporativo com alta recorrência.',
    ),
    const ClienteMock(
      id: 'cli-003',
      idExterno: 'CLI-0003',
      dataCadastro: '2026-02-19T11:34:00',
      nome: 'Aline Martins',
      nomeFantasia: 'Aline',
      tipoPessoa: 'PF',
      telefone: '(47) 99123-4567',
      whatsapp: '(47) 99123-4567',
      email: 'aline.martins@email.com',
      documento: '456.123.789-55',
      inscricaoEstadual: '',
      dataNascimentoFundacao: '1989-12-02',
      cep: '89035-550',
      logradouro: 'Rua Bahia',
      numero: '410',
      complemento: '',
      bairro: 'Salto',
      cidade: 'Blumenau',
      uf: 'SC',
      pais: 'BR',
      limiteCredito: 1800.00,
      prazoPagamentoDias: 15,
      descontoPadrao: 0.0,
      scoreCredito: 640,
      clienteAtivo: true,
      autorizaContato: true,
      aceitaWhatsapp: false,
      aceitaEmail: true,
      permiteCompraPrazo: true,
      bloqueadoInadimplencia: false,
      linkAutoCadastro:
          'https://sixapp.local/cliente/auto-cadastro?token=cli003',
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
    return _colaboradores
        .where((ColaboradorMock c) => c.ativo)
        .toList(growable: false);
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
          child:
              clientes.isEmpty
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
                            border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                cliente.nome,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${cliente.tipoPessoa} • ${cliente.documento}',
                              ),
                              const SizedBox(height: 4),
                              Text('${cliente.telefone} • ${cliente.email}'),
                              const SizedBox(height: 4),
                              Text(
                                'Limite: R\$ ${cliente.limiteCredito.toStringAsFixed(2).replaceAll('.', ',')}'
                                ' • Prazo: ${cliente.prazoPagamentoDias} dias',
                              ),
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
  final List<ColaboradorMock> colaboradores =
      apenasAtivos
          ? MockCadastrosStore.listarColaboradoresAtivos()
          : MockCadastrosStore.listarColaboradores();

  return showDialog<ColaboradorMock>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(titulo),
        content: SizedBox(
          width: 560,
          child:
              colaboradores.isEmpty
                  ? const Text('Nenhum colaborador cadastrado no mock local.')
                  : ListView.separated(
                    shrinkWrap: true,
                    itemCount: colaboradores.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, int index) {
                      final ColaboradorMock colaborador = colaboradores[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap:
                            () => Navigator.of(dialogContext).pop(colaborador),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      colaborador.nome,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          colaborador.ativo
                                              ? Colors.green.withOpacity(0.12)
                                              : Colors.red.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      colaborador.ativo ? 'Ativo' : 'Inativo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color:
                                            colaborador.ativo
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${colaborador.cargo} • ${colaborador.perfil}',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${colaborador.telefone} • ${colaborador.email}',
                              ),
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
