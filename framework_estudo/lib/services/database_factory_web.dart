// dart format off
import 'package:sqflite_common/sqlite_api.dart'; // Define o contrato de acesso ao SQLite.
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // Importa a fábrica WASM com persistência web.

DatabaseFactory criarFactoryPadrao() => databaseFactoryFfiWeb; // Armazena o banco no IndexedDB desta origem.
// dart format on
