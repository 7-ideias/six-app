import 'package:flutter/material.dart';

/// Átomo visual neutro. Não resolve regras de negócio nem estrutura de telas.
IconData perfilNegocioIcon(String codigo) => switch (codigo) {
  'MODA' || 'ROUPAS' || 'COSTURA_AJUSTES' => Icons.content_cut_rounded,
  'LIMPEZA' || 'PRODUTOS_LIMPEZA' || 'SERVICOS_LIMPEZA' =>
    Icons.cleaning_services_rounded,
  'ELETRONICOS' || 'CELULARES' || 'TV_AUDIO' || 'ELETRODOMESTICOS' =>
    Icons.devices_rounded,
  'INFORMATICA' || 'COMPUTADORES' || 'IMPRESSORAS' || 'REDES' =>
    Icons.computer_rounded,
  'AUTOMOTIVO' || 'CARROS' || 'MOTOS' || 'PECAS' =>
    Icons.directions_car_rounded,
  'CASA_CONSTRUCAO' || 'MATERIAIS' || 'MOVEIS' || 'MANUTENCAO_PREDIAL' =>
    Icons.home_repair_service_rounded,
  'BELEZA_ESTETICA' || 'SALAO' || 'ESTETICA' || 'COSMETICOS' =>
    Icons.auto_awesome_rounded,
  'ALIMENTACAO' => Icons.restaurant_rounded,
  'VENDAS' || 'VENDA_PRODUTOS' => Icons.shopping_bag_rounded,
  'SERVICOS' ||
  'REPAROS' ||
  'PRESTACAO_SERVICOS' ||
  'REPAROS_MANUTENCAO' ||
  'ORDEM_SERVICO' => Icons.build_rounded,
  'FINANCEIRO' => Icons.pie_chart_outline_rounded,
  'ESTOQUE' => Icons.inventory_2_outlined,
  'ORCAMENTOS' => Icons.request_quote_outlined,
  'AGENDAMENTO' => Icons.event_available_outlined,
  'COMUNICACAO' => Icons.chat_bubble_outline_rounded,
  'CLIENTES' => Icons.groups_2_outlined,
  _ => Icons.storefront_rounded,
};
