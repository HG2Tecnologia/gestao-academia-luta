FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["src/AcademiaFight.API/AcademiaFight.API.csproj", "src/AcademiaFight.API/"]
COPY ["src/AcademiaFight.Application/AcademiaFight.Application.csproj", "src/AcademiaFight.Application/"]
COPY ["src/AcademiaFight.Domain/AcademiaFight.Domain.csproj", "src/AcademiaFight.Domain/"]
COPY ["src/AcademiaFight.Infrastructure/AcademiaFight.Infrastructure.csproj", "src/AcademiaFight.Infrastructure/"]
COPY ["src/AcademiaFight.CatracaAgent/AcademiaFight.CatracaAgent.csproj", "src/AcademiaFight.CatracaAgent/"]
RUN dotnet restore "src/AcademiaFight.API/AcademiaFight.API.csproj"
COPY . .

# Compilar o agente para Windows x64 (cross-compilation no Linux)
WORKDIR "/src/src/AcademiaFight.CatracaAgent"
RUN dotnet publish "AcademiaFight.CatracaAgent.csproj" -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o /app/agent

# Copiar o .exe para wwwroot/agent antes de buildar a API
RUN mkdir -p /src/src/AcademiaFight.API/wwwroot/agent && \
    cp /app/agent/SenseiManagerCatracaAgent.exe /src/src/AcademiaFight.API/wwwroot/agent/

WORKDIR "/src/src/AcademiaFight.API"
RUN dotnet build "AcademiaFight.API.csproj" -c Release -o /app/build

FROM build AS publish
WORKDIR "/src/src/AcademiaFight.API"
RUN dotnet publish "AcademiaFight.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "AcademiaFight.API.dll"]
