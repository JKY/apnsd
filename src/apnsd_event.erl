%%
%% ansd_mq.erl 
%% 
-module(apnsd_event).
-include("apnsd.hrl").
-export([start_link/0,ej/1,pf/1]).


start_link()->
    P = spawn_link(fun() ->
                        handle_event()
                      end),
    pg2:create(?MODULE),
    pg2:join(?MODULE,P),
    register(?MODULE,P),
    %% add a trap
    apnsd_trace:add(?MODULE,ej),
    apnsd_trace:add(?MODULE,pf),
    {ok,P}.
    
%%
%%
%%
handle_event() ->
    receive 
        { q, Ch,Dev,Data} ->
            apnsd_mq:push(Ch,Dev,Data);
        { join, Ch, Dev } ->
            Self = self(),
            spawn(fun()-> apnsd_mq:pop(Self,Ch,Dev) end);
        { poped,C,D,L} ->
            spawn(fun()-> deq(C,D,L) end);
        _->
            ok
    end,
    handle_event().

%%
%%
%%
pf({mq,Ch,Dev,Data}) -> apnsd_util:send_pm_byname(?MODULE,{q, Ch, Dev,Data});
pf(_) -> next.

%%
%%
%%
deq(Ch,Dev,[{m,D}|L])-> 
  apnsd_util:send_pm_byname(apnsd_daemon,{self(),push,{Ch,Dev,D}}),
  timer:sleep(999),
  deq(Ch,Dev,L);
deq(_,_,[])-> ok.

%%
%%
%%
ej({dev_conncted,Ch,Dev}) ->
    spawn(fun()-> 
        case apnsd_util:gwait(?MODULE,1) of 
            ok ->
                L = pg2:get_members(?MODULE),
                lists:foldl(
                        fun(N,M) ->
                            apnsd_util:send_pm_byname(N, M),
                            M
                        end,
                        {join,Ch,Dev},
                        L
                      );
            timeout ->
                ok
        end
    end);
ej(_)-> next.

 