// dart format off
import 'package:device_preview/device_preview.dart'; // Simula dispositivos conforme a revisão 2.
import 'package:flutter/foundation.dart'; // Disponibiliza kDebugMode para limitar a simulação ao desenvolvimento.
import 'package:flutter/material.dart'; // Reúne os widgets Material e a navegação por abas.
import 'package:provider/provider.dart'; // Expõe o estado da impressão pelo BuildContext.
import 'pages/materiais_page.dart'; // Importa a interface da revisão 1.
import 'pages/impressao_page.dart'; // Importa a interface da revisão 2.
import 'providers/impressao_provider.dart'; // Importa o ChangeNotifier dos documentos.
import 'repositories/material_repository.dart'; // Importa o CRUD dos materiais.
import 'repositories/impressao_repository.dart'; // Importa o CRUD dos documentos.
import 'services/database_service.dart'; // Compartilha um banco com duas tabelas independentes.
import 'viewmodels/material_viewmodel.dart'; // Importa as regras de negócio dos materiais.

void main() { // Ponto de entrada executado pelo Flutter.
  WidgetsFlutterBinding.ensureInitialized(); // Prepara o framework antes de montar a aplicação.
  runApp( // Entrega a árvore visual ao motor do Flutter.
    DevicePreview( // Exibe ferramentas para escolher tamanhos de celular durante o estudo.
      enabled: kDebugMode, // Fica ativo em debug e desativado no build release.
      builder: (_) => const EstudoApp(), // Constrói o aplicativo dentro da simulação.
    ), // Fecha o DevicePreview.
  ); // Finaliza a montagem inicial.
} // Encerra main.

class EstudoApp extends StatefulWidget { // Mantém banco e estados vivos ao alternar as abas.
  const EstudoApp({super.key}); // Recebe uma chave opcional para identificação do widget.
  @override // Implementa o contrato de StatefulWidget.
  State<EstudoApp> createState() => _EstudoAppState(); // Cria o objeto que controla os recursos do aplicativo.
} // Encerra o widget raiz.

class _EstudoAppState extends State<EstudoApp> { // Guarda as dependências das duas revisões.
  late final DatabaseService _service; // Uma única instância atende às duas tabelas.
  late final MaterialViewModel _materiais; // Preserva os dados da revisão 1 enquanto a outra aba está aberta.
  late final ImpressaoProvider _impressao; // Preserva os dados e o filtro da revisão 2.

  @override // Inicializa os recursos uma vez por montagem do aplicativo.
  void initState() { // Executa antes do primeiro build.
    super.initState(); // Mantém a inicialização padrão do State.
    _service = DatabaseService(); // Seleciona o driver SQLite para o Chrome.
    _materiais = MaterialViewModel(MaterialRepository(_service)); // Liga ViewModel, repository e serviço.
    _impressao = ImpressaoProvider(ImpressaoRepository(_service)); // Usa a mesma infraestrutura para os documentos.
    _impressao.iniciar(); // Inicia a consulta; o Provider informa loading e eventuais falhas.
  } // Finaliza a criação das dependências.

  @override // Libera os recursos cujo proprietário é o aplicativo.
  void dispose() { // Executa quando a raiz sai definitivamente da árvore.
    _materiais.dispose(); // Libera os listeners da revisão 1.
    _impressao.dispose(); // Libera os listeners da revisão 2.
    _service.fechar(); // Solicita fechamento do banco; dispose não pode aguardar Future.
    super.dispose(); // Finaliza o ciclo de vida do State.
  } // Encerra a liberação dos recursos.

  @override // Descreve a interface a partir do estado atual.
  Widget build(BuildContext context) { // Usa o contexto para a integração com DevicePreview.
    return ChangeNotifierProvider<ImpressaoProvider>.value( // Expõe o objeto existente sem assumir seu descarte.
      value: _impressao, // context.watch/read obterão esta mesma instância.
      child: MaterialApp( // Configura o tema e a navegação do estudo.
        title: 'Frameworks: revisões comentadas', // Define o título da aba do navegador.
        debugShowCheckedModeBanner: false, // Remove a faixa DEBUG da interface.
        locale: DevicePreview.locale(context), // Aplica a localidade selecionada na simulação.
        builder: DevicePreview.appBuilder, // Aplica as dimensões de dispositivo ao conteúdo.
        theme: ThemeData( // Centraliza a aparência das duas revisões.
          useMaterial3: true, // Usa os componentes Material atuais.
          colorSchemeSeed: Colors.indigo, // Gera uma paleta consistente a partir do índigo.
        ), // Fecha a configuração do tema.
        home: DefaultTabController( // Controla a aba selecionada sem estado manual adicional.
          length: 2, // O projeto reúne as duas atividades enviadas.
          child: Scaffold( // Fornece a barra superior e o corpo das abas.
            appBar: AppBar( // Mostra título e navegação entre as revisões.
              title: const Text('Frameworks • estudo'), // Identifica o material como projeto de consulta.
              bottom: const TabBar( // Sincroniza os botões com o TabBarView abaixo.
                tabs: [ // Lista os dois destinos disponíveis.
                  Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Materiais'), // Sete TODOs resolvidos.
                  Tab(icon: Icon(Icons.print_outlined), text: 'Impressão'), // Cinco bugs corrigidos.
                ], // Finaliza a lista de abas.
              ), // Fecha a barra de abas.
            ), // Fecha a barra superior.
            body: TabBarView( // Apresenta a página correspondente à aba selecionada.
              children: [ // Mantém ambas as revisões no mesmo aplicativo.
                MateriaisPage(viewModel: _materiais), // Injeta a ViewModel explicitamente como na revisão 1.
                const ImpressaoPage(), // A revisão 2 encontra o Provider através do contexto.
              ], // Finaliza a lista de páginas.
            ), // Fecha o conteúdo das abas.
          ), // Fecha a estrutura externa do aplicativo.
        ), // Fecha o controlador das abas.
      ), // Fecha o MaterialApp.
    ); // Retorna a árvore que fornece o Provider.
  } // Finaliza build.
} // Encerra o estado do aplicativo.
// dart format on
