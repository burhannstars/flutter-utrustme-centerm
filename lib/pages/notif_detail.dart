import 'package:flutter/material.dart';

class NotificationDetail extends StatelessWidget {
  final String linkController; //if you have multiple values add here=
  NotificationDetail(this.linkController, {Key key}) : super(key: key); //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Notification Detail"),
      ),
      body: SafeArea(child: Text("Test")
          /*WebviewScaffold(
          url: linkController,
          userAgent: Config.userAgent,
          withJavascript: true,
        ),*/
          ),
    );
  }
}
