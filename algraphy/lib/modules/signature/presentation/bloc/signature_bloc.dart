import 'package:algraphy/modules/signature/data/repository/signature_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class SignatureEvent {}
class SubmitSignatureEvent extends SignatureEvent {
  final String token;
  final String base64Image;
  SubmitSignatureEvent(this.token, this.base64Image);
}

// States
abstract class SignatureState {}
class SignatureInitial extends SignatureState {}
class SignatureLoading extends SignatureState {}
class SignatureSuccess extends SignatureState {}
class SignatureError extends SignatureState { final String message; SignatureError(this.message); }

class SignatureBloc extends Bloc<SignatureEvent, SignatureState> {
  final SignatureRepository repository;

  SignatureBloc(this.repository) : super(SignatureInitial()) {
    on<SubmitSignatureEvent>((event, emit) async {
      emit(SignatureLoading());
      try {
        final response = await repository.submitSignature(
          token: event.token,
          base64Image: event.base64Image,
        );
        if (response.data['status'] == 'success') {
          emit(SignatureSuccess());
        } else {
          emit(SignatureError("Failed to save signature"));
        }
      } catch (e) {
        emit(SignatureError(e.toString()));
      }
    });
  }
}