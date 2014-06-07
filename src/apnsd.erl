%%
%% apnsd.erl 
%%
%% 
-module(apnsd).
-behaviour(application).
-export([start/0,start/2,stop/1,init/0]).

start() ->
	init().

start(_StartType,_Args) ->
    init().

stop(_State) ->
 	ok.
 
%%
%%
%%
init()->
	application:start(mongodb),
	net_adm:world(),
	pg2:start(),
 	apnsd_sup:start_link().

