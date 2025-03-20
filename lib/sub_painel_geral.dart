import 'package:flutter/material.dart';

class SubPainelGeral extends StatefulWidget {
  final Widget body;
  final String textoDaAppBar;

  const SubPainelGeral({super.key, required this.body, required this.textoDaAppBar});

  @override
  State<SubPainelGeral> createState() => _SubPainelGeralState();
}

class _SubPainelGeralState extends State<SubPainelGeral> {
  @override
  Widget build(BuildContext context) {
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
            backgroundColor: Colors.blue,
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
        child: SubPainelGeral(body: body, textoDaAppBar: textoDaAppBar),
      ),
    ),
  );
}
