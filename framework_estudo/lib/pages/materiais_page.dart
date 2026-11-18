// dart format off
import 'package:flutter/material.dart'; // Reúne campos, formulário, cartões e diálogos Material.
import '../models/material_evento.dart'; // Importa o modelo tipado exibido nos cartões.
import '../utils/validadores.dart'; // Usa no Form as mesmas regras verificadas pela ViewModel.
import '../viewmodels/material_viewmodel.dart'; // Encaminha ações sem colocar SQL na interface.

class MateriaisPage extends StatefulWidget { // Permite manter os controllers e o identificador da edição no State.
  final MaterialViewModel viewModel; // Recebe a dependência criada e administrada pelo aplicativo.
  const MateriaisPage({super.key, required this.viewModel}); // Exige a ViewModel e encaminha a chave ao widget base.
  @override // Implementa a criação do estado da página.
  State<MateriaisPage> createState() => _MateriaisPageState(); // Separa configuração do widget e dados mutáveis da interface.
} // Finaliza o widget público da Central de Materiais.

class _MateriaisPageState extends State<MateriaisPage> { // Guarda o estado local do formulário e das operações da página.
  final _formulario = GlobalKey<FormState>(); // Permite validar ou resetar todos os campos do Form.
  final _nome = TextEditingController(); // Lê o nome digitado e preenche esse campo ao editar.
  final _categoria = TextEditingController(); // Mantém o texto da categoria.
  final _quantidade = TextEditingController(); // Mantém o texto antes da conversão segura para int.
  final _minimo = TextEditingController(); // Mantém o texto do limite mínimo.
  int? _idEmEdicao; // null representa cadastro; um ID representa edição.
  bool _ocupado = true; // Bloqueia ações enquanto há consulta ou gravação em andamento.
  String? _falhaInicial; // Guarda um erro de abertura para oferecer nova tentativa.
  MaterialViewModel get vm => widget.viewModel; // Facilita o acesso à dependência recebida.

  @override // Executa a consulta inicial uma vez por montagem da página.
  void initState() { // Inicializa o ciclo de vida do formulário.
    super.initState(); // Mantém a inicialização padrão de State.
    _carregarInicial(); // Inicia a leitura assíncrona fora do build, que deve apenas construir widgets.
  } // Finaliza a inicialização da página.

  Future<void> _carregarInicial() async { // Reutiliza a consulta no início e no botão Recarregar.
    setState(() { // Atualiza o estado local antes de consultar o banco.
      _ocupado = true; // Desabilita os controles até a consulta terminar.
      _falhaInicial = null; // Remove uma mensagem de falha anterior.
    }); // Reconstrói o indicador de progresso e esconde o erro anterior.
    try { // Permite apresentar uma falha real de abertura ou consulta.
      await vm.carregar(); // A ViewModel consulta o banco e notifica sua lista de materiais.
    } catch (erro) { // Captura falhas sem tratar a lista como carregada com sucesso.
      if (mounted) setState(() => _falhaInicial = erro.toString()); // Só exibe detalhes numa página ainda montada.
    } finally { // Também executa quando a consulta lança erro.
      if (mounted) setState(() => _ocupado = false); // Libera a interface para uso ou nova tentativa.
    } // Fecha o tratamento de falhas e a liberação do carregamento inicial.
  } // Finaliza a consulta inicial.

  @override // Libera somente os recursos que pertencem a esta página.
  void dispose() { // Executa quando o formulário sai definitivamente da árvore.
    _nome.dispose(); // Libera o controller do nome.
    _categoria.dispose(); // Libera o controller da categoria.
    _quantidade.dispose(); // Libera o controller da quantidade.
    _minimo.dispose(); // Libera o controller do mínimo.
    super.dispose(); // A ViewModel pertence ao aplicativo e é descartada pelo proprietário no main.
  } // Finaliza a liberação dos controllers locais.

  void _limpar() { // Prepara os campos para um novo material.
    _idEmEdicao = null; // Evita atualizar acidentalmente o material editado anteriormente.
    _nome.clear(); // Apaga o nome.
    _categoria.clear(); // Apaga a categoria.
    _quantidade.clear(); // Apaga a quantidade disponível.
    _minimo.clear(); // Apaga a quantidade mínima.
    _formulario.currentState?.reset(); // Remove as mensagens de validação anteriores, se o Form existir.
  } // O chamador usa setState quando precisa atualizar o rótulo do modo.

  void _avisar(String mensagem) { // Mostra o resultado de uma ação no rodapé.
    ScaffoldMessenger.of(context).showSnackBar( // Localiza o mensageiro disponibilizado pelo MaterialApp.
      SnackBar(content: Text(mensagem)), // Constrói a mensagem transitória de sucesso ou falha.
    ); // Exibe o SnackBar sem trocar de página.
  } // Finaliza a comunicação do resultado com o usuário.

  Future<void> _executar(Future<void> Function() acao) async { // Centraliza bloqueio, erros e desbloqueio das ações.
    if (_ocupado) return; // Evita cliques duplicados enquanto o SQLite está trabalhando.
    setState(() => _ocupado = true); // Ativa o indicador e bloqueia os controles.
    try { // Aguarda a ação para que uma falha seja recebida neste tratamento.
      await acao(); // Espera a gravação e a recarga antes de liberar a tela.
    } on FormatException catch (erro) { // Separa as mensagens das regras de negócio das demais falhas.
      if (mounted) _avisar(erro.message); // Informa a validação sem apagar os campos digitados.
    } catch (erro) { // Apresenta também falhas inesperadas, como um erro do banco.
      if (mounted) _avisar('Não foi possível concluir: $erro'); // Evita informar sucesso em uma gravação malsucedida.
    } finally { // Garante que o aplicativo não fique bloqueado após um erro.
      if (mounted) setState(() => _ocupado = false); // Reativa controles apenas se a página ainda existe.
    } // Finaliza a ação protegida e sua limpeza de estado.
  } // Encerra o controle de operações assíncronas.

  Future<void> _salvar() async { // Trata o botão Cadastrar ou Salvar alterações.
    if (!_formulario.currentState!.validate()) return; // Exibe os erros dos TextFormFields e impede a gravação inválida.
    await _executar(() async { // Reutiliza a proteção contra múltiplos cliques e falhas.
      await vm.salvar( // A ViewModel repete as validações e escolhe INSERT ou UPDATE.
        id: _idEmEdicao, // Mantém o alvo quando o formulário está em edição.
        nome: _nome.text, // Envia o texto atual do nome.
        categoria: _categoria.text, // Envia a categoria digitada.
        quantidade: _quantidade.text, // Envia texto para validar conversão inteira e não negatividade.
        minimo: _minimo.text, // Envia o limite digitado como texto.
      ); // Aguarda a persistência e a lista atualizada.
      if (!mounted) return; // Não acessa widgets se a página saiu durante o await.
      _limpar(); // Apaga os campos somente depois do salvamento bem-sucedido.
      _avisar('Material salvo.'); // Confirma o resultado já persistido.
    }); // A rotina protegida desativa o indicador no finally.
  } // Finaliza o salvamento solicitado pela interface.

  void _editar(MaterialEvento material) { // Preenche o formulário com o material selecionado.
    setState(() { // Reconstrói o título e os botões no modo edição.
      _idEmEdicao = material.id; // Guarda o ID usado pelo WHERE do UPDATE.
      _nome.text = material.nome; // Mostra o nome existente.
      _categoria.text = material.categoria; // Mostra a categoria existente.
      _quantidade.text = material.quantidade.toString(); // Converte o inteiro para exibição no campo.
      _minimo.text = material.minimo.toString(); // Exibe o mínimo persistido.
    }); // Atualiza visualmente o formulário preenchido.
  } // Finaliza a entrada no modo edição.

  Future<void> _excluir(MaterialEvento material) async { // Pede confirmação antes de chamar o DELETE.
    final confirmou = await showDialog<bool>( // Aguarda true, false ou null se o diálogo for fechado.
      context: context, // Abre o diálogo na rota atual.
      builder: (dialogo) => AlertDialog( // Usa o contexto próprio do diálogo para fechá-lo.
        title: const Text('Excluir material?'), // Explica qual ação será executada.
        content: Text('Excluir ${material.nome}? Os outros materiais serão mantidos.'), // Identifica o alvo da exclusão.
        actions: [ // Oferece cancelamento e confirmação sem alterar dados antecipadamente.
          TextButton( // A opção de cancelamento mantém tudo no SQLite.
            onPressed: () => Navigator.pop(dialogo, false), // Fecha devolvendo recusa explícita.
            child: const Text('Cancelar'), // Nomeia a saída sem exclusão.
          ), // Fecha o botão de cancelamento.
          FilledButton( // Destaca a ação que removerá o registro.
            onPressed: () => Navigator.pop(dialogo, true), // Fecha devolvendo confirmação.
            child: const Text('Excluir'), // Nomeia a operação confirmada.
          ), // Fecha o botão de exclusão.
        ], // Finaliza as escolhas do diálogo.
      ), // Fecha o AlertDialog.
    ); // Obtém a escolha do usuário antes de tocar no repositório.
    if (confirmou != true || !mounted) return; // Cancelar, fechar ou sair da página não altera o banco.
    await _executar(() async { // Só executa o DELETE após a confirmação.
      await vm.excluir(material.id!); // O ID existe porque o cartão veio de uma linha persistida.
      if (!mounted) return; // Evita acessar o formulário depois de sair da página.
      if (_idEmEdicao == material.id) _limpar(); // Não mantém uma edição apontando para um item removido.
      _avisar('Material excluído.'); // Confirma o término da exclusão individual.
    }); // Reativa os controles após concluir ou falhar.
  } // Finaliza a exclusão com confirmação.

  Widget _campo( // Reutiliza a aparência e a escolha de validador dos quatro campos.
    TextEditingController controller, // Recebe o controller específico de cada informação.
    String titulo, { // Define o rótulo e inicia os argumentos nomeados opcionais.
    bool numerico = false, // Distingue texto obrigatório de quantidade inteira não negativa.
  }) => Padding( // Retorna o campo com espaçamento vertical.
    padding: const EdgeInsets.only(bottom: 12), // Mantém distância uniforme entre entradas.
    child: TextFormField( // Integra o campo ao FormState para validate e reset.
      controller: controller, // Liga o conteúdo digitado ao estado local.
      decoration: InputDecoration(labelText: titulo, border: const OutlineInputBorder()), // Exibe rótulo e borda.
      keyboardType: numerico ? TextInputType.number : TextInputType.text, // O teclado numérico ajuda a digitar, mas não valida.
      validator: numerico ? Validadores.quantidade : Validadores.textoObrigatorio, // Executa a regra apropriada em validate.
    ), // Fecha o TextFormField.
  ); // Finaliza o componente reutilizado para cada campo.

  @override // Constrói a página com o estado local e a lista observável.
  Widget build(BuildContext context) { // Reconstrói a página quando setState for chamado.
    if (_falhaInicial != null) { // Distingue falha de abertura de uma lista vazia carregada com sucesso.
      return Center( // Centraliza a mensagem de falha e a nova tentativa.
        child: Padding( // Afasta o conteúdo das bordas em telas pequenas.
          padding: const EdgeInsets.all(20), // Aplica espaçamento em todos os lados.
          child: Column( // Organiza a mensagem e o botão verticalmente.
            mainAxisSize: MainAxisSize.min, // Ocupa apenas a altura necessária.
            children: [ // Inicia os elementos da recuperação.
              const Text('Não foi possível abrir o banco.'), // Explica a falha de infraestrutura.
              SelectableText(_falhaInicial!), // Permite copiar os detalhes para diagnóstico.
              FilledButton( // Oferece uma recuperação sem reiniciar o aplicativo.
                onPressed: _carregarInicial, // Repete a leitura e limpa o erro anterior.
                child: const Text('Tentar novamente'), // Nomeia a ação de recuperação.
              ), // Finaliza o botão de nova tentativa.
            ], // Finaliza os elementos da recuperação.
          ), // Fecha a coluna de recuperação.
        ), // Fecha o espaçamento da mensagem.
      ); // Retorna a tela de falha sem construir o formulário normal.
    } // Finaliza a decisão de falha inicial.
    return AbsorbPointer( // Evita ações concorrentes sem esconder o progresso.
      absorbing: _ocupado, // Absorve toques enquanto uma operação está ativa.
      child: SingleChildScrollView( // Mantém formulário e lista acessíveis em alturas pequenas.
        padding: const EdgeInsets.all(16), // Evita campos colados às bordas.
        child: Center( // Centraliza o conteúdo em monitores largos.
          child: ConstrainedBox( // Evita esticar os campos por toda a tela desktop.
            constraints: const BoxConstraints(maxWidth: 900), // Limita a largura de leitura.
            child: Column( // Empilha título, formulário e cartões de materiais.
              crossAxisAlignment: CrossAxisAlignment.stretch, // Usa a largura disponível para os campos.
              children: [ // Começa o conteúdo principal da revisão 1.
                if (_ocupado) const LinearProgressIndicator(), // Mostra que há consulta ou gravação em andamento.
                Wrap( // Quebra título e botão de recarga em celulares estreitos.
                  alignment: WrapAlignment.spaceBetween, // Separa título e recarga quando houver espaço.
                  crossAxisAlignment: WrapCrossAlignment.center, // Alinha verticalmente os elementos do cabeçalho.
                  children: [ // Contém o título da atividade e a recarga.
                    Text( // Apresenta o nome da revisão com destaque tipográfico.
                      'Central de materiais', // Identifica a área de estudo.
                      style: Theme.of(context).textTheme.titleLarge, // Reutiliza o estilo de título do tema.
                    ), // Fecha o título da área de materiais.
                    IconButton( // Mostra a ação de consultar novamente os registros persistidos.
                      tooltip: 'Recarregar do banco', // Explica o ícone por leitura assistiva ou ponteiro.
                      onPressed: _carregarInicial, // Reaproveita a consulta com progresso e tratamento de erro.
                      icon: const Icon(Icons.refresh), // Representa visualmente a recarga.
                    ), // Fecha o botão de recarga.
                  ], // Fecha os elementos do cabeçalho.
                ), // Fecha o cabeçalho flexível.
                Text(_idEmEdicao == null ? 'Cadastrar material' : 'Editar material'), // Indica o modo atual do formulário.
                const SizedBox(height: 16), // Separa título e campos.
                Form( // Agrupa os campos validados antes de salvar.
                  key: _formulario, // Dá acesso aos métodos validate e reset.
                  child: Column( // Empilha os quatro campos e as ações.
                    children: [ // Lista as entradas de dados.
                      _campo(_nome, 'Nome'), // [R1-01] Nome é um campo textual obrigatório.
                      _campo(_categoria, 'Categoria'), // [R1-01] Categoria também não aceita apenas espaços.
                      _campo(_quantidade, 'Quantidade disponível', numerico: true), // [R1-02] Aceita inteiro maior ou igual a zero.
                      _campo(_minimo, 'Quantidade mínima', numerico: true), // [R1-02] Aplica o mesmo limite ao mínimo.
                      Wrap( // Quebra os botões em vez de causar overflow durante a edição.
                        spacing: 8, // Define a distância horizontal entre ações.
                        runSpacing: 8, // Separa as linhas quando as ações precisarem quebrar.
                        children: [ // Mostra a ação principal e o cancelamento opcional.
                          FilledButton( // Envia o formulário para validação e persistência.
                            onPressed: _salvar, // Usa a proteção de _executar contra concorrência.
                            child: Text(_idEmEdicao == null ? 'Cadastrar' : 'Salvar alterações'), // Usa o rótulo do modo ativo.
                          ), // Fecha o botão principal.
                          if (_idEmEdicao != null) // Exibe cancelamento apenas durante a edição.
                            TextButton( // Retorna ao modo cadastro sem alterar o registro persistido.
                              onPressed: () => setState(_limpar), // Limpa campos e reconstrói os rótulos do modo.
                              child: const Text('Cancelar'), // Identifica a saída do modo edição.
                            ), // Fecha o botão de cancelamento da edição.
                        ], // Finaliza as ações do formulário.
                      ), // Fecha a área de botões adaptável.
                    ], // Finaliza as entradas e ações.
                  ), // Fecha a coluna do Form.
                ), // Finaliza o formulário.
                const SizedBox(height: 20), // Separa as entradas da listagem.
                const Divider(), // Delimita visualmente formulário e registros.
                AnimatedBuilder( // Reconstrói a listagem quando a ViewModel notifica.
                  animation: vm, // ChangeNotifier implementa Listenable e pode ser observado aqui.
                  builder: (context, _) { // Constrói a lista com os dados mais recentes do estado.
                    final materiais = vm.materiais; // Recebe uma visão não modificável dos materiais.
                    if (materiais.isEmpty) return const Text('Nenhum material cadastrado.'); // Exibe a lista vazia sem confundir com falha.
                    return Column( // Empilha os cartões retornados pela consulta.
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Faz os cartões ocuparem a largura disponível para leitura.
                      children: materiais.map((material) => Card( // Converte cada modelo em um cartão da lista.
                        child: Padding( // Mantém os textos afastados da borda do cartão.
                          padding: const EdgeInsets.all(14), // Usa distância uniforme interna.
                          child: Column( // Organiza as informações do material verticalmente.
                            crossAxisAlignment: CrossAxisAlignment.start, // Alinha as informações à esquerda.
                            children: [ // Lista nome, categoria, quantidades, situação e ações.
                              Text( // Apresenta o nome persistido com o estilo de subtítulo.
                                material.nome, // Usa o nome do material representado por este cartão.
                                style: Theme.of(context).textTheme.titleMedium, // Obtém a tipografia do tema.
                              ), // Fecha o texto do nome do material.
                              Text('Categoria: ${material.categoria}'), // Exibe a categoria do registro.
                              Text('Disponível: ${material.quantidade} | Mínimo: ${material.minimo}'), // Mostra os dados usados na classificação.
                              Text( // Apresenta a classificação calculada pelo modelo.
                                material.situacao, // [R1-03] Usa o getter corrigido para zero, baixo e adequado.
                                style: const TextStyle(fontWeight: FontWeight.bold), // Destaca a situação sem duplicar a regra na interface.
                              ), // Fecha o texto da situação do estoque.
                              Wrap( // Mantém ambas as ações acessíveis em largura pequena.
                                spacing: 8, // Separa os botões de edição e exclusão.
                                children: [ // Lista as ações do material atual.
                                  TextButton.icon( // Oferece edição do registro deste cartão.
                                    onPressed: () => _editar(material), // Preenche o formulário com o material escolhido.
                                    icon: const Icon(Icons.edit), // Representa a ação de editar.
                                    label: const Text('Editar'), // Nomeia a ação também em texto.
                                  ), // Finaliza o botão de edição.
                                  TextButton.icon( // Oferece exclusão individual com confirmação.
                                    onPressed: () => _excluir(material), // Abre o diálogo antes de pedir o DELETE.
                                    icon: const Icon(Icons.delete_outline), // Representa a remoção do registro.
                                    label: const Text('Excluir'), // Nomeia a ação de exclusão.
                                  ), // Finaliza o botão de exclusão.
                                ], // Fecha as ações do cartão.
                              ), // Fecha a área de ações adaptável.
                            ], // Finaliza as informações deste material.
                          ), // Fecha a coluna interna do cartão.
                        ), // Fecha o espaçamento do cartão.
                      )).toList(), // Materializa os widgets exigidos por children e encerra map e Card.
                    ); // Retorna a lista de cartões atualizada.
                  }, // Fecha o builder que observa a ViewModel.
                ), // Fecha o AnimatedBuilder.
              ], // Finaliza o conteúdo principal.
            ), // Fecha a coluna de formulário e lista.
          ), // Fecha a largura máxima.
        ), // Fecha a centralização do conteúdo.
      ), // Fecha a área rolável.
    ); // Retorna a página protegida durante operações.
  } // Encerra build.
} // Encerra o estado da página de materiais.
// dart format on
