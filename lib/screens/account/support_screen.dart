import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Support')),
        body: ListView(children: const [
          ListTile(title: Text('FAQ'), trailing: Icon(Icons.chevron_right)),
          ListTile(
              title: Text('Contact Us'), trailing: Icon(Icons.chevron_right)),
          ListTile(
              title: Text('Report a problem'),
              trailing: Icon(Icons.chevron_right)),
        ]),
      );
}
