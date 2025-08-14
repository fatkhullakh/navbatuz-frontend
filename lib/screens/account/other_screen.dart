import 'package:flutter/material.dart';

class OtherScreen extends StatelessWidget {
  const OtherScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('About NavbatUz')),
        body: ListView(children: const [
          ListTile(title: Text('About NavbatUz')),
          ListTile(title: Text('Terms of Service')),
          ListTile(title: Text('Privacy Policy')),
        ]),
      );
}
