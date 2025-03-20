import 'package:flutter/material.dart';

class SubPainelGeral extends StatelessWidget {
  final Widget body;
  final String textoDaAppBar;

  const SubPainelGeral({super.key, required this.body, required this.textoDaAppBar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(textoDaAppBar),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
          ),
          body: body
        ),
      ),
    );
  }
}

void showSubPainel(BuildContext context, Widget body, String textoDaAppBar) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      return SubPainelGeral(body: body, textoDaAppBar: textoDaAppBar,);
    },
  );
}
