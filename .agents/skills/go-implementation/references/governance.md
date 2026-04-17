# Governança Go

## Objetivo
Aplicar mudanças em Go com a menor alteração segura, preservando contratos, fronteiras e legibilidade.

## Diretrizes
- Ler `AGENTS.md` e a skill base antes de editar.
- Confirmar a versão alvo em `go.mod` antes de introduzir APIs da linguagem ou dependências.
- Preferir correção de causa raiz a patches locais quando o problema for reproduzível.
- Evitar abstração prematura, camadas adicionais e helpers genéricos sem demanda concreta.
- Atualizar testes e validações de forma proporcional ao risco.

## Proibido
- Assumir versão de Go sem verificar.
- Introduzir interface por reflexo.
- Expandir o escopo sem necessidade técnica clara.
