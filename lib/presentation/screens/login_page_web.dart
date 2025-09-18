import 'web_helpers_stub.dart'
    if (dart.library.html) 'web_helpers_web.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'home_page_mobile_screen.dart';
import '../../core/utils/pkce_utils.dart';

class LoginPageWeb extends StatefulWidget {
  const LoginPageWeb({super.key});

  @override
  _LoginPageWebState createState() => _LoginPageWebState();
}

class _LoginPageWebState extends State<LoginPageWeb> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final WebHelpers webHelpers = WebHelpers();

  String? _oidcError;
  bool _loadingOidc = false;
  String? _pkceCodeVerifier;
  String? _pkceState;

  void _navigateToHome() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePageMobile(title: 'Flutter Demo Home Page')));
  }

  Future<void> _loginWithOidc() async {
    setState(() { _loadingOidc = true; _oidcError = null; });
    final codeVerifier = PkceUtils.generateRandomString(64);
    final codeChallenge = PkceUtils.codeChallengeFromVerifier(codeVerifier);
    final state = PkceUtils.generateState(32);
    _pkceCodeVerifier = codeVerifier;
    _pkceState = state;
    final redirectUri = webHelpers.getOrigin() + '/auth/oidc-callback';
    // Detecta ambiente e ajusta endereço do backend
    String backendHost = 'localhost:8082';
    // Se rodando em emulador Android, usar 10.0.2.2
    if (!kIsWeb && Theme.of(context).platform == TargetPlatform.android) {
      backendHost = '10.0.2.2:8082';

    }
    final uri = Uri.parse(
      'http://$backendHost/auth/oidc-login?codeChallenge=$codeChallenge&state=$state&redirect_uri=$redirectUri'
    );
    webHelpers.setLocalStorage('pkce_code_verifier', codeVerifier);
    webHelpers.setLocalStorage('pkce_state', state);
    webHelpers.redirectTo(uri.toString());
    setState(() { _loadingOidc = false; });
  }

  void _checkOidcCallback() async {
    final params = Uri.base.queryParameters;
    if (params.containsKey('token')) {
      final token = params['token']!;
      webHelpers.setLocalStorage('auth_token', token);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePageMobile(title: 'Flutter Demo Home Page')));
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkOidcCallback();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: kIsWeb ? MediaQuery.of(context).size.width * 0.25 : MediaQuery.of(context).size.width * 0.6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  controller: _loginController,
                  decoration: InputDecoration(
                    hintText: 'login',
                    // hintText: AppLocalizations.of(context)!.login.toUpperCase(),
                    labelText: 'login',
                    // labelText: AppLocalizations.of(context)!.login.toUpperCase(),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'login',
                    // hintText: AppLocalizations.of(context)!.senha.toUpperCase(),
                    labelText: 'login',
                    // labelText: AppLocalizations.of(context)!.senha.toUpperCase(),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _loadingOidc ? null : _loginWithOidc,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(50), // makes the button taller
                  ),
                  child: Text('entrar', style: TextStyle(fontSize: 18)),
                  // child: Text(AppLocalizations.of(context)!.entrar.toUpperCase(), style: TextStyle(fontSize: 18)),
                ),
                if (_oidcError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_oidcError!, style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
