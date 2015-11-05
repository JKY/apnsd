%%
%% apnsd_dev.erl 
%%
%% 
-module(apnsd_dev).
-include("apnsd.hrl").

%%
%% state
%%
-define(STATE_INIT,16#00).
-define(STATE_CONNECTED,16#01).
-define(STATE_WAITTING,16#02).
-define(STATE_JOINED,16#03).
-define(STATE_DISCONNECTED,16#04).
-define(STATE_WAITING_DISCONNECT,16#FE).
-define(STATE_ERR,16#FF).

%%
%% request
%%
-define(RQ_REDIRECT,16#0F).
-define(RQ_JOIN,16#01).
-define(RQ_ECHO,16#02).
-define(RQ_PUSH,16#03).
-define(RQ_TERM,16#04).
-define(RQ_LIMT,16#05).
-define(RQ_DUP,16#06).
%%
%% events
%%
-define(EVT_DEV_CONNECED,16#F0).
-define(EVT_DEV_JOIN,16#F1).
-define(EVT_DEV_EHCO,16#F2).
-define(EVT_DEV_RECV,16#F3).
-define(EVT_DEV_LEAVE,16#FF).
%% state 
-record(state, {
					id = nil,
                    ch ,
                    cn = nil,
                    sock,
                    curr = ?STATE_INIT,
                    err = no,
                    last_response = 0
               }).

-export([start_link/1, init/1]).
         
%% start link 
start_link( Listener ) ->
    Pid = spawn_link(?MODULE, init, [Listener]),
    {ok,Pid}.


% init 
init( Listener ) ->
    case gen_tcp:accept(Listener) of %% 5000
        {ok, Sock} ->
                apnsd_conn:open_dev(),
                inet:setopts(Sock, [{active, false}]),
                loop(#state{curr=?STATE_INIT,sock=Sock});
        {error, E} ->
                io:format("## device error:~s\n",[E]),
                apnsd_conn:open_dev()
            %    apnsd_trace:trap({err,accept,Reason})
    end,
    erlang:garbage_collect(self()).
    
%%
%%
%%
loop(S=#state{curr=?STATE_INIT}) ->
	{ok,S1} = event( ?EVT_DEV_CONNECED, S, [], nil),
    loop(S1);

loop(S=#state{curr=?STATE_WAITTING}) ->
     receive
       {ok,Ch} ->
            {_, Secs, _} = erlang:timestamp(),
            apnsd_trace:trap({dev_conncted,S#state.cn,S#state.id}),
            Next = S#state{curr=?STATE_JOINED,ch=Ch,last_response = Secs},
            loop(Next);
       dupd ->
            Next = S#state{err=dup},
            loop(Next);
       too_many ->
            Next = S#state{curr=?STATE_ERR,err=reach_limit},
            loop(Next);
       {kill,_} ->
            Next = S#state{curr=?STATE_ERR,err=killed},
            loop(Next)
     end;

    
loop( State=#state{err=no} ) ->
    %erlang:garbage_collect(self()),
    receive
        {push,Reporter,Data} ->
            {ok,Next} = event( ?RQ_PUSH, State , Reporter, Data),
            loop(Next);
        {error, Error} ->
        	?DEBUG_ERR(Error);
        {kill,_} ->
            Next = State#state{curr=?STATE_ERR,err=killed},
            loop(Next)
    after ?KEEP_ALIVE_INTERVAL -> 
    	{ok,Next} = event( ?RQ_ECHO, State , nil, nil),
        loop(Next)
    end;
    
    
loop( S=#state{ err = Reason ,last_response = LR }) ->
    erlang:garbage_collect(self()),
    apnsd_trace:trap({err,{c,S#state.cn,d,S#state.id,m,Reason}}),
    case Reason of
        reach_limit ->
            %% no capacity for this channel
            apnsd_pkt:write(S#state.sock,?RQ_LIMT,0,nil),
            apnsd_pkt:read(S#state.sock),
        	die(S);
        dup ->
            die(S);
        timeout ->
            {_, Now, _} = erlang:timestamp(),
            if Now - LR > ?ECHO_TIMEOUT/1000 ->
                loop(S#state{curr=?STATE_ERR,err=ping_timeout});
            true ->
                loop(S#state{err = no})
            end;
        killed ->
            die(S);
        _ ->
    	    die(S)
    end.
	


%%
%%
%%
event( ?EVT_DEV_CONNECED, S, _, _) ->
	apnsd_pkt:write(S#state.sock,?RQ_JOIN,0, nil),
    case apnsd_pkt:read(S#state.sock) of
        {pkt,?EVT_DEV_JOIN,_,Data} ->
            [ChStr,Dev] = Data, %% join channel
            Ch = binary_to_atom(ChStr,latin1),
            Id = binary_to_atom(Dev,latin1),
            apnsd_util:send_msg_to_process_byname(apnsd_channel,{join, Ch, {Id,self()}}),
            {ok,S#state{curr=?STATE_WAITTING,id=Id,cn=Ch}};
        {badmatch,_} ->
            {ok,S#state{curr=?STATE_ERR,err=badpkt}};
        {error,Reason} ->
            {ok,S#state{curr=?STATE_ERR,err=Reason}}
    end;



%	SERV_ADDR = apnsd_serv:host(),
%    	LOCAL_ADDR = apnsd_serv:local_addr(),
%	if  SERV_ADDR =:= LOCAL_ADDR -> 
%            apnsd_pkt:write(S#state.sock,?RQ_JOIN,0,[]),
%            case apnsd_pkt:read(S#state.sock) of
%                {pkt,?EVT_DEV_JOIN,_,Data} ->
%                    [Ch,Dev] = Data, %% join channel
%                    R = apnsd_channel:join(Ch,self()),
%                    case R of 
%                    	ok->
%                             apnsd_channel:nodup(Ch,Dev),
%                             {_, Secs, _} = erlang:timestamp(),
%                             Next = S#state{curr=?STATE_JOINED,id=Dev,last_response = Secs},
%                    		 MQ = apnsd_mq:pop(Dev),
%                    		 %lists:foreach(fun(N,Mess) ->
%                                 %  		  event( ?RQ_PUSH,Next,Mess )
%                             	 %	       end,MQ),
%                        	 {ok,Next};
%                        too_many->
%                        	 Next = S#state{curr=?STATE_ERR,err=reach_limit},
%                             {ok,Next}
%                    end;
%                {badmatch,_} ->
%                    {ok,S#state{curr=?STATE_ERR,err=badpkt}};
%                {error,Reason} ->
%                	{ok,S#state{curr=?STATE_ERR,err=Reason}}
%            end;
%    	true ->
%            {A,B,C,D} = SERV_ADDR,
%            ServHost = integer_to_list(A) ++ "." ++ integer_to_list(B) ++ "." ++ integer_to_list(C) ++ "." ++ integer_to_list(D),
%            apnsd_pkt:write(S#state.sock,?RQ_REDIRECT,0,[list_to_binary(ServHost)]),
%            {ok,S#state{curr=?STATE_WAITING_DISCONNECT}}
%    end;

event( ?RQ_ECHO, S , _, _) ->
    apnsd_pkt:write(S#state.sock,?RQ_ECHO,0, nil),
    case apnsd_pkt:read(S#state.sock) of
        {pkt,?EVT_DEV_EHCO,_,_} ->
        	{_, Secs, _} = erlang:timestamp(),
            {ok,S#state{last_response = Secs}};
        {badmatch,_} ->
        	{ok ,S#state{curr=?STATE_ERR,err=badpkt}};
        {error,Reason} ->
            {ok ,S#state{curr=?STATE_ERR,err=Reason}};
        _->
        	{ok, S}
    end;

event( ?RQ_PUSH, S=#state{curr=?STATE_JOINED}, nil, Data) ->
    case send(S,Data) of
        {ok,S1} ->
            apnsd_trace:trap({tx,{c,S#state.cn, d,S#state.id, m,Data}}),
            {ok,S1};
        {failed,S1} ->
            apnsd_trace:trap({tx_fail,{c,S#state.cn, d,S#state.id, m,Data}}),
            {ok,S1}
    end;

event( ?RQ_PUSH, S=#state{curr=?STATE_JOINED}, Reporter, Data) -> 
    case send(S,Data) of
        {ok,S1} ->
            apnsd_util:send_msg_to_process(Reporter,sent),
            apnsd_trace:trap({tx,{c,S#state.cn,d,S#state.id,m,Data}}),
            {ok,S1};
        {failed,S1} ->
            apnsd_util:send_msg_to_process(Reporter,failed),
            apnsd_trace:trap({tx_fail,{c,S#state.cn,d,S#state.id,m,Data}}),
            {ok,S1}
    end;

event(?RQ_PUSH, S , Reporter , _) ->
    case Reporter of 
        nil ->
            {ok,S};
        _ ->
            apnsd_util:send_msg_to_process(Reporter,failed),
            {ok,S}
    end.
%%
%%
%%
send( S, Data) ->
    apnsd_pkt:write(S#state.sock,?RQ_PUSH,0, Data),
    R = apnsd_pkt:read(S#state.sock),
    case R of
        {pkt,?EVT_DEV_RECV,_,_} ->
            {_, Secs, _} = erlang:timestamp(),
            {ok,S#state{last_response = Secs}};
        {badmatch,_} ->
            {failed,S#state{curr=?STATE_ERR,err=badpkt}};
        {error,timeout} ->
            {failed,S#state{curr=?STATE_ERR,err=timeout}};
        {error,Reason} ->
            {failed,S#state{curr=?STATE_ERR,err=Reason}}
    end. 

die(S)->
    gen_tcp:close(S#state.sock),
    if is_pid(S#state.ch) ->
        apnsd_util:send_msg_to_process(S#state.ch,{leave,S#state.id,self()});
    true ->
        ok
    end.

