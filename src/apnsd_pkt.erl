%%
%% apnsd_pkt.erl 
%%
%% 
-module(apnsd_pkt).
-include("apnsd.hrl").
-export([read/1, write/4, pkt_param/2, bsplit/3]).
-define( MF_START,16#05).
   
    
%%
%% read pkt 
%%
read( Sock )->
	case gen_tcp:recv(Sock,4,?READ_TIMEOUT) of
    	{ok, Data } ->
        	try hdr(Data) of
            	{ok,CMD,OPT,BLK_C} ->
                    case read_param(Sock,[],BLK_C) of
                        {ok, Param} ->
                            {pkt, CMD, OPT, Param};
                        {error, Reason} ->
                            {error, Reason}
                    end
            catch
            	error:{badmatch, V} ->
                	{badmatch,V}
            end;
        {error, Reason} ->
           {error, Reason}
    end.

hdr(Data)->
    <<?MF_START,CMD:8,OPT:8,BLK_C:8>>=Data,
    {ok,CMD,OPT,BLK_C}.
    
%%
%% send pkt
%%
write( Sock, CMD , OPT,  nil ) ->
    Hdr = [?MF_START, CMD, OPT,0],
    case gen_tcp:send(Sock,list_to_binary(Hdr)) of
        ok -> 
            {ok};
        {error,Reason} ->
            {error,Reason}  
    end;

write( Sock, CMD , OPT,  Bin ) ->
    Blocks = bsplit(Bin,byte_size(Bin),[]),
	BLK_C = length(Blocks),
    Hdr = [?MF_START, CMD, OPT,BLK_C],
    case pkt_param(Blocks,[]) of
    	{ok, List} ->
        	Data = Hdr ++ List,
            case gen_tcp:send(Sock,list_to_binary(Data)) of
            	ok -> 
                	{ok};
                {error,Reason} ->
               		{error,Reason} 	
            end;
        {error,Reason} -> 
    		{error,Reason}
    end.
    
   


%%
%% util functions
%%    
pkt_param([H|T],List)->
    L = byte_size(H),
    pkt_param(T,[H,L|List]); %List++[L,H]

pkt_param([],List)->
    {ok, lists:reverse(List)}.
 




%%
%% split binary to blocks 
%%
bsplit( Bin, N, List ) when N > 255 ->
    <<B:255/binary,R/binary>> = Bin,
    bsplit(R, byte_size(R), [B|List]);

bsplit( Bin, N, List ) when N > 0,N =< 255 ->
    bsplit(none, 0, [Bin|List]);

bsplit( _, N, List ) when N =:= 0 ->
    lists:reverse( List ).





%%
%%
%%
%%
read_param( Sock, List , N) when N > 0 ->
	case gen_tcp:recv(Sock,1,?READ_TIMEOUT) of 
    	{ok, Len} ->
        	<<L:8>> = Len,
        	case gen_tcp:recv(Sock,L,?READ_TIMEOUT) of
            	{ok, Data} ->
                	read_param(Sock,[Data|List],N-1);
                {error,Reason} -> 
                	{error, Reason}
            end;
        {error,Reason} -> 
                	{error, Reason}
    end;
    
read_param( _, List , 0) ->
	{ok,lists:reverse(List)}.	



