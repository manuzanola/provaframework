// dart format off
// Entrada mínima equivalente à fornecida pelo pacote, compilada com o pubspec.lock DESTE projeto.
// O setup da versão antiga resolve dependências separadamente e pode misturar SQLite 3.x com WASM 2.x.
// ignore_for_file: implementation_imports
import 'package:sqflite_common_ffi_web/src/sw/shared_worker.dart'; // Usa o mesmo ponto de entrada do gerador oficial 0.4.5+4; por isso a versão está fixada.

void main(List<String> argumentos) { // Entrada do worker compilada com dart compile js, sem abrir o app Flutter.
  mainSharedWorker(argumentos); // Delega ao código do pacote; preserva seu protocolo e suas transações.
} // Encerra o adaptador de geração, sem duplicar a implementação do driver.
// dart format on
