// dart format off
import 'dart:io'; // Fornece uma pasta temporária para o teste de persistência em disco.
import 'package:flutter_test/flutter_test.dart'; // Disponibiliza test, expect e os comparadores de resultados.
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Usa SQLite real nos testes executados no computador.
import 'package:framework_estudo/models/material_evento.dart'; // Importa as regras de classificação de estoque.
import 'package:framework_estudo/providers/impressao_provider.dart'; // Importa o estado e as regras da fila de impressão.
import 'package:framework_estudo/repositories/impressao_repository.dart'; // Importa as operações SQL de documentos.
import 'package:framework_estudo/repositories/material_repository.dart'; // Importa as operações SQL de materiais.
import 'package:framework_estudo/services/database_service.dart'; // Importa a criação e a abertura do banco.
import 'package:framework_estudo/utils/validadores.dart'; // Importa as validações reutilizadas pelo formulário e pela ViewModel.
import 'package:framework_estudo/viewmodels/material_viewmodel.dart'; // Importa a coordenação do cadastro de materiais.

void main() { // Agrupa os testes que podem ser executados com flutter test.
  setUpAll( sqfliteFfiInit); // Inicializa o mecanismo nativo uma única vez antes da suíte.

  test('texto obrigatório recusa null, vazio e espaços', () { // Reproduz o primeiro TODO da revisão 1.
    for (final entrada in <String?>[null, '', '   ', '\t\n']) { // Inclui também espaços invisíveis comuns em textos colados.
      expect(Validadores.textoObrigatorio(entrada), isNotNull); // Uma entrada inválida precisa produzir mensagem.
    } // Encerra a verificação das entradas inválidas.
    expect(Validadores.textoObrigatorio(' Microfone '), isNull); // Texto preenchido deve ser aceito mesmo com espaços externos.
  }); // Encerra o teste de texto obrigatório.

  test('quantidade de materiais aceita zero e recusa entradas inválidas', () { // Confere a fronteira maior ou igual a zero.
    for (final entrada in <String?>[null, '', ' ', 'abc', '-1', '1.5', '1,5']) { // Inclui vazio, letras, negativo e as duas notações decimais.
      expect(Validadores.quantidade(entrada), isNotNull, reason: 'Entrada: $entrada'); // Identifica a entrada responsável caso a validação falhe.
    } // Encerra os casos que devem ser recusados.
    expect(Validadores.quantidade('0'), isNull); // Diferentemente da impressão, o estoque pode ser zero.
    expect(Validadores.quantidade(' 12 '), isNull); // Um inteiro positivo com espaços externos continua válido.
  }); // Encerra o teste numérico de materiais.

  test('situação prioriza estoque zero e aceita igualdade com o mínimo', () { // Testa a ordem das condições pedida no roteiro.
    const zeroZero = MaterialEvento( nome: 'A', categoria: 'Teste', quantidade: 0, minimo: 0); // Prepara o caso em que duas condições poderiam coincidir.
    const zerado = MaterialEvento( nome: 'B', categoria: 'Teste', quantidade: 0, minimo: 3); // Prepara quantidade nula com mínimo positivo.
    const baixo = MaterialEvento( nome: 'C', categoria: 'Teste', quantidade: 1, minimo: 3); // Prepara estoque positivo abaixo do mínimo.
    const igual = MaterialEvento( nome: 'D', categoria: 'Teste', quantidade: 3, minimo: 3); // Prepara a igualdade que não deve ser classificada como baixa.
    const acima = MaterialEvento( nome: 'E', categoria: 'Teste', quantidade: 4, minimo: 3); // Prepara estoque acima do mínimo.
    expect(zeroZero.situacao, 'Sem estoque'); // A quantidade zero tem prioridade, inclusive quando o mínimo é zero.
    expect(zerado.situacao, 'Sem estoque'); // Quantidade nula não deve aparecer como apenas estoque baixo.
    expect(baixo.situacao, 'Estoque baixo'); // Somente valores positivos abaixo do mínimo entram nesta situação.
    expect(igual.situacao, 'Estoque adequado'); // Igualdade pertence ao caso maior ou igual.
    expect(acima.situacao, 'Estoque adequado'); // Valores acima do mínimo também são adequados.
  }); // Encerra os testes das fronteiras do estoque.

  group('SQLite real e atualização do estado', () { // Reúne cenários que conferem regras junto com a persistência.
    late DatabaseService service; // Declara o serviço particular de cada teste.
    late MaterialRepository materiais; // Declara o acesso aos registros de materiais.
    late ImpressaoRepository impressoes; // Declara o acesso aos registros de documentos.
    late MaterialViewModel vm; // Declara a coordenação de materiais observada pela tela.
    late ImpressaoProvider provider; // Declara a coordenação da impressão observada pela tela.

    setUp(() async { // Cria uma base limpa antes de cada cenário.
      service = DatabaseService( factory: databaseFactoryFfi, caminho: inMemoryDatabasePath); // Injeta SQLite em memória para isolar os testes.
      materiais = MaterialRepository( service); // Compartilha a mesma conexão entre as duas funcionalidades.
      impressoes = ImpressaoRepository( service); // Usa a tabela de documentos desse banco de teste.
      vm = MaterialViewModel(materiais); // Liga a ViewModel ao repositório real.
      provider = ImpressaoProvider(impressoes); // Liga o Provider ao repositório real.
      await service.database; // Abre o banco e cria suas tabelas e amostras.
    }); // Encerra a preparação.

    tearDown(() async { // Libera os recursos depois de cada cenário.
      vm.dispose(); // Remove os ouvintes da ViewModel criada pelo teste.
      provider.dispose(); // Remove os ouvintes do Provider criado pelo teste.
      await service .fechar(); // Fecha a conexão e impede que um teste reutilize dados do anterior.
    }); // Encerra a limpeza do cenário.

    test('nome normalizado inclui acentos e permite o próprio nome na edição', () async { // Confere duplicidade sem depender do NOCASE limitado do SQLite.
      final iniciais = await materiais.listar(); // Lê as amostras do banco.
      final extensao = iniciais.singleWhere((item) => item.nome == 'Extensão'); // Seleciona um exemplo com caractere acentuado.
      expect(await materiais.existeNome(' EXTENSÃO '), isTrue); // Maiúsculas e espaços externos precisam coincidir com o cadastro.
      expect(await materiais.existeNome(' extensão ', ignorarId: extensao.id), isFalse); // O próprio registro não é duplicidade durante a edição.
      expect(await materiais.existeNome('Microfone', ignorarId: extensao.id), isTrue); // Ignorar a extensão não pode ocultar outro material já existente.
      await vm.salvar( id: extensao.id, nome: ' EXTENSÃO ', categoria: 'Elétrica', quantidade: '1', minimo: '2'); // Salva o mesmo nome com outra capitalização.
      expect( vm.materiais.singleWhere((item) => item.id == extensao.id).quantidade, 1); // A edição com o próprio nome deve efetivamente persistir.
      await expectLater( vm.salvar( id: extensao.id, nome: ' MICROFONE ', categoria: 'Elétrica', quantidade: '1', minimo: '2'), throwsA(isA< FormatException>())); // Tentar adotar o nome de outro registro deve ser recusado.
      expect((await materiais.listar()).length, iniciais.length); // Nenhuma edição pode criar uma linha extra.
    }); // Encerra a verificação de duplicidade.

    test('cadastro notifica e revalida mesmo sem formulário', () async { // Garante que a regra não depende exclusivamente do widget Form.
      var notificacoes = 0; // Conta as atualizações enviadas aos ouvintes.
      vm.addListener( () => notificacoes++); // Simula uma tela observando a ViewModel.
      await vm.salvar( nome: 'Tripé', categoria: 'Vídeo', quantidade: '0', minimo: '2'); // Cadastra um material válido com estoque zerado.
      expect(vm.materiais.any((item) => item.nome == 'Tripé'), isTrue); // A lista deve ser recarregada automaticamente após o cadastro.
      expect(notificacoes, greaterThan(0)); // O notifyListeners precisa avisar a interface.
      final antes = (await materiais.listar()) .length; // Registra a quantidade persistida antes das tentativas inválidas.
      await expectLater( vm.salvar( nome: '   ', categoria: 'Teste', quantidade: '1', minimo: '0'), throwsA(isA< FormatException>())); // Recusa nome em branco chamado diretamente pela ViewModel.
      await expectLater( vm.salvar( nome: 'Inválido', categoria: 'Teste', quantidade: '-1', minimo: '0'), throwsA(isA< FormatException>())); // Recusa negativo mesmo quando não há formulário.
      await expectLater( vm.salvar( nome: 'Decimal', categoria: 'Teste', quantidade: '1.5', minimo: '0'), throwsA(isA< FormatException>())); // Recusa decimal sem transformá-lo em zero.
      expect((await materiais.listar()).length, antes); // As entradas recusadas não podem chegar ao banco.
    }); // Encerra a verificação de cadastro e notificação.

    test('atualizar e excluir materiais atingem somente o ID escolhido', () async { // Detecta WHERE ausente ou invertido nas operações destrutivas.
      final antes = await materiais .listar(); // Guarda uma fotografia de todos os registros.
      final alvo = antes.first; // Escolhe um único registro para a edição.
      final demais = antes .where((item) => item.id != alvo.id) .map((item) => item.toMap()) .toList(); // Guarda os valores dos materiais que devem continuar iguais.
      await materiais.atualizar(MaterialEvento( id: alvo.id, nome: alvo.nome, categoria: 'Categoria editada', quantidade: 7, minimo: 1)); // Altera exclusivamente o registro selecionado.
      final editados = await materiais .listar(); // Consulta novamente o SQLite em vez de confiar em uma lista local.
      expect(editados.singleWhere((item) => item.id == alvo.id).quantidade, 7); // Confere o novo valor no alvo.
      expect( editados .where((item) => item.id != alvo.id) .map((item) => item.toMap()) .toList(), demais); // Compara todos os campos dos demais materiais.
      await materiais .excluir(alvo.id!); // Solicita a exclusão do mesmo material.
      final restantes = await materiais.listar(); // Reconsulta o banco depois da exclusão.
      expect(restantes.any((item) => item.id == alvo.id), isFalse); // O alvo deve desaparecer.
      expect(restantes.map((item) => item.toMap()).toList(), demais); // Todos os outros registros devem permanecer integralmente iguais.
    }); // Encerra a verificação de isolamento do CRUD.

    test('impressão preserva chegada, multiplicação e resumo ao filtrar', () async { // Reproduz os três primeiros exemplos do roteiro de correção.
      expect(await provider.iniciar(), isTrue); // Carrega os documentos pelo fluxo usado pela interface.
      final todos = provider .documentosVisiveis; // Captura a fila completa antes de alterar o filtro.
      expect(todos.map((item) => item['nome']).toList(), [ 'Roteiro do evento', 'Cartaz da oficina', 'Lista de presença' ]); // ASC deve manter a ordem de chegada.
      expect(todos.map(provider.folhasDoDocumento).toList(), [ 12, 10, 2 ]); // Folhas são páginas multiplicadas pelo número de cópias.
      expect( provider.totalFolhas, 24); // Confere a soma das três multiplicações.
      provider.alterarFiltro( 'Pendentes'); // Seleciona documentos que ainda têm impresso igual a zero.
      expect(provider.documentosVisiveis.map((item) => item['nome']).toList(), [ 'Roteiro do evento', 'Cartaz da oficina' ]); // O filtro não pode trazer a amostra já impressa.
      expect(provider.totalFolhas, 24); // O resumo permanece calculado sobre a coleção completa, conforme a revisão.
      expect(provider.totalDocumentos, 3); // Filtrar não pode apagar documentos da coleção original.
      provider.alterarFiltro( 'Impressos'); // Seleciona somente os documentos com impresso igual a um.
      expect(provider.documentosVisiveis.single['nome'], 'Lista de presença'); // Exatamente uma amostra começa impressa.
    }); // Encerra a verificação de ordem, cálculo e filtros.

    test('impressão recusa zero, negativos, letras e decimais', () async { // Distingue a regra maior que zero da regra de materiais.
      await provider .iniciar(); // Obtém as amostras e o estado inicial do Provider.
      final antes = await impressoes .listar(); // Guarda o conteúdo persistido antes das entradas inválidas.
      for (final texto in ['0', '-1', '', 'abc', '1.5', '1,5']) { // Reúne valores recusados para páginas ou cópias.
        expect( await provider.salvar( nome: 'Documento', paginasTexto: texto, copiasTexto: '1'), isFalse, reason: 'Páginas: $texto'); // Testa cada entrada no campo de páginas.
        expect( await provider.salvar( nome: 'Documento', paginasTexto: '1', copiasTexto: texto), isFalse, reason: 'Cópias: $texto'); // Testa a mesma entrada no campo de cópias.
      } // Encerra a matriz de entradas inválidas.
      expect( await provider.salvar( nome: '   ', paginasTexto: '1', copiasTexto: '1'), isFalse); // Nome com espaços também deve ser recusado.
      expect(await impressoes.listar(), antes); // Todas as tentativas inválidas devem preservar o SQLite.
    }); // Encerra a verificação numérica da impressão.

    test('marcar impresso altera apenas o selecionado e pode ser desfeito', () async { // Reproduz o erro de ID diferente em vez de ID igual.
      await provider.iniciar(); // Carrega a fila inicial.
      final antes = await impressoes.listar(); // Obtém o estado persistido completo.
      final alvo = antes.first; // Seleciona o Roteiro do evento, que começa pendente.
      final demais = antes .where((item) => item['id'] != alvo['id']) .toList(); // Guarda os documentos que não devem mudar.
      expect(await provider.alternar(alvo), isTrue); // Solicita a marcação pelo Provider.
      final marcados = await impressoes.listar(); // Confere o resultado efetivamente salvo.
      final marcado = marcados.singleWhere( (item) => item['id'] == alvo['id']); // Encontra o documento marcado.
      expect(marcado['impresso'], 1); // Somente o alvo deve passar de zero para um.
      expect(marcados.where((item) => item['id'] != alvo['id']).toList(), demais); // Os campos de todos os outros documentos devem permanecer iguais.
      expect(await provider.alternar(marcado), isTrue); // Marca o mesmo documento novamente para reverter o status.
      expect((await impressoes.listar()).first['impresso'], 0); // A segunda alternância deve retornar ao estado pendente.
    }); // Encerra a verificação de marcação individual.

    test('documentos podem ser cadastrados, editados e excluídos por ID', () async { // Confere o CRUD que o roteiro pede na revisão final.
      await provider.iniciar(); // Carrega o estado inicial da fila.
      final antes = await impressoes.listar(); // Registra as três amostras originais.
      expect( await provider.salvar( nome: ' Certificado ', paginasTexto: '2', copiasTexto: '3'), isTrue); // Insere um documento válido com espaços externos no nome.
      final novo = (await impressoes.listar()) .last; // Pela ordem de chegada, o recém-criado deve estar no final.
      expect(novo['nome'], 'Certificado'); // O repositório deve persistir o nome sem espaços externos.
      expect(novo['impresso'], 0); // Um cadastro novo começa pendente.
      expect( await provider.salvar( id: novo['id'] as int, nome: 'Certificado editado', paginasTexto: '4', copiasTexto: '2'), isTrue); // Atualiza o documento usando seu ID.
      expect((await impressoes.listar()).last['paginas'], 4); // Confere o valor editado no banco.
      expect((await impressoes.listar()).take(antes.length).toList(), antes); // A edição não pode modificar as amostras anteriores.
      expect(await provider.excluir(novo['id'] as int), isTrue); // Exclui somente o documento criado no teste.
      expect(await impressoes.listar(), antes); // A fila deve voltar exatamente às três amostras originais.
    }); // Encerra a verificação de CRUD da impressão.

    test('restaurar documentos não altera a tabela de materiais', () async { // Confere o isolamento entre os dois módulos deste projeto de estudo.
      await vm.salvar( nome: 'Material de controle', categoria: 'Teste', quantidade: '9', minimo: '1'); // Cria um material para detectar exclusões indevidas.
      final materiaisAntes = (await materiais.listar()) .map((item) => item.toMap()) .toList(); // Guarda todos os materiais antes da restauração.
      await provider.iniciar(); // Carrega os documentos de exemplo.
      await provider.salvar( nome: 'Extra', paginasTexto: '8', copiasTexto: '2'); // Acrescenta um documento que a restauração deve remover.
      await provider.alternar(provider.documentosVisiveis .first); // Muda também um status para provar que os exemplos são reconstruídos.
      expect(await provider.restaurar(), isTrue); // Executa a transação de restauração de documentos.
      expect(provider.totalDocumentos, 3); // Os exemplos devem voltar a conter somente três documentos.
      expect(provider.totalFolhas, 24); // As páginas e cópias restauradas devem produzir o resumo original.
      expect( provider.documentosVisiveis.map((item) => item['impresso']).toList(), [0, 0, 1]); // A ordem e os estados iniciais devem ser recuperados.
      expect((await materiais.listar()).map((item) => item.toMap()).toList(), materiaisAntes); // A restauração de uma tabela não pode modificar a outra.
    }); // Encerra a verificação de restauração isolada.
  }); // Encerra o grupo de testes com banco em memória.

  test('dados persistem após fechar e reabrir um arquivo SQLite', () async { // Distingue persistência real de uma coleção mantida apenas em memória.
    final pasta = await Directory.systemTemp.createTemp( 'framework_estudo_teste_'); // Cria uma pasta nova exclusiva para este teste.
    final caminho = '${pasta.path}${Platform.pathSeparator}persistencia.db'; // Define o arquivo SQLite dentro da pasta recém-criada.
    final primeira = DatabaseService( factory: databaseFactoryFfi, caminho: caminho); // Abre uma primeira instância do serviço no arquivo físico.
    final segunda = DatabaseService( factory: databaseFactoryFfi, caminho: caminho); // Prepara outra instância para simular uma nova execução.
    try { // Garante limpeza mesmo se uma expectativa falhar.
      final repo = MaterialRepository( primeira); // Usa o primeiro serviço para inserir, editar e excluir.
      await repo.inserir(const MaterialEvento( nome: 'Persistente', categoria: 'Teste', quantidade: 4, minimo: 1)); // Persiste uma nova linha no arquivo.
      final original = (await repo.listar()).singleWhere((item) => item.nome == 'Persistente'); // Obtém o ID criado pelo SQLite.
      await repo.atualizar(MaterialEvento( id: original.id, nome: original.nome, categoria: 'Teste', quantidade: 8, minimo: 1)); // Persiste uma edição posterior.
      final excluir = (await repo.listar()).singleWhere((item) => item.nome == 'Microfone'); // Seleciona uma amostra para provar persistência da exclusão.
      await repo .excluir(excluir.id!); // Remove a amostra selecionada do arquivo.
      final impressao = ImpressaoRepository( primeira); // Acessa também a tabela de documentos no mesmo banco.
      final documento = (await impressao.listar()) .first; // Seleciona o primeiro documento da fila.
      await impressao.alternarImpressao(documento['id'] as int, false); // Grava o status impresso antes de fechar.
      await primeira .fechar(); // Fecha de verdade a primeira conexão com o arquivo.
      final reaberto = await MaterialRepository(segunda) .listar(); // Lê por outra instância que precisa reabrir o banco.
      expect( reaberto.singleWhere((item) => item.nome == 'Persistente').quantidade, 8); // O cadastro e sua edição devem sobreviver à reabertura.
      expect(reaberto.any((item) => item.nome == 'Microfone'), isFalse); // A exclusão também deve continuar aplicada.
      expect((await ImpressaoRepository(segunda).listar()).first['impresso'], 1); // A marcação individual deve continuar gravada após reabrir.
    } finally { // Libera as conexões antes de remover apenas a pasta temporária criada acima.
      await primeira .fechar(); // Fecha a primeira instância caso tenha ocorrido uma falha antes do fechamento anterior.
      await segunda .fechar(); // Fecha a conexão reaberta para liberar o arquivo no Windows.
      await pasta.delete( recursive: true); // Apaga exclusivamente os arquivos descartáveis deste teste.
    } // Encerra a limpeza garantida.
  }); // Encerra a verificação de persistência em arquivo.
} // Encerra a suíte de regras e persistência.
// dart format on
