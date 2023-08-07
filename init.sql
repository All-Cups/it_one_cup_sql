--  Текущее состояние игрового мира
CREATE SCHEMA world;
--  Глобальные значения. Данная таблица имеет ровно одну строку
CREATE TABLE "world"."global" (
    "game_time" DOUBLE PRECISION NOT NULL, --  Текущее игровое время
    "map_size" DOUBLE PRECISION NOT NULL --  Размер карты
);
--  Игроки - участники игры
CREATE TABLE "world"."players" (
    "id" SERIAL PRIMARY KEY NOT NULL, --  Уникальный идентификатор
    "money" DOUBLE PRECISION NOT NULL --  Текущее количество денег
);
--  Корабли
CREATE TABLE "world"."ships" (
    "id" SERIAL PRIMARY KEY NOT NULL, --  Уникальный идентификатор
    "player" INTEGER NOT NULL, --  Игрок, которому принадлежит корабль
    "speed" DOUBLE PRECISION NOT NULL, --  Скорость перемещения
    "capacity" DOUBLE PRECISION NOT NULL --  Вместимость трюма
);
--  Содержание трюмов кораблей
CREATE TABLE "world"."cargo" (
    "ship" INTEGER NOT NULL, --  Корабль
    "item" INTEGER NOT NULL, --  Тип товара
    "quantity" DOUBLE PRECISION NOT NULL --  Количество данного товара в трюме данного корабля
);
--  Припаркованные корабли
CREATE TABLE "world"."parked_ships" (
    "ship" INTEGER NOT NULL, --  Корабль
    "island" INTEGER NOT NULL --  Остров, на котором припаркован корабль
);
--  Движущиеся корабли
CREATE TABLE "world"."moving_ships" (
    "ship" INTEGER NOT NULL, --  Корабль
    "start" INTEGER NOT NULL, --  Остров отправления
    "destination" INTEGER NOT NULL, --  Целевой остров
    "arrives_at" DOUBLE PRECISION NOT NULL --  Момент прибытия
);
--  Корабли, занятые погрузкой/разгрузкой
CREATE TABLE "world"."transferring_ships" (
    "ship" INTEGER NOT NULL, --  Корабль
    "island" INTEGER NOT NULL, --  Остров
    "finish_time" DOUBLE PRECISION NOT NULL --  Время окончания погрузки/разгрузки
);
--  Острова
CREATE TABLE "world"."islands" (
    "id" SERIAL PRIMARY KEY NOT NULL, --  Уникальный идентификатор
    "x" DOUBLE PRECISION NOT NULL, --  Координата по горизонтали
    "y" DOUBLE PRECISION NOT NULL --  Координата по вертикали
);
--  Склады игроков на островах
CREATE TABLE "world"."storage" (
    "player" INTEGER NOT NULL, --  Игрок
    "island" INTEGER NOT NULL, --  Остров
    "item" INTEGER NOT NULL, --  Тип товара
    "quantity" DOUBLE PRECISION NOT NULL --  Количество данного типа товара на складе
);
--  Контрагенты
CREATE TYPE "world"."contractor_type" AS ENUM ('vendor', 'customer');
CREATE TABLE "world"."contractors" (
    "id" SERIAL PRIMARY KEY NOT NULL, --  Уникальный идентификатор
    "type" "world"."contractor_type" NOT NULL, --  Тип контрагента
    "island" INTEGER NOT NULL, --  Остров
    "item" INTEGER NOT NULL, --  Товар, который покупает/продает данный контрагент
    "quantity" DOUBLE PRECISION NOT NULL, --  Текущий спрос/предложение - максимальное количество товара при заключении контракта
    "price_per_unit" DOUBLE PRECISION NOT NULL --  Текущая цена за единицу товара
);
--  Предметы
CREATE TABLE "world"."items" (
    "id" SERIAL PRIMARY KEY NOT NULL, --  Уникальный идентификатор
    "name" TEXT NOT NULL --  Название товара
);
--  Контракты
CREATE TABLE "world"."contracts" (
    "id" SERIAL PRIMARY KEY NOT NULL, --  Уникальный идентификатор
    "player" INTEGER NOT NULL, --  Игрок, с которым заключен контракт
    "contractor" INTEGER NOT NULL, --  Контрагент
    "quantity" DOUBLE PRECISION NOT NULL, --  Договоренное количество товара
    "payment_sum" DOUBLE PRECISION NOT NULL --  Договоренная оплата по контракту
);

--  События, произошедшие с последнего вызова вашей логики
CREATE SCHEMA events;
--  Завершение действия ожидания
CREATE TABLE "events"."wait_finished" (
    "time" DOUBLE PRECISION NOT NULL, --  Время, когда произошло событие
    "wait" INTEGER NOT NULL --  Идентификатор действия
);
--  Завершение движения корабля
CREATE TABLE "events"."ship_move_finished" (
    "time" DOUBLE PRECISION NOT NULL, --  Время, когда произошло событие
    "ship" INTEGER NOT NULL --  Припарковавшийся корабль
);
--  Завершение погрузки/разгрузки корабля
CREATE TABLE "events"."transfer_completed" (
    "time" DOUBLE PRECISION NOT NULL, --  Время, когда произошло событие
    "ship" INTEGER NOT NULL --  Корабль
);
--  Успешное заключение контракта
CREATE TABLE "events"."contract_started" (
    "time" DOUBLE PRECISION NOT NULL, --  Время, когда произошло событие
    "offer" INTEGER NOT NULL, --  Предложение
    "contract" INTEGER --  Контракт, который был начат. Может отсутствовать, если контракт также мгновенно завершился - при покупке.
);
--  Отклоненные предложения
CREATE TABLE "events"."offer_rejected" (
    "time" DOUBLE PRECISION NOT NULL, --  Время, когда произошло событие
    "offer" INTEGER NOT NULL --  Предложение
);
--  Успешно завершенные контракты
CREATE TABLE "events"."contract_completed" (
    "time" DOUBLE PRECISION NOT NULL, --  Время, когда произошло событие
    "contract" INTEGER NOT NULL --  Контракт, который был завершен
);

--  Действия, которые вы желаете сделать. Данную схему вам предстоит заполнять данными.
CREATE SCHEMA actions;
--  Действия перемещения
CREATE TABLE "actions"."ship_moves" (
    "ship" INTEGER NOT NULL, --  Корабль
    "destination" INTEGER NOT NULL --  Целевой остров
);
--  Ожидание
CREATE TABLE "actions"."wait" (
    "id" SERIAL PRIMARY KEY NOT NULL, --  Идентификатор действия
    "until" DOUBLE PRECISION NOT NULL --  Момент времени в который ожидание должно закончиться
);
--  Предложения сделок с контрагентами
CREATE TABLE "actions"."offers" (
    "id" SERIAL PRIMARY KEY NOT NULL, --  Идентификатор предложения
    "contractor" INTEGER NOT NULL, --  Контрагент
    "quantity" DOUBLE PRECISION NOT NULL --  Количество покупаемого/продаваемого товара
);
--  Погрузка/разгрузка кораблей
CREATE TYPE "actions"."transfer_direction" AS ENUM ('load', 'unload');
CREATE TABLE "actions"."transfers" (
    "ship" INTEGER NOT NULL, --  Корабль, на/с которого переносить товар
    "item" INTEGER NOT NULL, --  Тип товара, который нужно переносить
    "quantity" DOUBLE PRECISION NOT NULL, --  Количество товара, которое нужно перенести
    "direction" "actions"."transfer_direction" NOT NULL --  Направление - погрузка/разгрузка
);