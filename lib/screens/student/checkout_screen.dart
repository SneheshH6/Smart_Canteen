import 'package:flutter/material.dart';
import '../payment/payment_screen.dart';

/// [CheckoutScreen] has been consolidated into [PaymentScreen]
/// to eliminate the redundant intermediate checkout page.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaymentScreen();
  }
}
