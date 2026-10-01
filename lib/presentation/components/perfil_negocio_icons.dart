import 'package:flutter/cupertino.dart';

/// Átomo visual neutro. Não resolve regras de negócio nem estrutura de telas.
IconData perfilNegocioIcon(String codigo) => switch (codigo) {
  'MODA' || 'ROUPAS' || 'COSTURA_AJUSTES' => CupertinoIcons.scissors,
  'LIMPEZA' => CupertinoIcons.drop,
  'ELETRONICOS' || 'CELULARES' => CupertinoIcons.device_phone_portrait,
  'INFORMATICA' => CupertinoIcons.desktopcomputer,
  'AUTOMOTIVO' => CupertinoIcons.car_detailed,
  'CASA_CONSTRUCAO' => CupertinoIcons.house,
  'BELEZA_ESTETICA' => CupertinoIcons.sparkles,
  'ALIMENTACAO' => CupertinoIcons.cart,
  'VENDAS' || 'VENDA_PRODUTOS' => CupertinoIcons.bag,
  'SERVICOS' || 'REPAROS' || 'PRESTACAO_SERVICOS' || 'REPAROS_MANUTENCAO' || 'ORDEM_SERVICO' => CupertinoIcons.wrench,
  'FINANCEIRO' => CupertinoIcons.chart_pie,
  'ESTOQUE' => CupertinoIcons.cube_box,
  'ORCAMENTOS' => CupertinoIcons.doc_text,
  'AGENDAMENTO' => CupertinoIcons.calendar,
  'COMUNICACAO' => CupertinoIcons.chat_bubble_2,
  'CLIENTES' => CupertinoIcons.person_2,
  _ => CupertinoIcons.building_2_fill,
};
