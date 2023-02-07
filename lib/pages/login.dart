import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gvmerchant_utrustme/config/config.dart';
import 'package:gvmerchant_utrustme/pages/frontMenu.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter_string_encryption/flutter_string_encryption.dart';
import 'package:package_info/package_info.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

final cryptor = new PlatformStringCryptor();
var fcmToken;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    initialFormValues();
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

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting, _obscureText = true;

  TextEditingController usernameController = new TextEditingController();
  TextEditingController passwordController = new TextEditingController();
  String username, password;
  bool isChecked = true;
  String checkedValue;
  String savedUsername2 = "";
  Widget _showTitle() {
    return Text('Merchant Access',
        style: Theme.of(context).textTheme.headline1);
  }

  Widget _showUsernameInput() {
    return Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: TextFormField(
          controller: usernameController,
          onSaved: (val) => username = val,
          validator: (val) =>
              val.length == 0 ? 'Harap masukkan username' : null,
          decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Username',
              hintText: 'Enter your valid GV Username',
              icon: Icon(Icons.mail, color: Colors.grey)),
        ));
  }

  Widget _showPasswordInput() {
    return Padding(
        padding: EdgeInsets.only(top: 20.0),
        child: TextFormField(
          onSaved: (val) => password = val,
          validator: (val) =>
              val.length == 0 ? 'Harap masukkan password' : null,
          obscureText: _obscureText,
          decoration: InputDecoration(
              suffixIcon: GestureDetector(
                  onTap: () {
                    setState(() => _obscureText = !_obscureText);
                  },
                  child: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off)),
              border: OutlineInputBorder(),
              labelText: 'Password',
              hintText: 'Enter password, min length 6',
              icon: Icon(Icons.lock, color: Colors.grey)),
        ));
  }

  Widget _showRememberMe() {
    return Padding(
        padding: EdgeInsets.only(top: 20.0, left: 10.0),
        child: CheckboxListTile(
          title: Text("Simpan informasi login"),
          value: isChecked,
          onChanged: (newValue) {
            setState(() {
              isChecked = newValue;
            });
          },
          controlAffinity:
              ListTileControlAffinity.leading, //  <-- leading Checkbox
        ));
  }

  Widget _showFormAction() {
    return Padding(
        padding: EdgeInsets.all(30.0),
        child: Column(children: [
          _isSubmitting == true
              ? CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation(Theme.of(context).accentColor),
                )
              : RaisedButton(
                  child: Text('Login'),
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0))),
                  color: Color.fromRGBO(231, 129, 109, 1.0),
                  onPressed: _submit),
          FlatButton(
              child: Text('Forgot Password ?'),
              onPressed: () {
                _launchURL(Config.forgetPassword);
              })
        ]));
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
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

  Widget loginForm() {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _showTitle(),
                  _showUsernameInput(),
                  _showPasswordInput(),
                  _showRememberMe(),
                  _showFormAction()
                ],
              ),
            ),
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
    }
  }

  void _login() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
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
          'TOKEN': "SCM_DEVICE",
          'APP_VERSION': versisekarang
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
        Navigator.of(context).pushReplacement(new MaterialPageRoute(
            builder: (BuildContext context) => FrontMenu()));
      });
    } else {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorSnack("Login Gagal");
    }
  }

  @override
  Widget build(BuildContext context) {
    return loginForm();
  }
}
