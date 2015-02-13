#!/bin/bash

####################################################################################
#
#	This is a bash script to help SIP number forwarding through SIPCMD.
#	*It must be located in the same directory as SIPCMD.*
#	
#	A config.cfg file must be created in the same directory, with 
# as many numbers as needed, according to the following example:
# 	
#   #---START OF CONFIG.CFG---
#	user=<value>\n
#	pass=<value>
#	gateway=<value>
#	number=<value>
#	number=<value>
#	number=<value>
# 	#---END OF CONFIG.CFG---
#
#	It works with the following parameters:
#	REQUIRED(only one):
#	-f 		   ->  it will iterate over the numbers inside config.cfg file to choose the one to forward to.
#	-n <value> ->  it will use the number passed as parameter from -n tag.
#	-d  	   ->  it will disable number forwarding.
#
#	OPTIONAL
#	-p <value> ->  change the listening port. Default is 5183.
#	-o         ->  create sipcmd log, named siplog.log, inside sipcmd directory.    
#
####################################################################################


#Checks if this script is inside SIPCMD directory. It won't work otherwise.
if [[ $PWD != *sipcmd* ]];	then
	echo "Wrong current directory. Move this script file to the sipcmd directory."
	exit 1;
fi

$config < config.cfg


###This block reads every line in config.cfg file, validates its content and store it in variables.
#if [ $? -ne 0 ]
if [[ ! -e config.cfg ]]
	then 
	printf "\nCouldn't find config.cfg file. Please create it, like this, with as many numbers you need: \n#---START OF CONFIG.CFG---\n\nuser=<value>\npass=<value>\ngateway=<value>\nnumber=<value>\nnumber=<value>\nnumber=<value>\n\n#---END OF CONFIG.CFG---\n" 
	exit 1;
    else
		while read line || [ -n "$line" ] #fix to read the last line of the document everytime
		do
			if [[ $line = user=*  ]];	then 
				user=${line#*=}
			elif [[ $line = pass=* ]];	then 
				pass=${line#*=}
			elif [[ $line = gateway=* ]];	then 
				gateway=${line#*=}
			elif [[ $line = number=* ]];	then 
				numbers[nNumbers]=${line#*=}
				((nNumbers++))
			else 
				printf "Invalid config.cfg line input. Please rewrite it with the right pattern.\n" 
				exit 1
			fi
		done < config.cfg

		if [[ -z $user ]];	then
			echo "No user found in the config.cfg file. Please rewrite it with the right pattern."
			exit 1
		fi

		if [[ -z $pass ]];	then 
			echo "No password found in the config.cfg file. Please rewrite it with the right pattern."
			exit 1
		fi

		if [[ -z $gateway  ]];	then 
			echo "No gateway found in the config.cfg file. Please rewrite it with the right pattern."
			exit 1
		fi

		if [[ $nNumbers -le 0 ]];	then 
			echo "No number found in the config.cfg file. Please rewrite it with the right pattern."
			exit 1
		fi	
fi

###Last number index reading
currentNumberIndex=$(head -n 1 /tmp/numberForwardingScript-NumIndex)
if [ $? -ne 0 ];	then 
	currentNumberIndex=0
fi

currentNumber=0
listPort=5183 #Default listening port

###Iterate to next number 
###If numberIndex equals the last index, it will start from the first index once again
###It's stored as a temporary file inside /tmp/
nextNumber(){
	if [ $currentNumberIndex -ge $(expr ${#numbers[@]} - 1) ];	then 
		currentNumberIndex=0
	else
			currentNumberIndex=$(expr $currentNumberIndex + 1)
	fi

	echo $currentNumberIndex > /tmp/numberForwardingScript-NumIndex
}

numberForwardingFromSingleNumber(){
	echo sudo ./sipcmd -P sip -p $listPort -u $user -c $pass -w $gateway -x "c*7200${currentNumber}" $logOn
	printf '\nForwarding from Number 1219 to Number %s. \n' "$currentNumber"
	exit 0
}

numberForwardingFromFile(){
	currentNumber=${numbers[currentNumberIndex]} 
	nextNumber

	###if number was found, do forward programming call
	if [ $currentNumber -ne 0 ];	then
		echo sudo ./sipcmd -P sip -p $listPort  -u $user -c $pass -w $gateway -x "c*7200${currentNumber} $logOn"
		printf '\nForwarding from Number 1219 to Number %s. \n' "$currentNumber"
		
	else
		echo "No number found."
		echo "Enter -f <filename> for file input or -n <number> for single number input."
		exit 1
	fi
	exit 0
}

disableNumberForwarding(){
	echo sudo ./sipcmd -P sip -p $listPort -u $user -c $pass -w $gateway -x "c*73" $logOn
	echo $'\nNumber Forwarding Disabled\n' >&2
	exit 0		
}

###Parameter handling. 
###Operation parameters: -f for file, -n for single number, -d for disabling forwarding.
###Optional call parameters: -p for listening port. Default port is 5183.
while getopts "op:dfn:" opt; do
  case $opt in
  	o)
        logOn="-o siplog.log"
	;;
  	p) 
		listPort="$OPTARG"
	;;
  	d) 	
		operation=disableForwarding
	;;
    f)  #fileName="$OPTARG"
	    operation=fileForwarding
    ;;
    n)  currentNumber="$OPTARG"
	    operation=singleNumberForwarding
    ;;

    \?) echo "Invalid option -$OPTARG. Enter -f for file input, -n <number> for single number input or -d for disabling forwarding." >&2
		exit 1
    ;;
  esac
done

###Operation calling.
if [[ $operation = fileForwarding ]]; then
	numberForwardingFromFile
elif [[ $operation = disableForwarding ]]; then
	disableNumberForwarding
elif [[ $operation = singleNumberForwarding ]]; then
	numberForwardingFromSingleNumber
else
	echo "Invalid operation. Enter -f for file input, -n <number> for single number input or -d for disabling forwarding." >&2
fi