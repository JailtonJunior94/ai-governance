# Padrões Go

## Objetivo
Manter o código idiomático, legível e compatível com a toolchain Go.

## Diretrizes
- Preferir nomes curtos e precisos no escopo certo.
- Retornar erros como último valor e usar wrapping com `%w` quando necessário.
- Manter funções pequenas quando isso melhorar leitura e teste, sem fragmentação artificial.
- Preferir zero values úteis e construtores apenas quando houver invariantes ou dependências obrigatórias.
- Usar `context.Context` em fronteiras de IO, rede, subprocesso ou operações canceláveis.

## Tipos de Erro
- Usar sentinel errors (`var ErrNotFound = errors.New("not found")`) para erros que o chamador precisa comparar com `errors.Is`.
- Usar tipos customizados (`type ValidationError struct{...}`) quando o chamador precisar extrair dados do erro com `errors.As`.
- Usar wrapping simples (`fmt.Errorf("doing X: %w", err)`) quando o chamador só precisa propagar contexto.
- Não misturar sentinel e tipo customizado para o mesmo cenário — escolher um.
- Definir sentinels e tipos de erro no pacote que os origina, não em pacote central de erros.
- Não criar tipo customizado quando um sentinel resolve.

## Validação
- Formatar com `gofmt`.
- Usar `go test ./...` como gate mínimo quando o contexto suportar esse passo.
