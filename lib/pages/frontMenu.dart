import 'dart:ui';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:crypto/crypto.dart';
import 'package:fancy_shimmer_image/fancy_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:gvmerchant_utrustme/config/config.dart';
import 'package:gvmerchant_utrustme/kirim_dana.dart';
import 'package:gvmerchant_utrustme/login_new.dart';
import 'package:gvmerchant_utrustme/network/network.dart';
import 'package:gvmerchant_utrustme/pages/bank_page.dart';
import 'package:gvmerchant_utrustme/pages/home.dart';
import 'package:gvmerchant_utrustme/pages/notifications/notif_page.dart';
import 'package:gvmerchant_utrustme/pages/print.dart';
import 'package:gvmerchant_utrustme/pages/tagihanDynamic.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
//import 'package:moneytextformfield/moneytextformfield.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:indonesia/indonesia.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text/flutter_masked_text.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:simple_speed_dial/simple_speed_dial.dart';
import 'package:styled_text/styled_text.dart';

Animation<double> _animation;
AnimationController _animationController;

final cryptor = new PlatformStringCryptor();
DateTime date = DateTime.now();
//String tanggalSekarang = tanggalHari(date);
String tanggalSekarang = tanggal(date);
final RoundedLoadingButtonController _btnController =
    new RoundedLoadingButtonController();
final price = NumberFormat("#,##0", "en_US");

Timer timer;

class FrontMenu extends StatefulWidget {
  @override
  _FrontMenuState createState() => _FrontMenuState();
}

class _FrontMenuState extends State<FrontMenu>
    with SingleTickerProviderStateMixin {
  String _myActivity = "1";
  String _myActivityResult;
  String indicator_tip = "01";
  String merchantName = "";
  String ref_users = "";
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  TextEditingController inputTagihanController = TextEditingController();
  TextEditingController nominalTagihanController = TextEditingController();
  TextEditingController nominalTipTagihanController = TextEditingController();
  var tagihanController =
      new MoneyMaskedTextController(precision: 0, decimalSeparator: "");
  var tipController =
      new MoneyMaskedTextController(precision: 0, decimalSeparator: "");
  final _formKey = GlobalKey<FormState>();

  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice _device;
  bool _connected = false;
  String pathImage;
  Printing testPrint;

  getPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      merchantName = prefs.getString('merchantName');
      ref_users = prefs.getString('I');
    });
  }

  void _showErrorSnack(String errorMsg) {
    final snackbar =
        SnackBar(content: Text(errorMsg, style: TextStyle(color: Colors.red)));

    _scaffoldKey.currentState.showSnackBar(snackbar);
    //throw Exception('Error Logging : $errorMsg');
  }

  void _showSuccessSnack(String msg) {
    final snackbar =
        SnackBar(content: Text(msg, style: TextStyle(color: Colors.white)));

    _scaffoldKey.currentState.showSnackBar(snackbar);
    //throw Exception('Error Logging : $errorMsg');
  }

  @override
  void initState() {
    // TODO: implement initState
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    //WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
    super.initState();
    getPrefs();
    getStatus();
    initPlatformState();
    initSavetoPath();
    testPrint = Printing();
    final myDevice = BluetoothDevice.fromMap({
      'name': 'InnerPrinter',
      'address': '00:00:00:00:00:01',
      'type': '10082'
    });

    bluetooth.isConnected.then((isConnected) {
      //print("Test Connect");
      if (!isConnected) {
        bluetooth.connect(myDevice).catchError((error) {
          setState(() {
            _connected = false;
          });
        });
      }
    });
    _animationController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    /*timer =
        //Timer.periodic(Duration(seconds: 3), (Timer t) => _checkQRIStrx());
        Timer.periodic(Duration(seconds: 3), (Timer t) {
      _streamQRIStrx();
    });*/
  }

  _streamQRIStrx() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ref_users = prefs.getString("I");
    });
    final response = await http.post(NetworkUrl.streamQRIStrx(),
        body: jsonEncode({"REF_USERS": ref_users}));
    final data = jsonDecode(response.body);
    int value = data['value'];
    if (response.statusCode == 200) {
      if (value == 1) {
        CoolAlert.show(
            context: context,
            type: CoolAlertType.success,
            text: "Rp ${data['amount_formatted']} \n (${data['issuer']})",
            barrierDismissible: true,
            title: "Transaksi Masuk",
            onConfirmBtnTap: () {
              Navigator.pop(context);
            });
      }
    }
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

  Future<void> initPlatformState() async {
    bool isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      // TODO - Error
    }

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
          });
          break;
        default:
          print(state);
          break;
      }
    });

    if (!mounted) return;
    setState(() {
      _devices = devices;
    });

    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    //timer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void getStatus() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var login = preferences.getBool('login');
    var keys = preferences.getString('_key');
    if (login == true && keys != null) {
      setState(() {});
    }
  }

  void _navigateToItemDetail(Map<String, dynamic> message) {
    final MessageBean item = _itemForMessage(message);
    // Clear away dialogs
    Navigator.popUntil(context, (Route<dynamic> route) => route is PageRoute);
    if (!item.route.isCurrent) {
      Navigator.push(context, item.route);
    }
  }

  var loadingButtonTagihan = false;

  _closeDialog() async {
    Navigator.of(context).pop(false);
  }

  _createTagihanQRDynamic() async {
    setState(() {
      loadingButtonTagihan = true;
      FocusScope.of(context).requestFocus(FocusNode());
    });
    try {
      final response =
          await http.post(NetworkUrl.createTagihanDynamic(), body: {
        "ref_users": ref_users,
        "amount": nominalTagihanController.text,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        var respondCode = data['respondcode'];
        if (respondCode == "00") {
          var imageQris = data['responddata']['data_qr'];
          var refLabel = data['responddata']['reference_label'];
          var expiredQris = data['responddata']['expired'];
          _btnController?.success();
          Timer(Duration(seconds: 3), () {
            _btnController.success();
            //timer?.cancel();
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => TagihanQRDynamic(
                          method: _closeDialog,
                          image: imageQris,
                          refLabel: refLabel,
                          totalTagihan: nominalTagihanController.text,
                          expiredQris: expiredQris,
                        )));
            /*Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TagihanQRDynamic(
                          method: _closeDialog,
                          image: imageQris,
                          refLabel: refLabel,
                          totalTagihan: nominalTagihanController.text,
                          expiredQris: expiredQris,
                        )));*/
          });
        } else {
          _showErrorSnack('Gagal membuat QR : ' + data['respondmsg']);
          _btnController?.error();
        }
      }
    } catch (e) {
      print("Error $e");
    }
  }

  showLogoutAlert(BuildContext context) {
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
        signOut();
        Navigator.of(context).pop();
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Info", style: TextStyle(fontStyle: FontStyle.italic)),
      content: Text("Apakah anda yakin ingin Logout akun Anda ?"),
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

  String license = 'Layanan GV - uTRUSTme ini diselenggarakan oleh: \n\n' +
      '<bold>PT Buana Media Teknologi</bold> \n\n' +
      'Izin resmi Penyelenggara Uang Elektronik (e-money) dari Bank Indonesia dengan <bold>Nomor : 19/468/DKSP/Srt/B</bold> \n\n' +
      'Izin resmi Penyelenggara Pemrosesan Transaksi QRIS dengan <bold>Nomor : 22/289/DKSP/Srt/B</bold> \n\n' +
      'Izin resmi Penyelenggara Transfer Dana dari Bank Indonesia dengan <bold>Nomor : No.23/309/DKSP/Srt/B</bold> \n\n' +
      'Telah mendapatkan Tanda Daftar Penyelenggara Sistem Elektronik (PSE) \n' +
      '<bold>No.001031.01/DJAI.PSE/06/2021</bold> dari Kementerian Komunikasi dan Informatika Republik Indonesia \n\n' +
      'Telah mendapatkan Konversi Izin "Kategori I" \n' +
      'dalam Penatausahaan Sumber Dana (sebagai Penerbit Uang Elektronik) \n' +
      'dan Layanan Remitansi (sebagai Penyelenggara Transfer Dana) dari Bank Indonesia <bold>No. 23/562/DKSP/Srt/B</bold>';

  showLicense(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title:
                Text("Lisensi", style: TextStyle(fontStyle: FontStyle.italic)),
            content: Container(
              width: double.maxFinite,
              child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                Expanded(
                    child: ListView(shrinkWrap: true, children: <Widget>[
                  StyledText(
                    text: license,
                    style: TextStyle(fontSize: 13.0),
                    tags: {
                      'bold': StyledTextTag(
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    },
                  )
                ]))
              ]),
            ),
            actions: [
              FlatButton(
                child: Text("Tutup"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        });
  }

  void signOut() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var loginStatus = preferences.getBool('login');
    var key = preferences.getString('_key');
    var _u = preferences.getString('U');
    var _i = preferences.getString('I');
    var _s = preferences.getString('S');
    if (loginStatus == true &&
        key != null &&
        _u != null &&
        _i != null &&
        _s != null) {
      final String decrypted = await cryptor.decrypt(key, Config.encryptionKey);
      var username2 = utf8.encode(_u);
      var password2 = utf8.encode(decrypted);
      var mrckey = utf8.encode(Config.mrcKey);
      var sign = sha1.convert(username2 + password2 + mrckey);
      final response = await http.post(Config.destroyURL,
          body: json.encode({
            'USR': _u,
            'PWD': decrypted,
            'SIGN': sign.toString(),
          }));
      final data = json.decode(response.body);
      if (data['status'] == 0) {
        CookieManager cookieManager = CookieManager.instance();
        await cookieManager.deleteCookie(
          url: Uri.parse(Config.links),
          name: "I",
          domain: "www.gudangvoucher.com",
        );
        await cookieManager.deleteCookie(
          url: Uri.parse(Config.links),
          name: "U",
          domain: "www.gudangvoucher.com",
        );
        await cookieManager.deleteCookie(
          url: Uri.parse(Config.links),
          name: "S",
          domain: "www.gudangvoucher.com",
        );
        preferences.remove('login');
        preferences.remove('U');
        preferences.remove('I');
        preferences.remove('S');
        preferences.remove('_key');
        //preferences.clear();
        Navigator.of(context).pushReplacement(new MaterialPageRoute(
            builder: (BuildContext context) => LoginPage()));
      } else {
        _showErrorSnack('Gagal Logout');
      }
    }
  }

  TextEditingController longCtrl = TextEditingController();
  TextEditingController compactCtrl = TextEditingController();

  bool enableTip = false;
  /*_openPopup(context) {
    TextStyle _ts = TextStyle(fontSize: 15.0);
    setState(() {
      nominalTagihanController.text = "";
      nominalTipTagihanController.text = "";
      tagihanController.text = "";
      tipController.text = "";
    });
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  new Text("Terima Uang"),
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close))
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Divider(height: 10, color: Colors.grey),
                      TextFormField(
                        maxLength: 7,
                        validator: (val) =>
                            val.length == 0 ? 'Nominal Wajib diisi!' : null,
                        controller: nominalTagihanController,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setState(() {
                            tagihanController.text = value;
                          });
                        },
                        decoration: InputDecoration(labelText: "Nominal"),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text("Rp. " + tagihanController.text,
                              style: TextStyle(
                                  color: Colors.lightBlue,
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Divider(height: 10, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                // usually buttons at the bottom of the dialog
                DialogButton(
                  color: Colors.transparent,
                  child: RoundedLoadingButton(
                    child:
                        Text('Buat QR', style: TextStyle(color: Colors.white)),
                    controller: _btnController,
                    onPressed: () {
                      _submitTagihan();
                    },
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }*/

  _nominalValidation(value) {
    if (value > 10000000) {
      return 'Nominal tidak boleh melebihi Rp 10.000.000';
    }
    if (value.length == 0) {
      return 'Nominal Wajib Diisi';
    }
  }

  _openPopupMenu(context) {
    var alertDialog = AlertDialog(
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          new Text("Terima Uang/\nPurchase", style: TextStyle(fontSize: 18.0)),
          IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: Icon(Icons.close))
        ],
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          child: Container(
            color: Colors.grey,
            padding: EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.qr_code, color: Colors.orangeAccent),
                SizedBox(width: 20),
                Text("via QRIS", style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          onTap: () {
            TextStyle _ts = TextStyle(fontSize: 15.0);
            setState(() {
              nominalTagihanController.text = "";
              nominalTipTagihanController.text = "";
              tagihanController.text = "";
              tipController.text = "";
            });
            showDialog(
              context: context,
              builder: (BuildContext context2) {
                return StatefulBuilder(
                  builder: (BuildContext context2, StateSetter setState) {
                    return AlertDialog(
                      title: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          new Text("Terima Uang/\nPurchase",
                              style: TextStyle(fontSize: 18.0)),
                          IconButton(
                              onPressed: () {
                                Navigator.pop(context2);
                              },
                              icon: Icon(Icons.close))
                        ],
                      ),
                      content: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Divider(height: 10, color: Colors.grey),
                              TextFormField(
                                maxLength: 8,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Nominal wajib diisi';
                                  }
                                  if (int.parse(value) > 10000000) {
                                    return 'Nominal melebihi Rp 10.000.000';
                                  }
                                  return null;
                                },
                                controller: nominalTagihanController,
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    tagihanController.text = value;
                                  });
                                },
                                decoration:
                                    InputDecoration(labelText: "Nominal"),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text("Rp. " + tagihanController.text,
                                      style: TextStyle(
                                          color: Colors.lightBlue,
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Divider(height: 10, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                      actions: <Widget>[
                        // usually buttons at the bottom of the dialog
                        DialogButton(
                          color: Colors.transparent,
                          child: RoundedLoadingButton(
                            child: Text('Buat QR',
                                style: TextStyle(color: Colors.white)),
                            controller: _btnController,
                            onPressed: () {
                              _submitTagihan();
                            },
                          ),
                        )
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
        SizedBox(height: 20),
        InkWell(
          child: Container(
            color: Colors.grey,
            padding: EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                FaIcon(FontAwesomeIcons.building, color: Colors.orangeAccent),
                SizedBox(width: 20),
                Text("via Transfer Bank",
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          onTap: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => BankPage()));
          },
        ),
      ]),
    );

    showDialog(
        context: context, builder: (BuildContext context) => alertDialog);
    /*showDialog(
      context: context,
      builder: (BuildContext context) {
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  new Text("Terima Uang"),
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close))
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Divider(height: 10, color: Colors.grey),
                      RaisedButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.qr_code, color: Colors.black45),
                            SizedBox(height: 5),
                            Text("via QRIS")
                          ],
                        ),
                        onPressed: _openPopup(context),
                      ),
                      RaisedButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FaIcon(FontAwesomeIcons.building,
                                color: Colors.black45),
                            SizedBox(height: 5),
                            Text("via Bank Transfer")
                          ],
                        ),
                        onPressed: _openPopup(context),
                      ),
                      Divider(height: 10, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          },
      },
    );*/
  }

  void _submitTagihan() {
    //FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      _createTagihanQRDynamic();
    } else {
      _btnController?.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.redAccent, Colors.lightBlue],
              stops: [0.5, 1.0],
            ),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        // leading: IconButton(
        //   onPressed: () => _scaffoldKey.currentState.openDrawer(),
        //   icon: Icon(Icons.menu),
        // ),
        title: Text(
          "GVe by uTRUSTme",
          style: TextStyle(letterSpacing: 2),
        ),
        actions: <Widget>[
          /*IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return NotificationPage();
                }));
              }),*/
          IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                showLogoutAlert(context);
              }),
        ],
      ),
      /*floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FloatingActionButton(
              backgroundColor: Colors.green,
              heroTag: "btn",
              onPressed: () {
                _openPopup(context);
              },
              child: Icon(Icons.qr_code),
            ),
            SizedBox(
              width: 40,
            ),
            FloatingActionButton(
              backgroundColor: Colors.red,
              heroTag: "btn2",
              onPressed: () {
                getBalance();
              },
              child: Icon(Icons.print),
            )
          ],
        ),
      ),*/
      floatingActionButton: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                left: 35.0, bottom: 5.0, top: 5.0, right: 5.0),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: FloatingActionButton.extended(
                heroTag: null,
                elevation: 4.0,
                backgroundColor: Colors.grey,
                label: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        FaIcon(FontAwesomeIcons.copyright, color: Colors.white),
                        SizedBox(
                          width: 10,
                        ),
                        Text("Lisensi",
                            style: TextStyle(
                                fontFamily: 'FrankRuhlLibre',
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                onPressed: () {
                  showLicense(context);
                  //_openPopup(context);
                  //_pc.isPanelOpen ? _pc.close() : _pc.open();
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.extended(
                heroTag: null,
                elevation: 4.0,
                backgroundColor: Colors.orangeAccent,
                label: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        FaIcon(FontAwesomeIcons.user, color: Colors.black45),
                        SizedBox(
                          width: 10,
                        ),
                        Text("Profil",
                            style: TextStyle(
                                fontFamily: 'FrankRuhlLibre',
                                color: Colors.black45,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => HomeScreen()));
                  //_openPopup(context);
                  //_pc.isPanelOpen ? _pc.close() : _pc.open();
                },
              ),
            ),
          ),
          /*Padding(
            padding: const EdgeInsets.all(5),
            child: FloatingActionButton.extended(
              elevation: 4.0,
              backgroundColor: Colors.orangeAccent,
              label: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      FaIcon(FontAwesomeIcons.user, color: Colors.black45),
                      SizedBox(
                        width: 10,
                      ),
                      Text("Profil",
                          style: TextStyle(
                              fontFamily: 'FrankRuhlLibre',
                              color: Colors.black45,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => HomeScreen()));
                //_openPopup(context);
                //_pc.isPanelOpen ? _pc.close() : _pc.open();
              },
            ),
          ),*/
        ],
      ),
      /*floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SpeedDial(
          child: Icon(
            Icons.arrow_upward_sharp,
            color: Colors.white,
          ),
          speedDialChildren: <SpeedDialChild>[
            SpeedDialChild(
              child: const Icon(Icons.qr_code),
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              label: 'Terima Uang via QRIS',
              onPressed: () {
                _openPopup(context);
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.money),
              foregroundColor: Colors.white,
              backgroundColor: Colors.blue,
              label: 'Terima Uang via Bank Transfer',
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => BankPage()));
              },
            ),
          ],
          closedForegroundColor: Colors.blue,
          openForegroundColor: Colors.grey,
          closedBackgroundColor: Colors.blue,
          openBackgroundColor: Colors.grey,
        ),
      ),*/
      //floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // bottomNavigationBar: BottomAppBar(
      //   child: new Row(
      //     mainAxisSize: MainAxisSize.max,
      //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //     children: <Widget>[
      //       IconButton(
      //         icon: Icon(Icons.menu),
      //         onPressed: () {},
      //       ),
      //       IconButton(
      //         icon: Icon(Icons.search),
      //         onPressed: () {},
      //       )
      //     ],
      //   ),
      // ),
      body: SafeArea(
        child: Container(
          color: Colors.grey[100],
          padding: EdgeInsets.all(20.0),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                height: 250,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient:
                          LinearGradient(begin: Alignment.bottomRight, colors: [
                        Colors.black.withOpacity(.6),
                        Colors.black.withOpacity(.2),
                      ])),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: 70,
                            minHeight: 60,
                            maxWidth: 350,
                            maxHeight: 100,
                          ),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: FancyShimmerImage(
                                imageUrl:
                                    "https://www.gudangvoucher.com/edc/api/getLogo.php?users=" +
                                        ref_users,
                                boxFit: BoxFit.fitWidth,
                                shimmerBaseColor: Colors.grey[300],
                                // shimmerHighlightColor: dataDefault[i].shimmerHighlightColor,
                                // shimmerBackColor: dataDefault[i].shimmerBackColor,
                                errorWidget: Image.asset(
                                    "assets/images/placeholder.jpg",
                                    fit: BoxFit.cover),
                              )),
                        ),
                      ),
                      Text(
                        merchantName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'SpectralRegular',
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Container(
                        height: 50,
                        margin: EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white),
                        child: Center(
                            child: Text(
                          "${tanggalSekarang}",
                          style: TextStyle(
                              color: Colors.grey[900],
                              fontWeight: FontWeight.bold),
                        )),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Expanded(
                  child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: <Widget>[
                  InkWell(
                      child: Container(
                          alignment: Alignment.center,
                          child: Card(
                            color: Colors.redAccent,
                            elevation: 5,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => KirimDana()));
                              },
                              child: Stack(
                                children: <Widget>[
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      margin: EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: AssetImage(
                                                "assets/images/send.png"),
                                            fit: BoxFit.contain),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      verticalDirection: VerticalDirection.up,
                                      children: <Widget>[
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          color: Colors.black.withOpacity(.2),
                                          child: Text(
                                            "Transfer Uang",
                                            style: TextStyle(
                                                fontFamily: 'FrankRuhlLibre',
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.normal),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))),
                  InkWell(
                      child: Container(
                          alignment: Alignment.center,
                          child: Card(
                            color: Colors.lightBlue,
                            elevation: 5,
                            child: InkWell(
                              onTap: () {
                                _openPopupMenu(context);
                              },
                              child: Stack(
                                children: <Widget>[
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                      margin: EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                            image: AssetImage(
                                                "assets/images/receive.png"),
                                            fit: BoxFit.contain),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      verticalDirection: VerticalDirection.up,
                                      children: <Widget>[
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          color: Colors.black.withOpacity(.2),
                                          child: Text(
                                            "Terima/Purchase",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'FrankRuhlLibre',
                                                fontSize: 16,
                                                fontWeight: FontWeight.normal),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))),
                ],
              ))
            ],
          ),
        ),
      ),
    );
  }
}

final Map<String, MessageBean> _items = <String, MessageBean>{};
MessageBean _itemForMessage(Map<String, dynamic> message) {
  //If the message['data'] is non-null, we will return its value, else return map message object
  final dynamic data = message['data'] ?? message;
  final String itemId = data['id'];
  final MessageBean item = _items.putIfAbsent(
      itemId, () => MessageBean(itemId: itemId))
    ..status = data['webURL'];
  return item;
}
