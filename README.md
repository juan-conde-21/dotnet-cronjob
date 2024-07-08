# dotnet-cronjob

Despliegue de BD

	kubectl apply -f bd.yaml

Conectar a BD y ejecutar linea de comandos sql

	/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P P4ssw0rd$

Ejecutar comandos para crear BD

	CREATE DATABASE TestDB;
	GO

Creación de cronjob

	kubectl apply -f cronjob.yaml

