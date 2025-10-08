CONTAINER_BACKEND=transcendence_backend
CONTAINER_FRONTEND=transcendence_frontend
CONTAINER_DB=transcendence_db


# -------------------------
# Comandos principales
# -------------------------
up: get_current build
	@docker-compose up --detach

logs:
	@docker-compose logs -f

# Crear carpetas necesarias
create-dirs:
	@mkdir -p data
	@mkdir -p backend/certs
	@mkdir -p frontend/certs

# Generar certificados
generate-certs: create-dirs
	echo "Generando Certificados"
	@cd backend && ./generate-certificate.sh
	@cd frontend && ./generate-certificate.sh

# Construir con docker-compose
build: generate-certs
	@docker-compose build
	
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

re: down up

# ------------------------------------------
# SUBMODULE MANAGEMENT
# ------------------------------------------

get_current:
	@if [ -z "$$(ls -A backend 2>/dev/null)" ] && [ -z "$$(ls -A frontend 2>/dev/null)" ] && [ -z "$$(ls -A database 2>/dev/null)" ]; then \
		echo "Submódulos Vacíos, Inicializandolos A Su Última Versión..."; \
		git submodule update --init --recursive; \
		git submodule update --remote --merge --recursive; \
	else \
		echo "Submodulos Ya Inicializados"; \
	fi

pull: get_current
	echo "Actualizando Todos Los Submódulos..."; 
	@git submodule update --remote --merge; 

pull-backend:
	@if [ -z "$$(ls -A backend 2>/dev/null)" ]; then \
		echo "Actualizando submódulo [backend]..."; \
		git submodule update --init --recursive backend; \
	fi
	@cd backend && git pull origin $$(git rev-parse --abbrev-ref HEAD); \

pull-frontend:
	@if [ -z "$$(ls -A frontend 2>/dev/null)" ]; then \
		echo "Actualizando submódulo [frontend]..."; \
		git submodule update --init --recursive frontend; \
	fi
	@cd frontend && git pull origin $$(git rev-parse --abbrev-ref HEAD); \

pull-database:
	@if [ -z "$$(ls -A database 2>/dev/null)" ]; then \
		echo "Actualizando submódulo [database]..."; \
		git submodule update --init --recursive database; \
	fi
	@cd database && git pull origin $$(git rev-parse --abbrev-ref HEAD);


.PHONY: create-dirs generate-certs build up logs shell-back shell-front shell-db down clean re dev get_current pull
