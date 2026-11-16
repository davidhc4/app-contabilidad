import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/storage/local_store.dart';

const _key = 'deudas';
const _uuid = Uuid();

/// Cómo se cobra el interés de una deuda.
enum InterestKind {
  /// Sin interés.
  none,

  /// Un porcentaje del monto por cada periodo (interés simple).
  percent,

  /// Una cantidad fija de dinero por cada periodo.
  fixed,
}

/// Cada cuánto corre el interés.
enum InterestPeriod { day, month, year }

extension InterestPeriodInfo on InterestPeriod {
  String get label => switch (this) {
        InterestPeriod.day => 'Día',
        InterestPeriod.month => 'Mes',
        InterestPeriod.year => 'Año',
      };

  String get plural => switch (this) {
        InterestPeriod.day => 'días',
        InterestPeriod.month => 'meses',
        InterestPeriod.year => 'años',
      };

  /// Cuántos días dura, en promedio, un periodo.
  double get days => switch (this) {
        InterestPeriod.day => 1,
        InterestPeriod.month => 30.4375,
        InterestPeriod.year => 365.25,
      };
}

/// Una deuda: dinero que alguien le debe al usuario o que el usuario le debe a
/// alguien. Se guarda en el teléfono (no sale a internet).
class Debt {
  final String id;

  /// Nombre de la persona.
  final String person;

  /// true: me deben a mí. false: yo debo.
  final bool theyOweMe;

  /// Monto prestado (sin intereses).
  final double amount;

  /// Fecha y hora en que se creó/empezó la deuda.
  final DateTime createdAt;

  final InterestKind interestKind;

  /// Porcentaje (si es percent) o pesos por periodo (si es fixed).
  final double interestRate;

  final InterestPeriod period;

  /// true cuando ya se pagó.
  final bool paid;

  final String note;

  const Debt({
    required this.id,
    required this.person,
    required this.theyOweMe,
    required this.amount,
    required this.createdAt,
    this.interestKind = InterestKind.none,
    this.interestRate = 0,
    this.period = InterestPeriod.month,
    this.paid = false,
    this.note = '',
  });

  /// Cuántos periodos de interés han pasado desde que se creó.
  double periodsElapsed([DateTime? now]) {
    final elapsedDays =
        (now ?? DateTime.now()).difference(createdAt).inSeconds / 86400.0;
    if (elapsedDays <= 0) return 0;
    return elapsedDays / period.days;
  }

  /// Interés acumulado hasta ahora (interés simple).
  double interestSoFar([DateTime? now]) {
    if (paid) return 0;
    final periods = periodsElapsed(now);
    return switch (interestKind) {
      InterestKind.none => 0,
      InterestKind.percent => amount * (interestRate / 100) * periods,
      InterestKind.fixed => interestRate * periods,
    };
  }

  /// Monto que se debe ahora mismo: capital + interés acumulado.
  double currentTotal([DateTime? now]) => amount + interestSoFar(now);

  bool get hasInterest => interestKind != InterestKind.none && interestRate > 0;

  Debt copyWith({
    String? person,
    bool? theyOweMe,
    double? amount,
    DateTime? createdAt,
    InterestKind? interestKind,
    double? interestRate,
    InterestPeriod? period,
    bool? paid,
    String? note,
  }) {
    return Debt(
      id: id,
      person: person ?? this.person,
      theyOweMe: theyOweMe ?? this.theyOweMe,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      interestKind: interestKind ?? this.interestKind,
      interestRate: interestRate ?? this.interestRate,
      period: period ?? this.period,
      paid: paid ?? this.paid,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'person': person,
        'theyOweMe': theyOweMe,
        'amount': amount,
        'createdAt': createdAt.toIso8601String(),
        'interestKind': interestKind.name,
        'interestRate': interestRate,
        'period': period.name,
        'paid': paid,
        'note': note,
      };

  static Debt fromJson(Map<String, dynamic> m) {
    T pick<T>(List<T> values, String? name, T fallback) {
      for (final v in values) {
        if ((v as Enum).name == name) return v;
      }
      return fallback;
    }

    return Debt(
      id: m['id'] as String? ?? _uuid.v4(),
      person: m['person'] as String? ?? '',
      theyOweMe: m['theyOweMe'] as bool? ?? true,
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      interestKind:
          pick(InterestKind.values, m['interestKind'] as String?, InterestKind.none),
      interestRate: (m['interestRate'] as num?)?.toDouble() ?? 0,
      period: pick(InterestPeriod.values, m['period'] as String?, InterestPeriod.month),
      paid: m['paid'] as bool? ?? false,
      note: m['note'] as String? ?? '',
    );
  }
}

class DebtsNotifier extends Notifier<List<Debt>> {
  @override
  List<Debt> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final raw = await LocalStore.getString(_key);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => Debt.fromJson(e as Map<String, dynamic>))
          .toList();
      // Conserva lo que se haya creado mientras cargaba.
      final ids = {for (final d in state) d.id};
      state = [...list.where((d) => !ids.contains(d.id)), ...state];
    } catch (_) {
      // Archivo dañado: se empieza de cero.
    }
  }

  Future<void> _save() => LocalStore.setString(
        _key,
        jsonEncode([for (final d in state) d.toJson()]),
      );

  String newId() => _uuid.v4();

  Future<void> upsert(Debt debt) async {
    final i = state.indexWhere((d) => d.id == debt.id);
    if (i >= 0) {
      final copy = [...state];
      copy[i] = debt;
      state = copy;
    } else {
      state = [...state, debt];
    }
    await _save();
  }

  Future<void> remove(String id) async {
    state = [for (final d in state) if (d.id != id) d];
    await _save();
  }

  Future<void> setPaid(String id, bool paid) async {
    state = [
      for (final d in state) d.id == id ? d.copyWith(paid: paid) : d,
    ];
    await _save();
  }
}

final debtsProvider =
    NotifierProvider<DebtsNotifier, List<Debt>>(DebtsNotifier.new);

/// Totales para el resumen de arriba: cuánto me deben y cuánto debo (con
/// intereses, sin contar las deudas ya pagadas).
class DebtTotals {
  final double theyOweMe;
  final double iOwe;
  const DebtTotals(this.theyOweMe, this.iOwe);
  double get net => theyOweMe - iOwe;
}

final debtTotalsProvider = Provider<DebtTotals>((ref) {
  final debts = ref.watch(debtsProvider);
  var owed = 0.0, owe = 0.0;
  for (final d in debts) {
    if (d.paid) continue;
    final total = d.currentTotal();
    if (d.theyOweMe) {
      owed += total;
    } else {
      owe += total;
    }
  }
  return DebtTotals(owed, owe);
});
