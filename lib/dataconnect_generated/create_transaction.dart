part of 'generated.dart';

class CreateTransactionVariablesBuilder {
  String accountId;
  double amount;
  String description;
  Timestamp transactionDate;
  Optional<String> _categoryId = Optional.optional(nativeFromJson, nativeToJson);
  Optional<String> _merchant = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreateTransactionVariablesBuilder categoryId(String? t) {
   _categoryId.value = t;
   return this;
  }
  CreateTransactionVariablesBuilder merchant(String? t) {
   _merchant.value = t;
   return this;
  }

  CreateTransactionVariablesBuilder(this._dataConnect, {required  this.accountId,required  this.amount,required  this.description,required  this.transactionDate,});
  Deserializer<CreateTransactionData> dataDeserializer = (dynamic json)  => CreateTransactionData.fromJson(jsonDecode(json));
  Serializer<CreateTransactionVariables> varsSerializer = (CreateTransactionVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateTransactionData, CreateTransactionVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateTransactionData, CreateTransactionVariables> ref() {
    CreateTransactionVariables vars= CreateTransactionVariables(accountId: accountId,amount: amount,description: description,transactionDate: transactionDate,categoryId: _categoryId,merchant: _merchant,);
    return _dataConnect.mutation("CreateTransaction", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateTransactionTransactionInsert {
  final String id;
  CreateTransactionTransactionInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTransactionTransactionInsert otherTyped = other as CreateTransactionTransactionInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateTransactionTransactionInsert({
    required this.id,
  });
}

@immutable
class CreateTransactionData {
  final CreateTransactionTransactionInsert transaction_insert;
  CreateTransactionData.fromJson(dynamic json):
  
  transaction_insert = CreateTransactionTransactionInsert.fromJson(json['transaction_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTransactionData otherTyped = other as CreateTransactionData;
    return transaction_insert == otherTyped.transaction_insert;
    
  }
  @override
  int get hashCode => transaction_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['transaction_insert'] = transaction_insert.toJson();
    return json;
  }

  CreateTransactionData({
    required this.transaction_insert,
  });
}

@immutable
class CreateTransactionVariables {
  final String accountId;
  final double amount;
  final String description;
  final Timestamp transactionDate;
  late final Optional<String>categoryId;
  late final Optional<String>merchant;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateTransactionVariables.fromJson(Map<String, dynamic> json):
  
  accountId = nativeFromJson<String>(json['accountId']),
  amount = nativeFromJson<double>(json['amount']),
  description = nativeFromJson<String>(json['description']),
  transactionDate = Timestamp.fromJson(json['transactionDate']) {
  
  
  
  
  
  
    categoryId = Optional.optional(nativeFromJson, nativeToJson);
    categoryId.value = json['categoryId'] == null ? null : nativeFromJson<String>(json['categoryId']);
  
  
    merchant = Optional.optional(nativeFromJson, nativeToJson);
    merchant.value = json['merchant'] == null ? null : nativeFromJson<String>(json['merchant']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateTransactionVariables otherTyped = other as CreateTransactionVariables;
    return accountId == otherTyped.accountId && 
    amount == otherTyped.amount && 
    description == otherTyped.description && 
    transactionDate == otherTyped.transactionDate && 
    categoryId == otherTyped.categoryId && 
    merchant == otherTyped.merchant;
    
  }
  @override
  int get hashCode => Object.hashAll([accountId.hashCode, amount.hashCode, description.hashCode, transactionDate.hashCode, categoryId.hashCode, merchant.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['accountId'] = nativeToJson<String>(accountId);
    json['amount'] = nativeToJson<double>(amount);
    json['description'] = nativeToJson<String>(description);
    json['transactionDate'] = transactionDate.toJson();
    if(categoryId.state == OptionalState.set) {
      json['categoryId'] = categoryId.toJson();
    }
    if(merchant.state == OptionalState.set) {
      json['merchant'] = merchant.toJson();
    }
    return json;
  }

  CreateTransactionVariables({
    required this.accountId,
    required this.amount,
    required this.description,
    required this.transactionDate,
    required this.categoryId,
    required this.merchant,
  });
}

