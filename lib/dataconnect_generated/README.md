# dataconnect_generated SDK

## Installation
```sh
flutter pub get firebase_data_connect
flutterfire configure
```
For more information, see [Flutter for Firebase installation documentation](https://firebase.google.com/docs/data-connect/flutter-sdk#use-core).

## Data Connect instance
Each connector creates a static class, with an instance of the `DataConnect` class that can be used to connect to your Data Connect backend and call operations.

### Connecting to the emulator

```dart
String host = 'localhost'; // or your host name
int port = 9399; // or your port number
ExampleConnector.instance.dataConnect.useDataConnectEmulator(host, port);
```

You can also call queries and mutations by using the connector class.
## Queries

### GetAccountsByUserId
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.getAccountsByUserId().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetAccountsByUserIdData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getAccountsByUserId();
GetAccountsByUserIdData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.getAccountsByUserId().ref();
ref.execute();

ref.subscribe(...);
```


### GetUserBudgets
#### Required Arguments
```dart
// No required arguments
ExampleConnector.instance.getUserBudgets().execute();
```



#### Return Type
`execute()` returns a `QueryResult<GetUserBudgetsData, void>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

/// Result of a query request. Created to hold extra variables in the future.
class QueryResult<Data, Variables> extends OperationResult<Data, Variables> {
  QueryResult(super.dataConnect, super.data, super.ref);
}

final result = await ExampleConnector.instance.getUserBudgets();
GetUserBudgetsData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
final ref = ExampleConnector.instance.getUserBudgets().ref();
ref.execute();

ref.subscribe(...);
```

## Mutations

### CreateTransaction
#### Required Arguments
```dart
String accountId = ...;
double amount = ...;
String description = ...;
Timestamp transactionDate = ...;
ExampleConnector.instance.createTransaction(
  accountId: accountId,
  amount: amount,
  description: description,
  transactionDate: transactionDate,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateTransaction, we created `CreateTransactionBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateTransactionVariablesBuilder {
  ...
   CreateTransactionVariablesBuilder categoryId(String? t) {
   _categoryId.value = t;
   return this;
  }
  CreateTransactionVariablesBuilder merchant(String? t) {
   _merchant.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.createTransaction(
  accountId: accountId,
  amount: amount,
  description: description,
  transactionDate: transactionDate,
)
.categoryId(categoryId)
.merchant(merchant)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateTransactionData, CreateTransactionVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createTransaction(
  accountId: accountId,
  amount: amount,
  description: description,
  transactionDate: transactionDate,
);
CreateTransactionData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String accountId = ...;
double amount = ...;
String description = ...;
Timestamp transactionDate = ...;

final ref = ExampleConnector.instance.createTransaction(
  accountId: accountId,
  amount: amount,
  description: description,
  transactionDate: transactionDate,
).ref();
ref.execute();
```


### CreateGoal
#### Required Arguments
```dart
String goalName = ...;
double targetAmount = ...;
double currentAmount = ...;
DateTime targetDate = ...;
String goalType = ...;
ExampleConnector.instance.createGoal(
  goalName: goalName,
  targetAmount: targetAmount,
  currentAmount: currentAmount,
  targetDate: targetDate,
  goalType: goalType,
).execute();
```

#### Optional Arguments
We return a builder for each query. For CreateGoal, we created `CreateGoalBuilder`. For queries and mutations with optional parameters, we return a builder class.
The builder pattern allows Data Connect to distinguish between fields that haven't been set and fields that have been set to null. A field can be set by calling its respective setter method like below:
```dart
class CreateGoalVariablesBuilder {
  ...
   CreateGoalVariablesBuilder description(String? t) {
   _description.value = t;
   return this;
  }

  ...
}
ExampleConnector.instance.createGoal(
  goalName: goalName,
  targetAmount: targetAmount,
  currentAmount: currentAmount,
  targetDate: targetDate,
  goalType: goalType,
)
.description(description)
.execute();
```

#### Return Type
`execute()` returns a `OperationResult<CreateGoalData, CreateGoalVariables>`
```dart
/// Result of an Operation Request (query/mutation).
class OperationResult<Data, Variables> {
  OperationResult(this.dataConnect, this.data, this.ref);
  Data data;
  OperationRef<Data, Variables> ref;
  FirebaseDataConnect dataConnect;
}

final result = await ExampleConnector.instance.createGoal(
  goalName: goalName,
  targetAmount: targetAmount,
  currentAmount: currentAmount,
  targetDate: targetDate,
  goalType: goalType,
);
CreateGoalData data = result.data;
final ref = result.ref;
```

#### Getting the Ref
Each builder returns an `execute` function, which is a helper function that creates a `Ref` object, and executes the underlying operation.
An example of how to use the `Ref` object is shown below:
```dart
String goalName = ...;
double targetAmount = ...;
double currentAmount = ...;
DateTime targetDate = ...;
String goalType = ...;

final ref = ExampleConnector.instance.createGoal(
  goalName: goalName,
  targetAmount: targetAmount,
  currentAmount: currentAmount,
  targetDate: targetDate,
  goalType: goalType,
).ref();
ref.execute();
```

