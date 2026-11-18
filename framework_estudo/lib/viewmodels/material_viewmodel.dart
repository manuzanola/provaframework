// dart format off
import 'package:flutter/foundation.dart'; // Disponibiliza ChangeNotifier para atualizar widgets observadores.
import '../models/material_evento.dart'; // Define o objeto que será persistido após a validação.
import '../repositories/material_repository.dart'; // Separa regras da aplicação das consultas SQL.
import '../utils/validadores.dart'; // Reutiliza as mesmas regras do formulário.

class MaterialViewModel extends ChangeNotifier { // Coordena validação, persistência e recarga dos materiais.
  final MaterialRepository repository; // Recebe o repository sem criar dependências escondidas.
  List<MaterialEvento> _materiais = []; // Mantém uma cópia privada dos dados recuperados do SQLite.
  bool _descartado = false; // Impede notificações tardias após o descarte do aplicativo.
  MaterialViewModel(this.repository); // Injeta o repository montado no main ou no teste.
  List<MaterialEvento> get materiais => List.unmodifiable(_materiais); // Impede que a tela altere a lista diretamente.

  Future<void> carregar() async { // Consulta novamente depois de cada gravação.
    _materiais = await repository.listar(); // Aguarda o banco; a lista não substitui a persistência real.
    if (!_descartado) notifyListeners(); // O AnimatedBuilder reconstrói os cartões quando a consulta termina.
  } // Finaliza a recarga observável.

  Future<void> salvar({ // Aplica o mesmo fluxo de validação em cadastro e edição.
      int? id, // null indica cadastro; valor presente indica edição.
      required String nome, // Recebe o conteúdo original do campo de nome.
      required String categoria, // Recebe o texto da categoria.
      required String quantidade, // Recebe texto para reconhecer vazio, letras e decimais.
      required String minimo, // Recebe o texto da quantidade mínima.
  }) async { // O chamador aguarda a operação antes de liberar o formulário.
    for (final campo in [nome, categoria]) { // Verifica ambos os campos obrigatórios.
      final erro = Validadores.textoObrigatorio(campo); // [R1-01] Rejeita também entradas apenas com espaços.
      if (erro != null) throw FormatException(erro); // Interrompe antes de gravar qualquer dado inválido.
    } // Finaliza as validações textuais.
    for (final campo in [quantidade, minimo]) { // Confere as duas quantidades com a mesma regra.
      final erro = Validadores.quantidade(campo); // [R1-02] Materiais permitem zero, ao contrário da impressão.
      if (erro != null) throw FormatException(erro); // A tela exibe a mensagem em um SnackBar.
    } // Finaliza a validação numérica.
    if (await repository.existeNome(nome, ignorarId: id)) { // [R1-04] A edição pode manter o nome do próprio registro.
      throw const FormatException('Já existe um material com esse nome.'); // Explica o conflito de nomes.
    } // Fecha a proteção contra duplicidade.
    final material = MaterialEvento( // Constrói o modelo somente depois de validar os textos.
      id: id, // Preserva o identificador da edição, quando houver.
      nome: nome.trim(), // Remove espaços externos antes de salvar.
      categoria: categoria.trim(), // Padroniza a apresentação da categoria.
      quantidade: int.parse(quantidade.trim()), // Seguro porque este mesmo texto passou pelo tryParse do validador.
      minimo: int.parse(minimo.trim()), // Converte o limite validado em int.
    ); // Finaliza a montagem do objeto.
    if (id == null) { // Ausência de ID significa que o material é novo.
      await repository.inserir(material); // [R1-05] Espera a conclusão do INSERT.
    } else { // Presença de ID indica edição de um material persistido.
      await repository.atualizar(material); // [R1-06] O repository aplica WHERE id = ?.
    } // Finaliza a escolha entre INSERT e UPDATE.
    await carregar(); // Reconsulta o SQLite e notifica a interface após a gravação.
  } // Finaliza o salvamento.

  Future<void> excluir(int id) async { // Recebe o identificador após a confirmação visual.
    await repository.excluir(id); // [R1-07] Espera o DELETE individual.
    await carregar(); // Atualiza os cartões com a consulta confirmada pelo banco.
  } // Finaliza a exclusão e recarga.

  @override // Personaliza o ciclo de vida do ChangeNotifier.
  void dispose() { // Libera o estado quando o aplicativo sai da árvore.
    _descartado = true; // Bloqueia notifyListeners depois de operações pendentes.
    super.dispose(); // Libera os listeners registrados na classe base.
  } // Finaliza o descarte da ViewModel.
} // Encerra a ViewModel de materiais.
// dart format on
