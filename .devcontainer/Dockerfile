FROM mcr.microsoft.com/devcontainers/dotnet:10.0

USER vscode

RUN dotnet tool install --global dotnet-ef

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD dotnet --info > /dev/null || exit 1
