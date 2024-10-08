FROM mcr.microsoft.com/devcontainers/dotnet:1.3.3-9.0-bookworm-slim

USER vscode

RUN dotnet tool install --global dotnet-ef --prerelease \
    && dotnet tool install --global dotnet-outdated-tool

ENV TESTCONTAINERS_HOST_OVERRIDE=host.docker.internal
