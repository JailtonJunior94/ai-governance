# Regras Adaptadas para Go

Estas regras devem ser tratadas como heuristicas para reduzir complexidade acidental, e nao como dogma. Cada regra so deve ser aplicada quando melhorar legibilidade, encapsulamento, testabilidade ou estabilidade do comportamento.

## 1. Uma camada de indentacao por funcao

Aplicar quando uma funcao acumular `if`, `for`, `switch`, `select` ou combinacoes aninhadas que escondem o fluxo principal.

Preferir:
- early returns
- guard clauses
- extracao de trechos em funcoes privadas
- troca de branching por despacho simples quando isso reduzir acoplamento real

Evitar:
- extrair funcoes sem nome semantico claro
- espalhar o fluxo em funcoes minimas que pioram navegacao

## 2. Nao usar `else` quando o fluxo puder retornar cedo

Aplicar quando um ramo invalido ou excepcional puder encerrar a funcao com `return`, `continue` ou `break`.

Preferir:
- validacao no topo
- erro retornado cedo
- caso feliz visivel no fluxo principal

Excecao:
- manter `else` quando ele deixar invariantes mais claras do que uma sequencia artificial de retornos

## 3. Encapsular primitivos de dominio

Aplicar quando `string`, `int`, `time.Time`, `float64` ou aliases crus carregarem semantica de negocio, regras de validacao ou formato relevante.

Preferir:
- tipos dedicados
- construtores ou funcoes de parse
- metodos pequenos no tipo quando eles expressarem regra de dominio

Evitar:
- wrappers vazios sem comportamento
- tipos so para satisfazer a regra sem ganho semantico

## 4. Colecoes de primeira classe

Aplicar quando slices ou maps carregarem regras, filtros, ordenacao, agregacao ou validacao recorrente.

Preferir:
- tipos dedicados para a colecao
- metodos focados no comportamento da colecao
- encapsulamento de invariantes de ordenacao, busca ou limite

Evitar:
- encapsular qualquer slice trivial sem comportamento associado

## 5. Um ponto por linha

Aplicar quando cadeias de acesso ou chamadas escondem acoplamento estrutural.

Em Go, observar principalmente:
- `a.B().C().D()`
- navegacao entre campos expostos de structs
- chamadas que exigem conhecer detalhes internos de varios tipos

Preferir:
- metodos de mais alto nivel
- transferencia de responsabilidade para o tipo que conhece os detalhes

## 6. Nao abreviar nomes de forma opaca

Aplicar a nomes de packages, tipos, variaveis, parametros e campos.

Preferir:
- nomes que revelem papel e semantica
- abreviacoes apenas quando forem idiomaticas e amplamente reconhecidas no ecossistema Go

Evitar:
- nomes como `ctx2`, `svcX`, `tmp1`, `obj`
- nomes longos que repetem informacao obvia do package

## 7. Manter entidades pequenas

Em Go, traduzir esta regra como controle de tamanho e responsabilidade de:
- funcoes
- metodos
- structs
- arquivos

Avaliar:
- numero de responsabilidades
- quantidade de campos
- volume de branching
- dependencia de varios colaboradores nao relacionados

Preferir separar por coesao, e nao por contagem cega de linhas.

## 8. No maximo duas variaveis de instancia por struct quando isso indicar alta coesao

Em Go, tratar como sinal de alerta e nao como limite absoluto.

Usar a regra para investigar:
- structs com muitos campos que misturam configuracao, estado e colaborador
- services que acumulam dependencias demais
- DTOs ou parametros agregados sem papel claro

Nao aplicar cegamente a:
- DTOs
- configuracoes
- aggregates
- tipos que precisam representar estado real do dominio

## 9. Nao usar getters e setters mecanicos

Preferir:
- campos nao exportados quando o estado precisa de protecao
- metodos com intencao de negocio
- operacoes que preservem invariantes

Aceitar getters simples quando:
- o contrato publico do package exigir exposicao controlada
- a API Go do contexto ja seguir esse padrao

## Quando interromper a aplicacao das regras

Interromper quando a refatoracao:
- exigir quebra de API publica
- aumentar indirecao sem reduzir acoplamento
- piorar idiomatismo Go
- tornar erro, observabilidade ou depuracao mais opacos
- espalhar responsabilidade por muitos arquivos sem beneficio proporcional
