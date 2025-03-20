import 'package:appplanilha/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SubPainelGeral extends StatelessWidget {
  final Widget body;

  const SubPainelGeral({Key? key, required this.body}) : super(key: key);

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
                Text('Painel Administrativo'),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
          ),
          body: Column(
            children: [
              body,
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: Text(AppLocalizations.of(context)!.preferences_dark_mode),
                trailing: Switch(
                  value: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showSubPainel(BuildContext context, Widget body) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      return SubPainelGeral(body: body);
    },
  );
}
