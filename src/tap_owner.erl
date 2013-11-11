-module(tap_owner).
-export([start/1]).



start(Num)-> start(Num,0).
	
	
start(Num,Num)->
	 io:format("created ~p taps\n",[Num]),
  	 loop();
start(Num,I)->
	Tap_num=I+1,
	Tap_name="tap" ++ integer_to_list(Tap_num),
	{ok,Tap}= tuncer:create(Tap_name, [tap, no_pi, {active, true}]),
	global:register_name(list_to_atom(Tap_name),Tap),
	unlink(Tap),
        start(Num,I+1).
	

loop()->
	receive 
		{Pid,Tap} -> tuncer:controlling_process(Tap,Pid);
		_->ok
	end,
	loop().
