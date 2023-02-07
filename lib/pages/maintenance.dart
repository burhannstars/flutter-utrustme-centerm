import 'package:flutter/material.dart';
import 'package:gvmerchant_utrustme/config/config.dart';
import 'package:url_launcher/url_launcher.dart';

class MaintenancePage extends StatefulWidget {
  @override
  _MaintenancePageState createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget _showForm() {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              //showLogo(),
              showDescription(),
              //showPrimaryButton(),
            ],
          ),
        ));
  }

  Widget showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 70.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 48.0,
          child: Image.asset('assets/images/splash.png'),
        ),
      ),
    );
  }

  Widget showDescription() {
    return Padding(
        padding: const EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0),
        child: new Text(
            "Aplikasi sedang dalam maintenance, silahkan coba beberapa saat lagi atau hubungi kami."));
  }

  Widget showPrimaryButton() {
    return new Padding(
        padding: EdgeInsets.only(top: 150.0),
        child: SizedBox(
          height: 40.0,
          child: new RaisedButton(
            hoverColor: Colors.red,
            elevation: 5.0,
            shape: new RoundedRectangleBorder(
                borderRadius: new BorderRadius.circular(10.0)),
            color: Colors.blue,
            child: new Text('UPDATE',
                style: new TextStyle(fontSize: 20.0, color: Colors.white)),
            onPressed: () {
              _launchURL(Config.PLAY_STORE_URL);
            },
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: Stack(
      children: <Widget>[
        _showForm(),
      ],
    ));
  }
}
