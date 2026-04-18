# Configuracao

## Objetivo
Carregar configuracao de forma explicita, validada e sem acoplamento global.

## Diretrizes
- Preferir variaveis de ambiente como fonte primaria para deploys em containers.
- Carregar configuracao uma vez na inicializacao e injetar como dependencia explicita.
- Validar valores obrigatorios e ranges na inicializacao — falhar cedo com mensagem clara.
- Usar objetos tipados (zod schema, class com decorators, interface TypeScript) para configuracao, nao lookups por string espalhados.
- Usar `dotenv` ou equivalente apenas para desenvolvimento local — nao em producao.
- Separar config de infra (porta, DSN, timeouts) de config de negocio (feature flags, limites).
- Usar defaults explicitos e documentados para valores opcionais.

## Padrao de Uso
```typescript
import { z } from 'zod'

const configSchema = z.object({
  PORT: z.coerce.number().default(3000),
  DATABASE_URL: z.string().url(),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
})

export type Config = z.infer<typeof configSchema>

export function loadConfig(): Config {
  return configSchema.parse(process.env)
}
```

## Riscos Comuns
- Config lida em multiplos pontos com logica de fallback duplicada.
- Segredo carregado de env sem validacao e usado como string vazia silenciosamente.
- `dotenv` carregado em producao sobrescrevendo variaveis do orquestrador.

## Proibido
- Hardcode de segredos, DSNs ou endpoints em codigo.
- Config mutavel apos inicializacao sem sincronizacao.
- Importar `process.env` diretamente em modulos de negocio.
