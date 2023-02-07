// To parse this JSON data, do
//
//     final salesReportModel = salesReportModelFromJson(jsonString);

import 'dart:convert';

List<SalesReportModel> salesReportModelFromJson(String str) => List<SalesReportModel>.from(json.decode(str).map((x) => SalesReportModel.fromJson(x)));

String salesReportModelToJson(List<SalesReportModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class SalesReportModel {
    SalesReportModel({
        this.id,
        this.action,
        this.customerName,
        this.customerEmail,
        this.qrData,
        this.invoiceNumber,
        this.total,
        this.paymentMethod,
        this.reference,
        this.orderDate,
        this.orderStatus,
        this.orderNote,
        this.orderProduk,
    });

    int id;
    String action;
    String customerName;
    String customerEmail;
    dynamic qrData;
    String invoiceNumber;
    String total;
    String paymentMethod;
    String reference;
    String orderDate;
    String orderStatus;
    String orderNote;
    List<OrderProduk> orderProduk;

    factory SalesReportModel.fromJson(Map<String, dynamic> json) => SalesReportModel(
        id: json["id"],
        action: json["action"],
        customerName: json["customer_name"],
        customerEmail: json["customer_email"],
        qrData: json["qr_data"],
        invoiceNumber: json["invoiceNumber"],
        total: json["total"],
        paymentMethod: json["payment_method"],
        reference: json["reference"],
        orderDate: json["order_date"],
        orderStatus: json["order_status"],
        orderNote: json["order_note"],
        orderProduk: List<OrderProduk>.from(json["order_produk"].map((x) => OrderProduk.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "action": action,
        "customer_name": customerName,
        "customer_email": customerEmail,
        "qr_data": qrData,
        "invoiceNumber": invoiceNumber,
        "total": total,
        "payment_method": paymentMethod,
        "reference": reference,
        "order_date": orderDate,
        "order_status": orderStatus,
        "order_note": orderNote,
        "order_produk": List<dynamic>.from(orderProduk.map((x) => x.toJson())),
    };
}

class OrderProduk {
    OrderProduk({
        this.namaProduk,
        this.hargaProduk,
        this.qtyProduk,
    });

    String namaProduk;
    String hargaProduk;
    String qtyProduk;

    factory OrderProduk.fromJson(Map<String, dynamic> json) => OrderProduk(
        namaProduk: json["nama_produk"],
        hargaProduk: json["harga_produk"],
        qtyProduk: json["qty_produk"],
    );

    Map<String, dynamic> toJson() => {
        "nama_produk": namaProduk,
        "harga_produk": hargaProduk,
        "qty_produk": qtyProduk,
    };
}
