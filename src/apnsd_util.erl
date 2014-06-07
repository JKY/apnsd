%%
%% apnsd_util.erl 
%%
%% 
-module(apnsd_util).
-export([gwait/2,send_pm/2,send_pm_byname/2,tsnow/0]).

gwait(G,Tries) when Tries > 0 ->
    pg2:which_groups(),
    case pg2:which_groups() of
        L when is_list(L) ->
            case lists:member(G, L) of
                true ->
                    ok;
                _ ->
                    timer:sleep(499),
                    gwait(G,Tries - 1)
            end;
        _ ->
            timer:sleep(499),
      gwait(G,Tries - 1)
    end;
    
gwait(_,Tries) when Tries == 0 ->
	timeout.

send_pm(P,M) ->
    case is_pid(P) of
        true ->
            P ! M;
        _ ->
            ok
    end.

send_pm_byname(Npro,M) ->
    try
        Npro ! M
    catch
        % registered process To is unavailable,
        X:Reason -> %exit: {badarg, _}
            ok % dbg only
    end.

tsnow()->
    {Mega, Secs, _} = now(),
    Mega*1000000 + Secs.
	