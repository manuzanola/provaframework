// dart format off
import '../models/material_evento.dart'; // Converte linhas SQLite para modelos tipados.
import '../services/database_service.dart'; // Obtém a conexão compartilhada pelas duas revisões.

class MaterialRepository { // Concentra as consultas SQL dos materiais.
  final DatabaseService service; // Recebe a infraestrutura por injeção de dependência.
  MaterialRepository(this.service); // Permite usar o mesmo serviço no app e nos testes.

  Future<List<MaterialEvento>> listar() async { // Consulta todos os materiais persistidos.
    final db = await service.database; // Aguarda a conexão estar pronta.
    final linhas = await db.query('materiais', orderBy: 'nome COLLATE NOCASE'); // Mantém a ordem alfabética original.
    return linhas.map(MaterialEvento.fromMap).toList(); // Converte cada Map retornado em MaterialEvento.
  } // Finaliza a listagem.

  Future<bool> existeNome(String nome, {int? ignorarId}) async { // [R1-04] Desconsidera o próprio ID na edição.
    final db = await service.database; // Reutiliza a conexão existente.
    final normalizado = nome.trim().toLowerCase(); // Mesma normalização de nomeNormalizado, inclusive em textos acentuados.
    final linhas = await db.query( // Consulta parametrizada evita concatenar valores no SQL.
      'materiais', // Limita a busca à tabela correta.
      columns: ['id'], // Só precisamos saber se há um registro com esse nome.
      where: ignorarId == null ? 'nome_normalizado = ?' : 'nome_normalizado = ? AND id <> ?', // <> ignora apenas o próprio ID.
      whereArgs: ignorarId == null ? [normalizado] : [normalizado, ignorarId], // Valores correspondem aos placeholders na ordem.
      limit: 1, // Uma ocorrência já é suficiente para apontar duplicidade.
    ); // Encerra a consulta.
    return linhas.isNotEmpty; // true indica nome ocupado; false permite salvar.
  } // Finaliza a verificação de nomes repetidos.

  Future<void> inserir(MaterialEvento material) async { // [R1-05] Implementa o INSERT solicitado no TODO.
    final db = await service.database; // Aguarda o banco antes de gravar.
    await db.insert('materiais', material.toMap()); // Usa o toMap do modelo; o banco gera o ID do cadastro.
  } // Encerra o cadastro.

  Future<void> atualizar(MaterialEvento material) async { // [R1-06] Atualiza somente o registro em edição.
    if (material.id == null) throw ArgumentError('Edição exige um ID existente.'); // Evita uma alteração sem alvo.
    final db = await service.database; // Obtém a conexão pronta.
    await db.update( // Executa o UPDATE individual.
      'materiais', // Define a tabela alterada.
      material.toMap(), // Atualiza campos e nome normalizado em conjunto.
      where: 'id = ?', // = escolhe somente o material selecionado; não omita o WHERE.
      whereArgs: [material.id], // Substitui o placeholder sem interpolar texto SQL.
    ); // Aguarda o término da gravação.
  } // Finaliza a edição.

  Future<void> excluir(int id) async { // [R1-07] Recebe o ID confirmado no diálogo da tela.
    final db = await service.database; // Reutiliza o banco.
    await db.delete('materiais', where: 'id = ?', whereArgs: [id]); // Preserva os demais registros.
  } // Finaliza a exclusão individual.
} // Encerra o repository de materiais.
// dart format on
