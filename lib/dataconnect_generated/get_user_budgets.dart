part of 'generated.dart';

class GetUserBudgetsVariablesBuilder {
  
  final FirebaseDataConnect _dataConnect;
  GetUserBudgetsVariablesBuilder(this._dataConnect, );
  Deserializer<GetUserBudgetsData> dataDeserializer = (dynamic json)  => GetUserBudgetsData.fromJson(jsonDecode(json));
  
  Future<QueryResult<GetUserBudgetsData, void>> execute({QueryFetchPolicy fetchPolicy = QueryFetchPolicy.preferCache}) {
    return ref().execute(fetchPolicy: fetchPolicy);
  }

  QueryRef<GetUserBudgetsData, void> ref() {
    
    return _dataConnect.query("GetUserBudgets", dataDeserializer, emptySerializer, null);
  }
}

@immutable
class GetUserBudgetsBudgets {
  final String id;
  final double budgetAmount;
  final DateTime startDate;
  final DateTime endDate;
  final GetUserBudgetsBudgetsCategory category;
  final double? alertThreshold;
  final Timestamp createdAt;
  GetUserBudgetsBudgets.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']),
  budgetAmount = nativeFromJson<double>(json['budgetAmount']),
  startDate = nativeFromJson<DateTime>(json['startDate']),
  endDate = nativeFromJson<DateTime>(json['endDate']),
  category = GetUserBudgetsBudgetsCategory.fromJson(json['category']),
  alertThreshold = json['alertThreshold'] == null ? null : nativeFromJson<double>(json['alertThreshold']),
  createdAt = Timestamp.fromJson(json['createdAt']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserBudgetsBudgets otherTyped = other as GetUserBudgetsBudgets;
    return id == otherTyped.id && 
    budgetAmount == otherTyped.budgetAmount && 
    startDate == otherTyped.startDate && 
    endDate == otherTyped.endDate && 
    category == otherTyped.category && 
    alertThreshold == otherTyped.alertThreshold && 
    createdAt == otherTyped.createdAt;
    
  }
  @override
  int get hashCode => Object.hashAll([id.hashCode, budgetAmount.hashCode, startDate.hashCode, endDate.hashCode, category.hashCode, alertThreshold.hashCode, createdAt.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    json['budgetAmount'] = nativeToJson<double>(budgetAmount);
    json['startDate'] = nativeToJson<DateTime>(startDate);
    json['endDate'] = nativeToJson<DateTime>(endDate);
    json['category'] = category.toJson();
    if (alertThreshold != null) {
      json['alertThreshold'] = nativeToJson<double?>(alertThreshold);
    }
    json['createdAt'] = createdAt.toJson();
    return json;
  }

  GetUserBudgetsBudgets({
    required this.id,
    required this.budgetAmount,
    required this.startDate,
    required this.endDate,
    required this.category,
    this.alertThreshold,
    required this.createdAt,
  });
}

@immutable
class GetUserBudgetsBudgetsCategory {
  final String categoryName;
  final String categoryType;
  GetUserBudgetsBudgetsCategory.fromJson(dynamic json):
  
  categoryName = nativeFromJson<String>(json['categoryName']),
  categoryType = nativeFromJson<String>(json['categoryType']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserBudgetsBudgetsCategory otherTyped = other as GetUserBudgetsBudgetsCategory;
    return categoryName == otherTyped.categoryName && 
    categoryType == otherTyped.categoryType;
    
  }
  @override
  int get hashCode => Object.hashAll([categoryName.hashCode, categoryType.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['categoryName'] = nativeToJson<String>(categoryName);
    json['categoryType'] = nativeToJson<String>(categoryType);
    return json;
  }

  GetUserBudgetsBudgetsCategory({
    required this.categoryName,
    required this.categoryType,
  });
}

@immutable
class GetUserBudgetsData {
  final List<GetUserBudgetsBudgets> budgets;
  GetUserBudgetsData.fromJson(dynamic json):
  
  budgets = (json['budgets'] as List<dynamic>)
        .map((e) => GetUserBudgetsBudgets.fromJson(e))
        .toList();
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final GetUserBudgetsData otherTyped = other as GetUserBudgetsData;
    return budgets == otherTyped.budgets;
    
  }
  @override
  int get hashCode => budgets.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['budgets'] = budgets.map((e) => e.toJson()).toList();
    return json;
  }

  GetUserBudgetsData({
    required this.budgets,
  });
}

