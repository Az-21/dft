import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Links and URL launcher
const String _github = "https://github.com/";
final Uri _wikipedia = Uri.parse("https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm");
final Uri _githubProfile = Uri.parse("${_github}Az-21/");
final Uri _githubRepo = Uri.parse("${_github}Az-21/dft");
final Uri _githubIssue = Uri.parse("${_github}Az-21/dft/issues");
final Uri _complex = Uri.parse("${_github}rwl/complex");
final Uri _getX = Uri.parse("${_github}jonataslaw/getx");
final Uri _urlLauncher = Uri.parse("${_github}flutter/packages/tree/main/packages/url_launcher/url_launcher");
final Uri _flutterLauncherIcons = Uri.parse("${_github}fluttercommunity/flutter_launcher_icons");
final Uri _dynamicColor = Uri.parse("${_github}material-foundation/flutter-packages/tree/main/packages/dynamic_color");
final Uri _sfCharts = Uri.parse("${_github}syncfusion/flutter-widgets/tree/master/packages/syncfusion_flutter_charts");

Future<void> _launchUrl(url) async {
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
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
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.arrow_right),
            title: const Text("n-point DFT Calculator"),
            subtitle: const Text("Radix2 DIT FFT algorithm"),
            trailing: OutlinedButton.icon(
              onPressed: () => _launchUrl(_wikipedia),
              icon: const Icon(Icons.school),
              label: const Text("Wikipedia"),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_right),
            title: const Text('Made by Az-21'),
            subtitle: const Text('Built with Flutter'),
            trailing: OutlinedButton.icon(
              onPressed: () => _launchUrl(_githubProfile),
              icon: const Icon(Icons.assignment_ind),
              label: const Text("Profile"),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_right),
            title: const Text("Source Code"),
            subtitle: const Text("View on GitHub | GPL v3"),
            trailing: OutlinedButton.icon(
              onPressed: () => _launchUrl(_githubRepo),
              icon: const Icon(Icons.code),
              label: const Text("Repo"),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_right),
            title: const Text("Report Issue"),
            subtitle: const Text("Open a GitHub Issue"),
            trailing: OutlinedButton.icon(
              onPressed: () => _launchUrl(_githubIssue),
              icon: const Icon(Icons.bug_report),
              label: const Text("Report"),
            ),
          ),
          const SizedBox(height: 32),
          ListTile(
            leading: Icon(Icons.favorite_outline, color: Theme.of(context).colorScheme.error),
            title: const Text("Credits"),
            subtitle: const Text("Special thanks to these open source projects"),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_right),
            title: const Text("Complex"),
            subtitle: const Text("Apache 2.0 License"),
            trailing: IconButton.outlined(
              onPressed: () => _launchUrl(_complex),
              icon: const Icon(Icons.open_in_new),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_right),
            title: const Text("Dynamic Color"),
            subtitle: const Text("Apache 2.0 License"),
            trailing: IconButton.outlined(
              onPressed: () => _launchUrl(_dynamicColor),
              icon: const Icon(Icons.open_in_new),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_right),
            title: const Text("Syncfusion Flutter Charts"),
            subtitle: const Text("Syncfusion Community License"),
            trailing: IconButton.outlined(
              onPressed: () => _launchUrl(_sfCharts),
              icon: const Icon(Icons.open_in_new),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_right),
            title: const Text("GetX"),
            subtitle: const Text("MIT License"),
            trailing: IconButton.outlined(
              onPressed: () => _launchUrl(_getX),
              icon: const Icon(Icons.open_in_new),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_right),
            title: const Text("URL Launcher"),
            subtitle: const Text("BSD 3-Clause License"),
            trailing: IconButton.outlined(
              onPressed: () => _launchUrl(_urlLauncher),
              icon: const Icon(Icons.open_in_new),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.arrow_right),
            title: const Text("Flutter Launcher Icons"),
            subtitle: const Text("MIT License"),
            trailing: IconButton.outlined(
              onPressed: () => _launchUrl(_flutterLauncherIcons),
              icon: const Icon(Icons.open_in_new),
            ),
          ),
          const SizedBox(height: 64),
          const ListTile(
            leading: Icon(Icons.book),
            titleAlignment: ListTileTitleAlignment.top,
            title: Text("Disclaimer"),
            subtitle: Text(
                "Use of trademarks throughout any text or content is purely for informative purposes. It does not imply any endorsement, sponsorship, or affiliation between the companies mentioned and the content provided. The respective companies hold all rights to their trademarks, logos, and any other intellectual property associated with their brand identities."),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
