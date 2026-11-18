# Laboratório de correção de erros

Os exercícios abaixo foram criados como **prática complementar**, a partir dos padrões dos materiais enviados. Eles não são novas questões publicadas pelo professor. Os trechos marcados como incorretos ficam apenas neste documento; o aplicativo entregue mantém suas implementações corretas.

Para cada exercício, responda antes de abrir o gabarito: **qual entrada revela o problema, qual linha causa o comportamento, qual mudança resolve e como verificar que os outros casos continuam corretos?**

Se quiser experimentar uma alteração, use uma cópia do projeto ou uma branch Git e reverta o trecho depois do teste. Não edite tudo ao mesmo tempo: uma correção por vez torna o efeito mais fácil de perceber.

## Exercícios

### E1. Nome aparentemente preenchido

**Trecho incorreto:**

```dart
if (valor == null || valor.isEmpty) return 'Preencha o campo.';
return null;
```

Entrada de investigação: `'   '`. O que `isEmpty` mede? Como atender à exigência de nome e categoria sem espaços isolados?

### E2. Zero vira um erro de quantidade

**Trecho incorreto para materiais:**

```dart
final quantidade = int.tryParse(texto.trim());
if (quantidade == null || quantidade <= 0) return 'Quantidade inválida.';
return null;
```

Compare as entradas `-1`, `0` e `1`. Essa mesma condição faria sentido no domínio da impressão?

### E3. Zero páginas é aceito

**Trecho incorreto para documentos:**

```dart
if (paginas == null || copias == null) return 'Informe inteiros.';
if (paginas < 0 || copias < 0) return 'Use valores maiores que zero.';
return null;
```

Investigue páginas/cópias `0/1`, `1/0`, `1/1` e `-1/1`. Compare a condição com a própria mensagem.

### E4. Estoque zero aparece como adequado

**Trecho incorreto:**

```dart
if (quantidade >= minimo) return 'Estoque adequado';
if (quantidade == 0) return 'Sem estoque';
return 'Estoque baixo';
```

Use quantidade `0`, mínimo `0`. Reordene a decisão e confira também quantidade igual ao mínimo e abaixo dele.

### E5. O material é duplicado de si mesmo

**Trecho incompleto para uma edição:**

```dart
final linhas = await db.query(
  'materiais',
  where: 'nome_normalizado = ?',
  whereArgs: [nome.trim().toLowerCase()],
);
return linhas.isNotEmpty;
```

Já existe Microfone com ID 4. Você está editando somente sua quantidade e mantém o nome. Por que a consulta acusa duplicidade? Como diferenciar o próprio material de outro registro?

### E6. A fila se comporta como uma pilha

**Trecho incorreto:**

```dart
return db.query('documentos', orderBy: 'id DESC');
```

Com IDs `1`, `2` e `3`, em que ordem a consulta retorna? Qual direção atende à chegada do mais antigo para o mais recente, considerando os IDs autoincrementados usados nessa atividade?

### E7. Soma no lugar de consumo

**Trecho incorreto:**

```dart
return paginas + copias;
```

O documento tem quatro páginas por cópia e serão feitas três cópias. Desenhe os três grupos de quatro folhas e calcule o total. Escolha outro par que também diferencie soma de multiplicação.

### E8. Pendentes e Impressos são iguais

**Trecho incorreto:**

```dart
if (filtro == 'Pendentes') return impresso == 1;
if (filtro == 'Impressos') return impresso == 1;
return true;
```

Use as amostras de estados `0, 0, 1`. Corrija somente a condição errada e explique o caso Todos.

### E9. O registro escolhido é o único que não muda

**Trecho incorreto:**

```dart
await db.update(
  'documentos',
  {'impresso': 1},
  where: 'id <> ?',
  whereArgs: [2],
);
```

Há documentos com IDs `1`, `2` e `3`. Quais linhas atendem à condição? Qual condição deve atingir apenas o ID 2? Por que `<>` era útil em E5, mas está errado aqui?

### E10. O resumo muda quando só o filtro muda

**Trecho incorreto para a regra da atividade:**

```dart
int get totalFolhas => documentosVisiveis.fold<int>(
  0,
  (soma, documento) => soma + folhasDoDocumento(documento),
);
```

Ao escolher Pendentes, o total cai de 24 para 22. O cálculo das folhas está correto; o que está errado no conjunto que ele percorre?

### E11. Sucesso antes de terminar a gravação

**Trecho incorreto:**

```dart
repository.inserir(material);
await carregar();
```

Pense em uma gravação que demora mais que a consulta seguinte. Qual resultado a lista pode mostrar? Como o tratamento de erro fica comprometido se a operação não for aguardada?

### E12. Erro de digitação vira quantidade zero

**Trecho incorreto:**

```dart
final quantidade = int.tryParse(texto.trim()) ?? 0;
if (quantidade < 0) return 'Não use negativos.';
return null;
```

Qual resultado a entrada `abc` produz? Por que substituir uma falha de conversão por zero esconde o problema em materiais?

### E13. Editar título desfaz a impressão

**Trecho incorreto para uma edição:**

```dart
await db.update(
  'documentos',
  {'nome': nome.trim(), 'paginas': paginas, 'copias': copias, 'impresso': 0},
  where: 'id = ?',
  whereArgs: [id],
);
```

Edite um documento que já está impresso e altere apenas o nome. Qual dado deve ser preservado? Em que momento inicializar `impresso` como zero é apropriado?

### E14. Cancelar exclui mesmo assim

**Trecho incorreto:**

```dart
final confirmou = await showDialog<bool>(context: context, builder: construirDialogo);
await repository.excluir(id);
```

Liste os resultados possíveis do diálogo: `true`, `false` e `null`. Qual deles autoriza a exclusão? O que você precisa conferir ao usar o estado da página depois do `await`?

## Gabarito comentado

### E1. Remover espaços externos antes de testar

```dart
if (valor == null || valor.trim().isEmpty) return 'Preencha o campo.';
return null;
```

`'   '` possui caracteres e não é uma string vazia. Após `trim()`, torna-se vazia. Confira também `null`, `''`, `'Cabo HDMI'` e categoria formada só por espaços. Relação: **R1-01**.

### E2. Materiais aceitam zero

```dart
if (quantidade == null || quantidade < 0) return 'Quantidade inválida.';
```

Rejeitar `< 0` permite `0`. Na impressão, a regra é outra: rejeitar `<= 0`. Um operador só é correto em relação à exigência do domínio. Relação: **R1-02**.

### E3. Documentos precisam de pelo menos uma página e uma cópia

```dart
if (paginas <= 0 || copias <= 0) return 'Use valores maiores que zero.';
```

Isso vem depois da verificação de nulos. `0/1` e `1/0` falham; `1/1` passa. Confira tanto cadastro quanto edição. Relação: **R2-02**.

### E4. Dar prioridade ao caso zero

```dart
if (quantidade == 0) return 'Sem estoque';
if (quantidade < minimo) return 'Estoque baixo';
return 'Estoque adequado';
```

Com valores válidos não negativos, o segundo caso só chega a ser avaliado para quantidade positiva. Quantidade igual ao mínimo fica adequada, exceto zero/zero, já resolvido antes. Relação: **R1-03**.

### E5. Ignorar somente o próprio ID

```dart
final linhas = await db.query(
  'materiais',
  where: ignorarId == null
      ? 'nome_normalizado = ?'
      : 'nome_normalizado = ? AND id <> ?',
  whereArgs: ignorarId == null
      ? [nome.trim().toLowerCase()]
      : [nome.trim().toLowerCase(), ignorarId],
  limit: 1,
);
return linhas.isNotEmpty;
```

No cadastro, a comparação considera todos. Na edição, o próprio registro sai da busca. Mantenha o próprio nome e depois tente usar o nome de outro item. Relação: **R1-04**.

### E6. Ordenar em sentido crescente

```dart
return db.query('documentos', orderBy: 'id ASC');
```

Retorna `1, 2, 3`. Nessa atividade, os IDs autoincrementados acompanham os cadastros. O enunciado não apresenta outro campo de data para usar como chave de chegada. Relação: **R2-01**.

### E7. Multiplicar páginas por cópias

```dart
return paginas * copias;
```

`4 * 3 = 12`; `2 * 5 = 10`. Um exemplo como `2/2` seria fraco para detectar esse erro, pois soma e produto dariam 4. Escolha dados que separem as hipóteses. Relação: **R2-03**.

### E8. Pendência corresponde a zero

```dart
if (filtro == 'Pendentes') return impresso == 0;
if (filtro == 'Impressos') return impresso == 1;
return true;
```

Pendentes exibe os dois registros `0`; Impressos, o registro `1`; Todos aceita cada registro. Relação: **R2-04**.

### E9. Igualdade para uma alteração individual

```dart
where: 'id = ?',
whereArgs: [2],
```

O trecho errado seleciona IDs 1 e 3. Em E5, a intenção era investigar **outros** materiais; aqui a intenção é modificar **o escolhido**. Teste também a operação inversa para desfazer a marcação. Relação: **R2-05**.

### E10. Somar a lista completa

```dart
int get totalFolhas => _documentos.fold<int>(
  0,
  (soma, documento) => soma + folhasDoDocumento(documento),
);
```

A coleção deve incluir todos os documentos. O filtro só controla a exibição. Depois de restaurar as amostras, espere 24 em Todos, Pendentes e Impressos. Isso é uma exigência de resumo no enunciado, não um sexto erro listado pelo roteiro.

### E11. Aguardar a gravação

```dart
await repository.inserir(material);
await carregar();
```

A consulta acontece depois que a inserção termina. O erro da gravação pode ser recebido pelo `try/catch` que aguarda essa cadeia. A atualização da interface precisa acompanhar a persistência, não correr à frente dela. Relação: fluxo de **R1-05**.

### E12. Tratar falha como falha

```dart
final quantidade = int.tryParse(texto.trim());
if (quantidade == null) return 'Informe um número inteiro.';
if (quantidade < 0) return 'Não use negativos.';
return null;
```

`abc` não pode se tornar silenciosamente um material sem estoque. Confira também decimal e vazio. Relação: **R1-02**.

### E13. Editar somente os campos do formulário

```dart
final dados = {'nome': nome.trim(), 'paginas': paginas, 'copias': copias};
await db.update('documentos', dados, where: 'id = ?', whereArgs: [id]);
```

Na inserção de um documento novo, inicializar `impresso: 0` faz sentido. Na edição, deixar a coluna fora do mapa mantém o estado existente. A alternância tem sua própria ação e regra. Esta é uma conferência complementar de regressão do CRUD.

### E14. Conferir a escolha antes de excluir

```dart
if (confirmou != true || !mounted) return;
await repository.excluir(id);
```

Só `true` prossegue. `false` e `null` encerram a ação sem excluir. `mounted` protege a continuação na página; na implementação completa, siga também o tratamento de erros e de carregamento. Relação: confirmação exigida na conferência de **R1-07** e na restauração de impressão.

## Conferência manual do conjunto

Este quadro é um roteiro para você preencher. As caixas em branco não declaram testes executados.

- [ ] Materiais: nome e categoria vazios ou com espaços são recusados.
- [ ] Materiais: zero é aceito; negativo, decimal, letras e vazio são recusados.
- [ ] Materiais: zero/zero significa Sem estoque; mínimo exato positivo significa adequado.
- [ ] Materiais: nome duplicado é bloqueado com variação de caixa e espaços externos.
- [ ] Materiais: editar mantendo o próprio nome funciona; usar o nome de outro não funciona.
- [ ] Materiais: cadastrar, editar e excluir afetam somente os registros esperados.
- [ ] Materiais: cancelar a exclusão preserva o registro.
- [ ] Impressão: amostras ficam na ordem Roteiro, Cartaz, Lista.
- [ ] Impressão: folhas individuais são 12, 10 e 2; total global é 24 em todos os filtros.
- [ ] Impressão: zero páginas e zero cópias são recusados no cadastro e na edição.
- [ ] Impressão: Pendentes mostra Roteiro e Cartaz; Impressos mostra Lista.
- [ ] Impressão: alternar Roteiro modifica somente ele; alternar novamente desfaz.
- [ ] Impressão: editar um documento impresso preserva o estado de impressão.
- [ ] Impressão: cancelar a restauração preserva os documentos; confirmar substitui as amostras da atividade.
- [ ] Persistência: recarregar a mesma origem preserva inserções, edições, exclusões e marcações.
- [ ] Interface: dois tamanhos de celular permitem acessar campos, ações e registros com rolagem.

Fontes dos padrões: `Revisao 1 - CENTRAL DE MATERIAIS.pdf`, p. 1-2; `REVISÃO 2.pdf`, p. 1-3; `Resolução das revisões.pdf`, p. 1-3. As variações E1-E14 são complementares e servem para treinar investigação, explicação e escolha de dados de teste.
