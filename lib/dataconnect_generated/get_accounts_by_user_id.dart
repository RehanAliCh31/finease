part of 'generated.dart';

class GetAccountsByUserIdVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetAccountsByUserIdVariablesBuilder(this._dataConnect, );
  Deserializer<GetAccountsByUserIdData> dataDeserializer = (dynamic json)  => GetAccountsByUserIdData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetAccountsByUserIdData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetAccountsByUserIdData, void> ref() {
    
    return _dataConnect.query("GetAccountsByUserId", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetAccountsByUserIdAccounts {
  final String id;
  final String accountName;
  final String accountType;
  final double balance;
  final String? institutionName;
  final Timestamp lastSyncedAt;
  final Timestamp createdAt;
  GetAccountsByUserIdAccounts.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  accountName = nativeFromJson<String>(json['accountName']),
  accountType = nativeFromJson<String>(json['accountType']),
  balance = nativeFromJson<double>(json['balance']),
  institutionName = json['institutionName'] == null ? null : nativeFromJson<String>(json['institutionName']),
  lastSyncedAt = Timestamp.fromJson(json['lastSyncedAt']),
  createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccountsByUserIdAccounts otherTyped = other as GetAccountsByUserIdAccounts;
    return id == otherTyped.id && 
    accountName == otherTyped.accountName && 
    accountType == otherTyped.accountType && 
    balance == otherTyped.balance && 
    institutionName == otherTyped.institutionName && 
    lastSyncedAt == otherTyped.lastSyncedAt && 
    createdAt == otherTyped.createdAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, accountName.hashCode, accountType.hashCode, balance.hashCode, institutionName.hashCode, lastSyncedAt.hashCode, createdAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['accountName'] = nativeToJson<String>(accountName);
    json['accountType'] = nativeToJson<String>(accountType);
    json['balance'] = nativeToJson<double>(balance);
    if (institutionName != null) {
      json['institutionName'] = nativeToJson<String?>(institutionName);
    }
    json['lastSyncedAt'] = lastSyncedAt.toJson();
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  GetAccountsByUserIdAccounts({
    required this.id,
    required this.accountName,
    required this.accountType,
    required this.balance,
    this.institutionName,
    required this.lastSyncedAt,
    required this.createdAt,
  });
}

@immutable
class GetAccountsByUserIdData {
  final List<GetAccountsByUserIdAccounts> accounts;
  GetAccountsByUserIdData.fromJson(dynamic json):
  
  accounts = (json['accounts'] as List<dynamic>)
        .map((e) => GetAccountsByUserIdAccounts.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetAccountsByUserIdData otherTyped = other as GetAccountsByUserIdData;
    return accounts == otherTyped.accounts;
    
  }
  @override
  int get hashCode => accounts.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['accounts'] = accounts.map((e) => e.toJson()).toList();
    return json;
  }

  GetAccountsByUserIdData({
    required this.accounts,
  });
}

