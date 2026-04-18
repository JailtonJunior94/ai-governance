FROM golang:1.23-alpine AS build
WORKDIR /app
COPY . .
RUN go build -o server ./cmd/server
FROM alpine:3.20
COPY --from=build /app/server /server
CMD ["/server"]
