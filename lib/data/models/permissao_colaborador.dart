import 'package:flutter/material.dart';

enum GrupoPermissao {
  atendimento('staff.groups.atendimento'),
  catalogo('staff.groups.catalogo'),
  fornecedores('staff.groups.fornecedores'),
  compras('staff.groups.compras'),
  financeiro('staff.groups.financeiro'),
  administracao('staff.groups.administracao');

  const GrupoPermissao(this.chave);
  final String chave;
}

enum PermissaoColaborador {
  vendas(
    GrupoPermissao.atendimento,
    'VENDAS_CRIAR',
    Icons.point_of_sale_outlined,
    'staff.permission.vendas',
    'staff.permission.vendas.description',
    'objVendasPode',
    'fazVenda',
  ),
  assistencia(
    GrupoPermissao.atendimento,
    'ASSISTENCIA_TECNICA_CRIAR',
    Icons.handyman_outlined,
    'staff.permission.assistencia',
    'staff.permission.assistencia.description',
    'objAssistenciaTecnicaPode',
    'lancaServico',
  ),
  clientes(
    GrupoPermissao.atendimento,
    'CLIENTES_EDITAR',
    Icons.people_alt_outlined,
    'staff.permission.clientes',
    'staff.permission.clientes.description',
    'objClientesPode',
    'podeEditarCliente',
  ),
  produtos(
    GrupoPermissao.catalogo,
    'PRODUTOS_CADASTRAR',
    Icons.inventory_2_outlined,
    'staff.permission.produtos',
    'staff.permission.produtos.description',
  ),
  servicos(
    GrupoPermissao.catalogo,
    'SERVICOS_CADASTRAR',
    Icons.design_services_outlined,
    'staff.permission.servicos',
    'staff.permission.servicos.description',
  ),
  fornecedoresRead(
    GrupoPermissao.fornecedores,
    'FORNECEDORES_CONSULTAR',
    Icons.local_shipping_outlined,
    'suppliers.permission.read',
    'suppliers.permission.readDescription',
  ),
  fornecedoresCreate(
    GrupoPermissao.fornecedores,
    'FORNECEDORES_CADASTRAR',
    Icons.add_business_outlined,
    'suppliers.permission.create',
    'suppliers.permission.createDescription',
  ),
  fornecedoresEdit(
    GrupoPermissao.fornecedores,
    'FORNECEDORES_EDITAR',
    Icons.edit_outlined,
    'suppliers.permission.edit',
    'suppliers.permission.editDescription',
  ),
  fornecedoresDisable(
    GrupoPermissao.fornecedores,
    'FORNECEDORES_INATIVAR',
    Icons.block_outlined,
    'suppliers.permission.disable',
    'suppliers.permission.disableDescription',
  ),
  comprasRead(
    GrupoPermissao.compras,
    'COMPRAS_CONSULTAR',
    Icons.shopping_cart_outlined,
    'purchases.permission.read',
    'purchases.permission.readDescription',
  ),
  comprasCreate(
    GrupoPermissao.compras,
    'COMPRAS_CRIAR',
    Icons.add_shopping_cart_outlined,
    'purchases.permission.create',
    'purchases.permission.createDescription',
  ),
  comprasEdit(
    GrupoPermissao.compras,
    'COMPRAS_EDITAR',
    Icons.edit_note_outlined,
    'purchases.permission.edit',
    'purchases.permission.editDescription',
  ),
  comprasConfirm(
    GrupoPermissao.compras,
    'COMPRAS_CONFIRMAR',
    Icons.check_circle_outline_rounded,
    'purchases.permission.confirm',
    'purchases.permission.confirmDescription',
  ),
  comprasCancel(
    GrupoPermissao.compras,
    'COMPRAS_CANCELAR',
    Icons.cancel_outlined,
    'purchases.permission.cancel',
    'purchases.permission.cancelDescription',
  ),
  comprasReceive(
    GrupoPermissao.compras,
    'COMPRAS_RECEBER',
    Icons.inventory_2_outlined,
    'purchases.permission.receive',
    'purchases.permission.receiveDescription',
  ),
  receber(
    GrupoPermissao.financeiro,
    'FINANCEIRO_ACESSAR',
    Icons.account_balance_wallet_outlined,
    'staff.permission.receber',
    'staff.permission.receber.description',
    'objLancamentosFinanceirosPode',
    'podeReceberNoCaixa',
  ),
  resumo(
    GrupoPermissao.financeiro,
    'VENDAS_CONSULTAR',
    Icons.insights_outlined,
    'staff.permission.resumo',
    'staff.permission.resumo.description',
    'objLancamentosFinanceirosPode',
    'podeVerQuantoVendeu',
  ),
  relatorios(
    GrupoPermissao.financeiro,
    'RELATORIOS_GERAR',
    Icons.analytics_outlined,
    'staff.permission.relatorios',
    'staff.permission.relatorios.description',
    'objRelatoriosPode',
    'geraRelatorioDeVendas',
  ),
  permissoes(
    GrupoPermissao.administracao,
    'PERMISSOES_GERENCIAR',
    Icons.verified_user_outlined,
    'staff.permission.permissoes',
    'staff.permission.permissoes.description',
  );

  const PermissaoColaborador(
    this.grupo,
    this.codigo,
    this.icone,
    this.titulo,
    this.descricao, [
    this.objeto,
    this.campo,
  ]);
  final GrupoPermissao grupo;
  final String codigo;
  final IconData icone;
  final String titulo;
  final String descricao;
  final String? objeto;
  final String? campo;

  static Set<PermissaoColaborador> iniciais() => {
    vendas,
    assistencia,
    clientes,
  };

  static Set<PermissaoColaborador> ler(Map<String, dynamic> autorizacoes) {
    final adicionais = autorizacoes['permissoesAdicionais'];
    return {
      for (final p in values)
        if ((p.objeto != null && autorizacoes[p.objeto]?[p.campo] == true) ||
            (p == produtos && autorizacoes['podeCadastrarProduto'] == true) ||
            (adicionais is List && adicionais.contains(p.codigo)))
          p,
    };
  }

  static void aplicar(
    Map<String, dynamic> autorizacoes,
    Set<PermissaoColaborador> marcadas,
  ) {
    for (final p in values.where((p) => p.objeto != null)) {
      final campos = Map<String, dynamic>.from(autorizacoes[p.objeto] ?? {});
      campos[p.campo!] = marcadas.contains(p);
      autorizacoes[p.objeto!] = campos;
    }
    autorizacoes['podeCadastrarProduto'] = marcadas.contains(produtos);
    autorizacoes['permissoesAdicionais'] = [
      for (final p in marcadas)
        if (p.objeto == null) p.codigo,
    ];
  }
}
