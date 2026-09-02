import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/services/auth_service.dart';
import '../core/services/websocket_service.dart';
import '../data/models/chat_suporte_models.dart';
import '../data/services/chat_suporte/chat_suporte_api_client.dart';

enum ChatSuporteFiltro { todas, aguardando, minhas, encerradas }

class ChatSuporteProvider extends ChangeNotifier {
  static const Duration _intervaloSincronizacaoDeSeguranca = Duration(
    seconds: 5,
  );

  ChatSuporteProvider({
    required this.ehSuper,
    this.idConversaInicial,
    this.idEmpresaInicial,
    ChatSuporteApiClient? apiClient,
    AuthService? authService,
  }) : _apiClient = apiClient ?? ChatSuporteApiClient(),
       _authService = authService ?? AuthService();

  final bool ehSuper;
  final String? idConversaInicial;
  final String? idEmpresaInicial;
  final ChatSuporteApiClient _apiClient;
  final AuthService _authService;

  final Map<String, Future<Uint8List>> _arquivos =
      <String, Future<Uint8List>>{};
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  Timer? _refreshDebounce;
  Timer? _syncFallbackTimer;

  List<ChatSuporteConversaModel> _conversas =
      const <ChatSuporteConversaModel>[];
  List<ChatSuporteMensagemModel> _mensagens =
      const <ChatSuporteMensagemModel>[];
  ChatSuporteConversaModel? _conversaSelecionada;
  ChatSuporteFiltro _filtro = ChatSuporteFiltro.todas;
  DateTime? _proximoAntesDe;
  bool _possuiMais = false;
  bool _carregando = true;
  bool _carregandoMensagens = false;
  bool _carregandoAnteriores = false;
  bool _enviando = false;
  bool _executandoAcao = false;
  bool _atualizando = false;
  bool _disposed = false;
  String? _erro;
  String? _idUsuarioAtual;

  List<ChatSuporteConversaModel> get conversas => _conversas;
  List<ChatSuporteMensagemModel> get mensagens => _mensagens;
  ChatSuporteConversaModel? get conversaSelecionada => _conversaSelecionada;
  ChatSuporteFiltro get filtro => _filtro;
  bool get possuiMais => _possuiMais;
  bool get carregando => _carregando;
  bool get carregandoMensagens => _carregandoMensagens;
  bool get carregandoAnteriores => _carregandoAnteriores;
  bool get enviando => _enviando;
  bool get executandoAcao => _executandoAcao;
  String? get erro => _erro;
  bool get conversaAtribuidaAMim {
    final ChatSuporteConversaModel? conversa = _conversaSelecionada;
    return conversa != null &&
        conversa.idSuperResponsavel != null &&
        conversa.idSuperResponsavel == _idUsuarioAtual;
  }

  Future<void> initialize() async {
    _eventSubscription ??= stompMessages.listen(_onRealtimeEvent);
    unawaited(_garantirConexaoTempoReal());
    _idUsuarioAtual = await _authService.getUserId();
    _carregando = true;
    _erro = null;
    notifyListeners();
    try {
      if (ehSuper) {
        await _carregarConversas();
        final String idInicial = idConversaInicial?.trim() ?? '';
        if (idInicial.isNotEmpty) {
          final ChatSuporteConversaModel conversa = await _apiClient
              .buscarConversa(idInicial);
          await selecionarConversa(conversa);
        }
      } else {
        final String idInicial = idConversaInicial?.trim() ?? '';
        final ChatSuporteConversaModel conversa = idInicial.isEmpty
            ? await _apiClient.buscarMinhaConversa()
            : await _apiClient.buscarConversa(
                idInicial,
                idUnicoDaEmpresa: idEmpresaInicial,
              );
        await selecionarConversa(conversa);
      }
    } on ChatSuporteApiException catch (exception) {
      _erro = exception.codigo;
    } catch (_) {
      _erro = 'CHAT_SUPORTE_ERRO_INESPERADO';
    } finally {
      _carregando = false;
      _iniciarSincronizacaoDeSeguranca();
      notifyListeners();
    }
  }

  Future<void> atualizar() async {
    if (_disposed ||
        _atualizando ||
        _carregando ||
        _carregandoAnteriores ||
        _enviando ||
        _executandoAcao) {
      return;
    }
    _atualizando = true;
    _erro = null;
    try {
      if (ehSuper) {
        await _carregarConversas();
      }
      final ChatSuporteConversaModel? selecionada = _conversaSelecionada;
      if (selecionada != null) {
        final ChatSuporteConversaModel conversa = await _apiClient
            .buscarConversa(
              selecionada.id,
              idUnicoDaEmpresa: selecionada.idUnicoDaEmpresa,
            );
        _substituirConversa(conversa);
        await _carregarMensagens(conversa, mesclar: true);
        if (_possuiMensagensNaoLidas(conversa)) {
          await _marcarComoLida(conversa);
        }
      }
    } on ChatSuporteApiException catch (exception) {
      _erro = exception.codigo;
    } catch (_) {
      _erro = 'CHAT_SUPORTE_ERRO_INESPERADO';
    } finally {
      _atualizando = false;
      notifyListeners();
    }
  }

  Future<void> selecionarConversa(ChatSuporteConversaModel conversa) async {
    _conversaSelecionada = conversa;
    _mensagens = const <ChatSuporteMensagemModel>[];
    _proximoAntesDe = null;
    _possuiMais = false;
    _erro = null;
    notifyListeners();
    await _carregarMensagens(conversa);
    await _marcarComoLida(conversa);
  }

  Future<void> limparSelecao() async {
    if (!ehSuper) return;
    _conversaSelecionada = null;
    _mensagens = const <ChatSuporteMensagemModel>[];
    _proximoAntesDe = null;
    _possuiMais = false;
    notifyListeners();
  }

  Future<void> alterarFiltro(ChatSuporteFiltro filtro) async {
    if (_filtro == filtro) return;
    _filtro = filtro;
    _carregando = true;
    notifyListeners();
    try {
      await _carregarConversas();
    } on ChatSuporteApiException catch (exception) {
      _erro = exception.codigo;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<bool> enviarMensagem({
    required String texto,
    List<ChatSuporteImagemUpload> imagens = const <ChatSuporteImagemUpload>[],
  }) async {
    final ChatSuporteConversaModel? conversa = _conversaSelecionada;
    if (conversa == null || _enviando) return false;
    _enviando = true;
    _erro = null;
    notifyListeners();
    try {
      final ChatSuporteEnvioMensagemModel response = await _apiClient
          .enviarMensagem(
            idConversa: conversa.id,
            idUnicoDaEmpresa: conversa.idUnicoDaEmpresa,
            texto: texto,
            imagens: imagens,
          );
      _substituirConversa(response.conversa);
      _mergeMensagens(<ChatSuporteMensagemModel>[response.mensagem]);
      return true;
    } on ChatSuporteApiException catch (exception) {
      _erro = exception.codigo;
      return false;
    } catch (_) {
      _erro = 'CHAT_SUPORTE_ERRO_INESPERADO';
      return false;
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }

  Future<void> carregarAnteriores() async {
    final ChatSuporteConversaModel? conversa = _conversaSelecionada;
    if (conversa == null || !_possuiMais || _carregandoAnteriores) return;
    _carregandoAnteriores = true;
    notifyListeners();
    try {
      final ChatSuporteMensagensPageModel page = await _apiClient
          .listarMensagens(
            idConversa: conversa.id,
            idUnicoDaEmpresa: conversa.idUnicoDaEmpresa,
            antesDe: _proximoAntesDe,
          );
      _proximoAntesDe = page.proximoAntesDe;
      _possuiMais = page.possuiMais;
      _mergeMensagens(page.mensagens);
    } on ChatSuporteApiException catch (exception) {
      _erro = exception.codigo;
    } finally {
      _carregandoAnteriores = false;
      notifyListeners();
    }
  }

  Future<bool> assumir() => _executarAcao(_apiClient.assumir);

  Future<bool> liberar() => _executarAcao(_apiClient.liberar);

  Future<bool> encerrar() => _executarAcao(_apiClient.encerrar);

  Future<Uint8List> carregarArquivo(ChatSuporteArquivoModel arquivo) {
    final ChatSuporteConversaModel? conversa = _conversaSelecionada;
    return _arquivos.putIfAbsent(
      arquivo.id,
      () => _apiClient.buscarArquivo(
        idArquivo: arquivo.id,
        idUnicoDaEmpresa: conversa?.idUnicoDaEmpresa,
      ),
    );
  }

  Future<bool> _executarAcao(
    Future<ChatSuporteConversaModel> Function(String idConversa) action,
  ) async {
    final ChatSuporteConversaModel? conversa = _conversaSelecionada;
    if (conversa == null || _executandoAcao) return false;
    _executandoAcao = true;
    _erro = null;
    notifyListeners();
    try {
      final ChatSuporteConversaModel atualizada = await action(conversa.id);
      _substituirConversa(atualizada);
      if (ehSuper) {
        try {
          await _carregarConversas();
        } catch (_) {
          // A ação já foi confirmada pelo backend; a fila será sincronizada
          // pelo próximo evento em tempo real ou pela atualização manual.
        }
      }
      return true;
    } on ChatSuporteApiException catch (exception) {
      _erro = exception.codigo;
      return false;
    } catch (_) {
      _erro = 'CHAT_SUPORTE_ERRO_INESPERADO';
      return false;
    } finally {
      _executandoAcao = false;
      notifyListeners();
    }
  }

  Future<void> _carregarConversas() async {
    final ChatSuporteStatus? status = switch (_filtro) {
      ChatSuporteFiltro.aguardando => ChatSuporteStatus.aguardandoSuporte,
      ChatSuporteFiltro.encerradas => ChatSuporteStatus.encerrada,
      _ => null,
    };
    _conversas = await _apiClient.listarConversas(
      status: status,
      somenteMinhas: _filtro == ChatSuporteFiltro.minhas,
    );
    final ChatSuporteConversaModel? selecionada = _conversaSelecionada;
    if (selecionada != null) {
      for (final ChatSuporteConversaModel conversa in _conversas) {
        if (conversa.id == selecionada.id) {
          _conversaSelecionada = conversa;
          break;
        }
      }
    }
  }

  Future<void> _carregarMensagens(
    ChatSuporteConversaModel conversa, {
    bool mesclar = false,
  }) async {
    _carregandoMensagens = true;
    notifyListeners();
    try {
      final ChatSuporteMensagensPageModel page = await _apiClient
          .listarMensagens(
            idConversa: conversa.id,
            idUnicoDaEmpresa: conversa.idUnicoDaEmpresa,
          );
      _proximoAntesDe = page.proximoAntesDe;
      _possuiMais = page.possuiMais;
      if (mesclar) {
        _mergeMensagens(page.mensagens);
      } else {
        _mensagens = page.mensagens;
      }
    } on ChatSuporteApiException catch (exception) {
      _erro = exception.codigo;
    } finally {
      _carregandoMensagens = false;
      notifyListeners();
    }
  }

  Future<void> _marcarComoLida(ChatSuporteConversaModel conversa) async {
    try {
      await _apiClient.marcarComoLida(
        idConversa: conversa.id,
        idUnicoDaEmpresa: conversa.idUnicoDaEmpresa,
      );
      final ChatSuporteConversaModel atualizada = await _apiClient
          .buscarConversa(
            conversa.id,
            idUnicoDaEmpresa: conversa.idUnicoDaEmpresa,
          );
      _substituirConversa(atualizada);
      notifyListeners();
    } catch (_) {
      return;
    }
  }

  void _mergeMensagens(List<ChatSuporteMensagemModel> novas) {
    final Map<String, ChatSuporteMensagemModel> porId =
        <String, ChatSuporteMensagemModel>{
          for (final ChatSuporteMensagemModel mensagem in _mensagens)
            mensagem.id: mensagem,
          for (final ChatSuporteMensagemModel mensagem in novas)
            mensagem.id: mensagem,
        };
    _mensagens = porId.values.toList(growable: false)
      ..sort(
        (ChatSuporteMensagemModel a, ChatSuporteMensagemModel b) =>
            a.criadaEm.compareTo(b.criadaEm),
      );
  }

  void _substituirConversa(ChatSuporteConversaModel conversa) {
    _conversaSelecionada = conversa;
    final List<ChatSuporteConversaModel> atualizadas =
        List<ChatSuporteConversaModel>.from(_conversas);
    final int index = atualizadas.indexWhere((item) => item.id == conversa.id);
    if (index >= 0) {
      atualizadas[index] = conversa;
    } else if (ehSuper) {
      atualizadas.insert(0, conversa);
    }
    _conversas = atualizadas;
  }

  bool _possuiMensagensNaoLidas(ChatSuporteConversaModel conversa) {
    return ehSuper
        ? conversa.naoLidasPeloSuporte > 0
        : conversa.naoLidasPeloSolicitante > 0;
  }

  Future<void> _garantirConexaoTempoReal() async {
    if (isStompConnected()) return;
    try {
      await reconnectStomp();
    } catch (_) {
      // A sincronizacao HTTP mantem o chat atualizado enquanto o STOMP
      // estiver temporariamente indisponivel.
    }
  }

  void _iniciarSincronizacaoDeSeguranca() {
    _syncFallbackTimer?.cancel();
    _syncFallbackTimer = Timer.periodic(
      _intervaloSincronizacaoDeSeguranca,
      (_) => unawaited(atualizar()),
    );
  }

  void _onRealtimeEvent(Map<String, dynamic> payload) {
    if (payload['destination']?.toString() != 'support.chat') return;
    final String idConversa = payload['conversationId']?.toString() ?? '';
    if (idConversa.isEmpty) return;
    final ChatSuporteConversaModel? selecionada = _conversaSelecionada;
    if (!ehSuper && selecionada != null && selecionada.id != idConversa) {
      return;
    }
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 220), () {
      unawaited(atualizar());
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshDebounce?.cancel();
    _syncFallbackTimer?.cancel();
    _eventSubscription?.cancel();
    _apiClient.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
