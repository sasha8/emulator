-module(ping_mm1).
-behaviour(gen_server).



-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2,handle_info/2,terminate/2,code_change/3]).
-export([ping/5,test/1]).







ping(Host1,Host2,Total,Lambda,M)->
    
	io:format("~p   ",[Lambda]),
	Host1_gateway=list_to_atom(atom_to_list(Host1)++"_ingress"),
    Host2_gateway=list_to_atom(atom_to_list(Host2)++"_ingress"),
    
    start_link({Host2, receiver, Host1, Host2_gateway,Total,Lambda,M}),  %% set up receiver
    start_link({Host1, sender, Host2, Host1_gateway,Total,Lambda,M}),  %% set up receiver
	Ref2=erlang:monitor(process, global:whereis_name(host2)),
	Ref1=erlang:monitor(process, global:whereis_name(host1)),
	receive
		{'DOWN', _, _, _, _}-> 
			receive
			{'DOWN', _, _, _, _}-> ok
			end
	end.

		
	

start_link({Name, Type, Dest, Gateway,Total,Lambda,M})->   % %the name is maybe unnecessary 
		gen_server:start_link({global,Name},ping_mm1,[{Name, Type, Dest, Gateway,Total,Lambda,M}],[]).

		
		
init([{Name, Type, Dest, Gateway,Total,Lambda,M}])->
		%%	io:fwrite("remote host ~s: init\n",[Name]),
			% net_adm:ping('main@Lenovo-THINK').  need to change every time we run on different machine 
        %%    io:fwrite("remote host is ~p ~n", [global:whereis_name(Gateway)]),
            gen_server:call(global:whereis_name(Gateway),{handshake}),  % todo: add try catch here
            Time=0,   % start time
            Sent=0,
			Receive=0,
		%%	io:fwrite("Flag0 \n"),
            {ok,{Name, Type,Dest,  Gateway,Total,Sent,Receive,Time,Lambda,M},0}.  
                                                            % Type: 1-sender, 0-receiver


handle_call(_Request,_From,State)->{noreply, State}.

handle_cast(Msg,State)->  my_handle_cast(Msg,State).

handle_info(Info,State)-> my_handle_info(Info,State).

terminate(_Reason,_State)->ok.

code_change(_Oldvsn, _State, _Extra)->{ok, state}.

% message format
% {Dst,Size,Maxhops,Mode,Payload}
% Payload format:
% {Src,Data,Time_list}

%% last message to send

my_handle_info(timeout,{Name, sender,Dest,  Gateway,Total,Total,Receive,Time,Lambda,M})-> 
	%io:format("done sending last message\n"),

      {stop,normal,{Name, sender,Dest,  Gateway,Total,Total,Total+1,Time,Lambda,M}};  


my_handle_info(timeout,{Name, sender,Dest,Gateway,Total,Sent,Receive,Time,Lambda,M})->
	%io:format("sending message\n"),
	BW=1,
	Size=pois(M)*BW, %TODO
	Send_time=erlang:now(),
	Message={Dest,Size,10,regular,{host1,{ping,Send_time},[]}},  %% ping message format
   
    gen_server:cast(global:whereis_name(Gateway),Message),
    %io:fwrite("~s: sent packet 0 \n",[Name]),
    X=round(pois(Lambda)*1000), %TODO
	mix_wait(X),
    {noreply,{Name, sender,Dest,  Gateway,Total,Sent+1,Receive,Time,Lambda,M},0};


% default:
my_handle_info(_Info,State)->  %io:format("Flag1\n"),
 
 {noreply, State}.    
    
    
%% receive last pong:    
% my_handle_cast({_,_Size,_Maxhops,_Mode,{_Src,{pong,Send_time},_Time_list}},{Name, sender,Dest,  Gateway,Total,Sent,Total,Time,Lambda,M})-> 
%     io:format("receive message number ~p\n",[Total]),
% 	Receive_time=erlang:now(),
% 	Packet_time=timer:now_diff(Receive_time,Send_time)/1000000,
% 	Total_time=Time+Packet_time,
%     Avg_time=Total_time/Total,
%     io:format("~p: average ping-pong time: ~p sec\n",[Name, Avg_time]),
% 	Message={Dest,0,10,regular,{host1,finish,[]}},
% 	gen_server:cast(global:whereis_name(Gateway),Message),
%     {stop,normal,{Name, sender,Dest,  Gateway,Total,Sent,Total+1,Time,Lambda,M}};
% 
% my_handle_cast({_,_Size,_Maxhops,_Mode,{_Src,{pong,Send_time},_Time_list}},{Name, sender,Dest,  Gateway,Total,Sent,Receive,Time,Lambda,M})-> 
%     io:format("receive message number ~p\n",[Receive]),
% 	Receive_time=erlang:now(),
% 	Packet_time=timer:now_diff(Receive_time,Send_time)/1000000,
% 	New_time=Time+Packet_time,
%     {noreply,{Name, sender,Dest,  Gateway,Total,Sent,Receive+1,New_time,Lambda,M}};	
	
	%% worm-up
	
	my_handle_cast({_,_Size,_Maxhops,_Mode,{_Src,{ping,Send_time},Time_list}},{Name, receiver,Dest,  Gateway,Total,Sent,Receive,Time,Lambda,M}) when Receive<(Total-10)->
		{noreply,{Name, receiver,Dest,  Gateway,Total,Sent,Receive+1,Time,Lambda,M}};
    
  %% create pong/receive ping:  
	my_handle_cast({_,_Size,_Maxhops,_Mode,{_Src,{ping,Send_time},Time_list}},{Name, receiver,Dest,  Gateway,Total,Sent,Receive,Time,Lambda,M}) when Receive==Total-1->
		Receive_time=erlang:now(),
		Packet_time=timer:now_diff(Receive_time,Send_time)/1000000,
		New_time=Time+Packet_time,
		Avg_time=New_time/10,
		%io:format("~p: average ping-pong time: ~p sec  last packet time ~p\n",[Name, Avg_time,Packet_time]),
		io:format("~p	~p\n",[Avg_time,Packet_time]),
		{stop,normal,{Name, receiver,Dest,  Gateway,Total,Sent,Receive+1,New_time,Lambda,M}};
		
		
  my_handle_cast({_,_Size,_Maxhops,_Mode,{_Src,{ping,Send_time},Time_list}},{Name, receiver,Dest,  Gateway,Total,Sent,Receive,Time,Lambda,M})-> 
      % io:fwrite("~s: packet recieved 0 \n",[Name]),
		Receive_time=erlang:now(),
		Packet_time=timer:now_diff(Receive_time,Send_time)/1000000,
		New_time=Time+Packet_time,
		%io:format("~p\n",[Packet_time]),
      {noreply,{Name, receiver,Dest,  Gateway,Total,Sent,Receive+1,New_time,Lambda,M}};
  	
  
      
  my_handle_cast(Message,{Name, Type,Dest,  Gateway,Total,Total,Start})-> 
      %io:fwrite("~p: illegal packet ~p \n",[Name, Message]),
     {noreply,{Name, Type,Dest,  Gateway,Total,Total,Start}}.
      
  


%%%%%%%%%%%%%%
pois(Lambda)-> -math:log(random:uniform())/Lambda. 



%%%%%%  wait implementation





test(Time)->
   Start=erlang:now(),
   mix_wait(Time),
   Now=erlang:now(),
   Diff=timer:now_diff(Now,Start)/(1000),	
   io:format("~p\n",[Diff]).


busy_wait(Time)->  %% accepts milliseconds
        Start=erlang:now(),
        busy_wait(Time,Start).

busy_wait(Time,Start)->
    Now=erlang:now(),
    Diff=timer:now_diff(Now,Start)/(1000),
    case Diff>=Time of
        true -> ok;
        _ -> busy_wait(Time,Start)
    end.
    
    
mix_wait(Time) when (Time>30) -> %% millisec
    %io:fwrite("~p: waiting\n",[Time]),
    Start=erlang:now(),
    SleepTime=Time- 20,
    timer:sleep(SleepTime),
    Now=erlang:now(),
    Diff=Time - round(timer:now_diff(Now,Start)/(1000)),
    busy_wait(Diff);
    
mix_wait(Time) ->
	%io:fwrite("~p: waiting\n",[Time]),
    busy_wait(Time).
