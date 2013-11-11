-module(bw_req).
-behaviour(gen_server).

-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2,handle_info/2,terminate/2,code_change/3]).


start_link({Name,Type,Dst,Next_hop,Bw,Num})->  %num- the message we want to measure
		gen_server:start_link({global,Name},bw_req,[{Name,Type,Dst,Next_hop,Bw,Num}],[]).
		
init([{Name,Type,Dst,Next_hop,Bw,Num}])->
			io:fwrite("host ~s: init\n",[Name]),
            Time=100,  % 100 millisecond   the result are bad if Time =1!!
			Size=Bw/10,
            
           {ok,{Name,Type,Dst,Next_hop,Size,Num,Time},0}.  % Type: 1-sender, 0-receiver
                                                            


handle_call(_Request,_From,State)->{noreply, State}.

handle_cast(Msg,State)->my_handle_cast(Msg,State).

handle_info(_Info,State)->my_handle_info(_Info,State).

terminate(_Reason,_State)->ok.

code_change(_Oldvsn, _State, _Extra)->{ok, state}.




%%last message
my_handle_info(timeout,{Name,1,Dst,Next_hop,Size,0,Time})->
    Message= {Dst,Size,10,0,{Name,{1,erlang:now()},[]}}, %% message format  data=1 -we measure this message.
	%io:fwrite("~s: sending last message: \n",[Name]),
    gen_server:cast(global:whereis_name(Next_hop),Message),
    {stop,normal,{Name,1,Dst,Next_hop,Size,-1,Time}};
	

%% regular timout:    
my_handle_info(timeout,{Name,1,Dst,Next_hop,Size,Num,Time}) when Num>0-> 
	%io:fwrite("~s: sending message: \n",[Name]),
    Message= {Dst,Size,10,0,{Name,{0,0},[]}}, %% message format data=0 -we don't measure this message.
    gen_server:cast(global:whereis_name(Next_hop),Message),
    {noreply,{Name,1,Dst,Next_hop,Size,Num-1,Time},Time};


% default:
my_handle_info(_Info,State)->{noreply, State}. 


%{Dst,Size,Maxhops,Mode,{Src,Data,Time_list}}
% responder
my_handle_cast({_,_Size,_Maxhops,_Mode,{_Src,{0,_Start},_Time_list}},{Name,0,Dst,Next_hop,Size,Num,Time})->   
	%io:fwrite("~s: get message: \n",[Name]),
    {noreply,{Name,0,Dst,Next_hop,Size,Num,Time}};

my_handle_cast({_,Size,_Maxhops,_Mode,{_Src,{1,Start},_Time_list}},{Name,0,Dst,Next_hop,Size,Num,Time})->
	%io:fwrite("~s: got last message: \n",[Name]),
	End=erlang:now(),
	Lat=timer:now_diff(End,Start)/(1000000),
	io:fwrite("~p: bw test, Lat= ~p sec\n",[Name, Lat]),
    {stop,normal,{Name,0,Dst,Next_hop,Size,Num,Time}};
		
	

% default:
my_handle_cast(_Message,{Name,Type,Dst,Next_hop,Size,Num,Time})-> 
    {noreply,{Name,Type,Dst,Next_hop,Size,Num,Time}}.
    
    
    




