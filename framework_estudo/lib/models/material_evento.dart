// dart format off
class MaterialEvento { // Representa uma linha da tabela materiais da revisão 1.
  final int? id; // null no cadastro; o SQLite gera o identificador persistente.
  final String nome; // Nome mostrado no formulário e no cartão.
  final String categoria; // Categoria obrigatória do material.
  final int quantidade; // Unidades disponíveis, incluindo zero.
  final int minimo; // Referência usada para classificar o estoque.

  const MaterialEvento({ // Constrói um objeto imutável com argumentos nomeados.
      this.id, // O cadastro não precisa informar um ID.
      required this.nome, // Exige o nome na construção.
      required this.categoria, // Exige a categoria.
      required this.quantidade, // Exige a quantidade disponível.
      required this.minimo, // Exige a quantidade mínima.
  }); // Fecha o construtor do modelo.

  String get nomeNormalizado => nome.trim().toLowerCase(); // Mesma normalização no mapa e na busca de duplicidade.

  String get situacao { // [R1-03] Calcula a classificação sem gravar um resultado redundante no banco.
    if (quantidade == 0) return 'Sem estoque'; // Primeiro caso: inclusive quantidade=0 e mínimo=0.
    if (quantidade < minimo) return 'Estoque baixo'; // Aqui a quantidade já é maior que zero.
    return 'Estoque adequado'; // Inclui a igualdade entre quantidade e mínimo.
  } // Finaliza a regra de situação do estoque.

  Map<String, Object?> toMap() => { // Traduz propriedades Dart para as colunas do SQLite.
    if (id != null) 'id': id, // Omite o ID de novos materiais para usar AUTOINCREMENT.
    'nome': nome.trim(), // Remove espaços externos do texto apresentado.
    'nome_normalizado': nomeNormalizado, // Alimenta a coluna UNIQUE de nomes.
    'categoria': categoria.trim(), // Persiste a categoria sem espaços externos.
    'quantidade': quantidade, // Persiste o valor como inteiro, sem convertê-lo para texto.
    'minimo': minimo, // Usa a mesma chave declarada no CREATE TABLE.
  }; // Fecha o mapa de persistência.

  factory MaterialEvento.fromMap(Map<String, Object?> map) => MaterialEvento( // Constrói um modelo após uma query.
    id: map['id'] as int, // Toda linha persistida já possui um ID.
    nome: map['nome'] as String, // Lê a coluna de nome.
    categoria: map['categoria'] as String, // Lê a categoria do registro.
    quantidade: (map['quantidade'] as num).toInt(), // Converte o número devolvido pelo driver para int.
    minimo: (map['minimo'] as num).toInt(), // Reconstrói o limite como inteiro.
  ); // Fecha a conversão da linha para modelo.
} // Encerra a classe de material.
// dart format on
