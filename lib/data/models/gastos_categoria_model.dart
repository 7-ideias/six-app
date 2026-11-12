class GastoCategoriaItem {
 GastoCategoriaItem.fromJson(Map<String,dynamic> j):id=j['id'] as String,descricao=j['descricao'] as String,origem=j['origem'] as String,cartao=j['cartao'] as String?,faturaId=j['faturaId'] as String?,data=DateTime.parse(j['data'] as String),situacao=j['situacao'] as String,valor=(j['valor'] as num).toDouble(),numeroParcela=j['numeroParcela'] as int?,quantidadeParcelas=j['quantidadeParcelas'] as int?;
 final String id,descricao,origem,situacao;final String? cartao,faturaId;final DateTime data;final double valor;final int? numeroParcela,quantidadeParcelas;
}
class GastoCategoria {
 GastoCategoria.fromJson(Map<String,dynamic> j):categoria=j['categoria'] as String,realizado=(j['realizado'] as num).toDouble(),previsto=(j['previsto'] as num).toDouble(),itens=(j['itens'] as List).map((e)=>GastoCategoriaItem.fromJson(Map<String,dynamic>.from(e as Map))).toList();
 final String categoria;final double realizado,previsto;final List<GastoCategoriaItem> itens;
}
class GastosCategorias {
 GastosCategorias.fromJson(Map<String,dynamic> j):inicio=DateTime.parse(j['inicio'] as String),fim=DateTime.parse(j['fim'] as String),realizado=(j['realizado'] as num).toDouble(),previsto=(j['previsto'] as num).toDouble(),categorias=(j['categorias'] as List).map((e)=>GastoCategoria.fromJson(Map<String,dynamic>.from(e as Map))).toList();
 final DateTime inicio,fim;final double realizado,previsto;final List<GastoCategoria> categorias;
}
