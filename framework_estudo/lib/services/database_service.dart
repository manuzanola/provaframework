// dart format off
import 'package:sqflite_common/sqlite_api.dart'; // Disponibiliza conexão, fábrica e opções do banco.
import 'database_factory.dart'; // Seleciona o driver sem importar código web nos testes nativos.

class DatabaseService { // Infraestrutura: abre o banco e cria o esquema, sem regras de formulário.
  final DatabaseFactory _factory; // Driver web no aplicativo e SQLite FFI real nos testes.
  final String _caminho; // Nome do banco web ou caminho de arquivo usado nos testes.
  Database? _database; // Guarda a conexão já aberta.
  Future<Database>? _abertura; // Compartilha a abertura em andamento entre as duas abas.

  DatabaseService({ // Recebe apenas as dependências necessárias para testar a persistência real.
      DatabaseFactory? factory, // Quando omitida, usa a fábrica para Chrome.
      String caminho = 'framework_estudo_v1.db', // Não sobrescreve os bancos dos projetos originais.
  })  : _factory = factory ?? criarFactoryPadrao(), // Testes fornecem explicitamente a fábrica FFI.
  _caminho = caminho; // Preserva o nome ou caminho solicitado.

  static const amostrasMateriais = <Map<String, Object?>>[ // Reproduz os dados da revisão 1.
    { 'nome': 'Microfone', 'nome_normalizado': 'microfone', 'categoria': 'Áudio', 'quantidade': 4, 'minimo': 2 }, // Adequado.
    { 'nome': 'Cabo HDMI', 'nome_normalizado': 'cabo hdmi', 'categoria': 'Vídeo', 'quantidade': 2, 'minimo': 3 }, // Baixo.
    { 'nome': 'Extensão', 'nome_normalizado': 'extensão', 'categoria': 'Elétrica', 'quantidade': 0, 'minimo': 2 }, // Sem estoque.
    { 'nome': 'Caixa de som', 'nome_normalizado': 'caixa de som', 'categoria': 'Áudio', 'quantidade': 3, 'minimo': 1 }, // Adequado.
  ]; // Fecha a lista inicial de materiais.

  static const amostrasDocumentos = <Map<String, Object?>>[ // Mantém a ordem de chegada do roteiro.
    { 'nome': 'Roteiro do evento', 'paginas': 4, 'copias': 3, 'impresso': 0 }, // 12 folhas, pendente.
    { 'nome': 'Cartaz da oficina', 'paginas': 2, 'copias': 5, 'impresso': 0 }, // 10 folhas, pendente.
    { 'nome': 'Lista de presença', 'paginas': 1, 'copias': 2, 'impresso': 1 }, // 2 folhas, impresso.
  ]; // Fecha a lista inicial de documentos.

  Future<Database> get database { // Entrega uma conexão pronta de forma assíncrona.
    if (_database != null) return Future.value(_database!); // Reutiliza o banco que já está aberto.
    return _abertura ??= _abrir(); // Evita duas aberturas concorrentes quando ambas as abas consultam.
  } // Fecha o getter da conexão.

  Future<Database> _abrir() async { // Executa a abertura no driver selecionado.
    try { // Prepara uma recuperação caso a abertura falhe.
      final db = await _factory.openDatabase( // Aguarda o driver abrir ou criar o banco.
        _caminho, // Reutilizar este nome permite recuperar os registros após recarregar a página.
        options: OpenDatabaseOptions( // Configura criação, versão e ciclo de vida da conexão.
          version: 1, // onCreate só será executado na primeira criação do banco.
          onCreate: (db, versao) async { // O driver executa a criação do esquema dentro de transação.
            await db.execute( // Cria a tabela usada pela revisão 1.
              'CREATE TABLE materiais (' // Inicia a declaração dos materiais.
              'id INTEGER PRIMARY KEY AUTOINCREMENT, ' // Identifica individualmente os registros.
              'nome TEXT NOT NULL, ' // Persiste o nome de apresentação.
              'nome_normalizado TEXT NOT NULL UNIQUE, ' // Protege a unicidade também no banco.
              'categoria TEXT NOT NULL, ' // Persiste a categoria.
              'quantidade INTEGER NOT NULL, ' // Guarda unidades disponíveis como inteiro.
              'minimo INTEGER NOT NULL)', // Conclui o esquema de materiais.
            ); // Finaliza a criação da primeira tabela.
            await db.execute( // Cria a tabela independente da revisão 2.
              'CREATE TABLE documentos (' // Inicia a declaração da fila de impressão.
              'id INTEGER PRIMARY KEY AUTOINCREMENT, ' // IDs crescentes permitem ordenar por chegada.
              'nome TEXT NOT NULL, ' // Guarda o título do documento.
              'paginas INTEGER NOT NULL, ' // Guarda páginas por cópia.
              'copias INTEGER NOT NULL, ' // Guarda a quantidade de cópias.
              'impresso INTEGER NOT NULL DEFAULT 0)', // SQLite representa o booleano como zero ou um.
            ); // Finaliza a criação da segunda tabela.
            for (final material in amostrasMateriais) { // Percorre os materiais do professor.
              await db.insert('materiais', material); // Aguarda a inserção de cada exemplo.
            } // Finaliza a população inicial de materiais.
            for (final documento in amostrasDocumentos) { // Percorre os documentos na ordem esperada.
              await db.insert('documentos', documento); // IDs 1, 2 e 3 preservam a sequência da fila.
            } // Finaliza a população inicial de documentos.
          }, // Fecha onCreate; recargas comuns não restauram nem apagam dados.
        ), // Fecha as opções do banco.
      ); // Recebe a conexão pronta.
      _database = db; // Memoriza a conexão para as consultas seguintes.
      return db; // Entrega o banco ao repository.
    } catch (_) { // Preserva o erro para a camada que vai apresentar a mensagem.
      _abertura = null; // Libera uma nova tentativa de abertura.
      rethrow; // Não transforma falha de banco em sucesso silencioso.
    } // Fecha o tratamento de falhas na abertura.
  } // Finaliza a abertura efetiva.

  Future<void> fechar() async { // Permite testar fechamento e reabertura sem perder os registros.
    final pendente = _abertura; // Considera também uma abertura ainda em andamento.
    final db = _database ?? (pendente == null ? null : await pendente); // Aguarda a conexão antes de fechá-la.
    await db?.close(); // Libera a conexão sem apagar os dados persistidos.
    _database = null; // Remove a referência ao banco fechado.
    _abertura = null; // Uma próxima consulta abrirá outra conexão.
  } // Finaliza o fechamento controlado.
} // Encerra o serviço compartilhado.
// dart format on
