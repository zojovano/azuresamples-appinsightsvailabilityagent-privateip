# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore dependencies
COPY ["src/AvailabilityAgent/AvailabilityAgent.csproj", "src/AvailabilityAgent/"]
RUN dotnet restore "src/AvailabilityAgent/AvailabilityAgent.csproj"

# Copy everything else and build
COPY . .
WORKDIR "/src/src/AvailabilityAgent"
RUN dotnet build "AvailabilityAgent.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "AvailabilityAgent.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated8.0
ENV AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true

WORKDIR /home/site/wwwroot
COPY --from=publish /app/publish .
