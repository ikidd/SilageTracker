import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sample_feature/sample_item_details_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'silage_entry_view.dart';
import 'herds_view.dart';

/// The Widget that configures your application.
class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late SupabaseClient _supabaseClient;

  @override
  void initState() {
    super.initState();
    _supabaseClient = SupabaseClient(
      'https://sxbetuloniiplaafjeaf.supabase.co', // Replace with your Supabase URL
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4YmV0dWxvbmlpcGxhYWZqZWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1MzcxNjgsImV4cCI6MjA1NDExMzE2OH0.GD3M_4BEm80dKCvjJxgm_D_dKialG0NiVO2FjS1Vka4', // Replace with your Supabase public anon key
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'app',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: widget.settingsController.themeMode,
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return SettingsView(controller: widget.settingsController);
                  case SampleItemDetailsView.routeName:
                    return const SampleItemDetailsView();
                  case SilageEntryView.routeName:
                    return SilageEntryView(supabaseClient: _supabaseClient);
                  case HerdsView.routeName:
                    return HerdsView(supabaseClient: _supabaseClient);
                  default:
                    return Scaffold(
                      appBar: AppBar(
                        title: Text('Home'),
                      ),
                      body: ListView(
                        children: [
                          ListTile(
                            title: Text('Silage'),
                            onTap: () {
                              Navigator.pushNamed(context, SilageEntryView.routeName);
                            },
                          ),
                          ListTile(
                            title: Text('Herds'),
                            onTap: () {
                              Navigator.pushNamed(context, HerdsView.routeName);
                            },
                          ),
                        ],
                      ),
                    );
                }
              },
            );
          },
        );
      },
    );
  }
}
