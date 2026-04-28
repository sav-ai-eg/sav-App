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
        return ChatConversationModel.fromBackendMap(response.data);
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
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
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
        queryParameters: <String, dynamic>{
          'page': page,
          'page_size': pageSize,
        },
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
        return ChatMessageModel.fromBackendMap(response.data);
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
        return ChatReadReceiptModel.fromBackendMap(response.data);
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
        return ChatUnreadSummaryModel.fromBackendMap(response.data);
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

  List<dynamic> _extractItems(dynamic rawData, Map<String, dynamic> fallbackData) {
    if (rawData is List) {
      return rawData;
    }

    if (fallbackData['results'] is List) {
      return fallbackData['results'] as List<dynamic>;
    }

    return const <dynamic>[];
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