import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
  late Future<Database> _databaseFuture;

  @override
  void initState() {
    super.initState();
    _databaseFuture = _initDatabase();
  }

  Future<Database> _initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'herds_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE herds(id INTEGER PRIMARY KEY, name TEXT, numberOfAnimals INTEGER)',
        );
      },
      version: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Database>(
      future: _databaseFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final database = snapshot.data!;

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
                        return SilageEntryView(database: database);
                      case HerdsView.routeName:
                        return HerdsView(database: database);
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
      },
    );
  }
}
