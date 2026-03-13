import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:connect/core/errors/failures.dart';
import 'package:connect/features/chat/domain/repositories/i_chat_repository.dart';

class UploadMediaUseCase {
  final IChatRepository repository;

  UploadMediaUseCase(this.repository);

  Future<Either<Failures, Map<String, dynamic>>> call(File file) async {
    return await repository.uploadMedia(file);
  }
}