// dart format off
export 'database_factory_stub.dart' // Evita carregar o driver web na execução nativa dos testes.
if (dart.library.js_interop) 'database_factory_web.dart'; // No Chrome seleciona o SQLite Web real.
// dart format on
