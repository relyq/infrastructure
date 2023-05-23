#!/bin/bash
ENV_FILE_PATH=/root/.tracker.env
docker pull relyq/tracker-nginx:master
docker pull relyq/tracker-dotnet:master
source "$ENV_FILE_PATH"
docker compose -f /opt/tracker/docker-compose.yml up --force-recreate --build -d