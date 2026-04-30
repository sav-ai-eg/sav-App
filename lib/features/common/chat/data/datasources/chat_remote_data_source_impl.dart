import 'package:injectable/injectable.dart';
import 'package:sav/core/constants/api_endpoints.dart';
import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/core/network/api_consumer.dart';
import 'package:sav/features/common/chat/data/datasources/chat_remote_data_source.dart';
import 'package:sav/features/common/chat/data/models/chat_conversation_model.dart';
import 'package:sav/features/common/chat/data/models/chat_message_model.dart';
import 'package:sav/features/common/chat/data/models/chat_read_receipt_model.dart';
import 'package:sav/features/common/chat/data/models/chat_unread_summary_model.dart';

@LazySingleton(as: ChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  ChatRemoteDataSourceImpl(this._apiConsumer);

  final ApiConsumer _apiConsumer;

  @override
  Future<ChatConversationModel> bootstrapConversation({int? driverId}) async {
    try {
      final response = await _apiConsumer.post(
        ApiEndpoints.chatConversationsBootstrap,
        body: <String, dynamic>{if (driverId != null) 'driver_id': driverId},
      );

      if (_isSuccess(response.statusCode)) {
        final payload = _extractObject(
          response.rawData,
          response.data,
          keys: const <String>['conversation', 'data', 'result'],
        );
        if (payload != null) {
          return ChatConversationModel.fromBackendMap(payload);
        }
      }

      throw ServerException(
        _extractErrorMessage(
          response.data,
          fallback: 'Unable to open chat right now.',
        ),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  @override
  Future<List<ChatConversationModel>> loadConversations({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final response = await _apiConsumer.get(
        ApiEndpoints.chatConversations,
        queryParameters: <String, dynamic>{
          'page': page,
          'page_size': pageSize,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
        },
      );

      if (!_isSuccess(response.statusCode)) {
        throw ServerException(
          _extractErrorMessage(
            response.data,
            fallback: 'Unable to load conversations right now.',
          ),
        );
      }

      return _extractItems(response.rawData, response.data)
          .whereType<Map<String, dynamic>>()
          .map(ChatConversationModel.fromBackendMap)
          .toList();
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  @override
  Future<List<ChatMessageModel>> loadMessages({
    required int conversationId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _apiConsumer.get(
        ApiEndpoints.chatConversationMessages(conversationId),
        queryParameters: <String, dynamic>{'page': page, 'page_size': pageSize},
      );

      if (!_isSuccess(response.statusCode)) {
        throw ServerException(
          _extractErrorMessage(
            response.data,
            fallback: 'Unable to load chat messages right now.',
          ),
        );
      }

      return _extractItems(response.rawData, response.data)
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageModel.fromBackendMap)
          .toList();
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required int conversationId,
    required String text,
  }) async {
    try {
      final response = await _apiConsumer.post(
        ApiEndpoints.chatConversationMessages(conversationId),
        body: <String, dynamic>{'text': text},
      );

      if (response.statusCode == 201 || _isSuccess(response.statusCode)) {
        final payload = _extractObject(
          response.rawData,
          response.data,
          keys: const <String>['message', 'data', 'result'],
        );
        if (payload != null) {
          return ChatMessageModel.fromBackendMap(payload);
        }
      }

      throw ServerException(
        _extractErrorMessage(
          response.data,
          fallback: 'Unable to send message right now.',
        ),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  @override
  Future<ChatReadReceiptModel> markConversationRead({
    required int conversationId,
    int? messageId,
  }) async {
    try {
      final response = await _apiConsumer.patch(
        ApiEndpoints.chatConversationMarkRead(conversationId),
        body: <String, dynamic>{if (messageId != null) 'message_id': messageId},
      );

      if (_isSuccess(response.statusCode)) {
        final payload = _extractObject(
          response.rawData,
          response.data,
          keys: const <String>['receipt', 'read_receipt', 'data', 'result'],
        );
        if (payload != null) {
          return ChatReadReceiptModel.fromBackendMap(payload);
        }
      }

      throw ServerException(
        _extractErrorMessage(
          response.data,
          fallback: 'Unable to mark messages as read right now.',
        ),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  @override
  Future<ChatUnreadSummaryModel> loadUnreadSummary() async {
    try {
      final response = await _apiConsumer.get(ApiEndpoints.chatUnreadSummary);
      if (_isSuccess(response.statusCode)) {
        final payload = _extractObject(
          response.rawData,
          response.data,
          keys: const <String>['summary', 'data', 'result'],
        );
        if (payload != null) {
          return ChatUnreadSummaryModel.fromBackendMap(payload);
        }
      }

      throw ServerException(
        _extractErrorMessage(
          response.data,
          fallback: 'Unable to load unread summary right now.',
        ),
      );
    } on AppException {
      rethrow;
    } catch (_) {
      throw const UnknownException();
    }
  }

  bool _isSuccess(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  List<dynamic> _extractItems(
    dynamic rawData,
    Map<String, dynamic> fallbackData,
  ) {
    return _readItems(rawData) ?? _readItems(fallbackData) ?? const <dynamic>[];
  }

  List<dynamic>? _readItems(dynamic value) {
    if (value is List) {
      return value;
    }

    if (value is Map<String, dynamic>) {
      return _readItemsFromMap(value);
    }

    if (value is Map) {
      return _readItemsFromMap(Map<String, dynamic>.from(value));
    }

    return null;
  }

  List<dynamic>? _readItemsFromMap(Map<String, dynamic> map) {
    for (final key in const <String>[
      'results',
      'items',
      'conversations',
      'messages',
      'data',
    ]) {
      final nestedItems = _readItems(map[key]);
      if (nestedItems != null) {
        return nestedItems;
      }
    }

    return null;
  }

  Map<String, dynamic>? _extractObject(
    dynamic rawData,
    Map<String, dynamic> fallbackData, {
    required List<String> keys,
  }) {
    return _readObject(rawData, keys: keys) ??
        _readObject(fallbackData, keys: keys);
  }

  Map<String, dynamic>? _readObject(
    dynamic value, {
    required List<String> keys,
  }) {
    if (value is Map<String, dynamic>) {
      return _readObjectFromMap(value, keys: keys);
    }

    if (value is Map) {
      return _readObjectFromMap(Map<String, dynamic>.from(value), keys: keys);
    }

    return null;
  }

  Map<String, dynamic>? _readObjectFromMap(
    Map<String, dynamic> map, {
    required List<String> keys,
  }) {
    for (final key in keys) {
      final nested = map[key];
      if (nested is Map<String, dynamic>) {
        return nested;
      }
      if (nested is Map) {
        return Map<String, dynamic>.from(nested);
      }
    }

    for (final key in const <String>['payload', 'data', 'result']) {
      final nested = map[key];
      if (nested is Map<String, dynamic>) {
        final unwrapped = _readObjectFromMap(nested, keys: keys);
        return unwrapped ?? nested;
      }
      if (nested is Map) {
        final nestedMap = Map<String, dynamic>.from(nested);
        final unwrapped = _readObjectFromMap(nestedMap, keys: keys);
        return unwrapped ?? nestedMap;
      }
    }

    return map.isEmpty ? null : map;
  }

  String _extractErrorMessage(
    Map<String, dynamic> payload, {
    required String fallback,
  }) {
    final detail = _readMessage(payload['detail']);
    if (detail != null) {
      return detail;
    }

    for (final key in const <String>['non_field_errors', 'message', 'error']) {
      final message = _readMessage(payload[key]);
      if (message != null) {
        return message;
      }
    }

    for (final entry in payload.entries) {
      if (entry.key == 'detail') {
        continue;
      }

      final nestedMessage = _readMessage(entry.value);
      if (nestedMessage != null) {
        return nestedMessage;
      }
    }

    return fallback;
  }

  String? _readMessage(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final message = value.trim();
      return message.isEmpty ? null : message;
    }

    if (value is List) {
      for (final item in value) {
        final message = _readMessage(item);
        if (message != null) {
          return message;
        }
      }
      return null;
    }

    if (value is Map) {
      for (final entry in value.entries) {
        final message = _readMessage(entry.value);
        if (message != null) {
          return message;
        }
      }
      return null;
    }

    return null;
  }
}
