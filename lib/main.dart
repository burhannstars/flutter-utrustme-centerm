import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:flutter/services.dart';
import 'package:gvmerchant_utrustme/config/config.dart';
import 'package:gvmerchant_utrustme/login_new.dart';
import 'package:gvmerchant_utrustme/pages/frontMenu.dart';
import 'package:gvmerchant_utrustme/pages/home.dart';
import 'package:gvmerchant_utrustme/pages/maintenance.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

var logStatus = false;
var users_token;
String deviceID;
final cryptor = new PlatformStringCryptor();
CookieManager cookieManager = CookieManager.instance();

void main() {
  runApp(
    MaterialApp(
        home: MyApp(),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            // Draw all modals with a white background and top rounded corners
            bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: Colors.transparent,
          /*shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(10)))*/
        ))),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var url, title, body, cookie, ref_users, link;
  final GlobalKey _scaffoldKey = new GlobalKey();

  @override
  void initState() {
    super.initState();
    startSplashScreenTimer();
  }

  void navigationToNextPage() {
    Navigator.of(context).pushReplacement(new MaterialPageRoute(
        builder: (BuildContext context) => LoadingPage()));
  }

  startSplashScreenTimer() async {
    var _duration = new Duration(seconds: 5);
    return new Timer(_duration, navigationToNextPage);
  }

  @override
  Widget build(BuildContext context) {
    //SystemChrome.setEnabledSystemUIOverlays([]);
    /*return Scaffold(
      key: _scaffoldKey,
      body: new SplashScreen(
          seconds: 2,
          //navigateAfterSeconds: LoadingPage(),
          /*title: new Text(
            'Welcome',
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
          ),*/
          image: new Image.asset('assets/images/splash2.png'),
          backgroundColor: Colors.white,
          styleTextUnderTheLoader: new TextStyle(),
          photoSize: 100.0,
          loaderColor: Colors.blue),
    );*/
    /*return MaterialApp(
        title: 'Clean Code',
        home: AnimatedSplashScreen(
            duration: 1000000,
            splash: 'assets/images/splash2.png',
            nextScreen: LoadingPage(),
            splashTransition: SplashTransition.fadeTransition,
            pageTransitionType: PageTransitionType.scale,
            backgroundColor: Colors.blue));*/
    /*return Container(
        color: Colors.white,
        child: new Image.asset('assets/images/splash_SCM.png', fit: BoxFit.fill));*/
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(color: Colors.white),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Container(
                  child: Image.asset('assets/images/splash_SCM.png',
                      fit: BoxFit.fill),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    CircularProgressIndicator(),
                    Padding(
                      padding: EdgeInsets.only(top: 20.0),
                    ),
                    Text(
                      "Welcome",
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                          color: Colors.black),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}

class LoadingPage extends StatefulWidget {
  @override
  _LoadingPageState createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  String deviceid;

  versionCheck(context) async {
    try {
      // Using default duration to force fetching from remote server.
      final response = await http.post(Config.cekMaintenance,
          body: json.encode({
            'SIGN': Config.mrcKey,
          }));
      final data = json.decode(response.body);

      int versi = data['status'];
      //double newVersion = double.parse(versi.trim().replaceAll(".", ""));
      if (versi == 1) {
        Navigator.of(context).pushReplacement(new MaterialPageRoute(
            builder: (BuildContext context) => MaintenancePage()));
      } else {
        _getPrefs();
      }
    } catch (exception) {
      print(
          'Unable to fetch remote config. Cached or default values will be used');
    }
  }

  void _getPrefs() async {
    //print("Get Prefs");
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
        deviceID = "SCM_DEVICE_NEXGO";
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
      setState(() {
        logStatus = true;
      });
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
          prefs.setString('merchantName', data['MerchantName']);
        });

        //print("Merchant Name : $merchantName");

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
        Navigator.of(context).pushReplacement(new MaterialPageRoute(
            builder: (BuildContext context) => FrontMenu()));
      } else {
        setState(() {
          prefs.remove('login');
          prefs.remove('U');
          prefs.remove('S');
          prefs.remove('I');
          prefs.remove('_key');
          prefs.remove('merchantName');
          logStatus = false;
        });
        await cookieManager.deleteAllCookies();
        Navigator.of(context).pushReplacement(new MaterialPageRoute(
            builder: (BuildContext context) => LoginPage()));
      }
    } else {
      setState(() {
        prefs.remove('login');
        prefs.remove('U');
        prefs.remove('S');
        prefs.remove('I');
        prefs.remove('_key');
        prefs.remove('merchantName');
        logStatus = false;
      });
      await cookieManager.deleteAllCookies();
      Navigator.of(context).pushReplacement(new MaterialPageRoute(
          builder: (BuildContext context) => LoginPage()));
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //_getPrefs();
    versionCheck(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (c, w) {
        ScreenUtil.instance =
            ScreenUtil(width: 750, height: 1334, allowFontScaling: true)
              ..init(c);
        var data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(textScaleFactor: 1.0),
          child: Scaffold(
            body: w,
          ),
        );
      },
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
