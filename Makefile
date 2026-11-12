COMPOSE = docker compose -f srcs/docker-compose.yml
DATA_PATH = /home/msingh/data

all: up

prepare:
	mkdir -p $(DATA_PATH)/mariadb
	mkdir -p $(DATA_PATH)/wordpress



up: prepare
	$(COMPOSE) up -d --build

bonus: prepare_bonus
	$(COMPOSE) --profile bonus up -d --build

down:
	$(COMPOSE) --profile bonus down

stop:
	$(COMPOSE) --profile bonus stop

start:
	$(COMPOSE) start

start_bonus:
	$(COMPOSE) --profile bonus start

logs:
	$(COMPOSE) logs -f

logs_bonus:
	$(COMPOSE) --profile bonus logs -f

ps:
	$(COMPOSE) ps

ps_bonus:
	$(COMPOSE) --profile bonus ps

clean:
	$(COMPOSE) --profile bonus down --remove-orphans

fclean:
	$(COMPOSE) --profile bonus down -v --rmi all --remove-orphans
	sudo rm -rf $(DATA_PATH)/mariadb
	sudo rm -rf $(DATA_PATH)/wordpress

re: fclean all

re_bonus: fclean bonus

.PHONY: all prepare prepare_bonus up bonus down stop start start_bonus \
	logs logs_bonus ps ps_bonus clean fclean re re_bonus