import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gvmerchant_utrustme/config/config.dart';
import 'package:gvmerchant_utrustme/login_new.dart';
import 'package:gvmerchant_utrustme/network/network.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'print.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

String ref_users, merchantName, deviceID;

final cryptor = new PlatformStringCryptor();
Timer timer;

CookieManager cookieManager = CookieManager.instance();
BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

List<BluetoothDevice> _devices = [];
BluetoothDevice _device;
bool _connected = false;
String pathImage;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(new HomeScreen());
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  //final flutterWebviewPlugin = new FlutterWebviewPlugin();
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  BluetoothDevice _device;
  bool _connected = false;
  String pathImage;
  Printing testPrint;

  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        userAgent: Config.userAgent,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  PullToRefreshController pullToRefreshController;
  String url = "";
  double progress = 0;
  final urlController = TextEditingController();

  void _onLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => new Dialog(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: <Widget>[
                  Icon(Icons.notifications),
                  Text("Load new notication")
                ],
              ),
              SizedBox(height: 20),
              new CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("Please Wait......")
            ],
          ),
        ),
      ),
    );
  }

  getBalance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ref_users = prefs.getString("I");
      merchantName = prefs.getString('merchantName');
    });
    final response = await http.post(NetworkUrl.getMerchantBalance(),
        body: jsonEncode({"REF_USERS": ref_users}));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      //print("Data Response : " + response.body);
      //testPrint.sample(pathImage);
    }
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
      //print(data);
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
        Navigator.of(context).pushReplacement(new MaterialPageRoute(
            builder: (BuildContext context) => LoginPage()));
      } else {
        _showErrorSnack('Gagal Logout');
      }
    }
  }

  //PRIVATE METHOD TO HANDLE NAVIGATION TO SPECIFIC PAGE
  void _navigateToItemDetail(Map<String, dynamic> message) {
    final MessageBean item = _itemForMessage(message);
    // Clear away dialogs
    Navigator.popUntil(context, (Route<dynamic> route) => route is PageRoute);
    if (!item.route.isCurrent) {
      Navigator.push(context, item.route);
    }
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initPlatformState();
    initSavetoPath();
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
    testPrint = Printing();
    final myDevice = BluetoothDevice.fromMap({
      'name': 'InnerPrinter',
      'address': Config.printerMacAddress,
      'type': '10082'
    });

    /*bluetooth.isConnected.then((isConnected) {
      print("Test Connect");
      if (!isConnected) {
        bluetooth.connect(myDevice).catchError((error) {
          setState(() {
            _connected = false;
          });
        });
      }
      getBalance();
    });*/
    /*flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    var android = new AndroidInitializationSettings('@mipmap/ic_launcher');
    var iOS = new IOSInitializationSettings();
    var initSetttings = new InitializationSettings(android, iOS);
    flutterLocalNotificationsPlugin.initialize(initSetttings,
        onSelectNotification: null);*/
    //getStatus();
    /*timer = Timer.periodic(Duration(seconds: 3), (Timer t) {
      _checkQRIStrx();
    });*/
    //flutterWebviewPlugin.evalJavascript("console.log('TEST123456');");
    //_evalJS();
  }

  /*_evalJS() async {
    flutterWebviewPlugin.evalJavascript("alert('TEST123456');");
    await headlessWebView?.webViewController.evaluateJavascript(
                        source: """alert('TEST');""");
  }*/

  _checkQRIStrx() async {
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
        timer?.cancel();
        final myDevice = BluetoothDevice.fromMap({
          'name': 'InnerPrinter',
          'address': Config.printerMacAddress,
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
          //bluetooth.printImage(pathImage);
          bluetooth.printCustom(merchantName, 2, 1);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          bluetooth.printCustom("Transaksi QRIS Berhasil", 1, 1);
          bluetooth.printNewLine();
          bluetooth.printLeftRight("Tanggal : ", data['order_date'], 1);
          bluetooth.printLeftRight("Jam     : ", data['order_time'], 1);
          bluetooth.printLeftRight("Ref     : ", data['reference'], 1);
          bluetooth.printLeftRight("Issuer  : ", data['issuer'], 1);
          bluetooth.writeBytes(
              Uint8List.fromList([0x1B, 0x21, 0x0])); // 1- only bold text
          bluetooth.writeBytes(
              Uint8List.fromList([0x1b, 0x61, 0x01])); //ESC_ALIGN_CENTER

          bluetooth.printCustom("--------------------------------", 1, 1);
          bluetooth.printLeftRight("Jumlah", data['amount'], 1);
          bluetooth.printLeftRight("Metode", "QRIS", 1);
          bluetooth.printCustom("--------------------------------", 1, 1);
          bluetooth.printNewLine();
          bluetooth.printCustom("Terima kasih :)", 1, 1);
          bluetooth.printNewLine();
        });
      }
    }
  }

  _printQRISreceipt(String reference) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ref_users = prefs.getString("I");
    });
    final response = await http.post(NetworkUrl.printQRISHistory(),
        body: jsonEncode({"REF_USERS": ref_users, "REF_INVOICE": reference}));
    final data = jsonDecode(response.body);
    int value = data['value'];
    if (response.statusCode == 200) {
      if (value == 1) {
        final myDevice = BluetoothDevice.fromMap({
          'name': 'InnerPrinter',
          'address': Config.printerMacAddress,
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
          var city = prefs.getString('city');
          bluetooth.printNewLine();
          bluetooth.printImage(pathImage);
          bluetooth.printNewLine();
          bluetooth.printCustom(merchantName, 2, 1);
          bluetooth.printCustom(city, 1, 1);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          //bluetooth.printCustom("Transaksi QRIS Berhasil", 1, 1);
          bluetooth.printLeftRight("TerminalID : ", data['terminal_id'], 1);
          bluetooth.printLeftRight("MerchantID : ", data['merchant_id'], 1);
          bluetooth.printNewLine();
          bluetooth.printLeftRight("Tanggal    : ", data['order_date'], 1);
          bluetooth.printLeftRight("Jam        : ", data['order_time'], 1);
          //bluetooth.printLeftRight("Ref : ", data['reference'], 1);
          bluetooth.printLeftRight("NO REFF    : ", data['reference'], 1);
          bluetooth.writeBytes(
              Uint8List.fromList([0x1B, 0x21, 0x0])); // 1- only bold text
          bluetooth.writeBytes(
              Uint8List.fromList([0x1b, 0x61, 0x01])); //ESC_ALIGN_CENTER

          bluetooth.printCustom("--------------------------------", 1, 1);

          //bluetooth.printLeftRight("Metode", "QRIS", 1);
          bluetooth.printCustom("TERIMA/PURCHASE", 2, 1);
          bluetooth.printCustom("QRIS", 2, 1);
          bluetooth.printNewLine();
          bluetooth.printCustom("NOMINAL   : Rp. " + data['amount'], 1, 0);

          bluetooth.printCustom("--------------------------------", 1, 1);
          bluetooth.printNewLine();
          bluetooth.printCustom(
              "HARAP TANDA TERIMA INI DISIMPAN \nSEBAGAI BUKTI TANDA TRANSAKSI YANG SAH",
              1,
              1);
          bluetooth.printNewLine();
          bluetooth.printCustom("***TERIMA KASIH***", 1, 1);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          bluetooth.printNewLine();
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
    super.dispose();
    timer?.cancel();
  }

  void getStatus() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    var login = preferences.getBool('login');
    var keys = preferences.getString('_key');
    if (login == true && keys != null) {
      setState(() {});
    }
  }

  void _setCookie() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    String versisekarang = info.version.toString();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      if (Platform.isAndroid) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        setState(() {
          deviceID = androidInfo.androidId;
        });
      } else if (Platform.isIOS) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        setState(() {
          deviceID = iosInfo.identifierForVendor;
        });
      }
    } on PlatformException {
      setState(() {
        deviceID = "";
      });
    }

    var loginStatus = prefs.getBool('login');
    var key = prefs.getString('_key');
    var _u = prefs.getString('U');
    var _i = prefs.getString('I');
    var _s = prefs.getString('S');
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
      final response = await http.post(Config.baseUrl,
          body: json.encode({
            'USR': _u,
            'PWD': decrypted,
            'SIGN': sign.toString(),
            'TOKEN': "SCM_DEVICE_NEXGO",
            'APP_VERSION': versisekarang,
            'DEVICE_ID': deviceID,
            'REQUEST_TYPE': "CHECK"
          }));
      final data = json.decode(response.body);
      if (data['status'] == 0) {
        setState(() {
          prefs.setBool('login', true);
          prefs.setString('U', data['U']);
          prefs.setString('S', data['S']);
          prefs.setString('I', data['I']);
          prefs.setString('_key', key);
        });
        CookieManager cookieManager = CookieManager.instance();
        await cookieManager.setCookie(
          url: Uri.parse(Config.links),
          name: "I",
          value: data['I'],
          domain: "www.gudangvoucher.com",
          isSecure: true,
        );
        await cookieManager.setCookie(
          url: Uri.parse(Config.links),
          name: "U",
          value: data['U'],
          domain: "www.gudangvoucher.com",
          isSecure: true,
        );
        await cookieManager.setCookie(
          url: Uri.parse(Config.links),
          name: "S",
          value: data['S'],
          domain: "www.gudangvoucher.com",
          isSecure: true,
        );
        webViewController?.reload();
        //flutterWebviewPlugin?.reload();
      } else {
        signOut();
      }
    } else {
      signOut();
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
      title: Text("Warning!"),
      content: Text("Apakah anda yakin ingin Logout akun anda ?"),
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

  void _showErrorSnack(String errorMsg) {
    final snackbar =
        SnackBar(content: Text(errorMsg, style: TextStyle(color: Colors.red)));

    _scaffoldKey.currentState.showSnackBar(snackbar);
    //throw Exception('Error Logging : $errorMsg');
  }

  /*Future<bool> _willPopCallback(WebViewController controller) async {
    if (await controller.canGoBack()) {
      controller.goBack();
    } else {
      showExitAlert(context);
    }
  }*/

  showExitAlert(BuildContext context) {
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
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Alert !"),
      content: Text("Apakah anda yakin ingin keluar dari aplikasi ?"),
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

  _printVirtualAccountReceipt(String reference) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Codec<String, String> stringToBase64 = utf8.fuse(base64);
    String encoded = stringToBase64.encode(reference);
    setState(() {
      ref_users = prefs.getString("I");
    });
    final response = await http.post(NetworkUrl.checkVATRX(),
        body: jsonEncode({"REF_USERS": ref_users, "REF_TRANSFER": "$encoded"}));
    final data = jsonDecode(response.body);
    //print("Response Data : "+response.body);
    int value = data['value'];
    if (response.statusCode == 200) {
      if (value == 1) {
        final myDevice = BluetoothDevice.fromMap({
          'name': 'InnerPrinter',
          'address': Config.printerMacAddress,
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
          var city = prefs.getString('city');
          bluetooth.printNewLine();
          bluetooth.printImage(pathImage);
          bluetooth.printNewLine();
          bluetooth.printCustom(merchantName, 2, 1);
          bluetooth.printCustom(city, 1, 1);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          //bluetooth.printCustom("Transaksi QRIS Berhasil", 1, 1);
          /*bluetooth.printLeftRight("TerminalID : ", data['terminal_id'], 1);
              bluetooth.printLeftRight("MerchantID : ", data['merchant_id'], 1);
              bluetooth.printNewLine();*/
          bluetooth.printLeftRight("Tanggal    : ", data['order_date'], 1);
          bluetooth.printLeftRight("Jam        : ", data['order_time'], 1);
          //bluetooth.printLeftRight("Ref : ", data['reference'], 1);
          bluetooth.printLeftRight("NO REFF    : ", data['reference'], 1);
          bluetooth.writeBytes(
              Uint8List.fromList([0x1B, 0x21, 0x0])); // 1- only bold text
          bluetooth.writeBytes(
              Uint8List.fromList([0x1b, 0x61, 0x01])); //ESC_ALIGN_CENTER

          bluetooth.printCustom("--------------------------------", 1, 1);

          //bluetooth.printLeftRight("Metode", "QRIS", 1);
          bluetooth.printCustom("TERIMA/PURCHASE", 2, 1);
          bluetooth.printCustom("VA", 2, 1);
          bluetooth.printNewLine();
          bluetooth.printCustom("BANK     : " + data['bank'], 1, 0);
          bluetooth.printCustom("NOMINAL  : Rp. " + data['amount'], 1, 0);
          /*bluetooth.printLeftRight("BANK", data['bank'], 1);
          bluetooth.printLeftRight("NOMINAL", "Rp " + data['amount'], 1);*/
          bluetooth.printCustom("--------------------------------", 1, 1);
          bluetooth.printNewLine();
          bluetooth.printCustom(
              "HARAP TANDA TERIMA INI DISIMPAN \nSEBAGAI BUKTI TANDA TRANSAKSI YANG SAH",
              1,
              1);
          bluetooth.printNewLine();
          bluetooth.printCustom("***TERIMA KASIH***", 1, 1);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          bluetooth.printNewLine();
        });
      }
    }
  }

  _printTransferReceipt(String reference) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ref_users = prefs.getString("I");
    });
    final response = await http.post(NetworkUrl.getPrintTransfer(),
        body:
            jsonEncode({"REF_USERS": ref_users, "REF_TRANSFER": "$reference"}));
    final data = jsonDecode(response.body);
    //print("Response Data : "+response.body);
    int value = data['value'];
    if (response.statusCode == 200) {
      if (value == 1) {
        final myDevice = BluetoothDevice.fromMap({
          'name': 'InnerPrinter',
          'address': Config.printerMacAddress,
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
            bluetooth.printCustom(merchantName.substring(0, 15), 1, 1);
            bluetooth.printCustom(merchantName.substring(15), 1, 1);
          } else {
            bluetooth.printCustom(merchantName, 1, 1);
          }
          bluetooth.printCustom(city, 1, 1);
          bluetooth.printNewLine();
          bluetooth.printCustom("TRANSFER BERHASIL", 1, 1);
          bluetooth.printNewLine();
          bluetooth.printLeftRight("Tanggal    : ", data['transfer_date'], 1);
          bluetooth.printLeftRight("Jam        : ", data['transfer_time'], 1);
          bluetooth.printLeftRight("NO REFF ", "", 1);
          bluetooth.printCustom(data['reference'], 1, 1);

          bluetooth.printCustom("--------------------------------", 1, 1);
          bluetooth.printCustom("TUJUAN", 1, 1);
          bluetooth.printNewLine();
          /*if (data['receiver_name'].toString().length > 19) {
            bluetooth.printCustom(
                "NAMA     : " +
                    data['receiver_name'].toString().substring(0, 20),
                2,
                0);
            bluetooth.printCustom(
                "           " + data['receiver_name'].toString().substring(21),
                2,
                0);
          } else {
            bluetooth.printCustom("NAMA     : " + data['receiver_name'], 2, 0);
          }*/
          bluetooth.printCustom("NAMA     : " + data['receiver_name'], 1, 0);
          bluetooth.printCustom("REKENING : " + data['receiver_number'], 1, 0);
          bluetooth.printCustom("BANK     : " + data['bank'], 1, 0);
          bluetooth.printCustom("JUMLAH   : " + data['amount'], 1, 0);
          bluetooth.printCustom("--------------------------------", 1, 1);
          bluetooth.printNewLine();
          bluetooth.printCustom("HARAP TANDA TERIMA INI DISIMPAN", 1, 1);
          bluetooth.printCustom("SEBAGAI BUKTI TRANSAKSI", 1, 1);
          bluetooth.printCustom("YANG SAH", 2, 1);
          bluetooth.printNewLine();
          bluetooth.printCustom("***TERIMA KASIH***", 1, 1);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          /*bluetooth.printNewLine();
          bluetooth.printImage(pathImage);
          bluetooth.printNewLine();
          bluetooth.printCustom(merchantName, 2, 1);
          bluetooth.printCustom(city, 1, 1);
          bluetooth.printNewLine();
          bluetooth.printCustom("TRANSFER BERHASIL", 2, 1);
          bluetooth.printNewLine();
          bluetooth.printLeftRight("Tanggal    : ", data['transfer_date'], 1);
          bluetooth.printLeftRight("Jam        : ", data['transfer_time'], 1);
          //bluetooth.printLeftRight("Ref : ", data['reference'], 1);
          bluetooth.printLeftRight("NO REFF ", data['reference'], 1);
          bluetooth.writeBytes(
              Uint8List.fromList([0x1B, 0x21, 0x0])); // 1- only bold text
          bluetooth.writeBytes(
              Uint8List.fromList([0x1b, 0x61, 0x01])); //ESC_ALIGN_CENTER

          bluetooth.printCustom("--------------------------------", 1, 1);
          bluetooth.printCustom("TUJUAN", 2, 1);
          bluetooth.printLeftRight("Nama        : ", data['receiver_name'], 1);
          bluetooth.printLeftRight(
              "No Rekening : ", data['receiver_number'], 1);
          bluetooth.printLeftRight("Bank        : ", data['bank'], 1);
          bluetooth.printLeftRight("Jumlah      : ", data['amount'], 1);
          bluetooth.printNewLine();
          bluetooth.printCustom("--------------------------------", 1, 1);
          bluetooth.printNewLine();
          bluetooth.printCustom(
              "HARAP TANDA TERIMA INI DISIMPAN \nSEBAGAI BUKTI TANDA TRANSAKSI YANG SAH",
              1,
              1);
          bluetooth.printNewLine();
          bluetooth.printCustom("***TERIMA KASIH***", 1, 1);
          bluetooth.printNewLine();
          bluetooth.printNewLine();
          bluetooth.printNewLine();*/
        });
      }
    }
  }

  var currentColor = Color.fromRGBO(231, 129, 109, 1.0);
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
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
            title: new Text(
              "Profil Merchant/Agen",
              style: TextStyle(fontSize: 16.0),
            ),
            leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            backgroundColor: currentColor,
            actions: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.refresh),
                        onPressed: () async {
                          //print("Reload");
                          webViewController?.reload();
                          //flutterWebviewPlugin?.reload();
                        },
                      ),
                      /*IconButton(
                      icon: Icon(Icons.exit_to_app),
                      onPressed: () {
                        signOut();
                      },
                    ),*/
                    ],
                  )),
            ],
            elevation: 0.0,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                InAppWebView(
                  key: webViewKey,
                  initialUrlRequest: URLRequest(
                      url: Uri.parse(NetworkUrl.urlHome()),
                      headers: {'Platform-Header': 'SCM'}),
                  initialOptions: options,
                  pullToRefreshController: pullToRefreshController,
                  onWebViewCreated: (controller) async {
                    webViewController = controller;
                    // controller.addJavaScriptHandler(
                    //     handlerName: 'handlerFoo',
                    //     callback: (args) {
                    //       // return data to the JavaScript side!
                    //       return {'bar': 'bar_value', 'baz': 'baz_value'};
                    //     });

                    // controller.addJavaScriptHandler(
                    //     handlerName: 'handlerFooWithArgs',
                    //     callback: (payload) {
                    //       payload = json.decode(payload.toString());
                    //       print("Reference Number : ${payload[0]['foo']}");
                    //       _showErrorSnack(
                    //           "Reference Number : " + payload[0]['foo']);
                    //       // it will print: [1, true, [bar, 5], {foo: baz}, {bar: bar_value, baz: baz_value}]
                    //     });
                    controller.addJavaScriptHandler(
                        handlerName: 'handlerPrint',
                        callback: (payload) {
                          payload = json.decode(payload.toString());
                          //print("Payload Print : $payload");
                          _printTransferReceipt(payload[0]['reference']);
                          // print(
                          //     "Reference Number : ${payload[0]['reference']}");
                          // _showErrorSnack(
                          //     "Reference Number : " + payload[0]['reference']);
                          // it will print: [1, true, [bar, 5], {foo: baz}, {bar: bar_value, baz: baz_value}]
                        });
                    controller.addJavaScriptHandler(
                        handlerName: 'printVA',
                        callback: (payload) {
                          payload = json.decode(payload.toString());
                          _printVirtualAccountReceipt(payload[0]['reference']);
                          //print("Payload Print : $payload");
                          //_printTransferReceipt(payload[0]['reference']);
                          // print(
                          //     "Reference Number : ${payload[0]['reference']}");
                          // _showErrorSnack(
                          //     "Reference Number : " + payload[0]['reference']);
                          // it will print: [1, true, [bar, 5], {foo: baz}, {bar: bar_value, baz: baz_value}]
                        });
                    controller.addJavaScriptHandler(
                        handlerName: 'printQRIS',
                        callback: (payload) {
                          payload = json.decode(payload.toString());
                          _printQRISreceipt(payload[0]['reference']);
                        });
                    controller.addJavaScriptHandler(
                        handlerName: 'refresh',
                        callback: (payload) {
                          payload = json.decode(payload.toString());
                          if (payload[0]['refresh']) {
                            _setCookie();
                          }
                          // print(
                          //     "Reference Number : ${payload[0]['reference']}");
                          // _showErrorSnack("Reference Number : " +
                          //     payload[0]['reference']);
                          // it will print: [1, true, [bar, 5], {foo: baz}, {bar: bar_value, baz: baz_value}]
                        });
                  },
                  onPrint: (controller, message) {
                    print("message :$message");
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  androidOnPermissionRequest:
                      (controller, origin, resources) async {
                    return PermissionRequestResponse(
                        resources: resources,
                        action: PermissionRequestResponseAction.GRANT);
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    var uri = navigationAction.request.url;

                    if (![
                      "http",
                      "https",
                      "file",
                      "chrome",
                      "data",
                      "javascript",
                      "about"
                    ].contains(uri.scheme)) {
                      if (await canLaunch(url)) {
                        // Launch the App
                        await launch(
                          url,
                        );
                        // and cancel the request
                        return NavigationActionPolicy.CANCEL;
                      }
                    }

                    return NavigationActionPolicy.ALLOW;
                  },
                  onLoadStop: (controller, url) async {
                    pullToRefreshController.endRefreshing();
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  onLoadError: (controller, url, code, message) {
                    pullToRefreshController.endRefreshing();
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      pullToRefreshController.endRefreshing();
                    }
                    setState(() {
                      this.progress = progress / 100;
                      urlController.text = this.url;
                    });
                  },
                  onUpdateVisitedHistory: (controller, url, androidIsReload) {
                    setState(() {
                      this.url = url.toString();
                      urlController.text = this.url;
                    });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    print(
                        "Message coming from the Dart side: ${consoleMessage.message}");
                  },
                ),
                progress < 1.0
                    ? LinearProgressIndicator(value: progress)
                    : Container(),
              ],
            ),
            /*WebviewScaffold(
          url: Config.links,
          withJavascript: true,
          userAgent: Config.userAgent,
          initialChild: Container(
            child: const Center(child: CircularProgressIndicator()),
          ),
          hidden: true,
          withLocalStorage: true,
          withLocalUrl: true,
          javascriptChannels: Set.from([
            JavascriptChannel(
                name: 'Print',
                onMessageReceived: (JavascriptMessage message) {
                  if (message.message == 'FlutterReload') {
                    print("Flutter Reload");
                    _setCookie();
                    //_controller?.reload();
                  } else if (message.message == 'FlutterGetBalance') {}
                }),
          ]),
                )),*/
          )),
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

//Model class to represent the message return by FCM
class MessageBean {
  MessageBean({this.itemId});
  final String itemId;

  StreamController<MessageBean> _controller =
      StreamController<MessageBean>.broadcast();
  Stream<MessageBean> get onChanged => _controller.stream;

  String _status;
  String get status => _status;
  set status(String value) {
    _status = value;
    _controller.add(this);
  }

  static final Map<String, Route<void>> routes = <String, Route<void>>{};
  Route<void> get route {
    final String routeName = '/detail/$itemId';
    return routes.putIfAbsent(
      routeName,
      () => MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (BuildContext context) => DetailPage(itemId),
      ),
    );
  }
}

//Detail UI screen that will display the content of the message return from FCM
class DetailPage extends StatefulWidget {
  DetailPage(this.itemId);
  final String itemId;
  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  MessageBean _item;
  StreamSubscription<MessageBean> _subscription;

  @override
  void initState() {
    super.initState();
    _item = _items[widget.itemId];
    _subscription = _item.onChanged.listen((MessageBean item) {
      if (!mounted) {
        _subscription.cancel();
      } else {
        setState(() {
          _item = item;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notification Detail"),
      ),
      body: Material(
        child: Center(child: Text("Test")
            /*WebviewScaffold(
          url: _item._status,
          withJavascript: true,
          userAgent: Config.userAgent,
        )*/
            ),
      ),
    );
  }
}
