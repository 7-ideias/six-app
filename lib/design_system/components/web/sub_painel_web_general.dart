import 'package:flutter/material.dart';

class SubPainelWebGeneral extends StatefulWidget {
  final Widget body;
  final String textoDaAppBar;

  const SubPainelWebGeneral(
      {super.key, required this.body, required this.textoDaAppBar});

  @override
  State<SubPainelWebGeneral> createState() => _SubPainelWebGeneralState();
}

class _SubPainelWebGeneralState extends State<SubPainelWebGeneral> {
  @override
  Widget build(BuildContext context) {
    final temaDaAplicacao = Theme.of(context);
    return Center(
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
              children: [
                Text(widget.textoDaAppBar),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            backgroundColor: temaDaAplicacao.appBarTheme.backgroundColor,
          ),
          body: widget.body
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
