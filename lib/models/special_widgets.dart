class SpecialWidgets {
  String widgetName;
  String productId;
  String supplierId;
  String description;
  String assemblyCode;
  int quantityInStock;
  int quantityOnOrder;
  double price;
  DateTime lastUsed;
  List<String> models;
  bool hasSubstitutes;
  String bomLink;

  SpecialWidgets(
      {this.widgetName,
      this.productId,
      this.supplierId,
      this.description,
      this.assemblyCode,
      this.quantityInStock,
      this.quantityOnOrder,
      this.price,
      this.lastUsed,
      this.models,
      this.hasSubstitutes,
      this.bomLink});

  String get name => 'SpecialWidgets';
  String get primaryKey => 'widgetname';
  Map<String, String> get typeMap => {
        "widgetName": "String",
        "productId": "String",
        "supplierId": "String",
        "description": "String",
        "assemblyCode": "String",
        "quantityInStock": "int",
        "quantityOnOrder": "int",
        "price": "double",
        "lastUsed": "DateTime",
        "models": "List<String>",
        "hasSubstitutes": "bool",
        "bomLink": "String",
      };

  List<String> get noUpdate => [
        'widgetname',
        'productId',
        'supplierId',
      ];

  Map<String, String> get foreginKeys => {
        "productId": "products",
        "supplierId": "supplier",
      };

  Map<String, String> get index => {
        "widgetProduct": "productId.asc",
        "wdigetSupplier": "supplierid",
      };

  SpecialWidgets.fromMap(Map<String, dynamic> map) {
    widgetName = map['widgetName'];
    productId = map['productId'];
    supplierId = map['supplierId'];
    description = map['description'];
    assemblyCode = map['assemblyCode'];
    quantityInStock = map['quantityInStock'];
    quantityOnOrder = map['quantityOnOrder'];
    price = map['price'];
    lastUsed = DateTime.tryParse(map['lastUsed']);
    models = map['models'].cast<String>();
    hasSubstitutes = map['hasSubstitutes'];
    bomLink = map['bomLink'];
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['widgetName'] = this.widgetName;
    data['productId'] = this.productId;
    data['supplierId'] = this.supplierId;
    data['description'] = this.description;
    data['assemblyCode'] = this.assemblyCode;
    data['quantityInStock'] = this.quantityInStock;
    data['quantityOnOrder'] = this.quantityOnOrder;
    data['price'] = this.price;
    data['lastUsed'] = 'this.lastUsed.toIso8601String()';
    data['models'] = this.models;
    data['hasSubstitutes'] = this.hasSubstitutes;
    data['bomLink'] = this.bomLink;
    return data;
  }
}
