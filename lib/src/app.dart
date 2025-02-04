import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'silage_entry_view.dart';
import 'herds_view.dart';
import 'services/connectivity_service.dart';

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
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _supabaseClient = SupabaseClient(
      'https://sxbetuloniiplaafjeaf.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4YmV0dWxvbmlpcGxhYWZqZWFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg1MzcxNjgsImV4cCI6MjA1NDExMzE2OH0.GD3M_4BEm80dKCvjJxgm_D_dKialG0NiVO2FjS1Vka4',
    );
    _connectivityService = ConnectivityService(_supabaseClient);
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConnectivityServiceProvider(
      service: _connectivityService,
      child: ListenableBuilder(
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
            builder: (context, child) {
              return Column(
                children: [
                  const ConnectionStatusWidget(),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              );
            },
            onGenerateRoute: (RouteSettings routeSettings) {
              return MaterialPageRoute<void>(
                settings: routeSettings,
                builder: (BuildContext context) {
                  switch (routeSettings.name) {
                    case SettingsView.routeName:
                      return SettingsView(controller: widget.settingsController);
                    case SilageEntryView.routeName:
                      return SilageEntryView(supabaseClient: _supabaseClient);
                    case HerdsView.routeName:
                      return HerdsView(supabaseClient: _supabaseClient);
                    default:
                      return Scaffold(
                        appBar: AppBar(
                          title: const Text('Home'),
                        ),
                        body: ListView(
                          children: [
                            ListTile(
                              title: const Text('Silage'),
                              onTap: () {
                                Navigator.pushNamed(
                                    context, SilageEntryView.routeName);
                              },
                            ),
                            ListTile(
                              title: const Text('Herds'),
                              onTap: () {
                                Navigator.pushNamed(context, HerdsView.routeName);
                              },
                            ),
                            ListTile(
                              title: const Text('Settings'),
                              leading: const Icon(Icons.settings),
                              onTap: () {
                                Navigator.pushNamed(context, SettingsView.routeName);
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
      ),
    );
  }
}
