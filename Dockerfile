
# Establecer la imagen base para la ejecución
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# Instalar los paquetes necesarios para la localización
RUN apk add --no-cache icu-libs

# Establecer la imagen de build para la compilación
FROM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
WORKDIR /src
COPY ["EFCoreExampleSeriLog/EFCoreExampleSeriLog.csproj", "EFCoreExampleSeriLog/"]
RUN dotnet restore "EFCoreExampleSeriLog/EFCoreExampleSeriLog.csproj"
COPY . .
WORKDIR "/src/EFCoreExampleSeriLog"
RUN dotnet build "EFCoreExampleSeriLog.csproj" -c Release -o /app/build

# Publicar la aplicación
FROM build AS publish
RUN dotnet publish "EFCoreExampleSeriLog.csproj" -c Release -o /app/publish

# Crear la imagen final basada en Alpine
FROM base AS final
WORKDIR /app

# Copiar los paquetes de localización de icu-libs al entorno final
COPY --from=base /usr/share/icu /usr/share/icu
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

COPY --from=publish /app/publish .


#Ejecucion de app utilizando script de instrumentacion automatica
RUN apk update && apk add unzip && apk add curl && apk add bash
RUN mkdir otel
RUN curl -L -o /app/otel/otel-dotnet-auto-install.sh https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/latest/download/otel-dotnet-auto-install.sh
RUN chmod +x /app/otel/otel-dotnet-auto-install.sh
ENV OTEL_DOTNET_AUTO_HOME=/app/otel
RUN /bin/bash /app/otel/otel-dotnet-auto-install.sh

ENV OTEL_TRACES_EXPORTER=otlp \
    OTEL_METRICS_EXPORTER=otlp \
    OTEL_LOGS_EXPORTER=otlp \
    OTEL_EXPORTER_OTLP_PROTOCOL=grpc \
    OTEL_DOTNET_AUTO_TRACES_CONSOLE_EXPORTER_ENABLED=true \
    OTEL_DOTNET_AUTO_METRICS_CONSOLE_EXPORTER_ENABLED=true \
    OTEL_DOTNET_AUTO_LOGS_CONSOLE_EXPORTER_ENABLED=true \
    OTEL_DOTNET_AUTO_HOME=/app/otel

ENV DOTNET_ADDITIONAL_DEPS=$OTEL_DOTNET_AUTO_HOME/AdditionalDeps:$OTEL_DOTNET_AUTO_HOME/AdditionalDeps \
    DOTNET_STARTUP_HOOKS=$OTEL_DOTNET_AUTO_HOME/net/OpenTelemetry.AutoInstrumentation.StartupHook.dll:$OTEL_DOTNET_AUTO_HOME/net/OpenTelemetry.AutoInstrumentation.StartupHook.dll \
    DOTNET_SHARED_STORE=$OTEL_DOTNET_AUTO_HOME/store:$OTEL_DOTNET_AUTO_HOME/store \
    CORECLR_ENABLE_PROFILING=1 \
    CORECLR_PROFILER={918728DD-259F-4A6A-AC2B-B85E1B658318} \
    CORECLR_PROFILER_PATH=$OTEL_DOTNET_AUTO_HOME/linux-musl-x64/OpenTelemetry.AutoInstrumentation.Native.so

ENTRYPOINT ["dotnet", "EFCoreExampleSeriLog.dll"]
