import 'flow_database.dart';

class AccountBalanceService {
  AccountBalanceService(this._database);
  final FlowDatabase _database;

  Future<int> calculateForAccount(int accountId) async {
    final rows = await _database.database.rawQuery(
      '''
      SELECT a.opening_balance + COALESCE(SUM(
        CASE
          WHEN t.type = 'income' AND t.account_id = a.id THEN t.amount
          WHEN t.type = 'expense' AND t.account_id = a.id THEN -t.amount
          WHEN t.type = 'transfer' AND t.destination_account_id = a.id THEN t.amount
          WHEN t.type = 'transfer' AND t.account_id = a.id THEN -t.amount
          ELSE 0
        END
      ), 0) AS balance
      FROM accounts a
      LEFT JOIN transactions t
        ON t.account_id = a.id OR t.destination_account_id = a.id
      WHERE a.id = ?
      GROUP BY a.id, a.opening_balance
    ''',
      [accountId],
    );
    if (rows.isEmpty) throw StateError('Account $accountId does not exist');
    return (rows.first['balance'] as num).toInt();
  }

  Future<Map<int, int>> calculateForAccounts(Iterable<int> accountIds) async {
    final balances = <int, int>{};
    for (final accountId in accountIds.toSet()) {
      balances[accountId] = await calculateForAccount(accountId);
    }
    return balances;
  }
}
