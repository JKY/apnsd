%%
%% apnsd_conn.erl 
%%
%% 

-module(apnsd_conn).
-behaviour(supervisor).
-include("apnsd.hrl").

-export([start_link/0,start_sock/0]).
-export([init/1]).

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).
    

init([]) ->
    {ok,Port} = application:get_env(port),
    {ok,ListenSocket} = gen_tcp:listen(Port,[binary,{active,false},{reuseaddr, true}]),
    spawn_link(fun empty_listeners/0),
    {ok, {{simple_one_for_one, 60, 3600},
         [
         	{socket,
          	{apnsd_dev, start_link, [ ListenSocket ]},
          	temporary, 1000, worker, [ apnsd_dev ]}
         ]}}.
         
start_sock() ->
    supervisor:start_child(?MODULE, []).
             
    
empty_listeners() ->
	{ok,MAX_QUEQUE} =  application:get_env(mc),
    [start_sock() || _ <- lists:seq(1,MAX_QUEQUE)],
    ok.
