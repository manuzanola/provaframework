# Guia de consulta do código Flutter

Este guia acompanha as duas áreas do aplicativo: **Materiais** e **Impressão**. Para localizar uma implementação, use Ctrl+P para abrir o arquivo e Ctrl+F para procurar o método ou o identificador `R1-xx`/`R2-xx`. Os comentários do código explicam o papel de cada linha; este documento conecta as peças.

## Por onde começar

| Quero entender... | Abra... | Procure... |
|---|---|---|
| Como o Flutter inicia e as dependências são montadas | `lib/main.dart` | `main`, `runApp`, `DevicePreview`, `MaterialApp` |
| Onde o banco é aberto e as tabelas nascem | `lib/services/database_service.dart` | `database`, `OpenDatabaseOptions`, `onCreate`, `CREATE TABLE` |
| Como um material vira uma linha do SQLite | `lib/models/material_evento.dart` | `toMap`, `fromMap`, `nomeNormalizado` |
| Como classificar o estoque | `lib/models/material_evento.dart` | `situacao`, `R1-03` |
| Como validar nome, categoria e quantidades | `lib/utils/validadores.dart` | `textoObrigatorio`, `quantidade` |
| Como impedir nomes repetidos e fazer CRUD de materiais | `lib/repositories/material_repository.dart` | `existeNome`, `inserir`, `atualizar`, `excluir` |
| Como coordenar o cadastro de materiais | `lib/viewmodels/material_viewmodel.dart` | `salvar`, `carregar`, `notifyListeners` |
| Como o formulário e a confirmação de exclusão funcionam | `lib/pages/materiais_page.dart` | `Form`, `validator`, `TextEditingController`, `showDialog` |
| Como listar documentos por chegada e modificar um ID | `lib/repositories/impressao_repository.dart` | `listar`, `salvar`, `alternarImpressao`, `restaurarAmostras` |
| Como filtrar e calcular os totais | `lib/providers/impressao_provider.dart` | `documentosVisiveis`, `_mostrar`, `folhasDoDocumento`, `totalFolhas` |
| Como a interface acompanha Provider | `lib/pages/impressao_page.dart` | `context.watch`, `context.read` |
| Como preparar e publicar o repositório | `github.md` | `git init`, `git add`, `git commit`, `git push` |

## O caminho de uma operação

```text
Usuário preenche e toca em Salvar
  -> Page lê os controllers e apresenta validações
  -> ViewModel/Provider confere regras e coordena a operação
  -> Repository executa insert ou update
  -> DatabaseService fornece a conexão SQLite
  -> a gravação termina
  -> ViewModel/Provider consulta novamente os registros
  -> notifyListeners avisa a interface
  -> AnimatedBuilder/context.watch reconstrói os widgets interessados
```

O banco guarda os registros; o estado em memória guarda o que a tela está usando agora. `notifyListeners()` avisa que o estado mudou. Ele não grava no banco por conta própria. Consulte a explicação oficial sobre [ChangeNotifier e Provider](https://docs.flutter.dev/data-and-backend/state-mgmt/simple) para aprofundar essa relação.

## Dart necessário para ler este projeto

| Construção | O que significa no projeto | Erro comum para investigar |
|---|---|---|
| `String?`, `int?` | O valor pode ser nulo, como o ID antes de um cadastro ou uma conversão inválida. | Usar `!` sem antes garantir que há um valor. |
| `final` | A referência/variável só recebe atribuição uma vez. | Confundir `final List` com uma lista cujo conteúdo nunca pode mudar. |
| `const` | Instância constante quando todos os argumentos permitem isso. | Aplicar `const` a dados conhecidos apenas durante a execução. |
| `required` | O argumento nomeado é obrigatório na chamada. | Omitir categoria ou quantidade ao montar um modelo. |
| `=>` | Forma curta de uma função que retorna uma expressão. | Achar que executa depois: a execução ainda depende da chamada. |
| `get` | Expõe um valor calculado como propriedade, como `material.situacao`. | Armazenar uma informação derivada que pode ficar desatualizada. |
| `as int` | Conversão de tipo esperada ao ler um mapa do SQLite. | A coluna ter outro tipo ou o campo não existir. |
| `Map<String, Object?>` | Mapa com nomes de colunas e valores de diferentes tipos. | Escrever a chave diferente do nome real da coluna. |
| `List<T>` | Sequência de itens do tipo `T`. | Substituir a lista principal pelo resultado do filtro e perder o conjunto completo. |
| `map(...).toList()` | Transforma cada elemento e materializa uma nova lista. | Confundir com busca ou alteração persistida. |
| `where(...)` | Produz os elementos que atendem à condição. | Inverter a comparação do filtro. |
| `fold<int>(0, ...)` | Acumula um inteiro, começando por zero. | Somar somente a lista visível quando o resumo precisa ser global. |
| `...?`, `...` | Espalha elementos de uma coleção; `...?` também admite coleção nula. | Confundir com o operador que trata um valor nulo. |
| `??` e `??=` | Usa alternativa quando nulo; atribui alternativa somente se ainda for nulo. | Criar uma conexão nova em cada leitura do banco. |
| `Future<T>` | Resultado que ficará disponível de forma assíncrona. | Acessar o resultado antes de aguardar. |
| `async` e `await` | Permitem esperar a operação sem bloquear a interface. | Esquecer `await` antes de recarregar os dados ou mostrar sucesso. |
| `try/catch/finally` | Executa, trata a falha e sempre conclui a limpeza do estado. | Deixar o indicador de carregamento ativo depois de um erro. |

O projeto usa `...` nos mapas/listas para compor dados. `...?` é mostrado na tabela apenas como consulta de sintaxe relacionada; não é uma exigência dos roteiros.

## Validação: o detalhe mais importante é a regra do domínio

**Materiais aceitam zero** para quantidade disponível e quantidade mínima. **Documentos recusam zero** tanto em páginas quanto em cópias. Não copie uma validação de um contexto para o outro sem rever o limite.

| Entrada | Materiais: quantidade ou mínimo | Impressão: páginas ou cópias |
|---|---|---|
| `null`, vazio ou espaços | Recusar | Recusar |
| `abc` | Recusar | Recusar |
| `1.5` ou `1,5` | Recusar | Recusar |
| `-1` | Recusar | Recusar |
| `0` | Aceitar | Recusar |
| `1` | Aceitar | Aceitar |
| `' 2 '` | Aceitar após remover espaços externos | Aceitar após remover espaços externos |

`trim()` retira espaços do começo e do fim; não remove espaços entre palavras. `int.tryParse()` devolve `null` se o texto não representar um inteiro aceito pelo parser. Use essa falha para apresentar uma mensagem. Evite `int.tryParse(texto) ?? 0`: isso poderia transformar erro de digitação em uma quantidade válida de materiais.

Para nome e categoria, o valor precisa continuar com algum conteúdo depois de `trim()`. Ao salvar, o texto é limpo para não persistir espaços externos desnecessários. Categoria também é obrigatória, embora a tabela resumida da resolução destaque o nome.

Fontes: `Revisao 1 - CENTRAL DE MATERIAIS.pdf`, p. 1; `REVISÃO 2.pdf`, p. 1-2.

## Situação do estoque: a ordem dos ifs importa

| Quantidade | Mínimo | Resultado |
|---:|---:|---|
| 0 | 0 | Sem estoque |
| 0 | 3 | Sem estoque |
| 1 | 3 | Estoque baixo |
| 3 | 3 | Estoque adequado |
| 4 | 3 | Estoque adequado |
| 1 | 0 | Estoque adequado |

O teste de zero vem antes do teste de quantidade maior ou igual ao mínimo. Caso contrário, `0 >= 0` classificaria o material como adequado. Essa exceção é explícita no primeiro enunciado, p. 1.

## Nomes duplicados: comparação e edição

O modelo produz `nomeNormalizado` com `trim().toLowerCase()`. A consulta `existeNome` deve usar a mesma transformação. Assim, cadastrar `' Microfone '` conflita com `microfone`.

Na edição, `ignorarId` representa o material atual. A consulta procura outro material com o mesmo nome e `id <> ?`. Isso permite manter o próprio nome, mas impede usar o de um vizinho. Compare com cuidado:

```sql
-- Busca de duplicidade na edição: procurar outro registro de mesmo nome.
SELECT id FROM materiais WHERE nome_normalizado = ? AND id <> ?;

-- Alteração de um registro: selecionar exatamente o ID escolhido.
UPDATE materiais SET quantidade = ? WHERE id = ?;
```

Esses SQLs mostram a ideia; as chamadas Dart do repositório usam mapas e parâmetros. A normalização não promete remover acentos nem espaços internos. `Cabo HDMI` e `Cabo  HDMI` não são definidos como iguais pelo enunciado.

## SQLite e CRUD

| Operação | Chamada típica | Cuidados |
|---|---|---|
| Criar tabela | `execute('CREATE TABLE ...')` | O nome e os tipos das colunas precisam combinar com os mapas. |
| Inserir | `insert('materiais', material.toMap())` | Um novo ID é gerado pelo SQLite; não invente um ID a partir do tamanho da lista. |
| Consultar | `query('documentos', orderBy: 'id ASC')` | A ordem precisa ser pedida explicitamente. |
| Atualizar | `update(..., where: 'id = ?', whereArgs: [id])` | O `WHERE` limita a alteração; dados do usuário vão em parâmetros. |
| Excluir | `delete(..., where: 'id = ?', whereArgs: [id])` | Sem condição, a operação poderia atingir a tabela inteira. |
| Transação | `transaction((txn) async { ... })` | Use o executor `txn` dentro da transação para agrupar a operação. |

`toMap()` prepara os campos para a escrita. `fromMap()` monta o objeto de domínio a partir da linha lida. A impressão mantém o formato de mapa do projeto original para facilitar a comparação com o exercício.

No campo `impresso`, `0` representa pendente e `1` representa impresso. Ao editar nome, páginas ou cópias, o repositório preserva o status existente. O botão de alternar é responsável pela troca `0 -> 1` ou `1 -> 0`.

A [receita oficial de persistência SQLite](https://docs.flutter.dev/cookbook/persistence/sqlite) explica as operações básicas. Seu exemplo usa o plugin `sqflite` para plataformas nativas suportadas; este projeto utiliza a implementação web correspondente para executar no Chrome, como nos materiais do professor.

## Filtros, cálculo e totais da impressão

`_documentos` mantém o conjunto completo. `documentosVisiveis` deriva outra lista para a tela usando `_mostrar`. Alterar o filtro não apaga registros e não deve substituir o conjunto original.

O cálculo de uma linha é `paginas * copias`, considerando apenas a frente da folha. O total usa todos os documentos. Com as amostras restauradas:

| Filtro | Documentos na lista | Resumo global |
|---|---|---|
| Todos | Roteiro, Cartaz e Lista | 3 documentos / 24 folhas |
| Pendentes | Roteiro e Cartaz | 3 documentos / 24 folhas |
| Impressos | Lista | 3 documentos / 24 folhas |

Não conclua que o resumo está errado só porque a quantidade de cartões visíveis mudou. O enunciado pede justamente os dois escopos diferentes. Fonte: `REVISÃO 2.pdf`, p. 2-3.

## Estado e ciclo de vida da interface

`StatefulWidget` permite guardar dados da interação, como o ID em edição e os controllers dos campos. `setState` informa que o estado local mudou e solicita uma reconstrução. Alterações compartilhadas nos registros são comunicadas por `ChangeNotifier`.

Na impressão, `context.watch<ImpressaoProvider>()` acompanha mudanças para construir a tela. `context.read<ImpressaoProvider>()` acessa a instância para executar uma ação sem criar uma assinatura naquela chamada. Na área de materiais, `AnimatedBuilder` ouve a ViewModel. São duas formas de conectar a notificação à UI, preservadas para estudar os formatos das revisões.

`TextEditingController` lê e preenche texto. Ao entrar em edição, recebe os dados do registro. Ao cancelar ou concluir, os campos e o ID em edição são limpos. `dispose()` libera recursos quando o objeto deixa de ser usado.

Após `await`, a página pode ter saído da árvore. `mounted` protege o uso de `context` e `setState` nessas continuações. O indicador de carregamento e a desativação de botões também evitam operações concorrentes provocadas por cliques repetidos.

## Confirmações e restauração

`showDialog<bool>` devolve uma escolha. Só o resultado `true` deve levar à exclusão ou à restauração; cancelar, fechar ou voltar preserva os registros.

Restaurar amostras substitui os documentos atuais da atividade pelos exemplos. Por isso há confirmação. A transação agrupa exclusão e reinserção: se uma etapa falha, a operação pode ser revertida em conjunto, evitando uma restauração parcial. A rotina de impressão atua em `documentos`; não deve apagar os materiais da outra aba.

## Executar e investigar problemas

Na raiz do projeto, onde está `pubspec.yaml`, execute um comando por vez:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --web-port=8080
```

Os comandos de análise e testes são meios de conferir o projeto; consulte o relatório de validação entregue para saber o que foi efetivamente executado nesta versão. Para o preparo web, confira se existem `web/sqlite3.wasm` e `web/sqflite_sw.js`. Se precisar gerá-los novamente, use:

```powershell
dart run sqflite_common_ffi_web:setup
dart compile js -O2 --no-source-maps -o web/sqflite_sw.js tool/sqlite_worker.dart
```

O segundo comando recompila o worker com as versões fixadas no `pubspec.lock` deste projeto. O setup antigo resolve dependências separadamente e pode misturar SQLite 3.x com WASM 2.x, produzindo `unsupported result null`. Esse cuidado de ambiente é complementar e não integra os cinco erros do roteiro. Os arquivos compatíveis já acompanham a entrega.

O SQLite web é persistido no armazenamento do navegador para aquela origem. Para conferir persistência, recarregue usando o mesmo navegador, perfil, host e porta. Trocar `localhost` por `127.0.0.1`, mudar a porta, usar uma janela privada ou limpar os dados do site pode resultar em outro armazenamento ou remover os dados. A existência de amostras novamente em uma origem diferente não prova que a gravação anterior falhou.

| Sintoma | Primeira investigação |
|---|---|
| `flutter` não é reconhecido | Verificar a instalação e o PATH; abrir um novo terminal após configurar. |
| Pacote `provider` não encontrado | Conferir a declaração em `pubspec.yaml` e executar `flutter pub get`. |
| Banco não abre no Chrome | Ler o erro, conferir os dois arquivos SQLite web e a origem usada. |
| Dados aparecem antes de recarregar, mas somem depois | Conferir `await`, nome do banco, gravação e armazenamento do navegador. |
| Tela não reflete o que foi salvo | Conferir recarga da lista e notificação, além da escrita no banco. |
| Total individual errado e geral correto | Comparar os dois cálculos e a coleção usada em cada um. |
| Outro registro muda no lugar do escolhido | Ler `WHERE`, `whereArgs` e o ID enviado pela página. |
| Campos ou ações são cortados em celular | Testar rolagem, `Wrap`, largura disponível e DevicePreview. |

## Roteiro de estudo sugerido

1. Leia `01_mapa_das_revisoes.md` e anote os operadores envolvidos.
2. Percorra validadores, modelo e repositório de materiais; explique cada caso de fronteira sem executar.
3. Percorra repositório e provider de impressão; preveja os resultados das três amostras.
4. Execute o aplicativo e confronte sua previsão com os resultados.
5. Complete o laboratório sem consultar o gabarito; depois explique cada correção em palavras.
6. Faça a conferência manual de persistência e das confirmações, registrando os resultados que você observar.

Os exercícios novos do laboratório ampliam a prática; os itens documentados pelo professor estão identificados no mapa para manter essa distinção.
