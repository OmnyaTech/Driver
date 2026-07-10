import '../models/app_trip_expense.dart';
import 'auth_service.dart';
import 'journey_service.dart';

class TripExpenseService {
  TripExpenseService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<List<AppTripExpense>> listExpenses() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .schema('driver')
        .from('trip_expenses')
        .select()
        .eq('user_id', user.id)
        .order('occurred_at', ascending: false);

    final journeys = await JourneyService(
      authService: _authService,
    ).listJourneyOptions();
    final labels = {for (final journey in journeys) journey.id: journey.label};

    return rows.map<AppTripExpense>((row) {
      final journeyId = row['journey_id']?.toString();
      return AppTripExpense(
        id: row['id'].toString(),
        type: row['type'].toString(),
        description: row['description'] as String?,
        amount: double.tryParse(row['amount'].toString()) ?? 0,
        occurredAt: DateTime.parse(row['occurred_at'].toString()),
        journeyId: journeyId,
        journeyLabel: journeyId == null ? null : labels[journeyId],
      );
    }).toList();
  }

  Future<void> createExpense({
    required String type,
    required String amount,
    required DateTime occurredAt,
    String? description,
    String? journeyId,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    await client.schema('driver').from('trip_expenses').insert({
      'user_id': user.id,
      'journey_id': _normalizeString(journeyId),
      'type': type,
      'description': _normalizeString(description),
      'amount': _stringToDouble(amount),
      'occurred_at': occurredAt.toUtc().toIso8601String(),
    });
  }

  String? _normalizeString(String? value) {
    final normalized = value?.trim();
    return (normalized == null || normalized.isEmpty) ? null : normalized;
  }

  double _stringToDouble(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    return double.parse(normalized);
  }
}
