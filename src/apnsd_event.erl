%%
%% ansd_event.erl 
%% handler device events, offline message
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
    
%% handle services 
handle_event() ->
    receive 
        { enqueue, Ch,Dev,Data} ->
            apnsd_mq:push(Ch,Dev,Data);
        { online, Ch, Dev } ->
            Self = self(),
            spawn(fun()-> 
                    apnsd_mq:pop(Self,Ch,Dev)
                  end);
        { dequeue,C,D,L} ->
            spawn(fun()-> deq(C,D,L) end);
        _->
            ok
    end,
    handle_event().

%% enqueue message when device not online 
pf({enqueue,Ch,Dev,Data}) -> 
    apnsd_util:send_msg_to_process_byname(
        ?MODULE,
        {enqueue, Ch, Dev,Data}
    );
pf(_) -> next.


%% called by apnsd_dev when device online 
ej({dev_conncted,Ch,Dev}) ->
    spawn(fun()-> 
        case apnsd_util:gwait(?MODULE,1) of 
            ok ->
                L = pg2:get_members(?MODULE),
                lists:foldl(
                        fun(N,M) ->
                            apnsd_util:send_msg_to_process_byname(N, M),
                            M
                        end,
                        {online,Ch,Dev},L);
            timeout ->
                ok
        end
    end);

ej(_)-> next.



%% dequeue message when device online 
deq(Ch,Dev,[{m,D}|L])-> 
  apnsd_util:send_msg_to_process_byname(apnsd_api,{self(),push,{Ch,Dev,D}}),
  timer:sleep(999),
  deq(Ch,Dev,L);

deq(_,_,[])-> ok.
 