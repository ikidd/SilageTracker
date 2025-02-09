import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  int _selectedIndex = 0; // 0 for settings
  bool _wasInSubPage = false;

  @override
  void initState() {
    super.initState();
    _initSupabase();
  }

  Future<void> _initSupabase() async {
    _supabaseClient = SupabaseClient(
      widget.settingsController.supabaseUrl,
      widget.settingsController.supabaseKey,
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
            home: Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: IndexedStack(
                      index: _selectedIndex,
                      children: [
                        // Home
                        Scaffold(
                          appBar: AppBar(
                            automaticallyImplyLeading: false,
                            leading: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => SystemNavigator.pop(),
                            ),
                          ),
                          body: Column(
                            children: [
                              const ConnectionStatusWidget(),
                              Expanded(
                                child: ListView(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  children: [
                                    Card(
                                      elevation: 4,
                                      child: ListTile(
                                        title: const Text(
                                          'Silage',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: const Text('Track feed and silage entries'),
                                        leading: Icon(
                                          Icons.grass,
                                          size: 32,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SilageEntryView(
                                                supabaseClient: _supabaseClient,
                                                settingsController: widget.settingsController,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Card(
                                      elevation: 4,
                                      child: ListTile(
                                        title: const Text(
                                          'Herds',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: const Text('Manage your herds'),
                                        leading: Icon(
                                          Icons.pets,
                                          size: 32,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => HerdsView(
                                                supabaseClient: _supabaseClient,
                                                settingsController: widget.settingsController,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Settings
                        SettingsView(
                          controller: widget.settingsController,
                          onNavigateBack: () {
                            setState(() {
                              _selectedIndex = 0;
                            });
                            if (_wasInSubPage) {
                              // If we were in a sub-page, pop back to it
                              Navigator.of(context).pop();
                              _wasInSubPage = false;
                            }
                          },
                        ),
                      ],
                    ),
                    floatingActionButton: FloatingActionButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex = 1;
                        });
                      },
                      child: const Icon(Icons.settings),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
