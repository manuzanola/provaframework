# Mapa das revisões e dos padrões de erros

Este projeto reúne os conteúdos das duas revisões enviadas. A Central de Materiais apresenta sete TODOs para completar; a Fila de Impressão apresenta cinco erros de funcionamento para investigar. O roteiro de resolução confirma onde procurar e quais resultados conferir. Esses padrões orientam o estudo, mas não garantem quais questões aparecerão na prova.

No VS Code, use **Ctrl+Shift+F** e procure um identificador como `R1-03` ou `R2-05`. Os comentários do código relacionam cada implementação ao quadro abaixo. Procure também pelo nome do método: os números das linhas mudam quando são adicionados comentários.

## Fontes analisadas

| Referência | Material fornecido | Evidência utilizada |
|---|---|---|
| A | `Revisao 1 - CENTRAL DE MATERIAIS.pdf` | P. 1: validações e situação do estoque. P. 2: CRUD, testes e nomes repetidos. P. 3-4: entrega e execução no Chrome com SQLite web. |
| B | `REVISÃO 2.pdf` | P. 1: DevicePreview, ordem de chegada e validação. P. 2: cálculo, filtros, alteração individual e amostras. P. 3: conferência, persistência e explicação de uma correção. |
| C | `Resolução das revisões.pdf` | P. 1-2: os sete TODOs de materiais. P. 2-3: os cinco erros da impressão e o roteiro de conferência. |
| D | `revisao 1.zip` | Implementações incompletas em validadores, modelo e repositório; interface e banco já fornecidos. |
| E | `revisao2.zip` | Implementações com operadores, ordenação e filtros incorretos, além de ajustes de configuração indicados abaixo. |

As orientações de entrega contidas nesses documentos pertencem à atividade original. Este pacote é um material de estudo; nenhum envio ao professor ou publicação no GitHub é feito automaticamente.

## Revisão 1: os sete pontos de implementação

| ID | Sintoma ou objetivo | Onde consultar neste projeto | Regra correta | Conferência decisiva |
|---|---|---|---|---|
| **R1-01** | Campo obrigatório aceita vazio ou espaços. | `lib/utils/validadores.dart`, `textoObrigatorio` | Tratar `null`, `''` e texto que fica vazio após `trim()`. A regra atende tanto nome quanto categoria. | Nome `'   '` e categoria `'   '` devem ser recusados. |
| **R1-02** | Quantidade inválida passa na validação. | `lib/utils/validadores.dart`, `quantidade` | Converter com segurança e aceitar somente inteiro **>= 0**. Não transformar erro de conversão em zero. | `0` deve passar; vazio, letras, `-1`, `1.5` e `1,5` devem falhar. |
| **R1-03** | A situação do estoque não é classificada. | `lib/models/material_evento.dart`, getter `situacao` | Verificar quantidade zero primeiro; depois quantidade abaixo do mínimo; depois estoque adequado. | Quantidade `0` e mínimo `0` continuam significando **Sem estoque**. |
| **R1-04** | Nomes repetidos não são detectados corretamente. | `lib/repositories/material_repository.dart`, `existeNome` | Consultar `nome.trim().toLowerCase()`; ao editar, excluir o próprio ID da busca. | `Microfone` e `' microfone '` são iguais; manter o próprio nome na edição é permitido. |
| **R1-05** | Cadastro lança erro de operação não implementada. | `lib/repositories/material_repository.dart`, `inserir` | Persistir `material.toMap()` em `materiais` e recarregar o estado após salvar. | Novo material aparece sem reiniciar; após recarregar a página, continua cadastrado. |
| **R1-06** | Edição não salva ou poderia atingir outros itens. | `lib/repositories/material_repository.dart`, `atualizar` | Atualizar somente `WHERE id = ?`, com o ID em `whereArgs`. | Edite um item entre três; apenas ele deve mudar e a mudança deve persistir. |
| **R1-07** | Exclusão não funciona ou poderia remover outros itens. | `lib/repositories/material_repository.dart`, `excluir` | Excluir somente `WHERE id = ?`; chamar o método após confirmação da interface. | Cancelar preserva tudo; confirmar remove só o selecionado. |

Fontes: A, p. 1-2; C, p. 1-2; D, arquivos correspondentes em `lib/`.

A duplicidade aparece como desafio extra no primeiro enunciado, mas integra os **sete TODOs** do roteiro de resolução. Por isso está contemplada integralmente aqui. O nome normalizado também possui uma restrição `UNIQUE` no esquema original: a consulta antecipada ajuda a apresentar uma mensagem clara, enquanto o banco mantém sua própria proteção.

## Revisão 2: os cinco erros do roteiro

| ID | Sintoma observado | Onde consultar | Trecho incorreto no original | Correção e teste |
|---|---|---|---|---|
| **R2-01** | Documentos novos aparecem no começo. | `lib/repositories/impressao_repository.dart`, `listar` | `orderBy: 'id DESC'` | Usar `id ASC`: amostras na ordem Roteiro, Cartaz, Lista. Um novo cadastro vai para o final. |
| **R2-02** | Zero páginas ou zero cópias são aceitos. | `lib/providers/impressao_provider.dart`, `validar` | `paginas < 0 || copias < 0` | Rejeitar `<= 0`; aceitar somente inteiros **> 0** nos dois campos, no cadastro e na edição. |
| **R2-03** | O número de folhas de cada cartão está errado. | `lib/providers/impressao_provider.dart`, `folhasDoDocumento` | `paginas + copias` | Multiplicar: `paginas * copias`. Para 4 páginas e 3 cópias, esperar 12. |
| **R2-04** | Pendentes mostra documentos impressos. | `lib/providers/impressao_provider.dart`, `_mostrar` | Pendentes compara `impresso == 1`. | Pendentes usa `impresso == 0`; Impressos usa `== 1`; Todos aceita ambos. |
| **R2-05** | Alternar impressão modifica os outros documentos. | `lib/repositories/impressao_repository.dart`, `alternarImpressao` | `where: 'id <> ?'` | Usar `where: 'id = ?'`. Alterar Roteiro não pode modificar Cartaz nem Lista. |

Fontes: B, p. 1-3; C, p. 2-3; E, `listar`, `validar`, `folhasDoDocumento`, `_mostrar` e `alternarImpressao`.

`<>` significa **diferente** em SQL. Na busca de duplicidade da revisão 1, excluir o próprio ID com `id <> ?` faz sentido. Na alteração individual da revisão 2, o mesmo operador está errado. A responsabilidade do método determina a condição correta.

## Configuração: pontos adicionais, separados dos cinco erros

No ZIP da revisão 2, `main.dart` e `impressao_page.dart` importam `provider`, mas `pubspec.yaml` não declara esse pacote. O manifesto do projeto de estudo inclui a dependência. Como o app importa esse pacote diretamente, a dependência deve ser declarada diretamente. Ele pode já ser resolvido de forma transitiva por `device_preview`, mascarando a omissão; portanto, sua ausência no manifesto não demonstra, sozinha, que o projeto não compilaria. É um ajuste de configuração e não substitui a ordenação entre os cinco erros do roteiro.

O pacote `device_preview` já consta no manifesto original da revisão 2, porém seu `main.dart` não o configura. O enunciado B, p. 1, pede sua configuração e conferência em pelo menos dois tamanhos de celular. Consulte `lib/main.dart` neste projeto para o encaixe entre `DevicePreview` e `MaterialApp`.

Os dois ZIPs já trazem `web/sqlite3.wasm` e `web/sqflite_sw.js`. Não havia ausência desses arquivos nos materiais enviados. Eles continuam necessários para a versão web; o comando de preparação aparece no guia de consulta caso seja preciso gerá-los novamente.

## Resultado esperado com as amostras da impressão

| Ordem | Documento | Páginas por cópia | Cópias | Folhas | Impresso |
|---|---|---:|---:|---:|---|
| 1 | Roteiro do evento | 4 | 3 | 12 | Não |
| 2 | Cartaz da oficina | 2 | 5 | 10 | Não |
| 3 | Lista de presença | 1 | 2 | 2 | Sim |

O resumo global é **3 documentos e 24 folhas**. Ao escolher Pendentes, aparecem dois documentos, mas o resumo permanece global: **3 e 24**. Esse comportamento está explicitamente pedido em B, p. 2-3. Não altere o total para usar somente a lista filtrada.

Ao marcar Roteiro como impresso, os estados devem ficar `1, 0, 1` na ordem acima. Após recarregar a página, devem continuar assim. Ao desfazer a marcação de Roteiro, voltam a `0, 0, 1`.

## Padrões que merecem prioridade no estudo

1. **Um operador muda toda a regra.** Compare `<` com `<=`, `+` com `*`, `=` com `<>`, `ASC` com `DESC` e `0` com `1`.
2. **O valor de fronteira revela o erro.** Teste zero, um, mínimo menos um, mínimo exato e o caso zero/zero. Um caso comum com números positivos pode esconder uma validação errada.
3. **Cada camada tem uma responsabilidade.** A página coleta e apresenta; ViewModel/Provider coordena regras e estado; Repository executa as operações; Service abre e cria o banco; Model converte e deriva informações de domínio.
4. **Salvar e atualizar a tela são etapas distintas.** A escrita no SQLite precisa terminar, os dados devem ser consultados novamente e os ouvintes precisam ser notificados.
5. **Persistência deve ser conferida fora da lista atual.** Uma alteração visível pode estar somente em memória. Recarregar a página ajuda a distinguir isso de uma gravação real.
6. **Mutações individuais exigem um conjunto de comparação.** Tenha vários registros. Com um único item é mais difícil perceber que a condição SQL seleciona os registros errados.
7. **Listagem e resumo podem ter escopos diferentes.** O filtro modifica a lista apresentada; o total da impressão continua incluindo todos os documentos.
8. **Confirmação pertence à interação.** Cancelar uma exclusão ou restauração não deve chegar à operação destrutiva do repositório. A restauração usa transação para substituir o conjunto de amostras de forma consistente.

Essas prioridades são uma inferência baseada na repetição dos padrões nos materiais, não uma previsão do conteúdo exato da prova.

## Como explicar uma correção

Use quatro frases: **comportamento observado**, **local e causa**, **mudança**, **conferência realizada por você**. Exemplo para estudo:

> O botão de alternar impressão modificava outros documentos. Em `ImpressaoRepository.alternarImpressao`, a cláusula `id <> ?` selecionava todos os IDs diferentes do documento escolhido. Troquei a comparação por `id = ?` e mantive o parâmetro em `whereArgs`. Para conferir, comparo o estado de três documentos antes/depois, recarrego a página e verifico se só o escolhido mudou.

O último período descreve uma forma de verificar. Ao escrever sua própria entrega, registre apenas resultados que você de fato executou.

Próximos arquivos: [guia de consulta](02_guia_de_consulta.md), [laboratório com gabarito](03_laboratorio_de_erros.md) e [publicação pelo terminal](../github.md).
