import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/utils/validators.dart' as v;

void main() {
  test('email validation', () {
    expect(v.emailValidator(''), isNotNull);
    expect(v.emailValidator('user@domain'), isNotNull);
    expect(v.emailValidator('user@domain.com'), isNull);
  });

  test('password validation', () {
    expect(v.passwordValidator(''), isNotNull);
    expect(v.passwordValidator('short'), isNotNull);
    expect(v.passwordValidator('longenough'), isNull);
  });

  test('confirm password validation', () {
    expect(v.confirmPasswordValidator('', 'pwd'), isNotNull);
    expect(v.confirmPasswordValidator('pwd', 'pwd'), isNull);
    expect(v.confirmPasswordValidator('no', 'pwd'), isNotNull);
  });

  test('cnp validation', () {
    expect(v.cnpValidator(''), isNotNull);
    expect(v.cnpValidator('123'), isNotNull);
    expect(v.cnpValidator('1234567890123'), isNull);
  });

  test('phone validation', () {
    expect(v.phoneValidator(''), isNotNull);
    expect(v.phoneValidator('1234'), isNotNull);
    expect(v.phoneValidator('0712345678'), isNull);
  });

  test('cuim validation', () {
    expect(v.cuimValidator(''), isNotNull);
    expect(v.cuimValidator('1234567'), isNotNull); // too short
    expect(v.cuimValidator('12345678'), isNull);
  });

  test('cod parafa validation', () {
    expect(v.codParafaValidator(''), isNotNull);
    expect(v.codParafaValidator('ab'), isNotNull);
    expect(v.codParafaValidator('ABC-123'), isNull);
  });
}
