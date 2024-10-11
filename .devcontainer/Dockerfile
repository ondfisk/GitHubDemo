FROM mcr.microsoft.com/devcontainers/dotnet:9.0

USER vscode

RUN dotnet tool install --global dotnet-ef --prerelease \
    && dotnet tool install --global dotnet-outdated-tool

ENV TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal
