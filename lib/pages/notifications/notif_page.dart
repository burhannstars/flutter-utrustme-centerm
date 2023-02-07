import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:gvmerchant_utrustme/config/config.dart';
import 'package:gvmerchant_utrustme/model/notifModel.dart';
import 'package:gvmerchant_utrustme/model/qrisnotifModel.dart';
import 'package:gvmerchant_utrustme/network/network.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  BuildContext context;
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  String ref_users;

  List<QrisNotifModel> list = [];

  @override
  void initState() {
    // TODO: implement initState

    //Check the server every 5 seconds
    //_timer = Timer.periodic(Duration(seconds: 5), (timer) => getData());
    super.initState();
    _setup();
    //getData();
  }

  @override
  void dispose() {
    //cancel the timer
    //if (_timer.isActive) _timer.cancel();
    super.dispose();
  }

  _setup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      ref_users = prefs.getString("I");
    });
  }

  Future<List<QrisNotifModel>> getDataQris() async {
    var username2 = utf8.encode(ref_users);
    var mrckey = utf8.encode(Config.mrcKey);

    var sign = sha1.convert(username2 + mrckey);
    final response = await http.post(NetworkUrl.getQrisLastTRX(),
        body: jsonEncode({"REF_USERS": ref_users, "SIGN": sign.toString()}));
    if (response.statusCode == 200) {
      return qrisDatafromJson(response.body);
    } else {
      return null;
    }
  }

  Future<List<NotifModel>> getDataNotif() async {
    var username2 = utf8.encode(ref_users);
    var mrckey = utf8.encode(Config.mrcKey);

    var sign = sha1.convert(username2 + mrckey);
    final response = await http.post(NetworkUrl.getLastNotif(),
        body: jsonEncode({"REF_USERS": ref_users, "SIGN": sign.toString()}));
    if (response.statusCode == 200) {
      return notifDatafromJson(response.body);
    } else {
      return null;
    }
  }

  Future _onRefreshQris() async {
    getDataQris();
    setState(() {});
  }

  Future _onRefreshDataNotif() async {
    getDataNotif();
    setState(() {});
  }

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: TabBar(
            tabs: [
              Tab(
                text: "Transaksi",
              ),
              Tab(
                text: "Info",
              ),
            ],
          ),
          title: Text('Notifikasi'),
          centerTitle: true,
        ),
        body: TabBarView(
          children: [displayQRISPage(), displayNotifData()],
        ),
      ),
    );
  }

  displayQRISPage() {
    return RefreshIndicator(
      onRefresh: _onRefreshQris,
      child: Container(
        color: Colors.grey[100],
        child: SafeArea(
          child: FutureBuilder(
            future: getDataQris(),
            builder: (BuildContext context,
                AsyncSnapshot<List<QrisNotifModel>> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                          "Something wrong with message: ${snapshot.error.toString()}"),
                    );
                  } else {
                    List<QrisNotifModel> profiles = snapshot.data;
                    return _buildListViewQris(profiles);
                  }
                }
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  displayNotifData() {
    return RefreshIndicator(
      onRefresh: _onRefreshDataNotif,
      child: Container(
        color: Colors.grey[100],
        child: SafeArea(
          child: FutureBuilder(
            future: getDataNotif(),
            builder: (BuildContext context,
                AsyncSnapshot<List<NotifModel>> snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasData) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                          "Something wrong with message: ${snapshot.error.toString()}"),
                    );
                  } else {
                    List<NotifModel> dataNotif = snapshot.data;
                    return _buildListViewDataNotif(dataNotif);
                  }
                }
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildListViewQris(List<QrisNotifModel> data2) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: data2.isEmpty
            ? Center(
                child: Text("Tidak ada data"),
              )
            : ListView.builder(
                itemBuilder: (context, index) {
                  QrisNotifModel dataQRIS = data2[index];
                  return Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Container(
                        decoration: BoxDecoration(
                            color: index % 2 == 0
                                ? Colors.white70
                                : Colors.grey[300]),
                        padding: EdgeInsets.only(
                            top: 20.0, bottom: 20.0, left: 5.0, right: 5.0),
                        child: Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(dataQRIS.type,
                                    style: TextStyle(
                                        fontSize: 25.0,
                                        fontFamily: 'Playball',
                                        letterSpacing: 2)),
                                Text(
                                    dataQRIS.type == "Uang Masuk"
                                        ? "+ ${dataQRIS.amount}"
                                        : dataQRIS.type == "Uang Keluar"
                                            ? "- ${dataQRIS.amount}"
                                            : dataQRIS.amount,
                                    style: TextStyle(
                                        color: dataQRIS.type == "Uang Masuk"
                                            ? Colors.grey
                                            : dataQRIS.type == "Uang Keluar"
                                                ? Colors.redAccent
                                                : Colors.grey,
                                        fontSize: 20.0))
                              ],
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(dataQRIS.rnn,
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 14.0)),
                                Text(dataQRIS.date,
                                    style: TextStyle(fontSize: 16.0))
                              ],
                            ),
                            SizedBox(
                              height: 10.0,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                Text(dataQRIS.issuer,
                                    style: TextStyle(fontSize: 16.0))
                              ],
                            ),
                          ],
                        ),
                      ));
                },
                itemCount: data2.length,
              ));
  }

  Widget _buildListViewDataNotif(List<NotifModel> data2) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: data2.isEmpty
            ? Center(
                child: Text("Tidak ada data"),
              )
            : ListView.builder(
                itemBuilder: (context, index) {
                  NotifModel dataNotif = data2[index];
                  return InkWell(
                    onTap: () {
                      dataNotif.url.isNotEmpty
                          ? _launchURL(dataNotif.url)
                          : null;
                    },
                    child: Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                              color: index % 2 == 0
                                  ? Colors.white70
                                  : Colors.grey[300]),
                          padding: EdgeInsets.only(
                              top: 20.0, bottom: 20.0, left: 5.0, right: 5.0),
                          child: ListTile(
                            title: Text(dataNotif.title),
                            subtitle: Text(dataNotif.message),
                            trailing: Text(dataNotif.date),
                          ),
                        )),
                  );
                },
                itemCount: data2.length,
              ));
  }
}
