-module(br).
-export([start/0]).


start() ->
    % Switch uplink
    {ok, Br} = tuncer:create("erlbr", [tap, no_pi, {active, true}]),

    % Switch port
    {ok, Dev} = tuncer:create("erl0", [tap, no_pi, {active, true}]),

    switch(Br, [Dev]).

switch(Br, Dev) ->
    receive
        {tuntap, Br, Data} ->
            % Data received on uplink: flood to ports
            error_logger:info_report([{br, Br}, {data, Data}]),
            [ ok = tuncer:send(N, Data) || N <- Dev ],
            switch(Br, Dev);
        {tuntap, Port, Data} ->
            % Data received on port: flood to all other ports and uplink
            error_logger:info_report([{dev, Port}, {data, Data}]),
            [ ok = tuncer:send(N, Data) || N <- Dev ++ [Br], N =/= Port ],
            switch(Br, Dev);
        Error ->
            error_logger:error_report([{error, Error}])
    end.
