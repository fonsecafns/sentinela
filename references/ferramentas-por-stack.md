# Ferramentas por stack

Este arquivo lista qual ferramenta usar em cada ecossistema durante a Fase 1 (varredura automatizada) da auditoria. Sempre peça permissão antes de instalar qualquer uma delas, explicando em linguagem simples o que ela faz (veja os exemplos no fim deste arquivo).

## Auditoria de dependências (CVEs)

### Node.js (npm, yarn, pnpm)
Comando: `npm audit --json` (troque por `pnpm audit` ou `yarn audit` conforme o gerenciador usado no projeto)
Alternativa mais ampla: `npx osv-scanner --lockfile=package-lock.json`
O que verificar em cada resultado: pacote afetado, versão instalada, versão corrigida disponível, e o CVE ou GHSA associado.

### Python
Comando: `pip-audit -r requirements.txt` (ou aponte para pyproject.toml/poetry.lock conforme o projeto)
Instalação, se faltar: `pip install pip-audit --break-system-packages`
Alternativa: `safety check`

### Go
Comando: `govulncheck ./...`
Instalação, se faltar: `go install golang.org/x/vuln/cmd/govulncheck@latest`

### Ruby
Comando: `bundler-audit check --update`
Instalação, se faltar: `gem install bundler-audit`

### Rust
Comando: `cargo audit`
Instalação, se faltar: `cargo install cargo-audit`

### PHP
Comando: `composer audit`

### Java ou Kotlin (Maven, Gradle)
Maven: `mvn org.owasp:dependency-check-maven:check` (baixa e usa o plugin OWASP Dependency-Check)
Gradle: adicionar o plugin `org.owasp.dependencycheck` e rodar `./gradlew dependencyCheckAnalyze`
Alternativa mais simples de instalar: `osv-scanner -r .` já lê pom.xml e arquivos de lock do Gradle sem precisar desses plugins.

### .NET ou C# (NuGet)
Comando: `dotnet list package --vulnerable --include-transitive`
Não precisa instalar nada além do próprio SDK do .NET, que já vem com esse comando embutido.

### Monorepo ou múltiplas linguagens
`osv-scanner` cobre vários ecossistemas de uma vez a partir dos lockfiles presentes: `osv-scanner -r .`
Use como complemento ou fallback quando o projeto mistura tecnologias diferentes.

## Detecção de segredos (incluindo histórico do git)

### gitleaks (primeira opção recomendada)
Comando: `gitleaks detect --source . --report-format json --report-path gitleaks-report.json`
Varre o histórico completo de commits, não só o estado atual dos arquivos.

### trufflehog (alternativa)
Comando: `trufflehog git file://. --json`

## Imagens Docker e containers

Se o projeto tem um Dockerfile, uma imagem publicada ou um docker-compose.yml, a auditoria de dependências (seção acima) não é suficiente: ela olha só as bibliotecas do código, não as camadas da imagem base (o sistema operacional e os pacotes que vêm dentro da imagem, tipo `python:3.11-slim` ou `node:22-alpine`).

### Trivy
Comando pra escanear a imagem construída: `trivy image <nome-da-imagem>:<tag>`
Comando pra escanear o Dockerfile e o docker-compose.yml em busca de configuração insegura (sem precisar buildar nada): `trivy config .`
Instalação, se faltar: siga o instalador oficial (`curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh`) ou o pacote do gerenciador do sistema, se preferir não rodar um script direto da internet, pergunte ao usuário qual prefere.

## Padrões de código inseguro (SAST automatizado)

A revisão manual da Fase 2 (SQL injection, validação, controle de acesso etc) é o núcleo da auditoria, mas uma ferramenta de SAST (Static Application Security Testing, varredura automática de padrões de código inseguro) serve como uma segunda camada que não depende só da sua leitura, útil especialmente em projetos grandes.

### Semgrep
Comando: `semgrep --config=p/security-audit --config=p/owasp-top-ten .`
Funciona na maioria das linguagens populares sem configuração extra, porque os pacotes de regras `p/security-audit` e `p/owasp-top-ten` já vêm prontos.
Instalação, se faltar: `pip install semgrep --break-system-packages` ou `brew install semgrep`, conforme o que estiver disponível no ambiente.
Trate os achados do Semgrep como pistas a confirmar, não como verdade automática: sempre leia o trecho apontado antes de incluir no relatório, porque toda ferramenta de SAST tem falsos positivos.

## Infraestrutura como código (IaC)

Se o projeto tem arquivos de Terraform, Kubernetes, CloudFormation ou o próprio Dockerfile/docker-compose, vale checar configurações inseguras nesses arquivos além do código da aplicação.

### Checkov
Comando: `checkov -d .`
Cobre Terraform, Kubernetes, CloudFormation, Dockerfile e outros formatos comuns de IaC num único comando.
Instalação, se faltar: `pip install checkov --break-system-packages`
Alternativa: `trivy config .` (o mesmo comando do Trivy usado pra Dockerfile e docker-compose acima também cobre Terraform e Kubernetes, então se o Trivy já foi instalado nessa auditoria, pode reaproveitar em vez de instalar o Checkov também).

## Quando nenhuma ferramenta está disponível e a instalação não é possível

Caia para checagem manual e diga claramente no relatório que essa parte foi feita de forma limitada:

- Dependências: leia manualmente o manifest e o lockfile e compare com o que você conhece, deixando claro que isso não consulta uma base de dados atualizada de vulnerabilidades.
- Segredos: procure por padrões comuns no estado atual dos arquivos (chaves com prefixos conhecidos como `sk_`, `AKIA`, tokens no formato JWT, blocos que parecem chave privada, senhas hardcoded em variáveis), avisando que isso não cobre o histórico do git.
- Imagens Docker e infraestrutura como código: leia o Dockerfile, o docker-compose.yml e quaisquer arquivos de Terraform/Kubernetes manualmente, procurando os problemas mais comuns (usuário root, credenciais hardcoded, portas expostas sem necessidade), avisando que isso é bem menos abrangente que uma ferramenta dedicada.
- Padrões de código inseguro: sem o Semgrep, a Fase 2 continua sendo feita, mas inteiramente pela sua leitura manual, sem a segunda camada automatizada de confirmação.

## Explicações em linguagem simples para pedir permissão

Use como ponto de partida e adapte ao caso real:

- Ferramentas de auditoria de dependências (npm audit, pip-audit, govulncheck, bundler-audit, cargo audit, composer audit, dependency-check do Java, `dotnet list package --vulnerable`): "isso é como checar se as peças, no caso as bibliotecas que o projeto usa, têm algum recall conhecido de segurança, comparando com uma lista pública de vulnerabilidades já documentadas".
- osv-scanner: "é uma checagem mais ampla, que cobre várias linguagens de uma vez, útil quando o projeto mistura tecnologias diferentes".
- gitleaks ou trufflehog: "isso vasculha não só os arquivos de hoje, mas todo o histórico de commits do projeto, porque uma senha ou chave que foi removida ontem ainda pode estar visível pra quem olhar o histórico".
- Trivy: "isso confere se a imagem do seu container (o pacote completo que roda em produção, incluindo o sistema por baixo do seu código) tem alguma peça desatualizada com falha conhecida, do mesmo jeito que a auditoria de dependências faz pro código, mas olhando a imagem inteira".
- Semgrep: "isso é um leitor automático de código que já conhece um catálogo de padrões perigosos (tipo um jeito inseguro de montar uma consulta ao banco de dados) e aponta onde esse padrão aparece no seu projeto, como uma segunda checagem além da minha própria leitura".
- Checkov: "isso confere se os arquivos que descrevem sua infraestrutura (Docker, Kubernetes, Terraform) têm alguma configuração arriscada, do mesmo jeito que um inspetor revisaria a planta de uma obra antes dela ser construída".
