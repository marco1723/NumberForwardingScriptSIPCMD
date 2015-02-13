####################################################################################
# NumberForwardingScriptSipcmd
#
#
	This is a bash script to help SIP number forwarding through SIPCMD.
	*It must be located in the same directory as SIPCMD.*
	
	A config.cfg file must be created in the same directory, with as many numbers as needed, according to the following example:
 	
   \#---START OF CONFIG.CFG---
	user=<value>\n
	pass=<value>
	gateway=<value>
	number=<value>
	number=<value>
	number=<value>
 	#---END OF CONFIG.CFG---

	It works with the following parameters:
	REQUIRED(only one):
	-f 		   ->  it will iterate over the numbers inside config.cfg file 
				   to choose the one to forward to.
	-n <value> ->  it will use the number passed as parameter from -n tag.
	-d  	   ->  it will disable number forwarding.

	OPTIONAL
	-p <value> ->  change the listening port. Default is 5183.
	-o         ->  create sipcmd log, named siplog.log, inside sipcmd directory.    
####################################################################################
