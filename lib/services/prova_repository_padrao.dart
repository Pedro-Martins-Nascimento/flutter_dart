// Instância única do repositório de provas, entregue às telas pelo
// app_router. Quando o Firestore entrar, só esta linha muda.

import 'prova_repository.dart';
import 'prova_repository_memoria.dart';

final ProvaRepository provaRepository = ProvaRepositoryMemoria.comMocks();
