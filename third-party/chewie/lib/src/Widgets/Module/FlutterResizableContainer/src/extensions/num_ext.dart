import 'package:decimal/decimal.dart';

extension DoubleExtensions on double {
  Decimal toDecimal() => Decimal.parse(toString());
}

extension ListDoubleExtensions on Iterable<double> {
  double sum() => fold(0.0, (sum, curr) => sum + curr);
}

extension ListIntExtensions on Iterable<int> {
  int sum() => fold(0, (sum, curr) => sum + curr);
}
