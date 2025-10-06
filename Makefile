CONTAINER_BACKEND=transcendence_backend
CONTAINER_FRONTEND=transcendence_frontend
CONTAINER_DB=transcendence_db

# Crear carpetas necesarias
create-dirs:
	mkdir -p data
	mkdir -p backend/certs
	mkdir -p frontend/certs

# Generar certificados
generate-certs: create-dirs
	cd backend && ./generate-certificate.sh
	cd frontend && ./generate-certificate.sh

# Construir con docker-compose
build: generate-certs
	docker-compose build

# -------------------------
# Comandos principales
# -------------------------
up: build
	docker-compose up --detach

logs:
	docker-compose logs -f

shell-back:
	docker exec -it $(CONTAINER_BACKEND) /bin/sh

shell-front:
	docker exec -it $(CONTAINER_FRONTEND) /bin/sh

shell-db:
	docker exec -it $(CONTAINER_DB) /bin/sh

down:
	docker-compose down

clean: down
	docker system prune -f

re: down up

.PHONY: create-dirs generate-certs build up logs shell-back shell-front shell-db down clean re dev