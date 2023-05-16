import 'package:dft/constant/about.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> _launchUrl(String url) async {
  final Uri uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        elevation: 1,
        title: const Text("About"),
      ),
      body: ListView(
        children: const <Widget>[
          // Basic info
          ListTilesFromIterable(iterable: constDataInfo),

          // Credits
          SizedBox(height: 64),
          CreditsListTile(),
          ListTilesFromIterable(iterable: constDataCredit),

          // Disclaimer
          SizedBox(height: 64),
          DisclaimerListTile(),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Tiles with useful information and links
class ListTilesFromIterable extends StatelessWidget {
  const ListTilesFromIterable({super.key, required this.iterable});

  final List<List<String>> iterable;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Enable ListView within ListView
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),

      // Core widget
      itemCount: iterable.length,
      itemBuilder: (context, index) => ListTile(
        leading: const Icon(Icons.arrow_right),
        title: Text(iterable[index][0]),
        subtitle: Text(iterable[index][1]),
        trailing: IconButton.outlined(
          onPressed: () => _launchUrl(iterable[index][2]),
          icon: const Icon(Icons.open_in_new),
        ),
      ),
    );
  }
}

class CreditsListTile extends StatelessWidget {
  const CreditsListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.favorite_outline, color: Theme.of(context).colorScheme.error),
      title: const Text("Credits"),
      subtitle: const Text("Special thanks to these open source projects"),
    );
  }
}

class DisclaimerListTile extends StatelessWidget {
  const DisclaimerListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      titleAlignment: ListTileTitleAlignment.top,
      title: Text("Disclaimer"),
      subtitle: Text(
        "Use of trademarks throughout any text or content is purely for informative purposes. It does not imply any endorsement, sponsorship, or affiliation between the companies mentioned and the content provided. The respective companies hold all rights to their trademarks, logos, and any other intellectual property associated with their brand identities.",
        textAlign: TextAlign.justify,
        style: TextStyle(fontSize: 9),
      ),
    );
  }
}
