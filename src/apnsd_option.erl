%%
%% apnsd_option.erl 
%%
%% 
-module(apnsd_option).
-include("apnsd.hrl").
-export([channel_capacity/1]).
%%
%%
%%
channel_capacity(Name) ->
    {ok,DB_HOST} =  application:get_env(db_host),
    {ok,DB_PORT} =  application:get_env(db_port),
    {ok,DB_NAME} =  application:get_env(db_name),
    %DB_HOST = localhost,
    %DB_PORT = 27017,
    %DB_NAME = apnsd,
    case mongo_connect:connect ({DB_HOST, DB_PORT}) of
		{ok,Conn} ->
			 R = mongo:do(unsafe, master, Conn, DB_NAME, 
			    	fun () ->
						mongo:find_one(channel,{name,Name})
					end
				 ),
			 mongo:disconnect(Conn),
			 case R of 
			 	{ok, Result} ->
		            case Result of
		                {Doc} -> 
		                	{N} = bson:lookup(cap,Doc),
		                	{T} = bson:lookup(type,Doc),
		                	{binary_to_atom(T,latin1),list_to_integer(binary_to_list(N))};
		                {} -> 
		                	{'PRO',20000}
		            end;
		        _ -> {'PRO',1}
			 end;
		_->
			{'PRO',0}
	end.

%    SQL = "select sum(conn) from apns_order where ch='" ++ atom_to_list(Ch) ++ "' and expired > now();",
%    case mysql:fetch(p,list_to_binary(SQL)) of
%        {data,{mysql_result,_,[A|_],_,_}} ->
%            [CLimit] = A,
%            CLimit;
%        _->
%            -1
%    end.
        
