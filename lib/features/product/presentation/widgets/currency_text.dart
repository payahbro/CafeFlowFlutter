import 'package:flutter/material.dart';

class CurrencyText extends StatelessWidget {
  const CurrencyText({super.key, required this.price, this.style});

  final int price;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(_formatRupiah(price), style: style);
  }

  String _formatRupiah(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < raw.length; index++) {
      final reverseIndex = raw.length - index;
      buffer.write(raw[index]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString()}';
  }
}

