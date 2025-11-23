CONTAINER_BACKEND=transcendence_backend
CONTAINER_FRONTEND=transcendence_frontend
CONTAINER_DB=transcendence_db


# -------------------------
# Comandos principales
# -------------------------
up: get_current build
	@docker-compose up --detach

copy-certs:
	@cp frontend/certs/rootCA.crt ~/Desktop/

logs:	
	@docker-compose logs -f

FE_logs:
	@docker-compose logs -f frontend	
BE_logs:
	@docker-compose logs -f backend
DB_logs:
	@docker-compose logs -f database

ca_check:
	@if [ -f rootCA/rootCA.key ] && [ -f rootCA/rootCA.crt ] \
		&& [ -f backend/certs/rootCA.key ] && [ -f backend/certs/rootCA.crt ] \
		&& [ -f frontend/certs/rootCA.crt ]; then \
		echo "CA Correctly Placed"; \
	else \
		echo "Missing CA"; \
		rm -rf rootCA; \
		rm -rf data/*; \
		rm -rf backend/certs/*; \
		rm -rf frontend/certs/*; \
		make generate-ca; \
	fi

# Generar la CA local (fer-ho UNA vegada)
generate-ca:
	chmod +x backend/scripts/generate-ca.sh
	cd backend/scripts && ./generate-ca.sh

# Crear carpetas necesarias
create-dirs:
	@mkdir -p data
	@mkdir -p backend/certs
	@mkdir -p frontend/certs

# Generar certificados
generate-certs:
	echo "Generating certificates"
	@cd backend/scripts && ./generate-certificate.sh
	@cd frontend && ./generate-certificate.sh

# Construir con docker-compose
build: create-dirs ca_check generate-certs build-base
	@docker-compose build

build-base:
	@docker build -t transcendence-base -f Dockerfile.base .

build-back:
	@docker-compose build backend

build-front:
	@docker-compose build frontend

build-db:
	@docker-compose build database
	
shell-back:
	@docker exec -it $(CONTAINER_BACKEND) /bin/sh

shell-front:
	@docker exec -it $(CONTAINER_FRONTEND) /bin/sh

shell-front-reload:
	@docker exec -it $(FRONTEND) sh -c "npm run dev"

shell-db:
	@docker exec -it $(CONTAINER_DB) /bin/sh

down:
	@docker-compose down

prune: down
	@docker system prune -f

clean:
	@echo "Cleaning up project resources (containers, images, volumes)..."
	@docker-compose down --rmi all --volumes
	@docker rmi transcendence-base 2>/dev/null || true

fclean: clean
	@echo "Removing local generated files (certs, data, etc)..."
	@rm -rf rootCA
	@rm -rf backend/certs
	@rm -rf frontend/certs
	@rm -rf data

re: fclean up

# ------------------------------------------
# REPO MANAGEMENT 
# ------------------------------------------

# Esta regla inicializa los repos y los fuerza a estar en la rama 'main'
# Si ya están clonados, los corrige para que dejen de estar en "detached HEAD"
get_current:
	@echo "Checking repositories configuration..."
	@git submodule update --init --recursive
	@# Iteramos por cada submódulo para asegurarnos de que está en la rama main
	@git submodule foreach -q 'branch="main"; \
		echo "Configuring $$name on branch $$branch..."; \
		git fetch origin --quiet; \
		if ! git show-ref --verify --quiet refs/heads/$$branch; then \
			git checkout -b $$branch origin/$$branch 2>/dev/null || git checkout $$branch; \
		else \
			git checkout $$branch 2>/dev/null; \
		fi; \
		git pull origin $$branch --ff-only || echo "Warning: Could not pull $$name"'

# Actualiza todos los repos a la última versión de su rama (git pull real)
pull: get_current
	@echo "Pulling latest changes for all modules..."
	@git submodule foreach 'git pull origin main'

pull-backend:
	@echo "Updating [backend] to latest main..."
	@git submodule update --init backend
	@cd backend && git fetch origin && (git checkout main 2>/dev/null || git checkout -b main origin/main) && git pull origin main

pull-frontend:
	@echo "Updating [frontend] to latest main..."
	@git submodule update --init frontend
	@cd frontend && git fetch origin && (git checkout main 2>/dev/null || git checkout -b main origin/main) && git pull origin main

pull-database:
	@echo "Updating [database] to latest main..."
	@git submodule update --init database
	@cd database && git fetch origin && (git checkout main 2>/dev/null || git checkout -b main origin/main) && git pull origin main

.PHONY: create-dirs generate-certs build up logs shell-back shell-front shell-db down clean re dev get_current pull pull-backend pull-frontend pull-database
