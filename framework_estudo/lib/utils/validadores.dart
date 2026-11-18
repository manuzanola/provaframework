// dart format off
class Validadores { // Reúne regras reutilizadas pelo Form e pela ViewModel.
  static String? textoObrigatorio(String? valor) { // [R1-01] Retorna uma mensagem ou null quando válido.
    if (valor == null || valor.trim().isEmpty) { // Rejeita ausência de texto e campos com apenas espaços.
      return 'Preencha este campo; espaços não são um valor.'; // Explica o problema ao usuário.
    } // Encerra a condição de texto inválido.
    return null; // O contrato de Form considera null como ausência de erro.
  } // Finaliza a validação de nome e categoria.

  static String? quantidade(String? valor) { // [R1-02] Materiais aceitam inteiros maiores ou iguais a zero.
    final numero = int.tryParse(valor?.trim() ?? ''); // Vazio, letras e decimais produzem null, sem exceção.
    if (numero == null || numero < 0) { // Zero passa; números negativos e entradas não inteiras falham.
      return 'Informe um número inteiro maior ou igual a zero.'; // Explica a regra de estoque.
    } // Encerra a verificação numérica.
    return null; // Confirma que a quantidade é válida.
  } // Finaliza a validação numérica.
} // Encerra a classe de validadores.
// dart format on
