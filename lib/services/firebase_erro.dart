import 'package:cloud_firestore/cloud_firestore.dart';

bool eErroDeConexao(Object erro) {
  return erro is FirebaseException &&
      (erro.code == 'unavailable' || erro.code == 'network-request-failed');
}
