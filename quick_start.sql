create procedure moveToTheNextIsland(player_id integer, ship_id integer, island_id integer) as $$
begin
    raise notice '[P-LAYER %] MOVING SHIP % TO ISLAND %', player_id, ship_id, island_id;
    insert into actions.ship_moves (ship, destination) values (ship_id, island_id);
end
$$ language plpgsql;

CREATE PROCEDURE think(player_id INTEGER) LANGUAGE PLPGSQL AS $$
declare
    currentTime double precision;
    myMoney double precision;
    ship record;
BEGIN
    select game_time into currentTime from world.global;
    select money into myMoney from world.players where id=player_id;
    raise notice '[PLAYER %] time: % and money: %', player_id, currentTime, myMoney;
    for ship in
        select
            ships.id as ship,
            island
        from world.ships
        join world.parked_ships
            on ships.id=parked_ships.ship
            and ships.player=player_id
        loop
            call moveToTheNextIsland(player_id, ship.ship, ship.island % 10 + 1);
        end loop;
END $$;
