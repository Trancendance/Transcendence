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
build: create-dirs ca_check generate-certs
	@docker-compose build

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

shell-db:
	@docker exec -it $(CONTAINER_DB) /bin/sh

down:
	@docker-compose down

clean: down
	@docker system prune -f

fclean: clean
	rm -rf rootCA
	rm -rf backend/certs
	rm -rf frontend/certs
	rm -rf data

re: down up

# ------------------------------------------
# SUBMODULE MANAGEMENT
# ------------------------------------------

get_current:
	@if [ -z "$$(ls -A backend 2>/dev/null)" ] && [ -z "$$(ls -A frontend 2>/dev/null)" ] && [ -z "$$(ls -A database 2>/dev/null)" ]; then \
		echo "Empty submodules, Initializing them to their latest version..."; \
		git submodule update --init --recursive; \
		git submodule update --remote --merge --recursive; \
	else \
		echo "Submodules already initialized"; \
	fi

pull: get_current
	@echo "Updating all submodules..."; 
	@git submodule update --remote --merge; 

pull-backend:
	@if [ -z "$$(ls -A backend 2>/dev/null)" ]; then \
		echo "Updating submodule [backend]..."; \
		git submodule update --init --recursive backend; \
	fi
	@cd backend && git pull origin $$(git rev-parse --abbrev-ref HEAD); \

pull-frontend:
	@if [ -z "$$(ls -A frontend 2>/dev/null)" ]; then \
		echo "Updating submodule [frontend]..."; \
		git submodule update --init --recursive frontend; \
	fi
	@cd frontend && git pull origin $$(git rev-parse --abbrev-ref HEAD); \

pull-database:
	@if [ -z "$$(ls -A database 2>/dev/null)" ]; then \
		echo "Updating submodule [database]..."; \
		git submodule update --init --recursive database; \
	fi
	@cd database && git pull origin $$(git rev-parse --abbrev-ref HEAD);


.PHONY: create-dirs generate-certs build up logs shell-back shell-front shell-db down clean re dev get_current pull
