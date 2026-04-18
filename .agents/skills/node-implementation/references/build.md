# Build e Packaging Node/TypeScript

## Objetivo
Orientar criacao de Dockerfiles, pipelines de build e empacotamento de projetos Node.js.

## Dockerfile Multi-Stage
- Usar multi-stage para separar build de runtime e reduzir tamanho da imagem.
- Padrao recomendado:
  ```dockerfile
  # --- Build ---
  FROM node:20-alpine AS builder
  WORKDIR /app
  COPY package.json package-lock.json ./
  RUN npm ci --ignore-scripts
  COPY . .
  RUN npm run build

  # --- Runtime ---
  FROM node:20-alpine
  WORKDIR /app
  RUN addgroup -S app && adduser -S app -G app
  COPY --from=builder /app/dist ./dist
  COPY --from=builder /app/package.json /app/package-lock.json ./
  RUN npm ci --omit=dev --ignore-scripts
  USER app
  EXPOSE 3000
  CMD ["node", "dist/index.js"]
  ```
- Usar `npm ci` (nao `npm install`) para builds reprodutiveis.
- `--omit=dev` no runtime para excluir devDependencies.
- `--ignore-scripts` por seguranca, a menos que postinstall seja necessario (ex: prisma generate).

## .dockerignore
- Sempre incluir: `node_modules`, `.git`, `dist`, `coverage`, `.env*`, `*.log`.
- Copiar apenas o necessario para cada stage.

## Package Manager
- Respeitar o lockfile existente: `package-lock.json` (npm), `pnpm-lock.yaml` (pnpm), `yarn.lock` (yarn).
- Nao misturar package managers no mesmo projeto.
- Em monorepos, usar workspace-aware install: `pnpm install --frozen-lockfile`, `npm ci --workspaces`.

## TypeScript Build
- Compilar com `tsc` ou bundler (esbuild, tsup, swc) conforme o projeto.
- Emitir para `dist/` ou `build/` — nunca commitar output compilado.
- Incluir `declaration: true` em `tsconfig.json` quando o pacote for consumido como lib.
- Verificar `target` e `module` compatíveis com a versao de Node em producao.

## CI Pipeline
- Ordem recomendada: install -> lint -> typecheck -> test -> build.
- Cachear `node_modules` ou `.npm/_cacache` entre runs.
- Rodar `npm audit --audit-level=high` como gate opcional.
- Em monorepo, rodar apenas workspaces afetados: `npx turbo run test --filter=...affected`.

## Proibido
- `npm install` em Dockerfile (usar `npm ci`).
- Rodar container como root em producao.
- Commitar `node_modules` ou `dist/`.
- Build sem lockfile (resulta em versoes nao-deterministicas).
