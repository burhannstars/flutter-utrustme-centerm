import 'dart:convert';

class NotifModel {
  String title;
  String message;
  String url;
  String date;

  NotifModel({this.title, this.message, this.url, this.date});

  factory NotifModel.fromJson(Map<String, dynamic> map) {
    return NotifModel(
        title: map["title"],
        message: map["message"],
        url: map["url"],
        date: map["date"]);
  }

  Map<String, dynamic> toJson() {
    return {"title": title, "message": message, "url": url, "date": date};
  }
}

List<NotifModel> notifDatafromJson(String jsonData) {
  final data = json.decode(jsonData);
  return List<NotifModel>.from(data.map((item) => NotifModel.fromJson(item)));
}

String notifDatatoJson(NotifModel data) {
  final jsonData = data.toJson();
  return json.encode(jsonData);
}
