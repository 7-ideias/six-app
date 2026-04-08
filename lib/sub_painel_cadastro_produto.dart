export 'sub_painel_cadastro_produto_mobile.dart'
if (dart.library.html) 'sub_painel_cadastro_produto_web.dart';


/*
explicacao desse arquivo:
Esse arquivo é um ponto de entrada para a implementação do sub painel de cadastro de produto.
Ele importa a versão específica para mobile ou web, dependendo do ambiente em que o aplicativo está sendo executado.
- Se o aplicativo estiver rodando em um ambiente que suporta a biblioteca 'dart:html' (como um navegador),
ele importará 'sub_painel_cadastro_produto_web.dart', que contém a implementação para a versão web do sub painel de cadastro de produto.
- Se o aplicativo estiver rodando em um ambiente que não suporta a biblioteca 'dart:html' (como um dispositivo móvel),
ele importará 'sub_painel_cadastro_produto_mobile.dart', que contém a implementação para a versão mobile do sub painel de cadastro de produto.
Essa abordagem permite que o código seja organizado de forma modular, separando as implementações específicas para cada plataforma,
enquanto mantém uma interface comum para o restante do aplicativo.

Assim, o código que utiliza o sub painel de cadastro de produto pode permanecer agnóstico em relação à plataforma,
sem precisar se preocupar com as diferenças de implementação entre mobile e web.

 */