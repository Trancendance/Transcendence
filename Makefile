generate-certs:
	cd backend && ./generate-certificate.sh
	cd frontend && ./generate-certificate.sh

build: generate-certs
	docker compose build

up: build
	docker compose up --detach

logs:
	docker compose logs -f

shell-back:
	docker exec -it mytra_back /bin/sh

shell-front:
	docker exec -it mytra_front /bin/sh

shell-db:
	docker exec -it mytra_db_server /bin/sh

down:
	docker compose down

clean: down
	docker system prune -f

re:
	down up

.PHONY: generate-certs build up logs shell-back shell-front shell-db down clean re