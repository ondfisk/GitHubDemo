FROM mcr.microsoft.com/devcontainers/dotnet:11.0

USER vscode

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN dotnet tool install --global dotnet-ef

RUN curl -fsSL https://biomejs.dev/install.sh | bash

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD ["dotnet", "--info"]
