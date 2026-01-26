import 'package:private_chat_hub/core/utils/result.dart';
import 'package:private_chat_hub/domain/entities/connection.dart';

abstract class IConnectionRepository {
  Future<Result<List<ConnectionProfile>>> getProfiles();

  Future<Result<ConnectionProfile?>> getDefaultProfile();

  Future<Result<ConnectionProfile>> getProfile(int id);

  Future<Result<ConnectionProfile>> createProfile({
    required String name,
    required String host,
    int port = 11434,
    bool isDefault = false,
  });

  Future<Result<ConnectionProfile>> updateProfile(ConnectionProfile profile);

  Future<Result<void>> deleteProfile(int id);

  Future<Result<void>> setDefaultProfile(int id);

  Future<Result<ConnectionHealth>> checkHealth(ConnectionProfile profile);

  Stream<ConnectionHealth> monitorConnection(ConnectionProfile profile);
}
