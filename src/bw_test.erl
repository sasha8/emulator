-module(bw_test).

-export([start_link/0]).


start_link()->
	%<configure the network>  % igors commands
	main_supervisor:start_link(),
	bw_req:start_link({host2,0,host1,switch1_ingress2,90000,100}),
	bw_req:start_link({host1,1,host2,switch1_ingress1,90000,100}).
	
	%Switch1={switch, switch1, Fwd_table_switch1,{ingress,[{switch1_ingress1},{switch1_ingress2}]},
	%		{egress,[{switch1_egress1,host1,{0,1000000,0}},{switch1_egress2,host2,{0,1000000,0}}]}}, % {Lat,BW,Drop_rate}
	
