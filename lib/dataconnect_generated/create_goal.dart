part of 'generated.dart';

class CreateGoalVariablesBuilder {
  String goalName;
  double targetAmount;
  double currentAmount;
  DateTime targetDate;
  String goalType;
  Optional<String> _description = Optional.optional(nativeFromJson, nativeToJson);

  final FirebaseDataConnect _dataConnect;  CreateGoalVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }

  CreateGoalVariablesBuilder(this._dataConnect, {required  this.goalName,required  this.targetAmount,required  this.currentAmount,required  this.targetDate,required  this.goalType,});
  Deserializer<CreateGoalData> dataDeserializer = (dynamic json)  => CreateGoalData.fromJson(jsonDecode(json));
  Serializer<CreateGoalVariables> varsSerializer = (CreateGoalVariables vars) => jsonEncode(vars.toJson());
  Future<OperationResult<CreateGoalData, CreateGoalVariables>> execute() {
    return ref().execute();
  }

  MutationRef<CreateGoalData, CreateGoalVariables> ref() {
    CreateGoalVariables vars= CreateGoalVariables(goalName: goalName,targetAmount: targetAmount,currentAmount: currentAmount,targetDate: targetDate,goalType: goalType,description: _description,);
    return _dataConnect.mutation("CreateGoal", dataDeserializer, varsSerializer, vars);
  }
}

@immutable
class CreateGoalGoalInsert {
  final String id;
  CreateGoalGoalInsert.fromJson(dynamic json):
  
  id = nativeFromJson<String>(json['id']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateGoalGoalInsert otherTyped = other as CreateGoalGoalInsert;
    return id == otherTyped.id;
    
  }
  @override
  int get hashCode => id.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = nativeToJson<String>(id);
    return json;
  }

  CreateGoalGoalInsert({
    required this.id,
  });
}

@immutable
class CreateGoalData {
  final CreateGoalGoalInsert goal_insert;
  CreateGoalData.fromJson(dynamic json):
  
  goal_insert = CreateGoalGoalInsert.fromJson(json['goal_insert']);
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateGoalData otherTyped = other as CreateGoalData;
    return goal_insert == otherTyped.goal_insert;
    
  }
  @override
  int get hashCode => goal_insert.hashCode;
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['goal_insert'] = goal_insert.toJson();
    return json;
  }

  CreateGoalData({
    required this.goal_insert,
  });
}

@immutable
class CreateGoalVariables {
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String goalType;
  late final Optional<String>description;
  @Deprecated('fromJson is deprecated for Variable classes as they are no longer required for deserialization.')
  CreateGoalVariables.fromJson(Map<String, dynamic> json):
  
  goalName = nativeFromJson<String>(json['goalName']),
  targetAmount = nativeFromJson<double>(json['targetAmount']),
  currentAmount = nativeFromJson<double>(json['currentAmount']),
  targetDate = nativeFromJson<DateTime>(json['targetDate']),
  goalType = nativeFromJson<String>(json['goalType']) {
  
  
  
  
  
  
  
    description = Optional.optional(nativeFromJson, nativeToJson);
    description.value = json['description'] == null ? null : nativeFromJson<String>(json['description']);
  
  }
  @override
  bool operator ==(Object other) {
    if(identical(this, other)) {
      return true;
    }
    if(other.runtimeType != runtimeType) {
      return false;
    }

    final CreateGoalVariables otherTyped = other as CreateGoalVariables;
    return goalName == otherTyped.goalName && 
    targetAmount == otherTyped.targetAmount && 
    currentAmount == otherTyped.currentAmount && 
    targetDate == otherTyped.targetDate && 
    goalType == otherTyped.goalType && 
    description == otherTyped.description;
    
  }
  @override
  int get hashCode => Object.hashAll([goalName.hashCode, targetAmount.hashCode, currentAmount.hashCode, targetDate.hashCode, goalType.hashCode, description.hashCode]);
  

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['goalName'] = nativeToJson<String>(goalName);
    json['targetAmount'] = nativeToJson<double>(targetAmount);
    json['currentAmount'] = nativeToJson<double>(currentAmount);
    json['targetDate'] = nativeToJson<DateTime>(targetDate);
    json['goalType'] = nativeToJson<String>(goalType);
    if(description.state == OptionalState.set) {
      json['description'] = description.toJson();
    }
    return json;
  }

  CreateGoalVariables({
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.goalType,
    required this.description,
  });
}

