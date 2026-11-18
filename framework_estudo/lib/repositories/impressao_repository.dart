// dart format off
import '../services/database_service.dart'; // Reutiliza a conexão SQLite aberta pelo serviço compartilhado.

// O repository conhece tabelas e SQL; a página só envia ações ao Provider.
class ImpressaoRepository { // Concentra a persistência da fila de impressão.
  final DatabaseService service; // Recebe o serviço em vez de criar outro banco escondido.
  ImpressaoRepository(this.service); // Permite que o aplicativo e os testes escolham o serviço utilizado.

  Future<List<Map<String, Object?>>> listar() async { // Entrega os registros somente depois de a consulta terminar.
    final db = await service.database; // Aguarda a mesma conexão utilizada pelas demais operações.
    return db.query('documentos', orderBy: 'id ASC'); // [R2-01] ASC mostra os documentos do menor ID para o maior.
  } // Encerra a consulta sem modificar os registros.

  Future<void> salvar({ // Serve tanto para inserir quanto para editar um documento.
    int? id, // A ausência de ID identifica um novo cadastro.
    required String nome, // Recebe o nome validado pelo Provider.
    required int paginas, // Recebe a quantidade inteira de páginas de cada cópia.
    required int copias, // Recebe a quantidade inteira de cópias solicitadas.
  }) async { // O Future permite aguardar a escrita antes de atualizar a lista.
    final db = await service.database; // Obtém a conexão antes de executar o comando.
    final dados = <String, Object?>{ // Associa cada valor ao nome de sua coluna SQLite.
      'nome': nome.trim(), // Remove espaços externos antes de persistir o nome.
      'paginas': paginas, // Salva páginas como INTEGER, sem converter para texto.
      'copias': copias, // Salva cópias separadamente para calcular páginas vezes cópias.
    }; // Mantém impresso fora deste mapa para preservar o status nas edições.
    if (id == null) { // Sem ID, a operação deve criar um registro.
      await db.insert('documentos', {...dados, 'impresso': 0}); // O spread copia os campos e o novo documento começa pendente.
    } else { // Com ID, a operação deve alterar o cadastro existente.
      await db.update( // Aguarda a edição antes de liberar o recarregamento da tela.
        'documentos', // Define a tabela que receberá os dados.
        dados, // Atualiza apenas nome, páginas e cópias; conserva impresso.
        where: 'id = ?', // Restringe a edição ao documento selecionado.
        whereArgs: [id], // Passa o ID como parâmetro, sem concatenar SQL.
      ); // Conclui o UPDATE específico do cadastro.
    } // Une novamente os caminhos de inserção e edição.
  } // A interface só recebe sucesso depois de a escrita terminar.

  Future<void> alternarImpressao(int id, bool estavaImpresso) async { // Recebe o ID e o estado anterior do documento.
    final db = await service.database; // Aguarda a conexão utilizada para persistir o status.
    final novoValor = estavaImpresso ? 0 : 1; // Inverte o booleano usando os inteiros aceitos pelo SQLite.
    await db.update( // Grava a mudança de status de impressão.
      'documentos', // A operação pertence somente à tabela da revisão 2.
      {'impresso': novoValor}, // Atualiza exclusivamente a coluna de status.
      where: 'id = ?', // [R2-05] Igualdade seleciona o clicado; <> alteraria todos os outros documentos.
      whereArgs: [id], // Substitui o marcador pelo ID escolhido de forma parametrizada.
    ); // Termina o UPDATE antes de o Provider consultar novamente.
  } // Encerra a alternância sem modificar os demais documentos.

  Future<void> excluir(int id) async { // Exclui somente o ID confirmado pela página.
    final db = await service.database; // Aguarda a disponibilidade do banco.
    await db.delete('documentos', where: 'id = ?', whereArgs: [id]); // O WHERE impede excluir toda a fila por engano.
  } // Devolve o controle depois da exclusão persistida.

  Future<void> restaurarAmostras() async { // Repõe os três exemplos quando o usuário confirma a restauração.
    final db = await service.database; // Usa o banco compartilhado, sem apagar outras tabelas.
    await db.transaction((txn) async { // Mantém limpeza e inserções na mesma transação.
        await txn.delete('documentos'); // Remove apenas os documentos desta atividade.
        await txn.delete( // Reinicia a sequência para recuperar os IDs didáticos das amostras.
          'sqlite_sequence', // AUTOINCREMENT mantém sua sequência nesta tabela interna.
          where: 'name = ?', // Seleciona a sequência de uma tabela específica.
          whereArgs: ['documentos'], // Preserva as sequências das outras atividades.
        ); // Conclui a limpeza restrita da sequência da fila.
        for (final documento in DatabaseService.amostrasDocumentos) { // Percorre as amostras definidas pelo serviço.
          await txn.insert('documentos', documento); // Insere cada amostra dentro da transação atual.
        } // Termina quando os três exemplos foram inseridos.
    }); // Confirma tudo junto; uma falha desfaz a restauração inteira.
  } // O Provider pode agora recarregar a lista e os totais.
} // Fecha a camada de persistência da revisão 2.
// dart format on
