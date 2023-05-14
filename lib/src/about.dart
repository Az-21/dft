import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        elevation: 5,
        title: const Text('About'),
      ),
      body: ListView(
        children: const <Widget>[
          ListTile(
            leading: Icon(Icons.calculate),
            title: Text('n-point DFT Calculator'),
            subtitle: Text('Radix2 DIT FFT algorithm.'),
          ),
          ListTile(
            leading: Icon(Icons.code),
            title: Text('Made by Az-21'),
            subtitle: Text('Built with Flutter'),
          ),
          ListTile(
            leading: Icon(Icons.email_outlined),
            title: Text('flutterDevAz21@google.com'),
            subtitle: Text('Report bugs and errors'),
          ),
        ],
      ),
    );
  }
}
