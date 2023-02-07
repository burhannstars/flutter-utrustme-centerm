import 'dart:convert';

class QrisNotifModel {
  String type;
  String amount;
  String date;
  String issuer;
  String rnn;

  QrisNotifModel(
      {this.type, this.amount, this.date, this.issuer, this.rnn});

  factory QrisNotifModel.fromJson(Map<String, dynamic> map) {
    return QrisNotifModel(
        type: map["type"],
        amount: map["amount"],
        date: map["date"],
        issuer: map["issuer"],
        rnn: map["rnn"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "amount": amount,
      "date": date,
      "issuer": issuer,
      "rnn": rnn
    };
  }
}

List<QrisNotifModel> qrisDatafromJson(String jsonData) {
  final data = json.decode(jsonData);
  return List<QrisNotifModel>.from(
      data.map((item) => QrisNotifModel.fromJson(item)));
}

String qrisDatatoJson(QrisNotifModel data) {
  final jsonData = data.toJson();
  return json.encode(jsonData);
}
