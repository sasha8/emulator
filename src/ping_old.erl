-module(ping_old).
-behaviour(gen_server).





-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2,handle_info/2,terminate/2,code_change/3]).


start_link({Name, Type, Dest, Next_hop})->
		gen_server:start_link({global,Name},ping,[{Name, Type,Dest,  Next_hop}],[]).

		
		
init([{Name, Type,Dest,  Next_hop}])->
			io:fwrite("host ~s: init\n",[Name]),
            {ok,{Name, Type,Dest,  Next_hop,10,0,0},500}.  % 10: total sends, 0: accumulated sends, 0: accumulated acks
                                                            % Type: 1-sender, 0-receiver


handle_call(_Request,_From,State)->{noreply, State}.

handle_cast(Msg,State)->my_handle_cast(Msg,State).

handle_info(_Info,State)->my_handle_info(_Info,State).

terminate(_Reason,_State)->ok.

code_change(_Oldvsn, _State, _Extra)->{ok, state}.





%% Last timeout:
my_handle_info(timeout,{Name, 1,Dest,  Next_hop,Total,Total,Acked})-> 
    io:fwrite("Done with ~p of packets received .\n",[Acked/Total]),
    {stop,normal,{Name, 1,Dest,  Next_hop,Total,Total,Acked}}; 

%% regular timout:    
my_handle_info(timeout,{Name, 1,Dest,  Next_hop,Total,Sent,Acked})-> 
    Message= {Dest,Name, {ping,0}}, %% ping message format
    gen_server:cast(global:whereis_name(Next_hop),Message),
    % io:fwrite("~s: ping ~p \n",[Name, Sent]),
    {noreply,{Name, 1,Dest,  Next_hop,Total,Sent+1,Acked},500};

% default:
my_handle_info(_Info,State)->{noreply, State}.    
    
    
%% receive pong:    
my_handle_cast({_Dest,_Name, {pong,_Size}},{Name, Type,Dest,  Next_hop,Total,Sent,Acked})-> 
    % io:fwrite("~s: pong ~p \n",[Name, Acked]),
    {noreply,{Name, Type,Dest,  Next_hop,Total,Sent,Acked+1},500};
    
%% create pong:    
my_handle_cast({Name,Src, {ping,_Size}},{Name, Type,Dest,  Next_hop,Total,Sent,Acked})-> 
    % io:fwrite("~s: got ping from ~p \n",[Name, Src]),
    Message= {Src,Name, {pong,0}}, %% pong message format
    gen_server:cast(global:whereis_name(Next_hop),Message),
    {noreply,{Name, Type,Dest,  Next_hop,Total,Sent,Acked},500};
    
my_handle_cast(_Message,State)-> 
    % io:fwrite("illegal message ~p \n",[Message]),
    {noreply,State}.
    