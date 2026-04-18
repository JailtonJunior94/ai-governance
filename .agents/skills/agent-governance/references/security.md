# Segurança

- Rule ID: R-SEC-001
- Severidade: hard
- Escopo: Todo código, configuração, logs e execução.

## Objetivo
Definir o baseline de segurança para projetos que utilizam agentes de IA e executam ações no filesystem.

## Requisitos

### Segredos
- Credenciais devem vir de ambiente, config do sistema ou autenticação já feita pela ferramenta.
- Segredos não devem ser hardcoded, logados ou persistidos em diretórios de artefatos.

### Filesystem
- Toda escrita deve ser intencional e auditável.
- Paths devem ser normalizados e validados antes do uso.
- Evitar sobrescrever artefatos anteriores sem política explícita.

### Execução de Comandos
- Subprocessos devem ser construídos com argumentos explícitos.
- Shell deve ser evitado quando a chamada puder ser feita diretamente.
- Comandos de git destrutivos ou publicações remotas são proibidos salvo pedido explícito do usuário.

### Input Externo
- Input de arquivo, respostas de provider e dados externos devem ser tratados como não confiáveis.
- Parsing e validação devem ocorrer antes de uso.

### Dependências
- Preferir bibliotecas pequenas, estáveis e mantidas.
- Evitar frameworks pesados para resolver problemas simples.

## Proibido
- Hardcode de token, segredo ou path sensível de usuário.
- Concatenação insegura de comandos shell.
- Persistir conteúdo sensível sem necessidade operacional clara.
