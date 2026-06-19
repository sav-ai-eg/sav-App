import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class LocalTelemetryServer {
  HttpServer? _server;
  final StreamController<Map<String, dynamic>> _telemetryController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of incoming telemetry payloads.
  Stream<Map<String, dynamic>> get telemetryStream => _telemetryController.stream;

  /// Starts the local server on port 8080.
  Future<void> start() async {
    if (_server != null) return;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      debugPrint('[LocalTelemetryServer] Started on port 8080');

      _server!.listen((HttpRequest request) async {
        final path = request.uri.path;
        final method = request.method;

        if (method == 'POST' && (path == '/esp' || path == '/api/esp/ingest' || path == '/api/esp/ingest/')) {
          try {
            final bodyBytes = await request.fold<List<int>>([], (list, element) => list..addAll(element));
            final bodyString = utf8.decode(bodyBytes);
            final payload = json.decode(bodyString);

            if (payload is Map<String, dynamic>) {
              debugPrint('[LocalTelemetryServer] Received payload: $payload');
              _telemetryController.add(payload);

              request.response
                ..statusCode = HttpStatus.created
                ..headers.contentType = ContentType.json
                ..write(json.encode({'status': 'ok', 'source': 'local_server'}));
            } else {
              request.response
                ..statusCode = HttpStatus.badRequest
                ..write('Invalid JSON payload');
            }
          } catch (e) {
            debugPrint('[LocalTelemetryServer] Error parsing request: $e');
            request.response
              ..statusCode = HttpStatus.internalServerError
              ..write('Internal Server Error');
          } finally {
            await request.response.close();
          }
        } else if (method == 'GET' && path == '/') {
          // Health check
          request.response
            ..statusCode = HttpStatus.ok
            ..write('SAV Local Telemetry Server Running');
          await request.response.close();
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..write('Not Found');
          await request.response.close();
        }
      });
    } catch (e) {
      debugPrint('[LocalTelemetryServer] Failed to start server: $e');
    }
  }

  /// Stops the local server.
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      debugPrint('[LocalTelemetryServer] Stopped');
    }
  }
}
