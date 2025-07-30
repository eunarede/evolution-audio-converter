# Troubleshooting FFmpeg no Dokploy

## Problema
Erro: `exec: "ffmpeg": executable file not found in $PATH`

## Soluções

### Opção 1: Usar Docker (Recomendado)
Se o Nixpacks não estiver funcionando corretamente, use Docker:

1. No Dokploy, selecione "Docker" como build provider em vez de "Nixpacks"
2. O Dockerfile já está configurado corretamente com FFmpeg

### Opção 2: Configuração Alternativa do Nixpacks
Se quiser continuar com Nixpacks:

1. Renomeie `nixpacks.toml.alternative` para `nixpacks.toml`
2. Redeploy a aplicação

### Opção 3: Verificar Logs
Use o script `start.sh` para debug:

```bash
# No container, execute:
./start.sh
```

Isso mostrará se o FFmpeg foi encontrado e onde está localizado.

### Opção 4: Variáveis de Ambiente
Adicione no Dokploy:

```env
PATH=/usr/bin:/usr/local/bin:/nix/store/*/bin:$PATH
```

## Testando Localmente

Para testar se FFmpeg está funcionando:

```bash
# Build local
go build -o out .

# Testar FFmpeg
ffmpeg -version

# Executar aplicação
./out
```

## Recomendação Final

Para máxima compatibilidade, recomendamos usar Docker em vez de Nixpacks para este projeto, já que o FFmpeg é uma dependência crítica do sistema.
