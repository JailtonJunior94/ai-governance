# Tratamento de Erros

- Rule ID: R-ERR-001
- Severidade: hard
- Escopo: Todo código com criação, wrapping, propagação e apresentação de erros.

## Objetivo
Padronizar erros com mensagens claras ao usuário e detalhes técnicos preservados para diagnóstico.

## Requisitos

### Modelagem
- Erros de domínio devem ser sentinelas ou tipos bem definidos em seus módulos.
- Erros de infraestrutura podem ser wrapped com contexto adicional.
- Mensagens internas devem ser curtas, em lowercase e estáveis.

### Wrapping
- Preservar cadeia para inspeção programática (e.g. `errors.Is`, `errors.As` em Go).
- Adapters devem adicionar contexto técnico útil: operação, componente, path.

### Apresentação
- A camada de apresentação deve traduzir erro técnico em mensagem acionável.
- Mensagens ao usuário devem dizer o que falhou, onde falhou e qual ação é possível.

### Retry e Remediação
- Retry automático deve ser restrito a casos previstos e falhas transitórias.
- Número máximo padrão de retries automáticos: 2.
- Se remediação automática falhar, pausar para intervenção ou encerrar de forma explícita.

### Comparação
- Usar mecanismos idiomáticos de comparação de erros da linguagem.
- Não comparar erro por string quando existir alternativa tipada.

## Proibido
- `panic` (ou equivalente) para erro recuperável.
- Engolir erro de IO, subprocesso, persistência ou validação.
- Exibir stack trace bruto por padrão ao usuário final.
- Mensagens vagas como `something went wrong`.
