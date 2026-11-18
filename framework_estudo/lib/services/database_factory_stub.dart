// dart format off
import 'package:sqflite_common/sqlite_api.dart'; // Compartilha o contrato DatabaseFactory entre os drivers.

DatabaseFactory criarFactoryPadrao() { // Define o comportamento fora do alvo web das revisões.
  throw UnsupportedError( // Os testes injetam uma fábrica FFI; o app foi preparado para Chrome.
    'Execute este projeto com flutter run -d chrome.', // Explica como escolher o alvo suportado.
  ); // Finaliza a exceção explicativa.
} // Fecha a seleção de driver fora do navegador.
// dart format on
