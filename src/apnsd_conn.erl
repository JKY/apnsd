%%
%% apnsd_conn.erl 
%%
%% 

-module(apnsd_conn).
-behaviour(supervisor).
-include("apnsd.hrl").

-export([start_link/0,open_dev/0]).
-export([init/1]).

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).
    

init([]) ->
    io:format("apnsd conn init!\n"),
    {ok,Port} = application:get_env(port),
    {ok,Sock} = gen_tcp:listen(Port,[binary,{active,false},{reuseaddr, true}]),
    spawn_link(fun init_Q/0),
    {ok, {{simple_one_for_one, 0, 10},
         [{socket,{apnsd_dev, start_link, [Sock]},temporary, 1000, worker, [ apnsd_dev ]}]}
    }.
         

open_dev() ->
    %%% apnsd_dev start_link 
    supervisor:start_child(?MODULE, []).
             
    
init_Q() ->
    io:format("apnsd_conn init_Q!\n"),
	{ok,MAX_QUEQUE} =  application:get_env(maxq),
    [open_dev() || _ <- lists:seq(1,MAX_QUEQUE)],
    ok.
