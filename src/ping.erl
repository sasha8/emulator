-module(ping).
-behaviour(gen_server).



-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2,handle_info/2,terminate/2,code_change/3]).
-export([ping/2, ping_all/1]).




ping_all(Max) ->
    [ping(list_to_atom("host"++integer_to_list(I)), list_to_atom("host"++integer_to_list(J)))||I<-lists:seq(1,Max),J<-lists:seq(1,Max),I=/=J].


ping(Host1,Host2)->
    Host1_gateway=list_to_atom(atom_to_list(Host1)++"_ingress"),
    Host2_gateway=list_to_atom(atom_to_list(Host2)++"_ingress"),
    
    start_link({Host2, receiver, Host1, Host2_gateway,1}),  %% set up receiver
    start_link({Host1, sender, Host2, Host1_gateway,1}).  %% set up receiver


start_link({Name, Type, Dest, Gateway,Total})->   % %the name is maybe unnecessary 
		gen_server:start_link({global,Name},ping,[{Name, Type,Dest,  Gateway,Total}],[]).

		
		
init([{Name, Type,Dest,  Gateway,Total}])->
			%io:fwrite("remote host ~s: init\n",[Name]),
			% net_adm:ping('main@Lenovo-THINK').  need to change every time we run on different machine 
            %io:fwrite("remote host is ~p ~n", [global:whereis_name(Gateway)]),
            gen_server:call(global:whereis_name(Gateway),{handshake}),  % todo: add try catch here
            Start=0,   % start time
            Sent=0,
            {ok,{Name, Type,Dest,  Gateway,Total,Sent,Start},0}.  
                                                            % Type: 1-sender, 0-receiver


handle_call(_Request,_From,State)->{noreply, State}.

handle_cast(Msg,State)->my_handle_cast(Msg,State).

handle_info(_Info,State)->my_handle_info(_Info,State).

terminate(_Reason,_State)->ok.

code_change(_Oldvsn, _State, _Extra)->{ok, state}.

% message format
% {Dst,Size,Maxhops,Mode,Payload}
% Payload format:
% {Src,Data,Time_list}

%% regular timout:    
my_handle_info(timeout,{Name, sender,Dest,  Gateway,Total,Sent, _Start})-> 
	Message={Dest,0,10,regular,{host1,ping,[]}},  %% ping message format
    %Message= {Dest,Name, {ping,0}}, 
    Start=erlang:now(),
    gen_server:cast(global:whereis_name(Gateway),Message),
   % io:fwrite("~s: sent packet 0 \n",[Name]),

    {noreply,{Name, sender,Dest,  Gateway,Total,Sent+1,Start},infinity};


% default:
my_handle_info(_Info,State)->{noreply, State}.    
    
    
%% receive last pong:    
my_handle_cast({_,_Size,_Maxhops,_Mode,{_Src,pong,_Time_list}},{Name, sender,Dest,  Gateway,Total,Total,Start})-> 
    End=erlang:now(),
    Avg_time=timer:now_diff(End,Start)/(Total*1000000),
    io:fwrite("~s: ping-pong time: ~p sec\n",[Name, Avg_time]),
    {stop,normal,{Name, sender,Dest,  Gateway,Total,Total,Start}};

%% receive pong:
my_handle_cast({_,Size,_Maxhops,_Mode,{_Src,pong,Time_list}},{Name, sender,Dest,  Gateway,Total,Sent,Start})-> 
    Message={Dest,Size,10,regular,{host1,ping,Time_list}},  % src=gateway  
	%Message= {Dest,Name, {ping,Size}}, %% ping message format
    gen_server:cast(global:whereis_name(Gateway),Message),
   %  io:fwrite("~s: sent packet ~p\n",[Name,Sent]),
    {noreply,{Name, sender,Dest,  Gateway,Total,Sent+1,Start}};

    
%% create pong/receive ping:    
my_handle_cast({_,Size,_Maxhops,_Mode,{_Src,ping,Time_list}},{Name, receiver,Dest,  Gateway,Total,Sent,Start})-> 
    % io:fwrite("~s: packet recieved 0 \n",[Name]),
	Message={Dest,Size,10,regular,{host2,pong,Time_list}},  % src=gateway 
    %Message= {Src,Name, {pong,Size}}, %% pong message format
    gen_server:cast(global:whereis_name(Gateway),Message),
    {noreply,{Name, receiver,Dest,  Gateway,Total,Sent,Start}};
    
my_handle_cast(Message,{Name, Type,Dest,  Gateway,Total,Total,Start})-> 
    io:fwrite("~s: illegal packet ~p \n",[Name, Message]),
    {noreply,{Name, Type,Dest,  Gateway,Total,Total,Start}}.
    
    
    

    
  
