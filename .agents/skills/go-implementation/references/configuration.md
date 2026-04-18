# Configuração

## Objetivo
Carregar configuração de forma explícita, validada e sem acoplamento global.

## Diretrizes
- Preferir variáveis de ambiente como fonte primária para deploys em containers.
- Carregar configuração uma vez na inicialização e injetar como dependência explícita.
- Validar valores obrigatórios e ranges na inicialização — falhar cedo com mensagem clara.
- Usar structs tipadas para configuração, não maps ou lookups por string espalhados no código.
- Não usar variáveis globais ou `init()` para carregar config.
- Separar config de infra (porta, DSN, timeouts) de config de negócio (sinalizadores de funcionalidade, limites) quando fizer sentido.
- Usar defaults explícitos e documentados para valores opcionais.

## Riscos Comuns
- Config lida em múltiplos pontos com lógica de fallback duplicada.
- Segredo carregado de env sem validação e usado como string vazia silenciosamente.
- Acoplamento global via singleton de config acessado de qualquer ponto.

## Proibido
- Hardcode de segredos, DSNs ou endpoints em código.
- Config mutável após inicialização sem sincronização.
