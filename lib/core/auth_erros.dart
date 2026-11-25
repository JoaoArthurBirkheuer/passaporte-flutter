import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

String mensagemErroAuth(Object erro) {
  if (erro is FirebaseAuthException) {
    switch (erro.code) {
      case 'invalid-credential':
        return 'Credenciais inválidas. Confira o e-mail e a senha.';
      case 'invalid-email':
        return 'Informe um e-mail válido.';
      case 'user-not-found':
        return 'E-mail não encontrado. Faça o cadastro primeiro.';
      case 'wrong-password':
        return 'Senha incorreta. Tente novamente.';
      case 'weak-password':
        return 'A senha é muito fraca. Use pelo menos 6 caracteres.';
      case 'email-already-in-use':
        return 'E-mail já cadastrado. Faça login.';
      case 'operation-not-allowed':
        return 'Este método de login não está habilitado.';
      case 'network-request-failed':
        return 'Sem conexão com a internet. Verifique sua rede.';
      case 'too-many-requests':
        return 'Muitas tentativas. Aguarde alguns instantes.';
      default:
        return 'Não foi possível autenticar (${erro.code}).';
    }
  }

  if (erro is GoogleSignInException) {
    if (erro.code == GoogleSignInExceptionCode.canceled) {
      return '';
    }
    return 'Não foi possível entrar com o Google (${erro.code}).';
  }

  return 'Ocorreu um erro inesperado. Tente novamente.';
}
