# Como subir este projeto ao GitHub pelo terminal do VS Code

Os comandos abaixo são para o terminal **PowerShell** do VS Code. Execute um por vez e leia o resultado antes de continuar. Este arquivo orienta a publicação; nenhum repositório remoto foi criado nem enviado automaticamente.

## 1. Abrir a pasta certa

Extraia o ZIP e, no VS Code, escolha **Arquivo > Abrir Pasta**. Abra a pasta `framework_estudo`, que contém `pubspec.yaml`, `lib`, `web`, `docs` e este arquivo. Depois escolha **Terminal > Novo Terminal**.

Confira a localização e as ferramentas:

```powershell
Get-Location
Test-Path .\pubspec.yaml
git --version
flutter --version
```

`Test-Path` deve retornar `True`. Se precisar navegar, use o caminho da sua cópia entre aspas:

```powershell
Set-Location -LiteralPath 'C:\caminho\da\sua\copia\framework_estudo'
```

Se `git` ou `flutter` não forem reconhecidos, ajuste a instalação/PATH e abra um novo terminal. Git e Flutter são ferramentas separadas.

Antes de iniciar, confira se a pasta já pertence a outro repositório:

```powershell
git rev-parse --show-toplevel
```

Se aparecer `not a git repository`, é o esperado para uma cópia extraída sem histórico. Se retornar uma pasta acima do projeto, mova/extraia sua cópia para um local fora daquele repositório e reabra-a. Isso evita adicionar arquivos pessoais da pasta superior. Se retornar exatamente a raiz deste projeto, ele já está inicializado: mantenha o histórico e confira `git status` e `git remote -v` antes de continuar.

## 2. Conferir a cópia antes do primeiro commit

Na raiz:

```powershell
flutter pub get
flutter analyze
flutter test
```

Para experimentar o app:

```powershell
flutter run -d chrome --web-port=8080
```

Encerre a execução com `q` no terminal antes de usar esse mesmo terminal para outros comandos.

O `.gitignore` do projeto evita incluir caches e arquivos de build. Para um aplicativo Flutter como este, mantenha **`pubspec.yaml` e `pubspec.lock`** no repositório: o primeiro declara dependências, e o segundo registra as versões resolvidas. Inclua `lib`, `test`, `web`, `tool`, `docs`, os guias e os arquivos de configuração da estrutura entregue. `web/sqlite3.wasm` e `web/sqflite_sw.js` fazem parte da preparação SQLite web e devem acompanhar o código.

Não adicione `.dart_tool/`, `build/`, banco pessoal de execução, caminhos locais de SDK, credenciais ou o ZIP da entrega. O código e a configuração necessários para recriar a aplicação são a referência principal.

## 3. Inicializar o repositório local

Se a pasta ainda não é um repositório:

```powershell
git init
git branch -M main
```

Agora configure sua identificação **somente neste repositório**, substituindo os exemplos:

```powershell
git config --local user.name "Seu Nome"
git config --local user.email "seu-email-de-commits@example.com"
git config --local --get user.name
git config --local --get user.email
```

O e-mail fica associado aos commits. Você pode usar o endereço `noreply` disponibilizado nas configurações da sua conta GitHub, se preferir. Não copie o endereço de outra pessoa.

Prepare e revise os arquivos:

```powershell
git status
git add .
git status --short
git diff --cached --stat
```

Leia a lista e confira se só contém o projeto. Para tirar um arquivo da preparação sem apagá-lo da pasta, depois que já existir um commit, use `git restore --staged -- caminho/do/arquivo`. Antes do primeiro commit, `git rm --cached -- caminho/do/arquivo` também remove somente do índice; confira o caminho antes de executar.

Crie o primeiro commit:

```powershell
git commit -m "Adiciona projeto de estudo Flutter das revisoes"
git log -1 --oneline
```

`commit` registra uma versão **local**. Ainda falta criar/conectar o destino e fazer `push`. Esse fluxo segue o procedimento de [adicionar código local ao GitHub](https://docs.github.com/pt/migrations/importing-source-code/using-the-command-line-to-import-source-code/adding-locally-hosted-code-to-github).

## 4. Criar o repositório remoto vazio

No GitHub, use **New repository** e escolha um nome, por exemplo `framework-estudo`. Escolha a visibilidade apropriada. Para este primeiro envio de um projeto que já possui arquivos locais, crie o repositório **vazio**, sem inicializar README, `.gitignore` ou licença na interface. Esses arquivos iniciais criariam um histórico remoto separado.

Depois de criar, copie a URL HTTPS, no formato:

```text
https://github.com/SEU-USUARIO/framework-estudo.git
```

Substitua `SEU-USUARIO` e o nome pelo destino real. A criação pela interface é só o preparo do destino; os arquivos serão enviados pelos comandos seguintes no terminal do VS Code.

## 5. Conectar o destino e enviar

```powershell
git remote add origin https://github.com/SEU-USUARIO/framework-estudo.git
git remote -v
```

Confira a URL exibida. `origin` é apenas o apelido local dado a esse endereço. Só após confirmar que o destino está correto, envie:

```powershell
git push -u origin main
```

No primeiro envio HTTPS, o Git/Git Credential Manager pode abrir o navegador para autenticação. Conclua o acesso na sua própria conta. Não coloque senha ou token neste arquivo, em comandos salvos, na URL do remoto ou dentro do código.

`-u` associa a branch local à remota. Depois disso, os próximos envios da mesma branch podem usar apenas `git push`. Veja a documentação de [remotos](https://docs.github.com/pt/get-started/git-basics/managing-remote-repositories) e de [envio de commits](https://docs.github.com/pt/get-started/using-git/pushing-commits-to-a-remote-repository).

Após o sucesso:

```powershell
git status
git branch -vv
```

Abra a página do repositório e confira `lib`, `web`, `docs`, `pubspec.yaml`, `pubspec.lock` e `github.md`. Essa conferência confirma o conteúdo remoto; um commit local sozinho não confirma o envio.

## Alternativa: criar e enviar com GitHub CLI

Esta alternativa é opcional e substitui as etapas 4 e 5. Use-a se `gh` já estiver instalado e você quiser criar o destino também pelo terminal. Comece depois do commit local e antes de adicionar `origin` manualmente:

```powershell
gh --version
gh auth login --web --git-protocol https
gh auth status
gh repo create framework-estudo --private --source=. --remote=origin --push
```

O último comando **cria um repositório privado e publica os commits**. Confira nome e conta antes de executar. Se o professor precisar acessar um repositório privado, você terá de fornecer acesso a ele conforme a orientação da atividade; se a exigência for público, escolha conscientemente a visibilidade correspondente. Os parâmetros estão no [manual oficial de `gh repo create`](https://cli.github.com/manual/gh_repo_create).

Não use essa alternativa se já criou o destino e configurou `origin`: prossiga pelo fluxo de envio para aquele repositório existente.

## 6. Enviar alterações depois de estudar ou corrigir

Depois de editar e conferir:

```powershell
git status
git diff
flutter analyze
flutter test
git add .
git diff --cached --stat
git commit -m "Ajusta validacao de quantidades"
git push
```

Escreva uma mensagem que descreva a mudança feita. `git diff` mostra alterações ainda não preparadas; `git diff --cached` mostra o que será incluído no próximo commit.

Se você trabalha no mesmo projeto em mais de um computador, busque mudanças remotas antes de começar uma nova alteração:

```powershell
git status
git pull --ff-only
```

Faça isso com o trabalho local organizado. Se o Git avisar que não consegue avançar sem reconciliar históricos, leia a situação antes de continuar.

## 7. Erros comuns

| Mensagem ou situação | Como investigar e seguir |
|---|---|
| `not a git repository` | Confira `Get-Location`; entre na raiz correta. Se ainda não inicializou a cópia, execute a etapa 3. |
| `remote origin already exists` | Execute `git remote -v`. Se a URL estiver correta, pule o `remote add`. Se estiver errada, use `git remote set-url origin URL-CORRETA`. |
| `src refspec main does not match any` | Confira se existe commit com `git log -1` e qual branch está ativa com `git branch --show-current`. |
| `nothing to commit` | Execute `git status`; talvez os arquivos já estejam commitados ou você esteja na pasta errada. O envio ainda pode estar pendente. |
| `Repository not found` ou falha de permissão | Confira conta autenticada, URL e acesso ao destino; não tente contornar com credenciais de outra pessoa. |
| `non-fast-forward` | Há commits remotos que sua cópia não contém. Preserve os dois históricos e integre as mudanças antes de enviar. Veja abaixo. |
| `fatal: refusing to merge unrelated histories` | O remoto provavelmente foi inicializado separadamente. Para um iniciante, clone o remoto em outra pasta e copie apenas os arquivos do projeto para ela, preservando `.git` do clone. Depois revise, faça commit e envie. |

Para investigar uma rejeição `non-fast-forward`:

```powershell
git status
git fetch origin
git log --oneline --graph --decorate --all -12
```

Se a branch remota e a local compartilham o mesmo histórico, e seu trabalho está commitado, integre as mudanças:

```powershell
git pull --no-rebase origin main
```

Se houver conflitos, o VS Code marcará os arquivos. Revise os dois lados, deixe o conteúdo final correto, remova os marcadores de conflito e finalize:

```powershell
git add .
git commit -m "Integra alteracoes remotas"
git push
```

O commit de integração só será necessário se o Git deixar uma mesclagem pendente; se o `pull` já concluir, faça o `push`. Não use `--force` como solução para essa rejeição. O GitHub documenta a preservação e integração das mudanças em [erros non-fast-forward](https://docs.github.com/pt/get-started/using-git/dealing-with-non-fast-forward-errors).

## Consulta rápida dos comandos

| Comando | Função |
|---|---|
| `git status` | Mostra o estado atual dos arquivos e da branch. |
| `git add .` | Prepara as alterações do diretório para o próximo commit. |
| `git commit -m "mensagem"` | Cria uma versão local com os arquivos preparados. |
| `git remote -v` | Mostra os endereços dos repositórios remotos. |
| `git push` | Envia os commits locais ao destino configurado. |
| `git fetch origin` | Busca referências do remoto sem mesclar os arquivos automaticamente. |
| `git pull` | Busca e integra mudanças do remoto conforme a estratégia escolhida. |
| `git log --oneline -5` | Mostra os cinco commits mais recentes. |

Quando for entregar a atividade, confira se o link abre para a pessoa que vai avaliar e registre somente os testes que você realizou. Este guia não publica nem altera permissões por você.
