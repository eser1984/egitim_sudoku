import 'package:flutter/material.dart';
import 'package:sudoku/dil.dart';

class GirisSayfasi extends StatefulWidget {
  @override
  _GirisSayfasiState createState() => _GirisSayfasiState();
}

class _GirisSayfasiState extends State<GirisSayfasi> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: dil['login_page'],
      ),
      body: Center(),
    );
  }
}
