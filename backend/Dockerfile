FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["src/AcademiaFight.API/AcademiaFight.API.csproj", "src/AcademiaFight.API/"]
COPY ["src/AcademiaFight.Application/AcademiaFight.Application.csproj", "src/AcademiaFight.Application/"]
COPY ["src/AcademiaFight.Domain/AcademiaFight.Domain.csproj", "src/AcademiaFight.Domain/"]
COPY ["src/AcademiaFight.Infrastructure/AcademiaFight.Infrastructure.csproj", "src/AcademiaFight.Infrastructure/"]
RUN dotnet restore "src/AcademiaFight.API/AcademiaFight.API.csproj"
COPY . .
WORKDIR "/src/src/AcademiaFight.API"
RUN dotnet build "AcademiaFight.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "AcademiaFight.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "AcademiaFight.API.dll"]
