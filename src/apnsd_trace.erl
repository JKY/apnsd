%%
%% apnsd_trace.erl 
%% Event Handler's chain 
%% 
-module(apnsd_trace).
-include("apnsd.hrl").
-export([start_link/0,loop/1,trap/1,add/2]).
%% start link 
start_link() ->
	Pid = spawn_link(apnsd_trace,loop,[[]]),
    register( apnsd_trace, Pid),
    {ok,Pid}.

%% main loop, receive message for registing and notify the handlers
loop(L) ->
    receive
        {regist, M, F} ->
            loop([{M,F}|L]);
        {trap, E} ->
            chain_process(L,E);
        _->
            ok
    end,
    loop(L).

%% process event by chains
chain_process([H|L],E) ->
    {M,F} = H,
    case erlang:apply(M,F,[E]) of 
        next ->
            chain_process(L,E);
        _->
            ok
    end;
chain_process([],_) -> failed.


%% regist handler
add(M,F)->
    apnsd_util:send_msg_to_process_byname(apnsd_trace,{regist,M,F}).

%% handle the Events
trap( E ) ->
   apnsd_util:send_msg_to_process_byname(apnsd_trace,{trap,E}).
