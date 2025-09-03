FROM mcr.microsoft.com/devcontainers/dotnet:1-9.0-bookworm

USER vscode

RUN dotnet tool install --global dotnet-ef \
    && dotnet tool install --global dotnet-outdated-tool

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
  CMD dotnet --info > /dev/null || exit 1

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1