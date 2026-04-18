# Principios de Teste (Cross-Linguagem)

## Unit Tests (obrigatorio)
- Todo comportamento de dominio, use case e logica pura deve ter unit test.
- Nomear pelo cenario, nao pelo metodo.
- Testes deterministicos: sem sleep, sem dependencia de ordem, sem estado global.
- Mocks apenas para fronteiras externas (IO, rede, filesystem, banco).
- Nao testar glue code sem logica (construtores triviais, DTOs, wiring).

## Integration Tests (quando adotados)
- Separar de unit tests via tag, marcador ou script dedicado.
- Usar testcontainers para provisionar dependencias reais em containers efemeros.
- Cada suite provisiona e destroi seu container — nao depender de infra pre-existente.
- Nao depender de servicos externos reais (banco de dev, API de staging).

## Proibido
- Sleep para sincronizacao em teste.
- Teste que passa sozinho mas falha em suite completa.
- Mock que nao reflete o contrato real da dependencia.
- Integration test sem separacao rodando junto com unit tests.
