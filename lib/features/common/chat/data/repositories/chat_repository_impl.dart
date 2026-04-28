import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/exceptions.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/common/chat/data/datasources/chat_remote_data_source.dart';
import 'package:sav/features/common/chat/domain/entities/chat_conversation_entity.dart';
import 'package:sav/features/common/chat/domain/entities/chat_message_entity.dart';
import 'package:sav/features/common/chat/domain/entities/chat_read_receipt_entity.dart';
import 'package:sav/features/common/chat/domain/entities/chat_unread_summary_entity.dart';
import 'package:sav/features/common/chat/domain/repositories/chat_repository.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._remoteDataSource);

  final ChatRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, ChatConversationEntity>> bootstrapConversation({
    int? driverId,
  }) async {
    try {
      final conversation = await _remoteDataSource.bootstrapConversation(
        driverId: driverId,
      );
      return Right<Failure, ChatConversationEntity>(conversation);
    } on AppException catch (exception) {
      return Left<Failure, ChatConversationEntity>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, ChatConversationEntity>(
        ApiFailure('Unable to open chat right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, List<ChatConversationEntity>>> loadConversations({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final conversations = await _remoteDataSource.loadConversations(
        page: page,
        pageSize: pageSize,
        search: search,
      );
      return Right<Failure, List<ChatConversationEntity>>(conversations);
    } on AppException catch (exception) {
      return Left<Failure, List<ChatConversationEntity>>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, List<ChatConversationEntity>>(
        ApiFailure('Unable to load conversations right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> loadMessages({
    required int conversationId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final messages = await _remoteDataSource.loadMessages(
        conversationId: conversationId,
        page: page,
        pageSize: pageSize,
      );
      return Right<Failure, List<ChatMessageEntity>>(messages);
    } on AppException catch (exception) {
      return Left<Failure, List<ChatMessageEntity>>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, List<ChatMessageEntity>>(
        ApiFailure('Unable to load messages right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required int conversationId,
    required String text,
  }) async {
    try {
      final message = await _remoteDataSource.sendMessage(
        conversationId: conversationId,
        text: text,
      );
      return Right<Failure, ChatMessageEntity>(message);
    } on AppException catch (exception) {
      return Left<Failure, ChatMessageEntity>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, ChatMessageEntity>(
        ApiFailure('Unable to send message right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, ChatReadReceiptEntity>> markConversationRead({
    required int conversationId,
    int? messageId,
  }) async {
    try {
      final receipt = await _remoteDataSource.markConversationRead(
        conversationId: conversationId,
        messageId: messageId,
      );
      return Right<Failure, ChatReadReceiptEntity>(receipt);
    } on AppException catch (exception) {
      return Left<Failure, ChatReadReceiptEntity>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, ChatReadReceiptEntity>(
        ApiFailure('Unable to mark messages as read right now.'),
      );
    }
  }

  @override
  Future<Either<Failure, ChatUnreadSummaryEntity>> loadUnreadSummary() async {
    try {
      final summary = await _remoteDataSource.loadUnreadSummary();
      return Right<Failure, ChatUnreadSummaryEntity>(summary);
    } on AppException catch (exception) {
      return Left<Failure, ChatUnreadSummaryEntity>(_mapFailure(exception));
    } catch (_) {
      return const Left<Failure, ChatUnreadSummaryEntity>(
        ApiFailure('Unable to load unread summary right now.'),
      );
    }
  }

  Failure _mapFailure(AppException exception) {
    if (exception is UnauthorizedException) {
      return const ApiFailure('Session expired. Please login again.');
    }

    if (exception is NoInternetException) {
      return const NetworkFailure(
        'No internet connection. Please check your network and try again.',
      );
    }

    if (exception is RequestTimeoutException) {
      return const NetworkFailure(
        'Connection timed out. Please try again.',
      );
    }

    if (exception is CacheException) {
      return CacheFailure(exception.message);
    }

    return ApiFailure(exception.message);
  }
}