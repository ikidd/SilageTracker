import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectivityService extends ChangeNotifier {
  final SupabaseClient supabaseClient;
  Timer? _healthCheckTimer;
  bool _isConnected = true;
  DateTime? _lastSuccessfulConnection;

  ConnectivityService(this.supabaseClient) {
    startMonitoring();
  }

  bool get isConnected => _isConnected;
  DateTime? get lastSuccessfulConnection => _lastSuccessfulConnection;

  void startMonitoring() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkConnection();
    });
    // Initial check
    checkConnection();
  }

  Future<void> checkConnection() async {
    try {
      // Try to make a simple health check query
      final response = await supabaseClient
          .from('silage_entries')
          .select('count')
          .limit(1)
          .maybeSingle();
      
      // If we get here, the connection is working
      _isConnected = true;
      _lastSuccessfulConnection = DateTime.now();
    } catch (e) {
      // Only mark as disconnected for network-related errors
      if (e is PostgrestException) {
        // Database errors don't indicate connection issues
        _isConnected = true;
      } else if (e is SocketException || 
                e is TimeoutException || 
                e.toString().toLowerCase().contains('network') ||
                e.toString().toLowerCase().contains('connection')) {
        _isConnected = false;
        debugPrint('Supabase connection error: $e');
      } else {
        // For other errors, assume connection is still okay
        _isConnected = true;
        debugPrint('Non-connection Supabase error: $e');
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    super.dispose();
  }
}

class ConnectivityServiceProvider extends InheritedNotifier<ConnectivityService> {
  const ConnectivityServiceProvider({
    super.key,
    required ConnectivityService service,
    required super.child,
  }) : super(notifier: service);

  static ConnectivityService of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ConnectivityServiceProvider>();
    if (provider == null) {
      throw FlutterError(
        'ConnectivityService not found in context. '
        'Make sure to wrap your app with ConnectivityServiceProvider.',
      );
    }
    return provider.notifier!;
  }
}

class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ConnectivityServiceProvider.of(context);
    
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        if (!service.isConnected) {
          return Container(
            color: Colors.red.withOpacity(0.8),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Network connection issue. Some features may be unavailable.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}