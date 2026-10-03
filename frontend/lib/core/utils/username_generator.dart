 import 'dart:math';

class UsernameGenerator {
  static String fromName(String name) {
    final cleaned = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), ''); // remove spaces & symbols

    final randomSuffix = Random().nextInt(9000) + 1000; // 4-digit number

    return "$cleaned$randomSuffix";
  }
}