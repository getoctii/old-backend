#!/bin/sh

docker stop nekos-dev-postgres
docker rm nekos-dev-postgres
docker run --name nekos-dev-postgres -e POSTGRES_PASSWORD=password -p 5432:5432 -e POSTGRES_DB=neko-chat -d postgres