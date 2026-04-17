# Roteiro de Avaliacao

Usar este roteiro para produzir review ou plano de refatoracao incremental.

## 1. Delimitar a superficie

Registrar:
- package ou fluxo analisado
- arquivos e tipos principais
- contrato publico afetado ou preservado

## 2. Identificar o problema dominante

Escolher o problema principal antes de listar regras:
- complexidade de fluxo
- baixo encapsulamento
- nomes opacos
- struct com responsabilidades demais
- colecao com logica espalhada

## 3. Mapear as regras relevantes

Selecionar somente as regras que ajudam de forma concreta. Evitar checklist mecanico.

## 4. Propor a menor mudanca segura

Descrever:
- que parte mudar
- por que isso reduz complexidade
- que comportamento precisa ser preservado
- que teste protege a mudanca

## 5. Decidir se executa ou para

Executar apenas se:
- o escopo for local
- o risco estiver contido
- a validacao for viavel

Parar e registrar quando:
- exigir quebra publica
- faltar contexto
- faltar teste minimo
- a refatoracao pedir redesenho amplo
