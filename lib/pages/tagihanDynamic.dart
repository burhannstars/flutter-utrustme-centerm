import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/foundation.dart'
    show consolidateHttpClientResponseBytes, kIsWeb;
import 'package:gvmerchant_utrustme/model/productCartModel.dart';
import 'package:gvmerchant_utrustme/network/network.dart';
import 'package:gvmerchant_utrustme/pages/frontMenu.dart';
import 'package:indonesia/indonesia.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:http/http.dart' as http;

final price = NumberFormat("#,##0", "en_US");
Timer timer;
String merchantName;

BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

List<BluetoothDevice> _devices = [];
BluetoothDevice _device;
bool _connected = false;
String pathImage;

class TagihanQRDynamic extends StatefulWidget {
  @override
  final String image;
  final String refLabel;
  final VoidCallback method;
  String totalTagihan;
  final String expiredQris;

  // receive data from the FirstScreen as a parameter
  TagihanQRDynamic(
      {Key key,
      @required this.image,
      this.refLabel,
      this.method,
      this.totalTagihan,
      this.expiredQris})
      : super(key: key);
  _TagihanQRDynamicState createState() => _TagihanQRDynamicState();
}

class _TagihanQRDynamicState extends State<TagihanQRDynamic> {
  String descriptionQR;
  String ref_users;
  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();
  List<ProductCartModel> list = [];

  /*Future<void> _shareImageFromUrl() async {
    try {
      var request = await HttpClient().getUrl(Uri.parse(
          "https://www.gudangvoucher.com/merchant/cetak.php?type=3&number=" +
              widget.image));
      var response = await request.close();
      Uint8List bytes = await consolidateHttpClientResponseBytes(response);
      await Share.file('Bagikan QR GV e-Money', 'amlog.jpg', bytes, 'image/jpg',
          text: descriptionQR);
    } catch (e) {
      print('error: $e');
    }
  }*/

  _checkQRIStrx(String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ref_users = prefs.getString("I");
    });
    final response = await http.post(NetworkUrl.checkQRIStrx(),
        body: jsonEncode(
            {"REF_USERS": ref_users, "REF_LABEL": "${widget.refLabel}"}));
    final data = jsonDecode(response.body);
    int value = data['value'];
    if (response.statusCode == 200) {
      if (value == 1) {
        timer?.cancel();
        _btnController?.stop();
        CoolAlert.show(
            context: context,
            type: CoolAlertType.success,
            text: "Transaksi berhasil",
            barrierDismissible: false,
            title: "Success",
            showCancelBtn: true,
            cancelBtnText: "Keluar",
            confirmBtnText: "Print",
            onCancelBtnTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => FrontMenu()),
                (Route<dynamic> route) => false,
              );
            },
            onConfirmBtnTap: () async {
              final myDevice = BluetoothDevice.fromMap({
                'name': 'InnerPrinter',
                'address': '00:00:00:00:00:01',
                'type': '10082'
              });

              bluetooth.isConnected.then((isConnected) {
                if (!isConnected) {
                  bluetooth.connect(myDevice).catchError((error) {
                    //show Not connected bluetooth dialog
                  });
                }
              }).then((snapshot) async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                bluetooth.writeBytes(
                    Uint8List.fromList([0x1B, 0x21, 0x0])); // 1- only bold text
                var city = prefs.getString('city');
                var merchantName = prefs.getString('merchantName');
                bluetooth.printNewLine();
                bluetooth.printImage(pathImage);
                bluetooth.printNewLine();
                if (merchantName.length > 15) {
                  bluetooth.printCustom(merchantName.substring(0, 15), 3, 1);
                  bluetooth.printCustom(merchantName.substring(15), 3, 1);
                } else {
                  bluetooth.printCustom(merchantName, 3, 1);
                }
                bluetooth.printCustom(city, 2, 1);
                bluetooth.printNewLine();
                bluetooth.printNewLine();
                //bluetooth.printCustom("Transaksi QRIS Berhasil", 1, 1);
                bluetooth.printLeftRight(
                    "TerminalID : ", data['terminal_id'], 2);
                bluetooth.printLeftRight(
                    "MerchantID : ", data['merchant_id'], 2);
                bluetooth.printNewLine();
                bluetooth.printLeftRight(
                    "Tanggal    : ", data['order_date'], 2);
                bluetooth.printLeftRight(
                    "Jam        : ", data['order_time'], 2);
                //bluetooth.printLeftRight("Ref : ", data['reference'], 1);
                bluetooth.printLeftRight("NO REFF    : ", "", 2);
                bluetooth.printCustom(data['reference'], 2, 1);
                bluetooth.printCustom("--------------------------------", 2, 1);

                //bluetooth.printLeftRight("Metode", "QRIS", 1);
                bluetooth.printCustom("TERIMA/PURCHASE", 2, 1);
                bluetooth.printCustom("QRIS", 2, 1);
                bluetooth.printNewLine();
                bluetooth.printCustom(
                    "NOMINAL   : Rp. " + data['amount'], 2, 0);

                bluetooth.printCustom("--------------------------------", 2, 1);
                bluetooth.printNewLine();
                bluetooth.printCustom("HARAP TANDA TERIMA INI DISIMPAN", 2, 1);
                bluetooth.printCustom("SEBAGAI BUKTI TRANSAKSI", 2, 1);
                bluetooth.printCustom("YANG SAH", 2, 1);
                bluetooth.printNewLine();
                bluetooth.printCustom("***TERIMA KASIH***", 2, 1);
                bluetooth.printNewLine();
                bluetooth.printNewLine();
                bluetooth.printNewLine();
              });
            }
            /*onCancelBtnTap: () async {
              print("Cancel Button tap");
              final myDevice = BluetoothDevice.fromMap({
                'name': 'InnerPrinter',
                'address': '00:00:00:00:00:01',
                'type': '10082'
              });

              bluetooth.isConnected.then((isConnected) {
                if (!isConnected) {
                  bluetooth.connect(myDevice).catchError((error) {
                    //show Not connected bluetooth dialog
                  });
                }
              }).then((snapshot) async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                merchantName = prefs.getString('merchantName');
                bluetooth.printNewLine();
                bluetooth.printImage(pathImage);
                bluetooth.printCustom(merchantName, 2, 1);
                bluetooth.printNewLine();
                bluetooth.printNewLine();
                bluetooth.printCustom("Transaksi QRIS Berhasil", 1, 1);
                bluetooth.printNewLine();
                bluetooth.printLeftRight("Tanggal : ", data['order_date'], 1);
                bluetooth.printLeftRight("Jam : ", data['order_time'], 1);
                bluetooth.printLeftRight("Ref : ", data['reference'], 1);
                bluetooth.writeBytes(
                    Uint8List.fromList([0x1B, 0x21, 0x0])); // 1- only bold text
                bluetooth.writeBytes(
                    Uint8List.fromList([0x1b, 0x61, 0x01])); //ESC_ALIGN_CENTER

                bluetooth.printCustom("--------------------------------", 1, 1);
                bluetooth.printLeftRight("Jumlah", data['amount'], 1);
                bluetooth.printLeftRight("Metode", "QRIS", 1);
                bluetooth.printCustom("--------------------------------", 1, 1);
                bluetooth.printNewLine();
                bluetooth.printCustom("Terima kasih :)", 2, 1);
                bluetooth.printNewLine();
              });
            }*/
            );
        /*showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return Platform.isAndroid
                  ? WillPopScope(
                      onWillPop: () {},
                      child: AlertDialog(
                        title: Text("Transaksi Selesai"),
                        content: Text("Transaksi sudah terbayar"),
                        actions: <Widget>[
                          FlatButton(
                            onPressed: () async {
                              final myDevice = BluetoothDevice.fromMap({
                                'name': 'InnerPrinter',
                                'address': '00:00:00:00:00:01',
                                'type': '10082'
                              });

                              bluetooth.isConnected.then((isConnected) {
                                if (!isConnected) {
                                  bluetooth
                                      .connect(myDevice)
                                      .catchError((error) {
                                    //show Not connected bluetooth dialog
                                  });
                                }
                              }).then((snapshot) async {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                merchantName = prefs.getString('merchantName');
                                bluetooth.printNewLine();
                                bluetooth.printImage(pathImage);
                                bluetooth.printCustom(merchantName, 2, 1);
                                bluetooth.printNewLine();
                                bluetooth.printNewLine();
                                bluetooth.printCustom(
                                    "Transaksi QRIS Berhasil", 1, 1);
                                bluetooth.printNewLine();
                                bluetooth.printLeftRight(
                                    "Tanggal : ", data['order_date'], 1);
                                bluetooth.printLeftRight(
                                    "Jam : ", data['order_time'], 1);
                                bluetooth.printLeftRight(
                                    "Ref : ", data['reference'], 1);
                                //bluetooth.printLeftRight("Kasir", "A01", 1);
                                /*bluetooth.printCustom(
                                        data[0]['invoice_number'], 1, 1);*/
                                bluetooth.writeBytes(Uint8List.fromList(
                                    [0x1B, 0x21, 0x0])); // 1- only bold text
                                bluetooth.writeBytes(Uint8List.fromList(
                                    [0x1b, 0x61, 0x01])); //ESC_ALIGN_CENTER
                                /*data[0]["item"].forEach((element) {
                                      print("Nama Produk : " +
                                          element['nama_produk']);
                                      bluetooth.printCustom(
                                          element['nama_produk'], 1, 0);
                                      bluetooth.printLeftRight(
                                          element['qty_produk'] +
                                              " x" +
                                              element['harga_produk'],
                                          element['subtotal'],
                                          0);
                                    });*/
                                bluetooth.printCustom(
                                    "--------------------------------", 1, 1);
                                bluetooth.printLeftRight(
                                    "Jumlah", data['amount'], 1);
                                bluetooth.printLeftRight("Metode", "QRIS", 1);
                                bluetooth.printCustom(
                                    "--------------------------------", 1, 1);
                                bluetooth.printNewLine();
                                bluetooth.printCustom("Terima kasih :)", 2, 1);
                                bluetooth.printNewLine();
                              });
                            },
                            child: Icon(Icons.print, color: Colors.white),
                            textColor: Colors.white,
                            color: Colors.orangeAccent,
                          ),
                          FlatButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FrontMenu()),
                                  (Route<dynamic> route) => false,
                                );
                              },
                              child: Text("OK"))
                        ],
                      ),
                    )
                  : WillPopScope(
                      onWillPop: () {},
                      child: CupertinoAlertDialog(
                        title: Text("Transaksi Selesai"),
                        content: Text("Transaksi sudah terbayar"),
                        actions: <Widget>[
                          FlatButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FrontMenu()),
                                  (Route<dynamic> route) => false,
                                );
                              },
                              child: Text("OK"))
                        ],
                      ),
                    );
            });*/
      } else {
        if (type == "2") {
          _btnController?.stop();
          showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                return Platform.isAndroid
                    ? WillPopScope(
                        onWillPop: () {},
                        child: AlertDialog(
                          title: Text("Informasi"),
                          content: Text("Transaksi belum terbayar"),
                          actions: <Widget>[
                            FlatButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("OK"))
                          ],
                        ),
                      )
                    : WillPopScope(
                        onWillPop: () {},
                        child: CupertinoAlertDialog(
                          title: Text("Informasi"),
                          content: Text("Transaksi belum terbayar"),
                          actions: <Widget>[
                            FlatButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text("OK"))
                          ],
                        ),
                      );
              });
        }
      }
      /*else {
        _btnController?.stop();
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return Platform.isAndroid
                  ? WillPopScope(
                      onWillPop: () {},
                      child: AlertDialog(
                        title: Text("Informasi"),
                        content: Text("Transaksi belum terbayar"),
                        actions: <Widget>[
                          FlatButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("OK"))
                        ],
                      ),
                    )
                  : WillPopScope(
                      onWillPop: () {},
                      child: CupertinoAlertDialog(
                        title: Text("Informasi"),
                        content: Text("Transaksi belum terbayar"),
                        actions: <Widget>[
                          FlatButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("OK"))
                        ],
                      ),
                    );
            });
      }*/
    }
  }

  // _getCartItem() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     ref_users = prefs.getString("I");
  //   });
  //   if (widget.type == "CART") {
  //     list.clear();
  //     final response = await http.post(NetworkUrl.cartItemDetail(),
  //         body: jsonEncode({
  //           "REF_USERS": ref_users,
  //           "REF_LABEL": widget.refLabel,
  //           "EXPIRED": widget.expiredQris
  //         }));
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       setState(() {
  //         descriptionQR = data['detail'];
  //       });
  //     }
  //   } else {
  //     setState(() {
  //       widget.totalTagihan =
  //           "Rp " + price.format(int.parse(widget.totalTagihan));
  //     });
  //     final response = await http.post(NetworkUrl.getQRISdesc(),
  //         body: jsonEncode({
  //           "REF_USERS": ref_users,
  //           "REF_LABEL": widget.refLabel,
  //           "EXPIRED": widget.expiredQris,
  //           "NOMINAL": widget.totalTagihan
  //         }));
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       setState(() {
  //         descriptionQR = data['detail'];
  //       });
  //     }
  //   }
  // }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initSavetoPath();
    //if (widget.type == "CART") {
    timer =
        //Timer.periodic(Duration(seconds: 3), (Timer t) => _checkQRIStrx());
        Timer.periodic(Duration(seconds: 3), (Timer t) {
      _checkQRIStrx("1");
    });
    /*} else {
      print("Type 1");
    }*/

    // flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    // var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    // var iOS = new IOSInitializationSettings();
    // var initSetttings = new InitializationSettings(android, iOS);
    // flutterLocalNotificationsPlugin.initialize(initSetttings,
    //     onSelectNotification: null);
  }

  initSavetoPath() async {
    //read and write
    //image max 300px X 300px
    final filename = 'header.png';
    var bytes = await rootBundle.load("assets/images/header.png");
    String dir = (await getApplicationDocumentsDirectory()).path;
    writeToFile(bytes, '$dir/$filename');
    setState(() {
      pathImage = '$dir/$filename';
    });
  }

  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return new File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  @override
  void dispose() {
    // TODO: implement dispose
    timer?.cancel();
    super.dispose();
  }

  void getStatus() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var login = preferences.getBool('login');
    var keys = preferences.getString('_key');
    if (login == true && keys != null) {
      setState(() {});
    }
  }

  showBackAlert(BuildContext context) {
    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text("Tidak"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = FlatButton(
      child: Text("Ya"),
      onPressed: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => FrontMenu()),
          (Route<dynamic> route) => false,
        );
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      content: Text("Kembali ke menu utama ?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        showBackAlert(context);
      },
      child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios),
              onPressed: () {
                showBackAlert(context);
              },
            ),
            actions: <Widget>[
              /*FlatButton(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.share,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5),
                    Text(
                      "Kirim QR",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                onPressed: _shareImageFromUrl,
              ),*/
              /*FlatButton(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.share,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        "Print",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  onPressed: () {
                    // Navigator.push(context,
                    //     MaterialPageRoute(builder: (_) => Print(data)));
                  })*/
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.redAccent, Colors.lightBlue],
                  stops: [0.5, 1.0],
                ),
              ),
            ),
            elevation: 0,
            title: Text("Terima Uang via QRIS"),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      "Total : ",
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text("${rupiah(widget.totalTagihan)}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                    SizedBox(height: 5),
                    SelectableText(
                      "Tanggal kadaluarsa : ",
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    SelectableText("${widget.expiredQris}",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                    Center(
                      child: FancyShimmerImage(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height / 1.75,
                        imageUrl:
                            "https://www.gudangvoucher.com/merchant/cetak.php?type=3&number=" +
                                widget.image,
                        boxFit: BoxFit.contain,
                        shimmerBaseColor: Colors.grey[300],
                        // shimmerHighlightColor: dataDefault[i].shimmerHighlightColor,
                        // shimmerBackColor: dataDefault[i].shimmerBackColor,
                        errorWidget: Image.asset(
                            "assets/images/placeholder.jpg",
                            fit: BoxFit.cover),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    RoundedLoadingButton(
                      color: Colors.orangeAccent,
                      child: Text('Cek Status Transaksi',
                          style: TextStyle(color: Colors.white)),
                      controller: _btnController,
                      onPressed: () {
                        _checkQRIStrx("2");
                        //_submitTagihan();
                      },
                    ),
                    // Image.network(
                    //   "https://www.gudangvoucher.com/merchant/cetak.php?type=3&number=" +
                    //       widget.image,
                    //   fit: BoxFit.cover,
                    // ),
                    // RaisedButton(
                    //   color: Colors.orangeAccent,
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: <Widget>[
                    //       FaIcon(FontAwesomeIcons.qrcode, color: Colors.black45),
                    //       SizedBox(
                    //         width: 10,
                    //       ),
                    //       Text("Bagikan QR",
                    //           style: TextStyle(
                    //               color: Colors.black45,
                    //               fontWeight: FontWeight.bold)),
                    //     ],
                    //   ),
                    //   onPressed: _shareImageFromUrl,
                    // )
                  ],
                ),
              ),
            ),
          )),
    );
  }
}
