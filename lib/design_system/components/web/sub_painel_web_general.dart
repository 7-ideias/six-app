import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SubPainelWebGeneral extends StatefulWidget {
  final Widget body;
  final String textoDaAppBar;

  const SubPainelWebGeneral({
    super.key,
    required this.body,
    required this.textoDaAppBar,
  });

  @override
  State<SubPainelWebGeneral> createState() => _SubPainelWebGeneralState();
}

class _SubPainelWebGeneralState extends State<SubPainelWebGeneral> {
  void _fecharSubPainel() {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData temaDaAplicacao = Theme.of(context);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _fecharSubPainel,
      },
      child: Focus(
        autofocus: true,
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Scaffold(
              appBar: AppBar(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(widget.textoDaAppBar),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _fecharSubPainel,
                    ),
                  ],
                ),
                backgroundColor: temaDaAplicacao.appBarTheme.backgroundColor,
              ),
              body: widget.body,
            ),
          ),
        ),
      ),
    );
  }
}

void showSubPainel(BuildContext context, Widget body, String textoDaAppBar) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
        opacity: animation,
        child: SubPainelWebGeneral(body: body, textoDaAppBar: textoDaAppBar),
      ),
    ),
  );
}
