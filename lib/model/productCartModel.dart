class ProductCartModel {
  final int id;
  final String productName;
  final int price;
  final String image;
  final int qty;

  ProductCartModel(
      {this.id,
      this.productName,
      this.price,
      this.image,
      this.qty
      });

  factory ProductCartModel.fromJson(Map<String, dynamic> json) {
    return ProductCartModel(
      id: json['id'],
      productName: json['productName'],
      price: json['price'],
      image: json['image'],
      qty: json['qty'],
    );
  }
}
