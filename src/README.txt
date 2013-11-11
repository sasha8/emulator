Read me:

version 06/09/2013

ping test that run on different VM (remote host), internal host are generated automaticly, the main_supervisor read a conf file.
every remote host need to ping first to the main VM and then registered to the local host.
it is working version but yet not all the flow was tested.  

go to dir: cd C:\school\project2 (sashas pc) 
start Erlang: "C:\Program Files\erl5.10.1\bin\werl.exe" -sname main  (sashas pc)   
start all the VM

on the main machine run: 
		c(main_supervisor),c(switch_supervisor),c(host_supervisor),c(ingress_port),c(egress_port),c(host_ingress_port).
		main_supervisor:start_link(aaaa).

on the server machine run:
		net_adm:ping('main@Lenovo-THINK').
		c(ping).
		 ping:start_link({aa,0,host1,host2_ingress,10}).   %aa - is not relevant name, 0-receiver, host1-dest,host2_ingress-gateway,10 - iteration    
		
on the clinet machine run:
		 net_adm:ping('main@Lenovo-THINK').
		 c(ping).
		 ping:start_link({bb,1,host2,host1_ingress,10}).	%bb - is not relevant name, 1 - sender, host2 - dest, host1_ingress - gateway, 10 - iteration 
		 