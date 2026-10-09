import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vxgram/core/l10n/app_strings.dart';

void main() {
  test('number formatting follows the language', () {
    expect(AppStrings(const Locale('en')).n(1234), '1,234');
    expect(AppStrings(const Locale('fa')).n(1234), '۱٬۲۳۴');
  });
}
