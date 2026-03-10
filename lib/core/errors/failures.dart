import 'package:equatable/equatable.dart';

class Failures extends Equatable{
  final String message;

  const Failures(this.message);

  @override
  List<Object?> get props => [message];
}

//Server Side Failures handle
class ServerFailure extends Failures{
  const ServerFailure(super.message);
}

//Network Failures handle
class NetworkFailure extends Failures{
  const NetworkFailure(super.message);
}

//Local Storage Side Failures handle
class CacheFailure extends Failures{
  const CacheFailure(super.message);
}