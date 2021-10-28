import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:sudoku/dil.dart';
import 'package:sudoku/sudokular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wakelock/wakelock.dart';

final Map<String, int> sudokuSeviyeleri = {
  dil["seviye1"]: 62,
  dil["seviye2"]: 53,
  dil["seviye3"]: 44,
  dil["seviye4"]: 35,
  dil["seviye5"]: 26,
  dil["seviye6"]: 17
};

class SudokuSayfasi extends StatefulWidget {
  @override
  _SudokuSayfasiState createState() => _SudokuSayfasiState();
}

class _SudokuSayfasiState extends State<SudokuSayfasi> {
  // final List<List<int>> ornekSudoku = [
  //   [1, 2, 3, 4, 5, 6, 7, 8, 9],
  //   [1, 2, 3, 4, 5, 6, 7, 8, 9],
  //   [1, 2, 3, 4, 5, 6, 7, 8, 9],
  //   [1, 2, 3, 4, 5, 6, 7, 8, 9],
  //   [1, 2, 3, 4, 5, 6, 7, 8, 9],
  //   [1, 2, 3, 4, 5, 6, 7, 8, 9],
  //   [1, 2, 3, 4, 5, 6, 7, 8, 9],
  //   [1, 2, 3, 4, 5, 6, 7, 8, 9],
  //   [1, 2, 3, 4, 5, 6, 7, 8, 9],
  // ];

  final List orneksudoku2 = List.generate(
      9, (i) => List.generate(9, (j) => j + 1)); // yukarıdaki ornegi kısa hali

  final Box _sudokuKutu = Hive.box("sudoku");
  late Timer _sayac;

  List _sudoku = [], _sudokuGecmis = [];
  late String _sudokuString;

  bool _note = false;

  void _sudokuOlustur() {
    int gorulecekSayi = sudokuSeviyeleri[
            _sudokuKutu.get('seviye', defaultValue: dil['seviye2'])]!
        .toInt();

    _sudokuString = sudokular[(Random().nextInt(sudokular.length))];
    _sudokuKutu.put('sudokuString', _sudokuString);

    _sudoku = List.generate(
        9,
        (i) => List.generate(
            9,
            (j) =>
                "e" +
                _sudokuString.substring(i * 9, (i + 1) * 9).split('')[j]));
    int i = 0;
    while (i < 81 - gorulecekSayi) {
      int x = Random().nextInt(9);
      int y = Random().nextInt(9);
      if (_sudoku[x][y] != "0") {
        _sudoku[x][y] = "0";
        i++;
      }
    }
    _sudokuKutu.put('sudokuSatirlari', _sudoku);
    _sudokuKutu.put('xy', "99");
    _sudokuKutu.put('ipucu', 3);
    _sudokuKutu.put('sure', 0);
  }

  void _adimKaydet() {
    String sudokuSonDurum = _sudokuKutu.get('sudokuSatirlari').toString();
    if (sudokuSonDurum.contains("0")) {
      Map gecmisParca = {
        'sudokuSatirlari': _sudokuKutu.get('sudokuSatirlari'),
        'xy': _sudokuKutu.get('xy'),
        'ipucu': _sudokuKutu.get('ipucu'),
      };

      _sudokuGecmis.add(jsonEncode(gecmisParca)); //string e çeviriyor
      _sudokuKutu.put('sudokuGecmis', _sudokuGecmis);
    } else {
      _sudokuString = _sudokuKutu.get('sudokuSitring');
      String kontrol = sudokuSonDurum.replaceAll(RegExp(r'[e, \][]'), '');
      String mesaj =
          "Sudokunuzda Hatalar Var, Dikkatli Bir Şekilde Tekrar İnceleyiniz.";

      if (kontrol == _sudokuString) {
        mesaj = "Tebrikler Sudokuyu Başarıyla Bitirdiniz.";
        Box tamamlananKutusu = Hive.box('tamamlanan_sudokular');
        Map tamamlananSudoku = {
          'tarih': DateTime.now(),
          'cozulmus': _sudokuKutu.get('sudokuSatirlari'),
          'sure': _sudokuKutu.get('sure'),
          'sudokuGecmis': _sudokuKutu.get('sudokuGecmis'),
        };
        tamamlananKutusu.add(tamamlananSudoku);
        _sudokuKutu.put('sudokuSatirlari', null);
        Navigator.pop(context);
      }

      Fluttertoast.showToast(
        msg: mesaj,
        toastLength: Toast.LENGTH_LONG,
        timeInSecForIosWeb: 3,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    Wakelock.enable(); // ekranı sürekli açık bırakır
    if (_sudokuKutu.get('sudokuSatirlari') == null)
      _sudokuOlustur();
    else
      _sudoku = _sudokuKutu.get('sudokuSatirlari');

    _sayac = Timer.periodic(Duration(seconds: 1), (timer) {
      int sure = _sudokuKutu.get('sure');
      _sudokuKutu.put('sure', ++sure);
    });
  }

  @override
  void dispose() {
    if (_sayac != null && _sayac.isActive) _sayac.cancel();
    Wakelock.disable(); // başka ekranlarda çalışmaması için
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(dil['sudoku_page']),
        actions: [
          Center(
              child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ValueListenableBuilder<Box>(
                valueListenable: _sudokuKutu.listenable(keys: ['sure']),
                builder: (context, box, _) {
                  String sure = Duration(seconds: box.get('sure')).toString();
                  return Text(sure.split('.').first);
                }),
          ))
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Zorluk Seviyesi: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
                Text(
                  _sudokuKutu.get('seviye', defaultValue: dil['seviye2']),
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0),
                ),
              ],
            ),
            AspectRatio(
              aspectRatio: 1.0,
              child: ValueListenableBuilder<Box>(
                  valueListenable: Hive.box('sudoku')
                      .listenable(keys: ['xy', 'sudokuSatirlari']),
                  builder: (context, box, _) {
                    String xy = box.get(
                      'xy',
                    );
                    int xkoor = int.parse(xy.substring(0, 1)),
                        ykoor = int.parse(xy.substring(1));

                    List sudokuSatirlari = box.get('sudokuSatirlari');

                    return Container(
                      padding: EdgeInsets.all(5.0),
                      margin: EdgeInsets.all(8.0),
                      color: Colors.green,
                      child: Column(
                        children: [
                          for (int x = 0; x < 9; x++)
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        for (int y = 0; y < 9; y++)
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    margin: EdgeInsets.all(1.0),
                                                    color: xkoor == x &&
                                                            ykoor == y
                                                        ? Colors.grey
                                                        : Colors.cyan
                                                            .withOpacity(
                                                                xkoor == x ||
                                                                        ykoor ==
                                                                            y
                                                                    ? 0.8
                                                                    : 1.0),
                                                    alignment: Alignment.center,
                                                    child:
                                                        "${sudokuSatirlari[x][y]}"
                                                                .startsWith("e")
                                                            ? Text(
                                                                "${sudokuSatirlari[x][y]}"
                                                                    .substring(
                                                                        1),
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        22.0),
                                                              )
                                                            : InkWell(
                                                                onTap: () {
                                                                  _sudokuKutu.put(
                                                                      "xy",
                                                                      "$x$y");
                                                                },
                                                                child: Center(
                                                                  child: "${sudokuSatirlari[x][y]}"
                                                                              .length >
                                                                          8
                                                                      ? Column(
                                                                          children: [
                                                                            for (int i = 0;
                                                                                i < 9;
                                                                                i += 3)
                                                                              Expanded(
                                                                                child: Row(
                                                                                  children: [
                                                                                    for (int j = 0; j < 3; j++)
                                                                                      Expanded(
                                                                                          child: Center(
                                                                                        child: Text(
                                                                                          "${sudokuSatirlari[x][y]}".split('')[i + j] == "0" ? "" : "${sudokuSatirlari[x][y]}".split('')[i + j],
                                                                                          style: TextStyle(fontSize: 10.0),
                                                                                        ),
                                                                                      )),
                                                                                  ],
                                                                                ),
                                                                              )
                                                                          ],
                                                                        )
                                                                      : Text(
                                                                          sudokuSatirlari[x][y] != "0"
                                                                              ? sudokuSatirlari[x][y]
                                                                              : '',
                                                                          style: TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 20.0),
                                                                        ),
                                                                ),
                                                              ),
                                                  ),
                                                ),
                                                if (y == 2 || y == 5)
                                                  SizedBox(
                                                    width: 2.0,
                                                  )
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (x == 2 || x == 5)
                                    SizedBox(
                                      height: 2.0,
                                    )
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
            ),
            SizedBox(height: 8.0),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Card(
                                color: Colors.green,
                                margin: EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: () {
                                    String xy = _sudokuKutu.get(
                                      'xy',
                                    );
                                    if (xy != "99") {
                                      int xkoor = int.parse(xy.substring(0, 1)),
                                          ykoor = int.parse(xy.substring(1));
                                      _sudoku[xkoor][ykoor] = "";
                                      _sudokuKutu.put(
                                          'sudokuSatirlari', _sudoku);
                                      _adimKaydet();
                                    }
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        color: Colors.black,
                                      ),
                                      Text(
                                        "Sil",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ValueListenableBuilder<Box>(
                                  valueListenable:
                                      _sudokuKutu.listenable(keys: ["ipucu"]),
                                  builder: (context, box, widget) {
                                    return Card(
                                      color: Colors.green,
                                      margin: EdgeInsets.all(8.0),
                                      child: InkWell(
                                        onTap: () {
                                          String xy = box.get(
                                            'xy',
                                          );
                                          if (xy != "99" &&
                                              box.get('ipucu') > 0) {
                                            int xkoor = int.parse(
                                                    xy.substring(0, 1)),
                                                ykoor =
                                                    int.parse(xy.substring(1));

                                            String cozumString =
                                                _sudokuKutu.get('sudokuString');

                                            List cozumSudoku = List.generate(
                                                9,
                                                (i) => List.generate(
                                                    9,
                                                    (j) => _sudokuString
                                                        .substring(
                                                            i * 9, (i + 1) * 9)
                                                        .split('')[j]));

                                            if (_sudoku[xkoor][ykoor] !=
                                                cozumSudoku[xkoor][ykoor]) {
                                              _sudoku[xkoor][ykoor] =
                                                  cozumSudoku[xkoor][ykoor];
                                              box.put(
                                                  'sudokuSatirlari', _sudoku);
                                              box.put('ipucu',
                                                  box.get('ipucu') - 1);
                                              _adimKaydet();
                                            }
                                          }
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.lightbulb_outline,
                                                  color: Colors.black,
                                                ),
                                                Text(
                                                  ": ${box.get('ipucu')}",
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              "İpucu",
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Card(
                                color: _note
                                    ? Colors.green.withOpacity(0.6)
                                    : Colors.green,
                                margin: EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: () => setState(() => _note = !_note),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.note_add,
                                        color: Colors.black,
                                      ),
                                      Text(
                                        "Not Al",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Card(
                                color: _note
                                    ? Colors.green.withOpacity(0.6)
                                    : Colors.green,
                                margin: EdgeInsets.all(8.0),
                                child: InkWell(
                                  onTap: () {
                                    if (_sudokuGecmis.length > 1) {
                                      _sudokuGecmis.removeLast();
                                      Map onceki =
                                          jsonDecode(_sudokuGecmis.last);
                                      // Map gecmisParca = {
                                      //   'sudokuSatirlari': _sudokuKutu.get('sudokuSatirlari'),
                                      //   'xy': _sudokuKutu.get('xy'),
                                      //   'ipucu': _sudokuKutu.get('ipucu'),
                                      // };
                                      _sudokuKutu.put('sudokuSatirlari',
                                          onceki['sudokuSatirlari']);
                                      _sudokuKutu.put('xy', onceki['xy']);
                                      _sudokuKutu.put('ipucu', onceki['ipucu']);

                                      _sudokuKutu.put(
                                          'sudokuGecmis', _sudokuGecmis);
                                    }
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.undo,
                                        color: Colors.black,
                                      ),
                                      Text(
                                        "Geri Al",
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      ValueListenableBuilder<Box>(
                                        valueListenable: _sudokuKutu
                                            .listenable(keys: ['sudokuGecmis']),
                                        builder: (context, kutu, _) {
                                          return Text(
                                              "${kutu.get('sudokuGecmis', defaultValue: []).length}");
                                        },
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )),
                  Expanded(
                    child: Column(
                      children: [
                        for (int i = 1; i < 10; i += 3)
                          Expanded(
                            child: Row(
                              children: [
                                for (int j = 0; j < 3; j++)
                                  Expanded(
                                    child: Card(
                                      color: Colors.green,
                                      shape: CircleBorder(),
                                      child: InkWell(
                                        onTap: () {
                                          String xy = _sudokuKutu.get(
                                            'xy',
                                          );

                                          if (xy != "99") {
                                            int xkoor = int.parse(
                                                    xy.substring(0, 1)),
                                                ykoor =
                                                    int.parse(xy.substring(1));
                                            if (!_note)
                                              _sudoku[xkoor][ykoor] =
                                                  "${i + j}";
                                            else {
                                              if ("${_sudoku[xkoor][ykoor]}"
                                                      .length <
                                                  8)
                                                _sudoku[xkoor][ykoor] =
                                                    '000000000';
                                              _sudoku[xkoor][ykoor] =
                                                  "${_sudoku[xkoor][ykoor]}"
                                                      .replaceRange(
                                                          i + j - 1,
                                                          i + j,
                                                          "${_sudoku[xkoor][ykoor]}"
                                                                      .substring(
                                                                          i +
                                                                              j -
                                                                              1,
                                                                          i + j) ==
                                                                  "${i + j}"
                                                              ? "0"
                                                              : "${i + j}");

                                              _sudokuKutu.put(
                                                  'sudokuSatirlari', _sudoku);
                                              _adimKaydet();
                                            }
                                          }
                                        },
                                        child: Container(
                                          margin: EdgeInsets.all(3.0),
                                          alignment: Alignment.center,
                                          child: Text(
                                            "${i + j}",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 24.0,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
