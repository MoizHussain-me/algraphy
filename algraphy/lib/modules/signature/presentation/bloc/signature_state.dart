import 'package:algraphy/modules/signature/data/models/signature_request_model.dart';

abstract class SignatureState {}

class SignatureInitial extends SignatureState {}
class SignatureLoading extends SignatureState {}
class SignatureLoaded extends SignatureState {
  final List<SignatureRequestModel> documents;
  SignatureLoaded(this.documents);
}
class SignatureSuccess extends SignatureState {}
class SignatureError extends SignatureState {
  final String message;
  SignatureError(this.message);
}