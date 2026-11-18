# Frameworks: projeto de estudo das revisões

Aplicativo Flutter para estudar **Central de Materiais** e **Fila de Impressão**, com as implementações resolvidas, comentários em português em cada linha dos fontes Dart autorais e um laboratório de investigação de erros. O alvo de execução é **Chrome**, como nos materiais do professor.

## Comece aqui

1. Leia [o mapa das revisões](docs/01_mapa_das_revisoes.md) para conhecer os sete TODOs e os cinco erros.
2. Abra [o guia de consulta](docs/02_guia_de_consulta.md) e encontre a funcionalidade desejada.
3. No VS Code, use **Ctrl+Shift+F** para procurar `R1-01` até `R1-07` ou `R2-01` até `R2-05`.
4. Execute o app e reproduza os comportamentos do roteiro.
5. Resolva [os exercícios complementares](docs/03_laboratorio_de_erros.md) antes de abrir o gabarito.
6. Consulte [REVISAO.md](REVISAO.md) para os resultados das verificações e [github.md](github.md) para publicar sua própria cópia pelo terminal.

Este projeto é um material de estudo elaborado a partir dos arquivos enviados. Os padrões indicam prioridades de preparação; não estabelecem qual será o conteúdo da prova.

## Executar pelo terminal do VS Code

Extraia o ZIP e abra **a pasta que contém este `pubspec.yaml`**, chamada `framework_estudo`. Escolha **Terminal > Novo Terminal**. Com Flutter instalado e disponível no PATH, execute um comando por vez:

```powershell
flutter --version
flutter pub get
flutter run -d chrome --web-port=8080
```

Mantenha o terminal aberto. `r` solicita hot reload, `R` solicita hot restart e `q` encerra a execução quando esses comandos estiverem disponíveis na sessão Flutter. Alterações em dependências ou no bootstrap podem exigir encerrar e executar novamente.

O SDK encontrado nesta máquina está em `C:\Users\gabri\sdk\flutter`. Se `flutter` não for reconhecido, você pode invocá-lo diretamente no PowerShell:

```powershell
& 'C:\Users\gabri\sdk\flutter\bin\flutter.bat' pub get
& 'C:\Users\gabri\sdk\flutter\bin\flutter.bat' run -d chrome --web-port=8080
```

Em outra máquina, substitua o caminho pela instalação local. Foi validado com **Flutter 3.47.9 stable e Dart 3.13.7**, no Windows, em 17/11/2026. Os pacotes SQLite e DevicePreview foram mantidos nas versões da família usada nos projetos enviados, com `provider` declarado explicitamente. O `pubspec.lock` registra a resolução validada; as versões não foram escolhidas por serem as mais recentes.

### SQLite no navegador

A pasta `web` já contém `sqlite3.wasm` e `sqflite_sw.js`, gerados a partir do pacote e das dependências fixadas neste projeto. Não é preciso gerá-los novamente na primeira execução. Se algum estiver faltando ou se você alterar a versão do driver, execute:

```powershell
dart run sqflite_common_ffi_web:setup
dart compile js -O2 --no-source-maps -o web/sqflite_sw.js tool/sqlite_worker.dart
```

**Execute os dois comandos, nessa ordem, apenas se precisar regenerar os arquivos.** O setup antigo resolve dependências em uma pasta separada e hoje pode gerar um worker SQLite 3.x para um WASM 2.x. O segundo comando recompila o ponto de entrada do pacote com o `pubspec.lock` do projeto e evita essa incompatibilidade. `tool/sqlite_worker.dart` é um adaptador mínimo para essa geração, não uma regra da atividade. Os arquivos compatíveis já acompanham o ZIP.

As amostras são inseridas **somente na criação inicial do banco**. Recarregar a página não apaga alterações. O banco deste estudo tem nome próprio (`framework_estudo_v1.db`) e não substitui os bancos dos projetos originais.

Use o mesmo endereço e porta para verificar persistência: `localhost:8080`, `127.0.0.1:8080` e `localhost:8081` são origens distintas. O navegador armazena o SQLite em IndexedDB; limpar os dados do site ou usar outra sessão/perfil pode eliminar ou separar os registros. No `flutter run`, confira se continua usando a mesma sessão Chrome aberta pelo Flutter durante o teste de recarga.

### O que experimentar

**Materiais:** cadastrar nome/categoria e quantidades inteiras não negativas; editar; cancelar ou confirmar exclusão; testar duplicidade com `Microfone` e ` microfone `; verificar estoque zero, abaixo do mínimo e igual ao mínimo. `0/0` precisa continuar **Sem estoque**.

**Impressão:** selecionar Todos, Pendentes e Impressos; cadastrar e editar documentos; alternar impressão; excluir com confirmação; restaurar amostras com confirmação. As três amostras têm **12, 10 e 2 folhas**, totalizam **3 documentos e 24 folhas**, e o resumo é global mesmo com filtro ativo. Restaurar amostras substitui somente os documentos, preservando os materiais.

### DevicePreview

Em execução de desenvolvimento (`flutter run`), a barra do DevicePreview permite escolher dispositivos, orientação e dimensões. Compare pelo menos dois celulares. Os testes de widgets também verificam as páginas em **360 × 800** e **390 × 844** pixels lógicos. O DevicePreview é uma simulação da interface no navegador; não significa que o projeto tenha sido executado em um aparelho Android/iPhone. No build release ele fica desativado.

## Estrutura da entrega

```text
framework_estudo/
  lib/
    main.dart                         # inicialização, dependências, abas e DevicePreview
    models/material_evento.dart       # toMap/fromMap e situação do estoque
    utils/validadores.dart             # texto obrigatório e inteiro >= 0
    services/
      database_service.dart           # esquema, abertura compartilhada e amostras
      database_factory.dart           # seleção condicional do driver
      database_factory_web.dart       # fábrica SQLite para Chrome
      database_factory_stub.dart      # orientação fora da web; testes injetam FFI
    repositories/
      material_repository.dart        # CRUD e nome duplicado, TODOs R1-04 a R1-07
      impressao_repository.dart       # chegada, CRUD, alternância e restauração
    viewmodels/material_viewmodel.dart # coordenação da revisão 1
    providers/impressao_provider.dart # coordenação, filtros e cálculo da revisão 2
    pages/
      materiais_page.dart             # Form, controllers, AnimatedBuilder e diálogos
      impressao_page.dart             # context.watch/read, formulários e diálogos
  tool/sqlite_worker.dart              # geração do worker com as versões fixadas
  test/                               # testes de regras, banco real e interface
  web/                                # estrutura de execução Flutter Web, WASM e worker
  docs/                               # mapa, consulta, laboratório, verificações e imagens
  pubspec.yaml                        # dependências comentadas
  pubspec.lock                        # versões resolvidas
  analysis_options.yaml               # regras da análise estática
  .gitignore                          # exclusão de caches e dados locais
  .metadata                           # metadados do projeto Flutter
  README.md                           # ponto de entrada do estudo
  REVISAO.md                          # resultados e explicação de validação
  github.md                           # passo a passo de publicação
```

A estrutura web está completa. Não há projetos nativos Android/iOS nesta entrega porque as duas revisões utilizam SQLite Web no Chrome. Os testes nativos usam SQLite FFI apenas para verificar as regras e a persistência, sem declarar suporte de execução do aplicativo nesses sistemas.

Os comentários de `lib` e `test` são deliberadamente extensos para consulta linha a linha. As diretivas `dart format off/on` preservam esse formato didático nas versões do formatter que as reconhecem. Os arquivos **gerados por terceiros**, especialmente `web/sqflite_sw.js`, `web/sqlite3.wasm` e `pubspec.lock`, não foram reescritos nem comentados manualmente. A explicação de seu papel está neste README e no guia.

## Verificar sua cópia

```powershell
flutter analyze
flutter test
flutter build web --no-wasm-dry-run --no-web-resources-cdn
```

Os testes usam SQLite real: em memória para isolamento e em arquivo temporário para fechar/reabrir e comprovar persistência. O aplicativo continua usando SQLite persistente na web. A opção `--no-web-resources-cdn` inclui os recursos gráficos locais no build, útil para testar sem depender do CDN do renderizador. Não execute o `index.html` por duplo clique; use `flutter run` ou um servidor HTTP para o build.

Para ler os resultados efetivamente executados, veja [o relatório de validação](docs/04_validacao.md). O roteiro de conferência manual está no fim do laboratório.

## Materiais analisados

- `Revisao 1 - CENTRAL DE MATERIAIS.pdf`, 4 páginas.
- `revisao 1.zip`, especialmente os sete TODOs de `lib`.
- `REVISÃO 2.pdf`, 3 páginas.
- `revisao2.zip`, especialmente Provider e Repository.
- `Resolução das revisões.pdf`, 3 páginas, usado para cruzar os resultados esperados.

Nenhum código dos materiais foi executado como instrução do sistema. Seus enunciados foram usados como referência pedagógica. Os ZIPs originais, caches de build e dados pessoais não integram esta entrega. Trechos incorretos aparecem identificados no laboratório e na análise; os fontes executáveis do app contêm as versões corrigidas.
