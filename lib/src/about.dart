import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  static const _websiteURL = 'https://dft-calculator-az-21.vercel.app/';
  static const _androidURL =
      'https://play.google.com/store/apps/details?id=com.flutterDevAz21.dft';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        elevation: 5,
        title: const Text('About'),
      ),
      body: ListView(
        children: <Widget>[
          const ListTile(
            leading: Icon(Icons.calculate),
            title: Text('n-point DFT Calculator'),
            subtitle: Text('Radix2 DIT FFT algorithm.'),
          ),
          const Divider(height: 40),
          const ListTile(
            leading: Icon(Icons.important_devices),
            title: Text(
              'Available On',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.laptop_chromebook),
            title: const Text('Website | Progressive Web App'),
            subtitle: const Text('DFT Calculator on Web'),
            trailing: IconButton(
                icon: const Icon(
                  Icons.launch,
                  color: Colors.green,
                ),
                onPressed: _launchWeb),
          ),
          ListTile(
            leading: const Icon(Icons.phone_android_sharp),
            title: const Text('Google Play Store'),
            subtitle: const Text('DFT Calculator on App'),
            trailing: IconButton(
                icon: const Icon(
                  Icons.launch,
                  color: Colors.green,
                ),
                onPressed: _launchAndroid),
          ),
          const Text(
            '                   Google Play is trademark of Google LLC',
            style: TextStyle(fontWeight: FontWeight.w300),
          ),
          const Divider(height: 40),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Made by Az-21'),
            subtitle: Text('Built with Flutter'),
          ),
          const ListTile(
            leading: Icon(Icons.email_outlined),
            title: Text('flutterDevAz21@google.com'),
            subtitle: Text('Report bugs and errors'),
          ),
        ],
      ),
    );
  }

// Launch WebApp
  void _launchWeb() async => await canLaunch(_websiteURL)
      ? await launch(_websiteURL)
      : throw 'Could not launch $_websiteURL';

// Launch Play Store Listing
  void _launchAndroid() async => await canLaunch(_androidURL)
      ? await launch(_androidURL)
      : throw 'Could not launch $_androidURL';
}
