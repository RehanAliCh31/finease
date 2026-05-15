library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'create_transaction.dart';

part 'get_accounts_by_user_id.dart';

part 'create_goal.dart';

part 'get_user_budgets.dart';







class ExampleConnector {
  
  
  CreateTransactionVariablesBuilder createTransaction ({required String accountId, required double amount, required String description, required Timestamp transactionDate, }) {
    return CreateTransactionVariablesBuilder(dataConnect, accountId: accountId,amount: amount,description: description,transactionDate: transactionDate,);
  }
  
  
  GetAccountsByUserIdVariablesBuilder getAccountsByUserId () {
    return GetAccountsByUserIdVariablesBuilder(dataConnect, );
  }
  
  
  CreateGoalVariablesBuilder createGoal ({required String goalName, required double targetAmount, required double currentAmount, required DateTime targetDate, required String goalType, }) {
    return CreateGoalVariablesBuilder(dataConnect, goalName: goalName,targetAmount: targetAmount,currentAmount: currentAmount,targetDate: targetDate,goalType: goalType,);
  }
  
  
  GetUserBudgetsVariablesBuilder getUserBudgets () {
    return GetUserBudgetsVariablesBuilder(dataConnect, );
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'us-east4',
    'example',
    'finease-1',
  );

  ExampleConnector({required this.dataConnect});
  static ExampleConnector get instance {
    
    CacheSettings cacheSettings = CacheSettings(
      maxAge: Duration(milliseconds:0),
      storage: CacheStorage.persistent,
    );
    
    return ExampleConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            cacheSettings: cacheSettings,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
