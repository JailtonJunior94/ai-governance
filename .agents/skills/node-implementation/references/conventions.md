# Convencoes Node/TypeScript

## Objetivo
Preservar consistencia, fronteiras e legibilidade em projetos Node/TypeScript.

## Diretrizes
- Seguir o estilo ja adotado pelo projeto (ESM vs CJS, tabs vs spaces, aspas).
- Preferir `const` sobre `let`; evitar `var`.
- Preferir funcoes puras e composicao sobre heranca de classe.
- Usar barrel exports (`index.ts`) apenas quando o projeto ja adotar esse padrao.
- Nomear arquivos em kebab-case ou no padrao ja existente no projeto.
- Manter imports organizados: stdlib, dependencias externas, imports internos.

## TypeScript
- Preferir `interface` para contratos publicos e `type` para uniao/intersecao.
- Evitar `any`; usar `unknown` quando o tipo nao puder ser inferido.
- Preferir generics sobre asercoes de tipo (`as`).
- Usar `strict: true` em `tsconfig.json` quando iniciar projeto novo.

## Estrutura
- Seguir o layout ja adotado pelo projeto.
- Em projetos novos, separar `src/` (codigo) de `test/` ou colocar `*.test.ts` ao lado do arquivo testado.
- `cmd/` ou `bin/` para entrypoints; `lib/` ou `src/` para logica.

## Proibido
- Assumir versao de Node sem verificar `engines` em `package.json` ou `.nvmrc`.
- Instalar dependencias sem verificar se ja existem alternativas no projeto.
- Usar `require()` em projetos ESM sem justificativa.
