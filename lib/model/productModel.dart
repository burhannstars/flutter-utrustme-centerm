class ProductModel {
  int id;
  String productName;
  int price;
  String image;
  String description;
  int discount;
  String createdDate;

  ProductModel(
      {this.id,
      this.productName,
      this.price,
      this.image,
      this.description,
      this.discount,
      this.createdDate});

  ProductModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productName = json['productName'];
    price = json['price'];
    image = json['image'];
    description = json['description'];
    discount = json['discount'];
    createdDate = json['createdDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['productName'] = this.productName;
    data['price'] = this.price;
    data['image'] = this.image;
    data['description'] = this.description;
    data['discount'] = this.discount;
    data['createdDate'] = this.createdDate;
    return data;
  }
}
