abstract class SignatureEvent {}

class LoadDocumentsEvent extends SignatureEvent {}

class SubmitSignatureEvent extends SignatureEvent {
  final String token;
  final String base64Image;
  SubmitSignatureEvent(this.token, this.base64Image);
}