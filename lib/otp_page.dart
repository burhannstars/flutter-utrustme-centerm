import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_overlay_loader/flutter_overlay_loader.dart';
import 'package:gvmerchant_utrustme/config/config.dart';
import 'package:gvmerchant_utrustme/network/network.dart';
import 'package:gvmerchant_utrustme/pages/frontMenu.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Otp extends StatefulWidget {
  final String ref_users;

  const Otp({
    Key key,
    @required this.ref_users,
  }) : super(key: key);

  @override
  _OtpState createState() => new _OtpState();
}

class _OtpState extends State<Otp> with SingleTickerProviderStateMixin {
  // Constants
  final int time = 300;
  AnimationController _controller;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // Variables
  Size _screenSize;
  int _currentDigit;
  int _firstDigit;
  int _secondDigit;
  int _thirdDigit;
  int _fourthDigit;

  Timer timer;
  int totalTimeInSeconds;
  bool _hideResendButton;

  String userName = "", deviceID;
  bool didReadNotifications = false;
  int unReadNotificationsCount = 0;
  bool isOTPwrong = false;

  // Returns "Appbar"
  get _getAppbar {
    return new AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      /*leading: new InkWell(
        borderRadius: BorderRadius.circular(30.0),
        child: new Icon(
          Icons.arrow_back,
          color: Colors.black54,
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),*/
      centerTitle: true,
      /*title: Text("Login Perangkat Baru",
          style: new TextStyle(
              fontSize: 28.0,
              color: Colors.black,
              fontWeight: FontWeight.bold)),*/
    );
  }

  // Return "Verification Code" label
  get _getVerificationCodeLabel {
    return new Text(
      "Verifikasi Login Perangkat Baru",
      textAlign: TextAlign.center,
      style: new TextStyle(
          fontSize: 20.0, color: Colors.black, fontWeight: FontWeight.bold),
    );
  }

  // Return "Email" label
  get _getEmailLabel {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: new Text(
        "Masukkan kode OTP \nyang dikirimkan ke email Anda.",
        textAlign: TextAlign.center,
        style: new TextStyle(
            fontSize: 15.0, color: Colors.black, fontWeight: FontWeight.w600),
      ),
    );
  }

  // Return "OTP" input field
  get _getInputField {
    return new Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _otpTextField(_firstDigit),
        _otpTextField(_secondDigit),
        _otpTextField(_thirdDigit),
        _otpTextField(_fourthDigit),
      ],
    );
  }

  // Returns "OTP" input part
  get _getInputPart {
    return new Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _getVerificationCodeLabel,
        _getEmailLabel,
        _getInputField,
        _hideResendButton ? _getTimerText : _getResendButton,
        _getOtpKeyboard
      ],
    );
  }

  // Returns "Timer" label
  get _getTimerText {
    return Container(
      height: 32,
      child: new Offstage(
        offstage: !_hideResendButton,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Icon(Icons.access_time),
            new SizedBox(
              width: 5.0,
            ),
            OtpTimer(_controller, 15.0, Colors.black)
          ],
        ),
      ),
    );
  }

  // Returns "Resend" button
  get _getResendButton {
    return new InkWell(
      child: new Container(
        height: 32,
        width: 120,
        decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(32)),
        alignment: Alignment.center,
        child: new Text(
          "Kirim ulang OTP",
          style:
              new TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      onTap: () {
        // Resend you OTP via API or anything
        //_startCountdown();
        resendOTP();
      },
    );
  }

  void resendOTP() async {
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
    var ref_users = utf8.encode(this.widget.ref_users);
    var device = utf8.encode(deviceID);
    var mrckey = utf8.encode(Config.mrcKey);
    var sign = sha1.convert(ref_users + device + mrckey);
    final response = await http.post(NetworkUrl.resendOTP(),
        body: json.encode({
          'REF_USERS': this.widget.ref_users,
          'SIGN': sign.toString(),
          'DEVICE_ID': deviceID,
          'REQUEST_TYPE': "NEW_LOGIN"
        }));
    final data = json.decode(response.body);
    print("Data Resend OTP : $data");
    if (data['status'] == 0) {
      _startCountdown();
    } else {
      _showErrorSnack("Gagal mengirim ulang OTP");
    }
  }

  // Returns "Otp" keyboard
  get _getOtpKeyboard {
    return new Container(
        height: _screenSize.width - 80,
        child: new Column(
          children: <Widget>[
            new Expanded(
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _otpKeyboardInputButton(
                      label: "1",
                      onPressed: () {
                        _setCurrentDigit(1);
                      }),
                  _otpKeyboardInputButton(
                      label: "2",
                      onPressed: () {
                        _setCurrentDigit(2);
                      }),
                  _otpKeyboardInputButton(
                      label: "3",
                      onPressed: () {
                        _setCurrentDigit(3);
                      }),
                ],
              ),
            ),
            new Expanded(
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _otpKeyboardInputButton(
                      label: "4",
                      onPressed: () {
                        _setCurrentDigit(4);
                      }),
                  _otpKeyboardInputButton(
                      label: "5",
                      onPressed: () {
                        _setCurrentDigit(5);
                      }),
                  _otpKeyboardInputButton(
                      label: "6",
                      onPressed: () {
                        _setCurrentDigit(6);
                      }),
                ],
              ),
            ),
            new Expanded(
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _otpKeyboardInputButton(
                      label: "7",
                      onPressed: () {
                        _setCurrentDigit(7);
                      }),
                  _otpKeyboardInputButton(
                      label: "8",
                      onPressed: () {
                        _setCurrentDigit(8);
                      }),
                  _otpKeyboardInputButton(
                      label: "9",
                      onPressed: () {
                        _setCurrentDigit(9);
                      }),
                ],
              ),
            ),
            new Expanded(
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new SizedBox(
                    width: 80.0,
                  ),
                  _otpKeyboardInputButton(
                      label: "0",
                      onPressed: () {
                        _setCurrentDigit(0);
                      }),
                  _otpKeyboardActionButton(
                      label: new Icon(
                        Icons.backspace,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_fourthDigit != null) {
                            _fourthDigit = null;
                          } else if (_thirdDigit != null) {
                            _thirdDigit = null;
                          } else if (_secondDigit != null) {
                            _secondDigit = null;
                          } else if (_firstDigit != null) {
                            _firstDigit = null;
                          }
                          isOTPwrong = false;
                        });
                      }),
                ],
              ),
            ),
          ],
        ));
  }

  // Overridden methods
  @override
  void initState() {
    totalTimeInSeconds = time;
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: time))
          ..addStatusListener((status) {
            if (status == AnimationStatus.dismissed) {
              setState(() {
                _hideResendButton = !_hideResendButton;
              });
            }
          });
    _controller.reverse(
        from: _controller.value == 0.0 ? 1.0 : _controller.value);
    _startCountdown();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;
    return new Scaffold(
      key: _scaffoldKey,
      appBar: _getAppbar,
      backgroundColor: Colors.white,
      body: new Container(
        width: _screenSize.width,
//        padding: new EdgeInsets.only(bottom: 16.0),
        child: _getInputPart,
      ),
    );
  }

  // Returns "Otp custom text field"
  Widget _otpTextField(int digit) {
    return new Container(
      width: 35.0,
      height: 45.0,
      alignment: Alignment.center,
      child: new Text(
        digit != null ? digit.toString() : "",
        style: new TextStyle(
          fontSize: 30.0,
          color: Colors.black,
        ),
      ),
      decoration: BoxDecoration(
//            color: Colors.grey.withOpacity(0.4),
          border: Border(
              bottom: BorderSide(
        width: 2.0,
        color: isOTPwrong ? Colors.red : Colors.black,
      ))),
    );
  }

  // Returns "Otp keyboard input Button"
  Widget _otpKeyboardInputButton({String label, VoidCallback onPressed}) {
    return new Material(
      color: Colors.transparent,
      child: new InkWell(
        onTap: onPressed,
        borderRadius: new BorderRadius.circular(40.0),
        child: new Container(
          height: 80.0,
          width: 80.0,
          decoration: new BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: new Center(
            child: new Text(
              label,
              style: new TextStyle(
                fontSize: 30.0,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorSnack(String errorMsg) {
    final snackbar =
        SnackBar(content: Text(errorMsg, style: TextStyle(color: Colors.red)));

    _scaffoldKey.currentState.showSnackBar(snackbar);
    //throw Exception('Error Logging : $errorMsg');
  }

  // Returns "Otp keyboard action Button"
  _otpKeyboardActionButton({Widget label, VoidCallback onPressed}) {
    return new InkWell(
      onTap: onPressed,
      borderRadius: new BorderRadius.circular(40.0),
      child: new Container(
        height: 80.0,
        width: 80.0,
        decoration: new BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: new Center(
          child: label,
        ),
      ),
    );
  }

  // Current digit
  void _setCurrentDigit(int i) {
    setState(() {
      _currentDigit = i;
      if (_firstDigit == null) {
        _firstDigit = _currentDigit;
      } else if (_secondDigit == null) {
        _secondDigit = _currentDigit;
      } else if (_thirdDigit == null) {
        _thirdDigit = _currentDigit;
      } else if (_fourthDigit == null) {
        _fourthDigit = _currentDigit;

        var otp = _firstDigit.toString() +
            _secondDigit.toString() +
            _thirdDigit.toString() +
            _fourthDigit.toString();

        // Verify your otp by here. API call
        print("Input Code : $otp");
        Loader.show(context,
            isSafeAreaOverlay: true,
            isBottomBarOverlay: true,
            overlayFromBottom: 80,
            overlayColor: Colors.black26,
            isAppbarOverlay: true,
            progressIndicator: CircularProgressIndicator(
              backgroundColor: Colors.red,
            ),
            themeData: Theme.of(context).copyWith(accentColor: Colors.green));
        submitOtp(otp);
      }
    });
  }

  Future<Null> _startCountdown() async {
    setState(() {
      _hideResendButton = true;
      totalTimeInSeconds = time;
    });
    _controller.reverse(
        from: _controller.value == 0.0 ? 1.0 : _controller.value);
  }

  void clearOtp() {
    _fourthDigit = null;
    _thirdDigit = null;
    _secondDigit = null;
    _firstDigit = null;
    setState(() {});
  }

  void submitOtp(String otpcode) async {
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
    var ref_users = utf8.encode(this.widget.ref_users);
    var device = utf8.encode(deviceID);
    var mrckey = utf8.encode(Config.mrcKey);
    var sign = sha1.convert(ref_users + device + mrckey);
    final response = await http.post(Uri.parse(NetworkUrl.checkOTP()),
        body: json.encode({
          'REF_USERS': this.widget.ref_users,
          'SIGN': sign.toString(),
          'DEVICE_ID': deviceID,
          'OTP_CODE': otpcode
        }));
    //print("USR $username | PWD : $password | SIGN "+sign.toString() +" | TOKEN $fcmToken");
    final data = json.decode(response.body);
    print("Data SUBMIT OTP : $data");
    if (data['status'] == 0) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        prefs.setBool('login', true);
        prefs.setString('U', data['U']);
        prefs.setString('S', data['S']);
        prefs.setString('I', data['I']);
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
          isSecure: true);
      await cookieManager.setCookie(
          url: Uri.parse(Config.links),
          name: "U",
          value: data['U'],
          domain: "www.gudangvoucher.com",
          isSecure: true);
      await cookieManager.setCookie(
          url: Uri.parse(Config.links),
          name: "S",
          value: data['S'],
          domain: "www.gudangvoucher.com",
          isSecure: true);
      Future.delayed(Duration(seconds: 2), () {
        Loader.hide();
        Navigator.of(context).pushReplacement(new MaterialPageRoute(
            builder: (BuildContext context) => FrontMenu()));
      });
      print("Sukses");
    } else if (data['status'] == 1) {
      Loader.hide();
      _showErrorSnack("OTP tidak ditemukan atau sudah expired");
      setState(() {
        isOTPwrong = true;
      });
    } else if (data['status'] == 2) {
      Loader.hide();
      _showErrorSnack("kode OTP tidak sesuai");
      setState(() {
        isOTPwrong = true;
      });
    } else {
      _showErrorSnack("Invalid Parameter!");
    }
  }
}

class OtpTimer extends StatelessWidget {
  final AnimationController controller;
  double fontSize;
  Color timeColor = Colors.black;

  OtpTimer(this.controller, this.fontSize, this.timeColor);

  String get timerString {
    Duration duration = controller.duration * controller.value;
    if (duration.inHours > 0) {
      return '${duration.inHours}:${duration.inMinutes % 60}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    return '${duration.inMinutes % 60}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Duration get duration {
    Duration duration = controller.duration;
    return duration;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget child) {
          return new Text(
            timerString,
            style: new TextStyle(
                fontSize: fontSize,
                color: timeColor,
                fontWeight: FontWeight.w600),
          );
        });
  }
}
