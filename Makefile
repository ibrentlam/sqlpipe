include .envrc

# ==================================================================================== #
# HELPERS
# ==================================================================================== #

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

.PHONY: confirm
confirm:
	@echo -n 'Are you sure? [y/N] ' && read ans && [ $${ans:-N} = y ]

# ==================================================================================== #
# DEVELOPMENT
# ==================================================================================== #

## sqlpipe: run the cmd/sqlpipe application
.PHONY: sqlpipe
sqlpipe: build/sqlpipe
	docker rm -f sqlpipe
	docker-compose up --build -d sqlpipe
	docker-compose logs -f sqlpipe

.PHONY: run
run: build/sqlpipe
	./bin/sqlpipe

## compose-reset: run docker-compose
.PHONY: compose
compose: build/sqlpipe
	docker-compose down -v
	docker-compose up --build -d
	docker-compose logs -f

## postgresql: run postgresql
.PHONY: postgresql
postgresql:
	docker compose down postgresql
	docker compose up -d postgresql
	clear
	docker compose logs -f postgresql

## mssql: run mssql
.PHONY: mssql
mssql:
	docker compose down mssql
	docker compose up -d mssql
	clear
	docker compose logs -f mssql

## mysql: run mysql
.PHONY: mysql
mysql:
	docker compose down mysql
	docker compose up -d mysql
	clear
	docker compose logs -f mysql

## oracle: run oracle
.PHONY: oracle
oracle:
	docker compose down oracle
	docker compose up -d oracle
	clear
	docker compose logs -f oracle

# ==================================================================================== #
# QUALITY CONTROL
# ==================================================================================== #

## audit: tidy and vendor dependencies and format, vet and test all code
.PHONY: audit
audit: vendor
	@echo 'Formatting code...'
	go fmt ./...
	@echo 'Vetting code...'
	go vet ./...
	staticcheck ./...
	@echo 'Running tests...'
	go test -race -vet=off ./...

## vendor: tidy and vendor dependencies
.PHONY: vendor
vendor:
	@echo 'Tidying and verifying module dependencies...'
	go mod tidy
	go mod verify
	@echo 'Vendoring dependencies...'
	go mod vendor

# ==================================================================================== #
# BUILD
# ==================================================================================== #

## build/sqlpipe: build the cmd/sqlpipe application
.PHONY: build/sqlpipe
build/sqlpipe:
	@echo 'Building cmd/sqlpipe...'
	GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o=./bin/sqlpipe ./cmd/sqlpipe
	# go build -ldflags="-w -s" -o=./bin/sqlpipe ./cmd/sqlpipe

## build/docker: build the cmd/sqlpipe docker image and push
.PHONY: build/docker
build/docker:
	@echo 'Building cmd/sqlpipe...'
	GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o=./bin/sqlpipe ./cmd/sqlpipe
	@echo 'Building docker image...'
	docker build -t sqlpipe/sqlpipe:latest -f sqlpipe.dockerfile .
	@echo 'Pushing docker image...'
	docker push sqlpipe/sqlpipe:latest
