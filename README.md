## Часто задаваемые вопросы (FAQ)

Смотри [FAQ](faq.md)

## Локальный запуск

Скачивание контейнера:

```sh
docker pull ghcr.io/all-cups/it_one_cup_sql
```

Запуск (с одним игроком и пустым решением):

```sh
docker run --rm -it ghcr.io/all-cups/it_one_cup_sql
```

Настройки мира лежат в [options.toml](options.toml)

Ваше решение можно передать через stdin с помощью аргумента `--solution -`
(вместо `-` можно указать путь к файлу, но в таком случае нужно чтобы он был доступен контейнеру):

```sh
cat solution.sql | docker run --rm -i ghcr.io/all-cups/it_one_cup_sql --solution -
```

Контейнер завершится, как только игра закончится.
Если хочется посмотреть в базу после окончания игры, можно использовать аргумент `--leave-running`.

Внутри контейнера поднимается база для создания логов на порту 5432,
а также по базе на каждое решение на портах 5433, 5434 и тд.

При желании можно пробросить нужный порт для соединения с базой снаружи:

```sh
docker run --rm -it -p 5433:5433 ghcr.io/all-cups/it_one_cup_sql --leave-running
```
Либо запустить `psql` изнутри запущенного контейнера:
```
docker exec -it <container_name> psql --host localhost --port 5433 --username postgres postgres
```

Фиксирование сида возможно с помощью переменной окружения `SEED`:

```sh
docker run --rm -it -e SEED=123 ghcr.io/all-cups/it_one_cup_sql
```

Другие доступные параметры запуска контейнера можно увидеть с помощью параметра `--help`:

```sh
docker run --rm -it ghcr.io/all-cups/it_one_cup_sql --help
```

## Пример локального запуска 

Для двух решений с сохранением содержимого init.sql и передачей своего файла настроек мира.

### MacOS / Linux:
```shell
docker run \
  --mount "type=bind,src=$(pwd)/my-solution.sql,dst=/tmp/player1-solution.sql" \
  --mount "type=bind,src=$(pwd)/quick_start.sql,dst=/tmp/player2-solution.sql" \
  --mount "type=bind,src=$(pwd)/init.sql,dst=/tmp/init.sql" \
  --mount "type=bind,src=$(pwd)/my-options.toml,dst=/tmp/options.toml" \
  --rm -it -e SEED=123456 ghcr.io/all-cups/it_one_cup_sql \
  --solution /tmp/player1-solution.sql \
  --solution /tmp/player2-solution.sql \
  --dump-init /tmp/init.sql \
  --options /tmp/options.toml \
  --log INFO   
```

### Windows:
```
docker run ^
  --mount "type=bind,src=%cd%/my-solution.sql,dst=/tmp/player1-solution.sql" ^
  --mount "type=bind,src=%cd%/quick_start.sql,dst=/tmp/player2-solution.sql" ^
  --mount "type=bind,src=%cd%/init.sql,dst=/tmp/init.sql" ^
  --mount "type=bind,src=%cd%/my-options.toml,dst=/tmp/options.toml" ^
  --rm -it -e SEED=123456 ghcr.io/all-cups/it_one_cup_sql ^
  --solution /tmp/player1-solution.sql ^
  --solution /tmp/player2-solution.sql ^
  --dump-init /tmp/init.sql ^
  --options /tmp/options.toml ^
  --log INFO   
```
Обратите внимание, что в этом примере:
* `$(pwd)` / `%cd%`- это текущий каталог хост машины
* Файл `init.sql` должен существовать _перед_ запуском (он будет перезаписан)
* Параметр `--log INFO` можно заменить на `--log DEBUG` для детализации ошибок

## Просмотр дампа игры

Пример просмотра дампа игры с помощью докера:

1. Поднять базу данных: `docker run --rm --detach --name dump-explorer --env POSTGRES_PASSWORD=verysecret postgres`
2. Загрузить дамп: `docker exec -i dump-explorer pg_restore --dbname postgres --username postgres < game.dump`
4. Подключиться к базе: `docker exec -it dump-explorer psql --host localhost --username postgres postgres`
5. Получить нужную информацию: `select * from final_world.players;`
6. Остановить контейнер: `docker stop dump-explorer`
