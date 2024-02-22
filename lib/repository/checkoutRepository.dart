import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gvmerchant_utrustme/config/config.dart';
import 'package:gvmerchant_utrustme/network/network.dart';
import 'package:gvmerchant_utrustme/pages/frontMenu.dart';
import 'package:gvmerchant_utrustme/pages/tagihanDynamic.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

List<BluetoothDevice> _devices = [];
BluetoothDevice _device;
bool _connected = false;

class CheckoutRepository {
  checkout(
    String uniqueID,
    VoidCallback method,
    BuildContext context,
  ) async {
    final response =
        await http.post(NetworkUrl, body: jsonEncode({"REF_USERS": uniqueID}));
    final data = jsonDecode(response.body);
    int value = data['value'];
    String message = data['message'];
    if (value == 1) {
      method();
      showDialog(
          context: context,
          builder: (context) {
            return Platform.isAndroid
                ? AlertDialog(
                    title: Text("Information"),
                    content: Text("$message"),
                    actions: <Widget>[
                      FlatButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Text("Ok"))
                    ],
                  )
                : CupertinoAlertDialog(
                    title: Text("Information"),
                    content: Text("$message"),
                    actions: <Widget>[
                      FlatButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Text("Ok"))
                    ],
                  );
          });
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return Platform.isAndroid
                ? AlertDialog(
                    title: Text("Warning"),
                    content: Text("$message"),
                    actions: <Widget>[
                      FlatButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Ok"))
                    ],
                  )
                : CupertinoAlertDialog(
                    title: Text("Warning"),
                    content: Text("$message"),
                    actions: <Widget>[
                      FlatButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Ok"))
                    ],
                  );
          });
    }
  }

  newCheckout(
      String paymentMethod,
      String uniqueID,
      String custName,
      String custEmail,
      int total,
      String refLabel,
      String qrData,
      String orderNote,
      String total_text,
      String expiredQris,
      String pathImage,
      BuildContext context) async {
    //     String ref_label = null;
    // if (paymentMethod == "QRIS") {
    //   final res = await http.post(NetworkUrl.createTagihanDynamic(),
    //       body: {"ref_users": uniqueID, "amount": "$total"});
    //   final data = jsonDecode(res.body);
    //   String ref_label = data['responddata']['reference_label'];
    //   print("Data QR : $ref_label");
    // }
    final response = await http.post(NetworkUrl.checkoutCart(),
        body: jsonEncode({
          "REF_USERS": uniqueID,
          "PAYMENT_METHOD": paymentMethod,
          "CUSTOMER_NAME": custName,
          "CUSTOMER_EMAIL": custEmail,
          "REFERENCE_LABEL": refLabel,
          "ORDER_NOTE": orderNote
        }));
    final data = jsonDecode(response.body);
    int value = data['value'];
    String message = data['message'];
    String no_invoice = data['invoice_number'];
    if (value == 1) {
      if (paymentMethod == "QRIS") {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TagihanQRDynamic(
                    method: null,
                    image: qrData,
                    refLabel: refLabel,
                    totalTagihan: total_text,
                    expiredQris: expiredQris)));
      } else {
        /*final response = await http.post(
            Uri.parse(
                "https://gudangvoucher.com/merchant/gvpos/getPrintOrder.php"),
            body: jsonEncode(
              {"REF_USERS": uniqueID, "INVOICE": no_invoice},
            ));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data[0]['item'] != null) {
            final myDevice = BluetoothDevice.fromMap({
              'name': 'InnerPrinter',
              'address': Config.printerMacAddress',
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
              merchantName = prefs.getString('merchantName');
              bluetooth.printNewLine();
              bluetooth.printImage(pathImage);
              bluetooth.printCustom(merchantName, 2, 1);
              bluetooth.printNewLine();
              bluetooth.printLeftRight("Tanggal : ", data[0]['order_date'], 1);
              bluetooth.printLeftRight("Jam : ", data[0]['order_time'], 1);
              //bluetooth.printLeftRight("Kasir", "A01", 1);
              bluetooth.printCustom(data[0]['invoice_number'], 1, 1);
              bluetooth.writeBytes(
                  Uint8List.fromList([0x1B, 0x21, 0x0])); // 1- only bold text
              bluetooth.writeBytes(
                  Uint8List.fromList([0x1b, 0x61, 0x01])); //ESC_ALIGN_CENTER
              bluetooth.printCustom("================================", 1, 1);
              bluetooth.printNewLine();
              data[0]["item"].forEach((element) {
                print("Nama Produk : " + element['nama_produk']);
                bluetooth.printCustom(element['nama_produk'], 1, 0);
                bluetooth.printLeftRight(
                    element['qty_produk'] + " x" + element['harga_produk'],
                    element['subtotal'],
                    0);
              });
              bluetooth.printCustom("================================", 1, 1);
              bluetooth.printLeftRight("Total", data[0]['order_total'], 1);
              bluetooth.printLeftRight("Metode", paymentMethod, 1);
              bluetooth.printCustom("================================", 1, 1);
              bluetooth.printNewLine();
              bluetooth.printCustom("Terima kasih :)", 2, 1);
              bluetooth.printNewLine();
            });
          }
        }*/
        showDialog(
            barrierDismissible: false,
            context: context,
            builder: (context) {
              return Platform.isAndroid
                  ? WillPopScope(
                      onWillPop: () {},
                      child: AlertDialog(
                        title: Text("Informasi"),
                        content: SingleChildScrollView(
                          child: Column(
                            children: [
                              Text("Transaksi sebesar $total_text berhasil"),
                              SizedBox(
                                height: 5,
                              ),
                              Text("Nomor Invoice : "),
                              SelectableText(no_invoice)
                            ],
                          ),
                        ),
                        actions: <Widget>[
                          FlatButton(
                            onPressed: () async {
                              final response = await http.post(
                                  Uri.parse(
                                      "https://gudangvoucher.com/merchant/gvpos/getPrintOrder.php"),
                                  body: jsonEncode(
                                    {
                                      "REF_USERS": uniqueID,
                                      "INVOICE": no_invoice
                                    },
                                  ));
                              if (response.statusCode == 200) {
                                final data = jsonDecode(response.body);
                                if (data[0]['item'] != null) {
                                  final myDevice = BluetoothDevice.fromMap({
                                    'name': 'InnerPrinter',
                                    'address': Config.printerMacAddress,
                                    'type': '10082'
                                  });

                                  bluetooth.isConnected.then((isConnected) {
                                    if (!isConnected) {
                                      bluetooth
                                          .connect(myDevice)
                                          .catchError((error) {
                                        //show Not connected bluetooth dialog
                                      });
                                    }
                                  }).then((snapshot) async {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    merchantName =
                                        prefs.getString('merchantName');
                                    bluetooth.printNewLine();
                                    bluetooth.printImage(pathImage);
                                    bluetooth.printCustom(merchantName, 2, 1);
                                    bluetooth.printNewLine();
                                    bluetooth.printLeftRight(
                                        "Tanggal : ", data[0]['order_date'], 1);
                                    bluetooth.printLeftRight(
                                        "Jam : ", data[0]['order_time'], 1);
                                    //bluetooth.printLeftRight("Kasir", "A01", 1);
                                    bluetooth.printCustom(
                                        data[0]['invoice_number'], 1, 1);
                                    bluetooth.writeBytes(Uint8List.fromList([
                                      0x1B,
                                      0x21,
                                      0x0
                                    ])); // 1- only bold text
                                    bluetooth.writeBytes(Uint8List.fromList(
                                        [0x1b, 0x61, 0x01])); //ESC_ALIGN_CENTER
                                    bluetooth.printCustom(
                                        "--------------------------------",
                                        1,
                                        1);
                                    bluetooth.printNewLine();
                                    data[0]["item"].forEach((element) {
                                      print("Nama Produk : " +
                                          element['nama_produk']);
                                      bluetooth.printCustom(
                                          element['nama_produk'], 1, 0);
                                      bluetooth.printLeftRight(
                                          element['qty_produk'] +
                                              " x" +
                                              element['harga_produk'],
                                          element['subtotal'],
                                          0);
                                    });
                                    bluetooth.printCustom(
                                        "--------------------------------",
                                        1,
                                        1);
                                    bluetooth.printLeftRight(
                                        "Total", data[0]['order_total'], 1);
                                    bluetooth.printLeftRight(
                                        "Metode", paymentMethod, 1);
                                    bluetooth.printCustom(
                                        "--------------------------------",
                                        1,
                                        1);
                                    bluetooth.printNewLine();
                                    bluetooth.printCustom(
                                        "Terima kasih :)", 2, 1);
                                    bluetooth.printNewLine();
                                  });
                                }
                              }
                            },
                            child: Icon(Icons.print, color: Colors.white),
                            textColor: Colors.white,
                            color: Colors.orangeAccent,
                          ),
                          FlatButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FrontMenu()),
                                  (Route<dynamic> route) => false,
                                );
                              },
                              child: Text("OK")),
                        ],
                      ),
                    )
                  : WillPopScope(
                      onWillPop: () {},
                      child: CupertinoAlertDialog(
                        title: Text("Information"),
                        content: Text("$message"),
                        actions: <Widget>[
                          FlatButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: Text("OK"))
                        ],
                      ),
                    );
            });
      }
    } else {
      showDialog(
          context: context,
          builder: (context) {
            return Platform.isAndroid
                ? AlertDialog(
                    title: Text("Warning"),
                    content: Text("$message"),
                    actions: <Widget>[
                      FlatButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Ok"))
                    ],
                  )
                : CupertinoAlertDialog(
                    title: Text("Warning"),
                    content: Text("$message"),
                    actions: <Widget>[
                      FlatButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Ok"))
                    ],
                  );
          });
    }
  }
}
