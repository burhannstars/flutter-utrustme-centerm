import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info/device_info.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gvmerchant_utrustme/config/config.dart';
import 'package:gvmerchant_utrustme/otp_page.dart';
import 'package:gvmerchant_utrustme/pages/frontMenu.dart';
import 'package:gvmerchant_utrustme/utilities/constant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter/services.dart';
import 'package:rounded_loading_button/rounded_loading_button.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const String flutterUrl = 'https://flutter.io/';
  static const String githubUrl = 'http://www.codesnippettalk.com';
  static const TextStyle linkStyle = const TextStyle(
    color: Colors.blue,
    decoration: TextDecoration.underline,
  );

  TapGestureRecognizer _flutterTapRecognizer;
  TapGestureRecognizer _githubTapRecognizer;
  final cryptor = new PlatformStringCryptor();
  var fcmToken;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting, _obscureText = true;
  final RoundedLoadingButtonController _btnController =
      new RoundedLoadingButtonController();

  TextEditingController usernameController = new TextEditingController();
  TextEditingController passwordController = new TextEditingController();
  String username, password, deviceID;
  bool isChecked = true;
  String checkedValue;
  String savedUsername2 = "";

  @override
  void initState() {
    super.initState();
    initialFormValues();
    _flutterTapRecognizer = new TapGestureRecognizer()
      ..onTap =
          () => _openUrl("https://www.gudangvoucher.com/merchant/register");
    _githubTapRecognizer = new TapGestureRecognizer()
      ..onTap = () => _openUrl(githubUrl);
    // _firebaseMessaging.requestNotificationPermissions(
    //     const IosNotificationSettings(sound: true, badge: true, alert: true));
    // _firebaseMessaging.onIosSettingsRegistered
    //     .listen((IosNotificationSettings settings) {});
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    usernameController.dispose();
    passwordController.dispose();
  }

  Future<void> initialFormValues() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    //print(prefs.getString('savedUsername'));
    var savedUsername3 = prefs.getString('savedUsername');
    setState(() {
      usernameController.text = "";
      usernameController.text = savedUsername3;
      usernameController = TextEditingController(text: savedUsername3);
    });
    //print("Saved Username : $usernameController");
  }

  void _showErrorSnack(String errorMsg) {
    final snackbar =
        SnackBar(content: Text(errorMsg, style: TextStyle(color: Colors.red)));

    _scaffoldKey.currentState.showSnackBar(snackbar);
    //throw Exception('Error Logging : $errorMsg');
  }

  void _showSuccessSnack(String errorMsg) {
    final snackbar = SnackBar(
        content: Text(errorMsg, style: TextStyle(color: Colors.green)));

    _scaffoldKey.currentState.showSnackBar(snackbar);
    //throw Exception('Error Logging : $errorMsg');
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _openUrl(String url) async {
    // Close the about dialog.
    Navigator.pop(context);

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _buildUsernameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Username',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextFormField(
            controller: usernameController,
            onSaved: (val) => username = val,
            validator: (val) =>
                val.length == 0 ? 'Harap masukkan username' : null,
            keyboardType: TextInputType.text,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              errorStyle: kHintErrorStyle,
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.person,
                color: Colors.white,
              ),
              hintText: 'Masukkan username GV Merchant anda',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Password',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: kBoxDecorationStyle,
          height: 60.0,
          child: TextFormField(
            onSaved: (val) => password = val,
            validator: (val) =>
                val.length == 0 ? 'Harap masukkan password' : null,
            obscureText: _obscureText,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() => _obscureText = !_obscureText);
                  },
                  child: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off)),
              errorStyle: kHintErrorStyle,
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.lock,
                color: Colors.white,
              ),
              hintText: 'Masukkan password anda',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordBtn() {
    return Container(
      alignment: Alignment.centerRight,
      child: FlatButton(
        onPressed: () {
          _launchURL(Config.forgetPassword);
        },
        padding: EdgeInsets.only(right: 0.0),
        child: Text(
          'Lupa Password?',
          style: kLabelStyle,
        ),
      ),
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Container(
      height: 20.0,
      child: Row(
        children: <Widget>[
          Theme(
            data: ThemeData(unselectedWidgetColor: Colors.white),
            child: Checkbox(
              value: isChecked,
              checkColor: Colors.green,
              activeColor: Colors.white,
              onChanged: (value) {
                setState(() {
                  isChecked = value;
                });
              },
            ),
          ),
          Text(
            'Simpan username',
            style: kLabelStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildLoginBtn() {
    return Container(
        padding: EdgeInsets.symmetric(vertical: 25.0),
        width: double.infinity,
        child:
            /*_isSubmitting == true
          ? CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Theme.of(context).accentColor),
            )
          : RaisedButton(
              elevation: 5.0,
              onPressed: _submit,
              padding: EdgeInsets.all(15.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              color: Colors.white,
              child: Text(
                'LOGIN',
                style: TextStyle(
                  color: Color(0xFF527DAA),
                  letterSpacing: 1.5,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'OpenSans',
                ),
              ),
            ),*/
            RoundedLoadingButton(
          color: Colors.white,
          valueColor: Colors.redAccent,
          elevation: 5.0,
          child: Text(
            'LOGIN',
            style: TextStyle(
              color: Color(0xFF527DAA),
              letterSpacing: 1.5,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              fontFamily: 'OpenSans',
            ),
          ),
          controller: _btnController,
          onPressed: _submit,
        ));
  }

  Widget _buildSignInWithText() {
    return Column(
      children: <Widget>[
        Text(
          '- ATAU -',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 25.0),
          width: double.infinity,
          child: RaisedButton(
            elevation: 5.0,
            onPressed: () {
              //_launchURL("https://www.gudangvoucher.com/merchant/register/");
              showDialog(
                context: context,
                builder: (BuildContext context) => _buildAboutDialog(context),
              );
            },
            padding: EdgeInsets.all(15.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            color: Colors.white,
            child: Text(
              'DAFTAR',
              style: TextStyle(
                color: Color(0xFF527DAA),
                letterSpacing: 1.5,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                fontFamily: 'OpenSans',
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildAboutDialog(BuildContext context) {
    return new AlertDialog(
      title: const Text('Pendaftaran'),
      content: new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildAboutText(),
          _buildLogoAttribution(),
        ],
      ),
      actions: <Widget>[
        new FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          textColor: Theme.of(context).primaryColor,
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildAboutText() {
    return new RichText(
      text: new TextSpan(
        text:
            'Saat ini pendaftaran merchant hanya dapat dilakukan melalui Merchant Acquirer kami\n\n',
        style: const TextStyle(color: Colors.black87),
        children: <TextSpan>[
          const TextSpan(
              text:
                  'Untuk mencari Merchant Acquirer terdekat, silahkan kunjungi '),
          new TextSpan(
            text: 'www.gudangvoucher.com/merchant/register',
            recognizer: _flutterTapRecognizer,
            style: linkStyle,
          ),
          const TextSpan(
            text: ' atau dapat menghubungi Customer Service kami, di nomor '
                '021-725-4654 ',
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _buildLogoAttribution() {
    return new Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.only(top: 0.0),
            child: new Image.asset(
              "assets/images/qris.png",
              width: 200.0,
            ),
          ),
          /*const Expanded(
            child: const Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: const Text(
                'Popup window is like a dialog box that gains complete focus when it appears on screen.',
                style: const TextStyle(fontSize: 12.0),
              ),
            ),
          ),*/
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: <Widget>[
              Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.lightBlue, Colors.redAccent],
                    stops: [0.5, 1.0],
                  ),
                ),
              ),
              Container(
                height: double.infinity,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 120.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Selamat Datang, \nAgen uTRUSTme - GV',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'OpenSans',
                              fontSize: 25.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 30.0),
                        _buildUsernameTF(),
                        SizedBox(
                          height: 30.0,
                        ),
                        _buildPasswordTF(),
                        _buildForgotPasswordBtn(),
                        _buildRememberMeCheckbox(),
                        _buildLoginBtn(),
                        //_buildSignInWithText(),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      _login();
    } else {
      _btnController.stop();
    }
  }

  void _login() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
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
        deviceID = fcmToken;
      });
    }
    String versisekarang = info.version.toString();
    final String encrypted =
        await cryptor.encrypt(password, Config.encryptionKey);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSubmitting = true;
    });
    var username2 = utf8.encode(username);
    var password2 = utf8.encode(password);
    var mrckey = utf8.encode(Config.mrcKey);
    var sign = sha1.convert(username2 + password2 + mrckey);
    final response = await http.post(Config.baseUrl,
        body: json.encode({
          'USR': username,
          'PWD': password,
          'SIGN': sign.toString(),
          'TOKEN': "SCM_DEVICE_NEXGO",
          'APP_VERSION': versisekarang,
          'DEVICE_ID': deviceID,
          'REQUEST_TYPE': "NEW_LOGIN"
        }));
    //print("USR $username | PWD : $password | SIGN "+sign.toString() +" | TOKEN $fcmToken");
    final data = json.decode(response.body);
    if (data['status'] == 0) {
      if (isChecked) {
        prefs.setString('savedUsername', username);
      } else {
        prefs.remove('savedUsername');
      }
      setState(() {
        _isSubmitting = false;
        prefs.setBool('login', true);
        prefs.setString('U', data['U']);
        prefs.setString('S', data['S']);
        prefs.setString('I', data['I']);
        prefs.setString('_key', encrypted);
        prefs.setString('merchantName', data['MerchantName']);
        prefs.setString('emailMerchant', data['EmailMerchant']);
        prefs.setString('city', data['City']);
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
      Future.delayed(Duration(seconds: 2), () {
        _btnController.success();
        Navigator.of(context).pushReplacement(new MaterialPageRoute(
            builder: (BuildContext context) => FrontMenu()));
      });
    } else if (data['status'] == 4) {
      if (isChecked) {
        prefs.setString('savedUsername', username);
      } else {
        prefs.remove('savedUsername');
      }

      prefs.setString('_key', encrypted);
      Future.delayed(Duration(seconds: 2), () {
        _btnController.success();
        Navigator.of(context).pushReplacement(new MaterialPageRoute(
            builder: (BuildContext context) => Otp(ref_users: data['I'])));
      });
    } else {
      _btnController.stop();
      setState(() {
        _isSubmitting = false;
      });
      _showErrorSnack("Login Gagal");
    }
  }
}
