%%
%% ansd_mq.erl 
%% 
-module(apnsd_mq).
-include("apnsd.hrl").
-export([start_link/0,push/3,pop/3]).

-record(context, {
                  mgn_conn_pool,
                  db_name
               }).

start_link()->
    %{ok,DB_HOST} =  application:get_env(db_host),
    %{ok,DB_PORT} =  application:get_env(db_port),
    %{ok,DB_NAME} =  application:get_env(db_name),
    DB_HOST = localhost,
    DB_PORT = 27017,
    DB_NAME = apnsd,
    Pid = spawn_link(fun() ->
                        Ctx = #context{
                                   mgn_conn_pool = resource_pool:new (mongo:connect_factory({DB_HOST,DB_PORT}), 15),
                                   db_name = DB_NAME 
                            },
                        register( ?MODULE, self()),
                        loop(Ctx),
                        resource_pool:close(Ctx#context.mgn_conn_pool)
                      end),
    {ok,Pid}.

%%
%%
%%
loop(Ctx) ->
    receive 
        {push,Ch,Dev,M} ->
            TS = apnsd_util:tsnow(),
            save_m(Ctx,mqueue,Ch,Dev,M,TS);
        {pop,Sender,C,D}->
            case flush_m(Ctx,mqueue,C,D) of
              {ok,L} ->
                  apnsd_util:send_pm(Sender,{poped,C,D,L});
              _ ->
                ok
            end;
        _->
            ok
    end,
    loop(Ctx).



push(Ch, Dev, Data) ->
    apnsd_util:send_pm_byname(?MODULE,{push,Ch,Dev,Data}),
    ok.
%% event call
pop(Sender,Ch,Dev)-> 
    apnsd_util:send_pm_byname(?MODULE,{pop,Sender,Ch,Dev}).


%%
%%
%%
save_m(Ctx,DB,Ch,Dev,Data,T)->
  case resource_pool:get(Ctx#context.mgn_conn_pool) of 
    {ok,Conn} ->
        mongo:do(safe, master, Conn, Ctx#context.db_name, 
              fun () ->
                mongo:insert(DB,{c,Ch,d,Dev,m,Data,t,T})
              end
        );
    _->
        ok
  end.

flush_m(Ctx,DB,Ch,Dev)->
  case resource_pool:get(Ctx#context.mgn_conn_pool) of 
    {ok,Conn} ->
        mongo:do(safe, master, Conn, Ctx#context.db_name, 
              fun () ->
                Cur = mongo:find(DB,{c,Ch,d,Dev},{'_id',0,m,1}),
                R = mongo:rest (Cur),
                mongo:delete(DB,{c,Ch,d,Dev}),
                R
              end
        );
    _->
        []
  end.
