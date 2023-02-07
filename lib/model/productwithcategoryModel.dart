import 'dart:convert';

class ProductCat {
  int id;
  int categoryId;
  String categoryName;
  String productName;
  int price;
  String image;
  String createdAt;

  ProductCat({this.id = 0, this.categoryId, this.categoryName, this.productName, this.price, this.image, this.createdAt});

  factory ProductCat.fromJson(Map<String, dynamic> map) {
    return ProductCat(
        id: map["id"],
        categoryId: map["categoryId"],
        categoryName: map["categoryName"],
        productName: map["productName"],
        price: map["price"],
        image: map["image"],
        createdAt: map["createdAt"],
        );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "categoryId": categoryId,
      "categoryName": categoryName,
      "productName": productName,
      "price": price,
      "image": image,
      "createdAt": createdAt
    };
  }

  @override
  String toString() {
    return 'Category{id: $id, idCategory: $categoryId, categoryName: $categoryName, productName: $productName, price: $price, image: $image, createdAt: $createdAt}';
  }
}

List<ProductCat> productCatFromJson(String jsonData) {
  final data = json.decode(jsonData);
  return List<ProductCat>.from(
      data.map((item) => ProductCat.fromJson(item)));
}

String productCatToJson(ProductCat data) {
  final jsonData = data.toJson();
  return json.encode(jsonData);
}

