/// RF57 / RF59: valor de las cuotas de una compra simulada y comparación de
/// alternativas. Puro: no lee ni escribe la base.
library;

import 'dart:math' as math;

import 'installments.dart';

/// RF57: de 1 (al contado) a 48 cuotas.
const kMinSimulatedInstallments = 1;

/// Números de cuotas que se comparan siempre (RF59), además del elegido.
const kAlternativeCounts = [1, 3, 6, 12];

/// Tasa mensual máxima aceptada, en porcentaje. Sobre esto es casi seguro un
/// error de tipeo (una tasa anual escrita como mensual).
const kMaxMonthlyRatePercent = 10.0;

/// Tasa mensual en porcentaje desde lo que escribe el usuario ("1,89",
/// "1.89", "2 %"). Vacío = 0 (sin interés). Null si no es un número válido
/// entre 0 y [kMaxMonthlyRatePercent].
double? parseMonthlyRatePercent(String text) {
  final clean = text.replaceAll('%', '').replaceAll(',', '.').trim();
  if (clean.isEmpty) return 0;
  final value = double.tryParse(clean);
  if (value == null || value.isNaN || value < 0) return null;
  if (value > kMaxMonthlyRatePercent) return null;
  return value;
}

/// Valor de la cuota fija (sistema francés) para [principal] en [count]
/// cuotas con tasa mensual [ratePercent]: P·i / (1 − (1 + i)^−n),
/// redondeado al peso.
int fixedInstallment(int principal, double ratePercent, int count) {
  final i = ratePercent / 100;
  if (i == 0) return (principal / count).round();
  return (principal * i / (1 - math.pow(1 + i, -count))).round();
}

/// Una forma de pagar la compra: cuántas cuotas y cuánto cada una.
class PurchaseOption {
  const PurchaseOption._(this.principal, this.amounts);

  /// Cuotas de la compra. Al contado (1 cuota) nunca lleva interés. Sin
  /// tasa, son las mismas que se registran a mano (la última absorbe el
  /// resto de la división). Con tasa, todas valen la cuota fija.
  factory PurchaseOption(int principal, int count, {double ratePercent = 0}) {
    if (count < kMinSimulatedInstallments || count > kMaxInstallments) {
      throw ArgumentError.value(count, 'count');
    }
    if (count == 1) return PurchaseOption._(principal, [principal]);
    if (ratePercent == 0) {
      return PurchaseOption._(principal, installmentAmounts(principal, count));
    }
    final cuota = fixedInstallment(principal, ratePercent, count);
    return PurchaseOption._(principal, List.filled(count, cuota));
  }

  /// Precio de la compra, sin interés.
  final int principal;

  /// Monto de cada cuota, en orden.
  final List<int> amounts;

  int get count => amounts.length;
  bool get isCash => count == 1;

  /// Valor de la primera cuota (todas iguales salvo, a veces, la última).
  int get installment => amounts.first;

  /// Lo que se termina pagando.
  int get total => amounts.fold(0, (sum, a) => sum + a);

  /// Interés pagado: [total] menos [principal]. 0 sin tasa.
  int get interest => total - principal;
}

/// RF59: números de cuotas a comparar: al contado, 3, 6 y 12, y el elegido
/// por el usuario. Ordenados y sin repetir.
List<int> alternativeCounts(int chosen) =>
    ({...kAlternativeCounts, chosen}.toList()..sort());
