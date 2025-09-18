import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/pkce_utils.dart';
import 'home_page_mobile_screen.dart';

class LoginOidcPage extends StatefulWidget {
  const LoginOidcPage({super.key});

  @override
  State<LoginOidcPage> createState() => _LoginOidcPageState();
}

class _LoginOidcPageState extends State<LoginOidcPage> {
  bool _loading = false;
  String? _error;
  String? _authToken;
  AppLinks? _appLinks;
  String? _codeVerifier;
  String? _pkceState;

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePageMobile(title: 'Home')),
    );
  }

  void _saveToken(String token) async {
    _authToken = token;
    // Exemplo: salvar com shared_preferences
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('auth_token', token);
    _navigateToHome();
  }

  Future<void> _startOidcFlow() async {
    setState(() { _loading = true; _error = null; });
    _codeVerifier = PkceUtils.generateRandomString(64);
    final codeChallenge = PkceUtils.codeChallengeFromVerifier(_codeVerifier!);
    final state = PkceUtils.generateState(32);
    _pkceState = state;
    final backendUrl = 'http://10.0.2.2:8082';
    final redirectUri = 'sixapp://oidc-callback';
    final uri = Uri.parse(
      '$backendUrl/auth/oidc-login?codeChallenge=$codeChallenge&state=$state&redirect_uri=$redirectUri'
    );
    print('DEBUG OIDC LOGIN URL: ' + uri.toString());
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    setState(() { _loading = false; });
  }

  void _initAppLinks() async {
    _appLinks = AppLinks();
    _appLinks!.uriLinkStream.listen((Uri? uri) async {
      print('DEBUG deep link recebido: ' + uri.toString());
      if (uri == null) return;
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      if (code != null && state != null && _codeVerifier != null) {
        print('DEBUG code: ' + code);
        print('DEBUG state: ' + state);
        print('DEBUG codeVerifier: ' + _codeVerifier!);
        final backendUrl = 'http://10.0.2.2:8082';
        final url = '$backendUrl/auth/oidc-callback?code=$code&state=$state&codeVerifier=${Uri.encodeComponent(_codeVerifier!)}';
        print('DEBUG OIDC CALLBACK URL: ' + url);
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final token = response.body;
          _saveToken(token);
        } else {
          setState(() { _error = 'Erro ao trocar código por token.'; });
        }
      } else {
        setState(() {
          _error = 'Erro ao receber código OIDC. code: '
              + (code ?? 'null') + ', state: ' + (state ?? 'null') + ', codeVerifier: ' + (_codeVerifier ?? 'null');
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 80),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _loading ? null : _startOidcFlow,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Entrar', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
