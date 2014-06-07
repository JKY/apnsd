%%
%% apnsd_trace.erl 
%%
%% 
-module(apnsd_trace).
-include("apnsd.hrl").
-export([start_link/0,loop/1,trap/1,add/2]).

start_link() ->
	Pid = spawn_link(apnsd_trace,loop,[[]]),
    register( apnsd_trace, Pid),
    {ok,Pid}.

add(M,F)->
    apnsd_util:send_pm_byname(apnsd_trace,{regist,M,F}).


loop(L) ->
	receive
    	{regist, M, F} ->
            loop([{M,F}|L]);
        {trap, Data} ->
        	classify(L,Data);
        _->
        	ok
    end,
    loop(L).


%%
%%
%%
classify([H|L],Data) ->
	{M,F} = H,
	case erlang:apply(M,F,[Data]) of 
		next ->
			classify(L,Data);
		_->
			ok
	end;

classify([],Data) -> failed.


%%
%%
%%
trap( Evt ) ->
   apnsd_util:send_pm_byname(apnsd_trace,{trap,Evt}).
