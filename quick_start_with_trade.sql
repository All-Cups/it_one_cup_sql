CREATE PROCEDURE find_deal(player_id INTEGER, parked_ship record) LANGUAGE PLPGSQL AS $$
DECLARE
    deal record;
BEGIN
    for deal in
        select
            items.name as name,
            seller.id as seller_id,
            buyer.id as buyer_id,
            least(seller.quantity, buyer.quantity, parked_ship.capacity) as quantity,
            least(seller.quantity, buyer.quantity, parked_ship.capacity) * (buyer.price_per_unit - seller.price_per_unit) as profit
        from world.contractors as seller
        join world.items as items
            on items.id = seller.item
        join world.contractors as buyer
            on seller.item = buyer.item
            and seller.type = 'vendor'
            and buyer.type = 'customer'
        left join world.contracts as contract
            on contract.player = player_id
            and contract.contractor = buyer.id
        where seller.island = parked_ship.island
            and contract.contractor is null
        order by profit desc
        limit 1

        loop
            raise notice '[PLAYER %] found deal on island %: buy "%" from % and sell to % (PROFIT = %)',
                player_id, parked_ship.island, deal.name, deal.seller_id, deal.buyer_id, deal.profit;

            insert into actions.offers (contractor, quantity) values (deal.seller_id, deal.quantity);
            insert into actions.offers (contractor, quantity) values (deal.buyer_id, deal.quantity);

            return;
        end loop;

    raise notice '[PLAYER %] ....... IDLE moving ship % from % to %',
        player_id, parked_ship.ship, parked_ship.island, parked_ship.island % 10 + 1;

    insert into actions.ship_moves (ship, destination)
    values (parked_ship.ship, parked_ship.island % 10 + 1);

END $$;

CREATE PROCEDURE think(player_id INTEGER) LANGUAGE PLPGSQL AS $$
DECLARE
    cur_time DOUBLE PRECISION;
    my_money DOUBLE PRECISION;

    parked_ship record;
    loading record;
    shipping record;
    unloading record;

    ship_sent BOOLEAN := false;
    transfer_started BOOLEAN := false;
BEGIN
    select game_time into cur_time from world.global;
    select money into my_money from world.players where id=player_id;
    raise notice '[PLAYER %] time: % and money: %', player_id, cur_time, my_money;
    for parked_ship in
        select
            ship,
            island,
            ships.capacity as capacity,
            ships.speed as speed
        from world.parked_ships
        join world.ships
            on ships.id = parked_ships.ship
            and ships.player = player_id
        limit 1
        loop
            -- событие = КОРАБЛЬ приплыл?
            for unloading in
                select
                    cargo.ship as ship,
                    cargo.item as item,
                    cargo.quantity as quantity
                from events.ship_move_finished as e
                inner join world.cargo as cargo
                    on cargo.ship = e.ship
                    and cargo.quantity > 0
                where e.ship = parked_ship.ship
                loop
                    -- в трюме есть товар - разгружаем
                    raise notice '[PLAYER %] ship_move_finished ---> ship % start to unloading % of item % on island %',
                        player_id, unloading.ship, unloading.quantity, unloading.item, parked_ship.island;

                    insert into actions.transfers (ship, item, quantity, direction)
                    values (unloading.ship,
                            unloading.item,
                            unloading.quantity,
                            'unload');
                    transfer_started := true;
                end loop;

            -- событие = ПОГРУЗКА завершена ?
            for shipping in
                select
                    cargo.item as item,
                    cargo.quantity as quantity,
                    customer.island as island
                from events.transfer_completed as e
                join world.cargo as cargo
                    on cargo.ship = e.ship
                    and cargo.quantity > 0
                join world.contractors as customer
                    on customer.item = cargo.item
                join world.contracts as contract
                    on contract.contractor = customer.id
                    and contract.player = player_id
                where e.ship = parked_ship.ship
                loop
                    -- загрузились - плывем к покупателю
                    raise notice '[PLAYER %] transfer_completed ---> sent ship % to island % with % of item %',
                        player_id, parked_ship.ship, shipping.island, shipping.quantity, shipping.item;

                    insert into actions.ship_moves (ship, destination)
                    values (parked_ship.ship,
                            shipping.island);

                    ship_sent := true;
                end loop;

            -- событие = ПРЕДЛОЖЕНИЕ принято ?
            for loading in
                select
                    vendor.item as item,
                    contract.quantity as quantity,
                    contract.id as id
                from events.contract_started as e
                join world.contracts as contract
                    on contract.id = e.contract
                    and contract.quantity > 0
                    and contract.player = player_id
                join world.contractors as vendor
                    on vendor.id = contract.contractor
                join world.storage as storage
                    on storage.item = vendor.item
                    and storage.quantity >= contract.quantity
                    and storage.island = parked_ship.island
                    and storage.player = player_id
                loop
                    -- на складе продавца есть товар - загружаем его в корабль
                    raise notice '[PLAYER %] contract_started #% ---> ship % start to loading % of item %',
                        player_id, loading.id, parked_ship.ship, loading.quantity, loading.item;

                    insert into actions.transfers (ship, item, quantity, direction)
                    values (parked_ship.ship,
                            loading.item,
                            loading.quantity,
                            'load');

                    transfer_started := true;
                end loop;

            -- если ничего еще не было сделано - ищем новую сделку
            if not ship_sent and not transfer_started
            then
                call find_deal(player_id, parked_ship);
            end if;

        end loop;
END $$;
