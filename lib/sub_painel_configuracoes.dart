import 'package:appplanilha/sub_painel_geral.dart';
import 'package:appplanilha/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SubPainelConfiguracoes extends SubPainelGeral {
  const SubPainelConfiguracoes({super.key, required super.body, required super.textoDaAppBar});
}

void showSubPainelConfiguracoes(BuildContext context, String textoDaAppBar) {
  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      var widget = Column(
        children: [
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: Text('preferences_dark_mode'),
            // title: Text(AppLocalizations.of(context)!.preferences_dark_mode),
            trailing: Switch(
              value: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark,
              onChanged: (value) {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value);
              },
            ),
          ),
        ],
      );
      return SubPainelConfiguracoes(body: widget, textoDaAppBar: textoDaAppBar,);
    },
  );
}