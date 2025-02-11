import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'silage_entry_view.dart';
import 'herds_view.dart';
import 'services/connectivity_service.dart';
import 'services/auth_service.dart';
import 'auth/auth_view.dart';

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
  late ConnectivityService _connectivityService;
  late AuthService _authService;
  int _selectedIndex = 0; // 0 for settings
  bool _wasInSubPage = false;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  void _initServices() {
    final supabaseClient = Supabase.instance.client;
    _connectivityService = ConnectivityService(supabaseClient);
    _authService = AuthService();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: _authService),
        ChangeNotifierProvider<ConnectivityService>.value(value: _connectivityService),
      ],
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
            home: Consumer<AuthService>(
              builder: (context, authService, _) {
                if (!authService.isAuthenticated) {
                  return const AuthView();
                }

                return Navigator(
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
                                                    supabaseClient: Supabase.instance.client,
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
                                                    supabaseClient: Supabase.instance.client,
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
                        floatingActionButton: _selectedIndex == 0 ? FloatingActionButton(
                          onPressed: () {
                            setState(() {
                              _selectedIndex = 1;
                            });
                          },
                          child: const Icon(Icons.settings),
                        ) : null,
                      ),
                    );
                  },
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
