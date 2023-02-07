class TodaySalesCSV {
  String orderDate;
  String orderNumber;
  String customerName;
  String customerEmail;
  String productName;
  String productPrice;
  String productQty;
  String subtotal;
  String total;

  TodaySalesCSV(
      {this.orderDate,
      this.orderNumber,
      this.customerName,
      this.customerEmail,
      this.productName,
      this.productPrice,
      this.productQty,
      this.subtotal,
      this.total});

  TodaySalesCSV.fromJson(Map<String, dynamic> json) {
    orderDate = json['order_date'];
    orderNumber = json['order_number'];
    customerName = json['customer_name'];
    customerEmail = json['customer_email'];
    productName = json['product_name'];
    productPrice = json['product_price'];
    productQty = json['product_qty'];
    subtotal = json['subtotal'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['order_date'] = this.orderDate;
    data['order_number'] = this.orderNumber;
    data['customer_name'] = this.customerName;
    data['customer_email'] = this.customerEmail;
    data['product_name'] = this.productName;
    data['product_price'] = this.productPrice;
    data['product_qty'] = this.productQty;
    data['subtotal'] = this.subtotal;
    data['total'] = this.total;
    return data;
  }
}