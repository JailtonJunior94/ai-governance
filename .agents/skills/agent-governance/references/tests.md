# Testes

- Rule ID: R-TEST-001
- Severidade: hard para correção e determinismo, guideline para estilo

## Objetivo
Garantir confiabilidade do código, dos adapters e das integrações.

## Requisitos

### Cobertura Prioritária
- Validadores de input devem ter testes unitários.
- Fluxos principais devem cobrir caminho feliz e cenários de falha.
- Integrações externas devem ter testes com doubles de subprocesso ou mock.
- Persistência e IO devem ter testes de integração com filesystem temporário.

### Estratégia
- Testes unitários devem usar doubles simples e determinísticos.
- Testes de integração devem validar filesystem e compatibilidade quando possível.
- Casos com matriz de entrada devem usar table-driven tests.

### Ferramentas (Go)
- Usar `testify/suite` como estrutura padrão para testes — agrupar casos relacionados em uma suite com setup/teardown.
- Usar `testify/assert` para asserções legíveis; preferir `require` quando a falha deve interromper o teste imediatamente.
- Gerar mocks com `mockery` configurado via `.mockery.yml` na raiz do projeto — não criar mocks manuais quando mockery puder gerar.
- Mocks gerados devem ficar em diretório `mocks/` dentro do pacote que define a interface.

### Fuzz Testing (Go)
- Usar fuzz tests (`func FuzzXxx(f *testing.F)`) para funções que processam input externo: parsers, validadores, deserializadores, encoders e qualquer transformação de dados não-confiáveis.
- Adicionar seed corpus com valores representativos e edge cases conhecidos via `f.Add(...)`.
- Fuzz target deve ser determinístico e sem efeitos colaterais.
- Rodar localmente com `go test -fuzz=FuzzXxx -fuzztime=30s` antes de submeter; em CI usar apenas o seed corpus (`go test ./...` executa seeds automaticamente).

### Determinismo
- Testes não devem depender de rede real nem de ferramentas externas instaladas.
- Tempo, IO e subprocesso devem ser abstraídos para teste.
- Estado compartilhado entre casos é proibido.

### Gates
- O comando de teste padrão do projeto deve ser o gate mínimo.
- Suites separadas devem ser claramente documentadas.

## Proibido
- Teste unitário chamando ferramentas externas reais.
- Testes frágeis baseados em `sleep`.
- Cobrir apenas o caminho feliz.
