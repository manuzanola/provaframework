// dart format off
import 'dart:async'; // Permite aguardar uma notificação real sem usar atrasos arbitrários.
import 'package:flutter/foundation.dart'; // Disponibiliza Listenable e a plataforma simulada nos testes.
import 'package:flutter/material.dart'; // Fornece os widgets usados para montar as páginas isoladamente.
import 'package:flutter_test/flutter_test.dart'; // Disponibiliza os testes de interface e as simulações de interação.
import 'package:provider/provider.dart'; // Injeta a instância real do Provider na página de impressão.
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // Executa as operações contra SQLite real no computador.
import 'package:framework_estudo/models/material_evento.dart'; // Permite preparar um material de controle para a restauração.
import 'package:framework_estudo/pages/impressao_page.dart'; // Importa a interface da fila de impressão.
import 'package:framework_estudo/pages/materiais_page.dart'; // Importa a interface da central de materiais.
import 'package:framework_estudo/providers/impressao_provider.dart'; // Importa o estado observado pela página de impressão.
import 'package:framework_estudo/repositories/impressao_repository.dart'; // Permite verificar diretamente os documentos persistidos.
import 'package:framework_estudo/repositories/material_repository.dart'; // Permite verificar diretamente os materiais persistidos.
import 'package:framework_estudo/services/database_service.dart'; // Permite injetar uma conexão SQLite de teste.
import 'package:framework_estudo/viewmodels/material_viewmodel.dart'; // Importa o estado observado pela central de materiais.

void configurarTela(WidgetTester tester, Size tamanho) { // Simula o tamanho lógico de um celular sem alterar a configuração da máquina.
  tester.view.devicePixelRatio = 1; // Faz a resolução física coincidir com os pixels lógicos definidos abaixo.
  tester.view.physicalSize = tamanho; // Aplica 360x800 ou 390x844 ao layout.
  debugDefaultTargetPlatformOverride = TargetPlatform.android; // Usa o comportamento Material móvel em vez da plataforma do computador.
  addTearDown(() { // Restaura as configurações mesmo quando uma expectativa falhar.
    tester.view.resetPhysicalSize(); // Remove a resolução simulada ao terminar o cenário.
    tester.view.resetDevicePixelRatio(); // Restaura a densidade de pixels original do teste.
    debugDefaultTargetPlatformOverride = null; // Não deixa a plataforma Android afetar os próximos testes.
  }); // Finaliza o registro da limpeza das métricas.
} // Encerra a configuração da tela simulada.

Future<void> tocarVisivel(WidgetTester tester, Finder alvo) async { // Rola até uma ação antes de simular o toque.
  expect(alvo, findsOneWidget); // Evita clicar acidentalmente em outra ação com o mesmo texto.
  await tester.ensureVisible(alvo); // Move o SingleChildScrollView até o controle solicitado.
  await tester.pumpAndSettle(); // Conclui a rolagem e as animações anteriores antes do toque.
  await tester.tap(alvo); // Dispara o mesmo callback utilizado por um toque no aplicativo.
} // O chamador decide quando aguardar o diálogo ou a operação de banco iniciada pelo toque.

Future<void> preencher(WidgetTester tester, Finder campo, String texto) async { // Preenche um campo mesmo quando ele começou fora da tela.
  await tester.ensureVisible(campo); // Traz o campo para a região visível do formulário.
  await tester.pumpAndSettle(); // Aguarda a rolagem antes de solicitar foco.
  await tester.enterText(campo, texto); // Digita pelo mecanismo de teste de TextField e TextFormField.
  await tester.pump(); // Reconstrói a interface com o texto atualizado.
} // Encerra o preenchimento de uma entrada.

Future<void> aguardarBanco(WidgetTester tester, Listenable estado, Future<void> Function() acao, bool Function() terminou) async { // Sincroniza a interação com a conclusão real do SQLite FFI.
  final conclusao = Completer<void>(); // Representa a notificação que comprova o término esperado.
  void verificar() { // Examina o estado publicado sem adivinhar o tempo necessário para o banco.
    if (terminou() && !conclusao.isCompleted) conclusao.complete(); // Completa uma única vez quando o resultado esperado existe.
  } // Encerra a observação do estado.
  estado.addListener(verificar); // Começa a observar antes do toque para não perder notificações rápidas.
  try { // Remove o observador mesmo quando houver erro na interação ou no banco.
    await acao(); // Monta a página ou toca no botão que inicia a consulta ou a gravação.
    final limite = Stopwatch()..start(); // Mede o limite real de espera sem depender do relógio simulado do Flutter.
    while (!conclusao.isCompleted && limite.elapsed < const Duration(seconds: 15)) { // Aguarda o resultado, preservando uma falha clara se ele nunca chegar.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10))); // Cede o loop real para o SQLite terminar a chamada nativa.
      await tester.pump(const Duration(milliseconds: 16)); // Processa as continuações e notificações que pertencem à zona simulada dos widgets.
      verificar(); // Reconhece o término pela condição observável, sem pressupor duração fixa da consulta.
    } // Alterna os dois loops apenas enquanto o trabalho real estiver pendente.
    expect(conclusao.isCompleted, isTrue, reason: 'O SQLite não publicou o estado esperado dentro de 15 segundos.'); // Falha em vez de avançar usando dados antigos.
  } finally { // Executa também se a operação não alcançar o estado esperado.
    estado.removeListener(verificar); // Não mantém observadores entre diferentes interações.
  } // Finaliza a limpeza do observador temporário.
  await tester.pumpAndSettle(); // Só estabiliza as animações depois de o trabalho nativo estar concluído.
  expect(tester.takeException(), isNull); // Detecta overflow e outras exceções de construção após a ação.
} // Encerra a espera baseada em resultado observável.

Finder acaoDoCartao(String nome, String acao) { // Localiza uma ação pelo registro a que ela pertence.
  final cartao = find.ancestor(of: find.text(nome), matching: find.byType(Card)); // Identifica o cartão com o nome exato do material ou documento.
  return find.descendant(of: cartao, matching: find.text(acao)); // Impede confundir Excluir ou Editar de registros diferentes.
} // Encerra a busca contextual do botão.

Finder acaoDoDialogo(String acao) => find.descendant(of: find.byType(AlertDialog), matching: find.text(acao)); // Restringe Cancelar e Confirmar ao diálogo aberto.

void main() { // Declara os cenários de interface executados por flutter test.
  TestWidgetsFlutterBinding.ensureInitialized(); // Inicializa o ambiente necessário para simular as duas resoluções.
  setUpAll(sqfliteFfiInit); // Inicializa SQLite nativo uma vez para todos os cenários.

  for (final tamanho in [const Size(360, 800), const Size(390, 844)]) { // Repete as interações completas nas duas larguras de celular.
    testWidgets('materiais em ${tamanho.width.toInt()}x${tamanho.height.toInt()}: formulário e exclusão confirmada', (tester) async { // Verifica layout estreito e preservação dos registros.
      configurarTela(tester, tamanho); // Configura a resolução e o comportamento de plataforma deste teste.
      final service = DatabaseService(factory: databaseFactoryFfi, caminho: inMemoryDatabasePath); // Cria um SQLite real e isolado para este cenário.
      final repository = MaterialRepository(service); // Usa o repository verdadeiro em vez de uma lista falsa.
      final vm = MaterialViewModel(repository); // Injeta a mesma coordenação utilizada pelo aplicativo.
      try { // Garante descarte da página e fechamento do banco após o cenário.
        await tester.runAsync(() async => service.database); // Cria o esquema e as amostras fora do relógio falso do teste.
        await aguardarBanco(tester, vm, () => tester.pumpWidget(MaterialApp(home: Scaffold(body: MateriaisPage(viewModel: vm)))), () => vm.materiais.isNotEmpty); // Monta a página e aguarda sua consulta inicial.
        expect(find.text('Central de materiais'), findsOneWidget); // Confirma que a página normal foi aberta, sem mensagem de falha.
        final campos = find.byType(TextFormField); // Seleciona os quatro campos do formulário de materiais.
        await preencher(tester, campos.at(0), 'Material da interface'); // Preenche o nome do registro a ser estudado.
        await preencher(tester, campos.at(1), 'Teste'); // Preenche uma categoria válida.
        await preencher(tester, campos.at(2), '2'); // Informa uma quantidade disponível válida.
        await preencher(tester, campos.at(3), '1'); // Informa um mínimo válido.
        await aguardarBanco(tester, vm, () => tocarVisivel(tester, find.widgetWithText(FilledButton, 'Cadastrar')), () => vm.materiais.any((item) => item.nome == 'Material da interface')); // Rola até o botão e aguarda o INSERT real.
        expect(find.text('Material salvo.'), findsOneWidget); // A confirmação só deve aparecer após a persistência.
        await tocarVisivel(tester, acaoDoCartao('Material da interface', 'Editar')); // Entra em edição pelo cartão que foi cadastrado.
        await tester.pumpAndSettle(); // Reconstrói o formulário com os botões Salvar alterações e Cancelar.
        await preencher(tester, campos.at(2), '6'); // Altera somente a quantidade do material selecionado.
        await aguardarBanco(tester, vm, () => tocarVisivel(tester, find.widgetWithText(FilledButton, 'Salvar alterações')), () => vm.materiais.any((item) => item.nome == 'Material da interface' && item.quantidade == 6)); // Exercita o layout dos botões de edição e o UPDATE.
        final antes = (await tester.runAsync(repository.listar))!; // Lê a fotografia persistida antes de tentar excluir.
        final alvo = antes.singleWhere((item) => item.nome == 'Material da interface'); // Obtém o ID gerado pelo cadastro feito na interface.
        await tocarVisivel(tester, acaoDoCartao(alvo.nome, 'Excluir')); // Abre a confirmação de exclusão do alvo.
        await tester.pumpAndSettle(); // Conclui a animação do diálogo antes de examinar suas ações.
        expect(find.text('Excluir material?'), findsOneWidget); // Comprova que o toque não executou um DELETE direto.
        await tocarVisivel(tester, acaoDoDialogo('Cancelar')); // Recusa a primeira tentativa de exclusão.
        await tester.pumpAndSettle(); // Fecha o diálogo e devolve a interação para a lista.
        final cancelados = (await tester.runAsync(repository.listar))!; // Reconsulta o banco depois do cancelamento.
        expect(cancelados.map((item) => item.toMap()).toList(), antes.map((item) => item.toMap()).toList()); // Cancelar precisa preservar todos os campos e todos os registros.
        await tocarVisivel(tester, acaoDoCartao(alvo.nome, 'Excluir')); // Abre novamente a confirmação do mesmo alvo.
        await tester.pumpAndSettle(); // Aguarda o diálogo estar pronto para receber a confirmação.
        await aguardarBanco(tester, vm, () => tocarVisivel(tester, acaoDoDialogo('Excluir')), () => !vm.materiais.any((item) => item.id == alvo.id)); // Confirma e aguarda a exclusão persistida.
        final depois = (await tester.runAsync(repository.listar))!; // Lê os registros restantes diretamente do SQLite.
        expect(depois.map((item) => item.toMap()).toList(), antes.where((item) => item.id != alvo.id).map((item) => item.toMap()).toList()); // Somente o ID confirmado pode desaparecer.
        expect(tester.takeException(), isNull); // Confere que formulário, cartões e diálogos não geraram overflow na resolução simulada.
      } finally { // Libera recursos mesmo quando uma expectativa falha.
        await tester.pumpWidget(const SizedBox.shrink()); // Desmonta a página antes de descartar suas dependências.
        vm.dispose(); // Libera os ouvintes da ViewModel pertencente ao teste.
        await tester.runAsync(service.fechar); // Fecha a conexão real fora do relógio falso.
        debugDefaultTargetPlatformOverride = null; // Restaura a plataforma antes de o Flutter verificar suas invariantes de fim do teste.
      } // Finaliza a limpeza do cenário de materiais.
    }); // Encerra o cenário de materiais nesta resolução.

    testWidgets('impressão em ${tamanho.width.toInt()}x${tamanho.height.toInt()}: formulário, exclusão e restauração', (tester) async { // Verifica as confirmações e o isolamento das tabelas em celular.
      configurarTela(tester, tamanho); // Configura a largura e a altura usadas no layout.
      final service = DatabaseService(factory: databaseFactoryFfi, caminho: inMemoryDatabasePath); // Cria um banco independente das demais resoluções.
      final repository = ImpressaoRepository(service); // Usa as operações SQL reais de documentos.
      final materiais = MaterialRepository(service); // Permite verificar que restaurar documentos não afeta materiais.
      final provider = ImpressaoProvider(repository); // Cria o estado que será observado pela página.
      try { // Garante desmontagem e fechamento da conexão ao terminar.
        await tester.runAsync(() async { // Prepara os dados usando o loop real das chamadas SQLite.
          await materiais.inserir(const MaterialEvento(nome: 'Controle da interface', categoria: 'Teste', quantidade: 5, minimo: 1)); // Cria um material particular cuja sobrevivência comprova o isolamento.
          await provider.iniciar(); // Carrega a fila antes de montar a página, como faz a montagem do aplicativo.
        }); // Finaliza a preparação persistida.
        final materiaisAntes = (await tester.runAsync(materiais.listar))!; // Guarda todos os materiais para comparar após a restauração.
        await tester.pumpWidget(MaterialApp(home: ChangeNotifierProvider<ImpressaoProvider>.value(value: provider, child: const ImpressaoPage()))); // Injeta a instância sem transferir sua propriedade ao Provider.
        await tester.pumpAndSettle(); // Conclui a primeira construção da interface.
        expect(find.text('Fila de impressão'), findsOneWidget); // Confirma que o fluxo normal da página está visível.
        expect(tester.takeException(), isNull); // Detecta problemas no cabeçalho ou nos cartões já na primeira construção.
        await tocarVisivel(tester, find.byType(DropdownButton<String>)); // Abre pela interface o seletor inicialmente marcado como Todos.
        await tester.pumpAndSettle(); // Aguarda a rota de menu suspenso terminar sua animação.
        expect(find.text('Pendentes'), findsOneWidget); // Comprova que a opção real do menu foi construída e está disponível.
        await tocarVisivel(tester, find.text('Pendentes')); // Escolhe os documentos ainda não impressos pelo mesmo toque usado no aplicativo.
        await tester.pumpAndSettle(); // Aguarda o fechamento do menu e a reconstrução do filtro.
        expect(provider.filtro, 'Pendentes'); // Confirma que onChanged comunicou a seleção ao Provider.
        expect(find.text('Roteiro do evento'), findsOneWidget); // O primeiro documento pendente deve continuar no conteúdo da página.
        expect(find.text('Cartaz da oficina'), findsOneWidget); // O segundo documento pendente também deve aparecer.
        expect(find.text('Lista de presença'), findsNothing); // O documento já impresso não pode permanecer entre os cartões filtrados.
        expect(find.text('Documentos: 3 | Folhas necessárias: 24'), findsOneWidget); // O resumo continua global mesmo quando somente dois cartões são exibidos.
        await tocarVisivel(tester, find.byType(DropdownButton<String>)); // Reabre o seletor depois de confirmar o filtro Pendentes.
        await tester.pumpAndSettle(); // Aguarda novamente a abertura do menu suspenso.
        await tocarVisivel(tester, find.text('Todos')); // Restaura a visualização completa antes dos cenários de cadastro e exclusão.
        await tester.pumpAndSettle(); // Fecha o menu e reconstrói os três cartões originais.
        expect(provider.filtro, 'Todos'); // Confirma que a segunda troca também executou o callback normalmente.
        expect(find.text('Lista de presença'), findsOneWidget); // O cartão impresso deve reaparecer ao voltar ao filtro completo.
        expect(tester.takeException(), isNull); // Confere que abrir e fechar o menu nas duas larguras não produziu erro ou overflow.
        final campos = find.byType(TextField); // Seleciona Documento, Páginas por cópia e Cópias.
        await preencher(tester, campos.at(0), 'Documento da interface'); // Preenche o nome do documento novo.
        await preencher(tester, campos.at(1), '2'); // Informa páginas positivas.
        await preencher(tester, campos.at(2), '3'); // Informa cópias positivas.
        await aguardarBanco(tester, provider, () => tocarVisivel(tester, find.widgetWithText(FilledButton, 'Salvar')), () => !provider.carregando && provider.totalDocumentos == 4); // Rola até Salvar e aguarda o novo registro.
        await tocarVisivel(tester, acaoDoCartao('Documento da interface', 'Editar')); // Preenche o formulário pelo cartão recém-criado.
        await tester.pumpAndSettle(); // Mostra o botão Cancelar edição junto ao botão Salvar.
        await preencher(tester, campos.at(1), '7'); // Modifica o documento para tornar a restauração detectável.
        await aguardarBanco(tester, provider, () => tocarVisivel(tester, find.widgetWithText(FilledButton, 'Salvar')), () => !provider.carregando && provider.documentosVisiveis.any((item) => item['nome'] == 'Documento da interface' && item['paginas'] == 7)); // Confere persistência da edição feita na interface.
        final antes = (await tester.runAsync(repository.listar))!; // Guarda os documentos já modificados antes das confirmações.
        await tocarVisivel(tester, acaoDoCartao('Documento da interface', 'Excluir')); // Abre o diálogo de exclusão individual.
        await tester.pumpAndSettle(); // Conclui a apresentação do diálogo.
        expect(find.text('Excluir documento?'), findsOneWidget); // Verifica que a página pediu confirmação.
        await tocarVisivel(tester, acaoDoDialogo('Cancelar')); // Recusa a remoção do documento editado.
        await tester.pumpAndSettle(); // Fecha o diálogo sem iniciar uma operação SQLite.
        expect(await tester.runAsync(repository.listar), antes); // Cancelar a exclusão deve manter inclusive o valor editado.
        final alvo = antes.singleWhere((item) => item['nome'] == 'Cartaz da oficina'); // Escolhe outro documento para testar uma exclusão confirmada.
        await tocarVisivel(tester, acaoDoCartao('Cartaz da oficina', 'Excluir')); // Abre o diálogo do ID que realmente será removido.
        await tester.pumpAndSettle(); // Deixa a ação Confirmar disponível.
        await aguardarBanco(tester, provider, () => tocarVisivel(tester, acaoDoDialogo('Confirmar')), () => !provider.carregando && !provider.documentosVisiveis.any((item) => item['id'] == alvo['id'])); // Confirma e aguarda o DELETE individual.
        final modificados = (await tester.runAsync(repository.listar))!; // Consulta a fila após a exclusão confirmada.
        expect(modificados, antes.where((item) => item['id'] != alvo['id']).toList()); // Todos os documentos não selecionados devem continuar iguais.
        await tocarVisivel(tester, find.byTooltip('Restaurar amostras')); // Rola ao cabeçalho e abre a confirmação de restauração.
        await tester.pumpAndSettle(); // Aguarda o diálogo aparecer na tela estreita.
        expect(find.text('Restaurar amostras?'), findsOneWidget); // Comprova que a restauração não acontece com um único toque no ícone.
        await tocarVisivel(tester, acaoDoDialogo('Cancelar')); // Recusa a primeira tentativa de substituição das amostras.
        await tester.pumpAndSettle(); // Fecha o diálogo mantendo a fila atual.
        expect(await tester.runAsync(repository.listar), modificados); // Cancelar preserva o documento novo editado e a exclusão anterior.
        await tocarVisivel(tester, find.byTooltip('Restaurar amostras')); // Abre a confirmação novamente para aceitar a reposição.
        await tester.pumpAndSettle(); // Aguarda a ação Confirmar do novo diálogo.
        await aguardarBanco(tester, provider, () => tocarVisivel(tester, acaoDoDialogo('Confirmar')), () => !provider.carregando && provider.totalDocumentos == 3 && !provider.documentosVisiveis.any((item) => item['nome'] == 'Documento da interface')); // Confirma e aguarda a transação de restauração.
        final restaurados = (await tester.runAsync(repository.listar))!; // Consulta o resultado efetivo da transação.
        expect(restaurados.map((item) => item['nome']).toList(), ['Roteiro do evento', 'Cartaz da oficina', 'Lista de presença']); // A fila deve recuperar os exemplos e sua ordem original.
        expect(restaurados.map((item) => item['impresso']).toList(), [0, 0, 1]); // Os status de impressão iniciais também devem ser restaurados.
        expect(provider.totalFolhas, 24); // Confere que os dados reconstituídos voltaram a produzir o resumo original.
        final materiaisDepois = (await tester.runAsync(materiais.listar))!; // Reconsulta a tabela que a restauração não poderia alterar.
        expect(materiaisDepois.map((item) => item.toMap()).toList(), materiaisAntes.map((item) => item.toMap()).toList()); // A confirmação de documentos deve preservar todos os materiais.
        expect(tester.takeException(), isNull); // Confere ausência de overflow após formulário, diálogos e restauração.
      } finally { // Garante liberação da interface antes de fechar o banco.
        await tester.pumpWidget(const SizedBox.shrink()); // Desmonta a página e seus controllers locais.
        provider.dispose(); // A variante .value deixa o descarte sob responsabilidade deste teste.
        await tester.runAsync(service.fechar); // Fecha a conexão SQLite usando o loop real.
        debugDefaultTargetPlatformOverride = null; // Restaura a plataforma antes da verificação automática das variáveis de depuração.
      } // Finaliza a limpeza do cenário de impressão.
    }); // Encerra o cenário de impressão nesta resolução.
  } // Encerra a repetição das duas resoluções de celular.
} // Encerra os testes de interação com formulários e confirmações.
// dart format on
