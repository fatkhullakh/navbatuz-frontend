import 'package:flutter/material.dart';

class ClientPickerScreen extends StatelessWidget {
  const ClientPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick client')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Fatkhullakh'),
            subtitle: const Text('+998 90 000 00 00'),
            onTap: () => Navigator.pop<Map<String, String?>>(context, {
              'guestPhone': '+998900000000',
              'guestName': 'Fatkhullakh',
            }),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('John Doe (Customer)'),
            subtitle: const Text('customer account'),
            onTap: () => Navigator.pop<Map<String, String?>>(context, {
              'customerId': 'CUSTOMER_ID_STUB',
            }),
          ),
        ],
      ),
    );
  }
}
