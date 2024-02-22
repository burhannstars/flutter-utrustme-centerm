import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:cool_alert/cool_alert.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';
import 'package:gvmerchant_utrustme/config/config.dart';
import 'package:gvmerchant_utrustme/login_new.dart';
import 'package:gvmerchant_utrustme/network/network.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

final cryptor = new PlatformStringCryptor();
CookieManager cookieManager = CookieManager.instance();
BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

List<BluetoothDevice> _devices = [];
BluetoothDevice _device;
bool _connected = false;
String pathImage, ref_users, deviceID;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);

    var swAvailable = await AndroidWebViewFeature.isFeatureSupported(
        AndroidWebViewFeature.SERVICE_WORKER_BASIC_USAGE);
    var swInterceptAvailable = await AndroidWebViewFeature.isFeatureSupported(
        AndroidWebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);

    if (swAvailable && swInterceptAvailable) {
      AndroidServiceWorkerController serviceWorkerController =
          AndroidServiceWorkerController.instance();

      serviceWorkerController.serviceWorkerClient = AndroidServiceWorkerClient(
        shouldInterceptRequest: (request) async {
          return null;
        },
      );
    }
  }

  runApp(new KirimDana());
}

class KirimDana extends StatefulWidget {
  @override
  _KirimDanaState createState() => _KirimDanaState();
}

class _KirimDanaState extends State<KirimDana> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  //final flutterWebviewPlugin = new FlutterWebviewPlugin();

  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          userAgent: Config.userAgent,
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: true),
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

  @override
  void initState() {
    super.initState();
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
    /*CoolAlert.show(
        context: context,
        type: CoolAlertType.success,
        text: "Transaksi berhasil",
        barrierDismissible: false,
        title: "Success",
        showCancelBtn: true,
        cancelBtnText: "Keluar",
        confirmBtnText: "Print",
        onCancelBtnTap: () {
          Navigator.pop(context);
        },
        onConfirmBtnTap: () {
          Navigator.pop(context);
        });*/
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
    super.dispose();
  }

  void _setCookie() async {
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
    final PackageInfo info = await PackageInfo.fromPlatform();
    String versisekarang = info.version.toString();
    SharedPreferences prefs = await SharedPreferences.getInstance();

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
        await cookieManager.deleteAllCookies();
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

  void _showErrorSnack(String errorMsg) {
    final snackbar =
        SnackBar(content: Text(errorMsg, style: TextStyle(color: Colors.red)));

    _scaffoldKey.currentState.showSnackBar(snackbar);
    //throw Exception('Error Logging : $errorMsg');
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
            bluetooth.printCustom(merchantName.substring(0, 15), 3, 1);
            bluetooth.printCustom(merchantName.substring(15), 3, 1);
          } else {
            bluetooth.printCustom(merchantName, 3, 1);
          }
          bluetooth.printCustom(city, 2, 1);
          bluetooth.printNewLine();
          bluetooth.printCustom("TRANSFER BERHASIL", 2, 1);
          bluetooth.printNewLine();
          bluetooth.printLeftRight("Tanggal    : ", data['transfer_date'], 2);
          bluetooth.printLeftRight("Jam        : ", data['transfer_time'], 2);
          bluetooth.printLeftRight("NO REFF ", "", 2);
          bluetooth.printCustom(data['reference'], 2, 1);

          // bluetooth.writeBytes(
          //     Uint8List.fromList([0x1b, 0x61, 0x01])); //ESC_ALIGN_CENTER

          bluetooth.printCustom("--------------------------------", 2, 1);
          bluetooth.printCustom("TUJUAN", 2, 1);
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
          bluetooth.printCustom("NAMA     : " + data['receiver_name'], 2, 0);
          bluetooth.printCustom("REKENING : " + data['receiver_number'], 2, 0);
          bluetooth.printCustom("BANK     : " + data['bank'], 2, 0);
          bluetooth.printCustom("JUMLAH   : " + data['amount'], 2, 0);
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
      } else {
        CoolAlert.show(
            context: context,
            type: CoolAlertType.warning,
            text: data['message'],
            barrierDismissible: false,
            title: "Informasi",
            showCancelBtn: false,
            confirmBtnText: "OK",
            onConfirmBtnTap: () {
              Navigator.pop(context);
            });
      }
    }
  }

  var currentColor = Color.fromRGBO(231, 129, 109, 1.0);
  @override
  Widget build(BuildContext context) {
    /*return WillPopScope(
      onWillPop: () {
        Navigator.pop(context);
      },
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
            "Kirim Uang",
            style: TextStyle(fontSize: 16.0),
          ),
          centerTitle: true,
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
                        flutterWebviewPlugin?.reload();
                      },
                    ),
                  ],
                )),
          ],
          elevation: 0.0,
        ),
        body: SafeArea(
            child: WebviewScaffold(
          url: NetworkUrl.urlTransferDana(),
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
                    //print("Flutter Reload");
                    _setCookie();
                    //_controller?.reload();
                  } else if (message.message == 'FlutterGetBalance') {}
                }),
          ]),
        )),
      ),
    );*/
    return WillPopScope(
      onWillPop: () async => false,
      child: MaterialApp(
        home: Scaffold(
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
                "Transfer Uang",
                style: TextStyle(fontSize: 16.0),
              ),
              centerTitle: true,
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
                            webViewController?.reload();
                          },
                        ),
                      ],
                    )),
              ],
            ),
            body: SafeArea(
                child: Column(children: <Widget>[
              Expanded(
                child: Stack(
                  children: [
                    InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(
                          url: Uri.parse(NetworkUrl.urlTransferDana()),
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

                        controller.addJavaScriptHandler(
                            handlerName: 'handlerFooWithArgs',
                            callback: (payload) {
                              payload = json.decode(payload.toString());
                              // print("Reference Number : ${payload[0]['foo']}");
                              // _showErrorSnack(
                              //     "Reference Number : " + payload[0]['foo']);
                              // it will print: [1, true, [bar, 5], {foo: baz}, {bar: bar_value, baz: baz_value}]
                            });
                        controller.addJavaScriptHandler(
                            handlerName: 'handlerPrint',
                            callback: (payload) {
                              payload = json.decode(payload.toString());
                              _printTransferReceipt(payload[0]['reference']);
                              // print(
                              //     "Reference Number : ${payload[0]['reference']}");
                              // _showErrorSnack("Reference Number : " +
                              //     payload[0]['reference']);
                              // it will print: [1, true, [bar, 5], {foo: baz}, {bar: bar_value, baz: baz_value}]
                            });
                        controller.addJavaScriptHandler(
                            handlerName: 'refresh',
                            callback: (payload) {
                              payload = json.decode(payload.toString());
                              if (payload[0]['refresh']) {
                                _setCookie();
                              }
                            });
                        if (!Platform.isAndroid ||
                            await AndroidWebViewFeature.isFeatureSupported(
                                AndroidWebViewFeature.WEB_MESSAGE_LISTENER)) {
                          await controller
                              .addWebMessageListener(WebMessageListener(
                            jsObjectName: "Print",
                            onPostMessage: (message, sourceOrigin, isMainFrame,
                                replyProxy) {
                              // do something about message, sourceOrigin and isMainFrame.
                              if (message == "FlutterReload") {
                                _setCookie();
                                //print("Flutter Reload");
                                //webViewController?.reload();
                                //_showErrorSnack("Test");
                              }
                              //replyProxy.postMessage("Got it!");
                            },
                          ));
                        }
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
                      onUpdateVisitedHistory:
                          (controller, url, androidIsReload) {
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
              ),
              // ButtonBar(
              //   alignment: MainAxisAlignment.center,
              //   children: <Widget>[
              //     ElevatedButton(
              //       child: Icon(Icons.arrow_back),
              //       onPressed: () {
              //         webViewController?.goBack();
              //       },
              //     ),
              //     ElevatedButton(
              //       child: Icon(Icons.arrow_forward),
              //       onPressed: () {
              //         webViewController?.goForward();
              //       },
              //     ),
              //     ElevatedButton(
              //       child: Icon(Icons.refresh),
              //       onPressed: () {
              //         webViewController?.reload();
              //       },
              //     ),
              //   ],
              // ),
            ]))),
      ),
    );
  }
}
