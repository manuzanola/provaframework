# Revisões: resultados e explicação de uma validação

Material de estudo elaborado em 17/11/2026 a partir dos três PDFs e dos dois projetos enviados. O projeto executável contém as implementações resolvidas; os trechos incorretos usados para treino estão identificados em `docs/03_laboratorio_de_erros.md`.

## Resultados verificados

| Verificação | Resultado |
|---|---|
| `flutter pub get` | Dependências resolvidas; `pubspec.lock` incluído. |
| `flutter analyze` | Sem apontamentos. |
| `flutter test` | 16 testes aprovados: 12 de regras/SQLite e 4 fluxos de interface. |
| Build web release com recursos gráficos locais | Compilado com sucesso. |
| Build web debug com DevicePreview | Compilado e aberto no Chrome; simulação visível. |
| SQLite Web no Chrome | Material cadastrado com estoque 0/0 e recuperado após recarga. |
| Impressão no Chrome | Amostras 12/10/2 e resumo 24; alternância individual preserva os outros registros. |
| Persistência do status no Chrome | Marcação mantida após recarregar a mesma origem. |
| Filtro Pendentes no Chrome | Somente documentos não impressos; resumo global continua 24. |
| Restauração no Chrome | Confirmação executada e amostras recuperadas. |
| Formulários em 360×800 e 390×844 | Widgets testados sem overflow, com cadastro, edição, exclusão e restauração. |

Os testes de interface verificam também cancelar exclusão e cancelar restauração sem modificar os registros. O teste em arquivo físico fecha e reabre o SQLite para verificar cadastro, edição, exclusão e status. Os detalhes e os limites estão em [docs/04_validacao.md](docs/04_validacao.md).

## Explicação de uma validação

**Arquivo e método:** `lib/utils/validadores.dart`, `Validadores.quantidade` (`R1-02`).

O método remove os espaços externos, tenta converter o texto com `int.tryParse` e devolve uma mensagem quando a conversão falha ou o inteiro é negativo. Um retorno `null` representa uma entrada válida no contrato de `TextFormField.validator`.

Esse local é adequado porque a mesma regra atende aos dois campos numéricos de materiais e é reaproveitada pela ViewModel. O formulário apresenta mensagens junto ao campo; a ViewModel verifica novamente antes de persistir, inclusive se for chamada sem a tela.

Exemplos: `0` e ` 12 ` são aceitos; vazio, espaços, letras, `-1`, `1.5` e `1,5` são recusados. A regra de materiais é `>= 0`. A revisão de impressão exige **`> 0`**, por isso seu Provider usa a validação própria em `validar` (`R2-02`).

## Exemplo de correção explicado

**Arquivo e método:** `lib/repositories/impressao_repository.dart`, `alternarImpressao` (`R2-05`).

O original usa `where: 'id <> ?'`. Assim, seleciona os registros cujo ID é diferente do escolhido. A correção `where: 'id = ?'`, com `whereArgs: [id]`, limita a alteração ao documento selecionado. O valor novo é `0` quando estava impresso e `1` quando estava pendente.

Para conferir, há três documentos. Marcar Roteiro precisa mudar apenas ele; Cartaz permanece pendente e Lista permanece impressa. O teste repete a alternância para desfazê-la e compara os registros. A conferência no navegador também recarregou a página antes de verificar o status persistido.

## Preparação complementar

O manifesto declara `provider` explicitamente, e `main.dart` configura o DevicePreview. O worker SQLite foi compilado com o lock do projeto para evitar a mistura de versões do gerador antigo. Essas providências de ambiente não substituem os cinco erros de funcionamento indicados no roteiro.

Não houve envio de repositório ou atividade ao professor. O arquivo `github.md` explica os passos para você publicar sua própria cópia. O alvo do aplicativo é Chrome; testes FFI no computador não constituem validação de aplicativo Android/iOS.
