import 'package:flutter/material.dart';

class MobileGeneralScreen extends StatefulWidget {
  final Widget body;
  final String textoDaAppBar;
  final void Function(String)? onOptionSelected;

  const MobileGeneralScreen({
    super.key,
    required this.body,
    required this.textoDaAppBar,
    this.onOptionSelected,
  });

  @override
  State<MobileGeneralScreen> createState() => _MobileGeneralScreenState();
}

class _MobileGeneralScreenState extends State<MobileGeneralScreen> {
  String selected = "PRODUTOS";

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.textoDaAppBar),
            backgroundColor: Colors.blue,
            leading: const BackButton(),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => selected = "PRODUTOS");
                            widget.onOptionSelected?.call("PRODUTOS");
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color:
                                  selected == "PRODUTOS"
                                      ? Colors.white
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                'PRODUTOS',
                                style: TextStyle(
                                  color:
                                      selected == "PRODUTOS"
                                          ? Colors.blue
                                          : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => selected = "SERVIÇOS");
                            widget.onOptionSelected?.call("SERVIÇOS");
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color:
                                  selected == "SERVIÇOS"
                                      ? Colors.white
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                'SERVIÇOS',
                                style: TextStyle(
                                  color:
                                      selected == "SERVIÇOS"
                                          ? Colors.blue
                                          : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: widget.body,
        ),
      ),
    );
  }
}
