#!/bin/ksh

#auth rpawar.021@gmail.com
# USR="aimadm90"


##################INIT_VAR###############

export FLAG=0
export FLAG1=0
export FLAG2=0
export dFLAG=0
export dFLAG1=0
export dFLAG2=0
export nFLAG=0

. ${HOME}/SysStat/systat.config

# font colours
export GREEN='<font color="#00ff00">'
export RED='<font color="#ff0000">'
export NOC='</font>'
export LSTART='<ul><li>'
export LEND='</li></ul>'

# Local path to ssh and other bins
export SSH="/usr/bin/ssh"
export PING="/bin/ping"
export NOW="$(date)"


echo "started lookup @ $NOW"      > "$LOGDEST" 
echo "server lookup list  $Q_HOST" >> "$LOGDEST" 

####################Init_done#############
 
sendMailBlock()
{
echo 'MIME-Version: 1.0'  > $MFILE
echo "From: $FROM"  >> $MFILE
echo "To: $TOLIST"  >> $MFILE
echo "Subject: $SUB"  >> $MFILE
echo 'Content-Type: text/html'  >> $MFILE
echo 'Content-Id: <graph>'  >> $MFILE 
}
 
 
## functions ##
writeHead(){
echo '<HTML><HEAD><TITLE>Network Status</TITLE></HEAD>
<BODY alink="#0066ff" bgcolor="#606060" link="#0000ff" text="#ccddee" vlink="#0033ff">'  >> $MFILE
echo '<CENTER><H1>'  >> $MFILE 
echo "$MYNETINFO</H1>"  >> $MFILE 
echo "Generated on $NOW"  >> $MFILE
echo '</CENTER>'   >> $MFILE 

}
 
 
## main ##
main() {

sendMailBlock
export NOW="$(date)" 
writeHead
echo '<TABLE WIDTH=100% BORDER=2 BORDERCOLOR="#000080" CELLPADDING=4 CELLSPACING=4 FRAME=HSIDES RULES=NONE" >'  >> $MFILE
echo '<TR VALIGN=TOP>'  >> $MFILE 
echo "<tr>"  >> $MFILE 
echo "<th bgcolor=#7FFFD4 <font color=#000000 size=5><b>HOST</th>" >> $MFILE
echo "<th>Network</th>" >> $MFILE
echo "<th>Uptime</th>" >> $MFILE
echo "<th>Current CPU</th>" >> $MFILE
echo "<th>Average Daily CPU</th>" >> $MFILE
echo "<th>Total Processes</th>" >> $MFILE
echo "<th>Ram + Swap</th>" >> $MFILE
echo "</tr>" >> $MFILE


for host in $Q_HOST
do

_CMD="$SSH $USR@$host"
rhostname="$($_CMD hostname)"
 
ruptime="$($_CMD uptime)"
if $(echo $ruptime | grep -E "min|days" >/dev/null); then
x=$(echo $ruptime | awk '{ print $3 $4}')
else
x=$(echo $ruptime | sed s/,//g| awk '{ print $3 " (hh:mm)"}')
fi
ruptime="$x"
 
rload="$($_CMD top -n 1 -b  -u aimadm90 | head -10 | grep Cpu |  sed 's/  / /g'  |cut -d " " -f2 | cut -d "%" -f1 )"
rusage="$($_CMD top -n 1 -b  -u aimadm90 | head -10 | grep Cpu |  sed 's/  / /g'  |cut -d " " -f5 | cut -d "%" -f1 )"

y="$(echo "$rload >= $LOAD_WARN" | bc)" > /dev/null 2>&1
FLAG=$y
dFLAG="${dFLAG}$y" 
[ "$y" == "1" ] && rload="$RED $rload (High) $NOC" || rload="$GREEN $rload (Ok) $NOC"

 
rclock="$($_CMD date +"%r")"
rtotalprocess="$($_CMD ps axue | grep -vE "^USER|grep|ps" | wc -l)"

 
rusedram="$($_CMD free -gto | grep Mem: | awk '{ print $3 }')"
rfreeram="$($_CMD free -gto | grep Mem: | awk '{ print $4 }')"
y="$(echo "$rfreeram <=$MEM_WARN" | bc)" > /dev/null 2>&1
FLAG1=$y
dFLAG1="${dFLAG1}$y"
[ "$y" == "1" ] && rfreeram="$RED $rfreeram (HiGH) $NOC" || rfreeram="$GREEN $rfreeram (Ok) $NOC"

rtotalram="$($_CMD free -gto | grep Mem: | awk '{ print $2 }')"
rusedswap="$($_CMD free -t | awk '/Swap:/ {printf("%.2f\n", $3/$2*100)}')"
y="$(echo "$rusedswap >=$SWAP_WARN" | bc)" 
FLAG2=$y
dFLAG2="${dFLAG2}$y"
[ "$y" == "1" ] && rusedswap="$RED $rusedswap % (HiGH) $NOC" || rusedswap="$GREEN $rusedswap (Ok) $NOC"

didl="$($_CMD /usr/bin/sar | grep Av | tail -1  | sed 's/    / /g' | sed 's/   / /g' |  sed 's/  / /g' | cut -d " " -f8)"
davg="$($_CMD /usr/bin/sar | grep Av | tail -1  | sed 's/    / /g' | sed 's/   / /g' |  sed 's/  / /g' | cut -d " " -f3)"



$PING -c1 $host>/dev/null
if [ "$?" != "0" ] ; then
	rping="$RED Failed $NOC"
	DRTY="$DRTY $host"
	
		echo "</tr>"   >> $MFILE
		echo "<td <b> <font color="\#ff0000"> $host</b></td>" >> $MFILE
		echo "<td width="20%">" >> $MFILE
		echo "      <ul>" >> $MFILE
		echo "        <li>Ping status: $rping</li>" >> $MFILE
		echo "      </ul>" >> $MFILE
		echo "    </td>" >> $MFILE
		echo "<td>	</td>" >> $MFILE
		echo "<td width="20%">" >> $MFILE
		echo "      <ul>" >> $MFILE
		echo "        <li>FAILED TO CONNECT</li>" >> $MFILE
		echo "      </ul>" >> $MFILE
		echo "    </td>" >> $MFILE
		echo "<td width="20%">" >> $MFILE
		echo "      <ul>" >> $MFILE
		echo "      </ul>" >> $MFILE
		echo "    </td>" >> $MFILE
		echo "<td width=5%>$rtotalprocess</td>" >> $MFILE
		echo "<td width=20%>" >> $MFILE
		echo "      <ul>" >> $MFILE
		echo "        <li>FAILED TO CONNECT</li>" >> $MFILE
		echo "      </ul>" >> $MFILE
		echo "    </td>" >> $MFILE
		echo "</tr>" >> $MFILE
		
else
	rping="$GREEN Ok $NOC"

	if [[ "$FLAG" == "1" || "$FLAG1" == "1" && "$FLAG2" == "1"  || ! -z "$DRTY" ]] ; then 
		echo "</tr>"   >> $MFILE
		echo "<td <b> <font color="\#00ff00"> $host</b></td>" >> $MFILE
		echo "<td width="20%">" >> $MFILE
		echo "      <ul>" >> $MFILE
		echo "        <li>Ping status: $rping</li>" >> $MFILE
		echo "      </ul>" >> $MFILE
		echo "    </td>" >> $MFILE
		echo "<td>$ruptime</td>" >> $MFILE
		echo "<td width="20%">" >> $MFILE
		echo "      <ul>" >> $MFILE
		echo "        <li>Cpu Load : $rload  </li>" >> $MFILE
		echo "        <li>Cpu Idle : $rusage%</li>" >> $MFILE
		echo "      </ul>" >> $MFILE
		echo "    </td>" >> $MFILE
		echo "<td width="20%">" >> $MFILE
		echo "      <ul>" >> $MFILE
		echo "        <li>Cpu Load   :  $davg % </li>" >> $MFILE
		echo "        <li>Cpu Idle   :  $didl %</li>" >> $MFILE
		echo "      </ul>" >> $MFILE
		echo "    </td>" >> $MFILE
		echo "<td width=5%>$rtotalprocess</td>" >> $MFILE
		echo "<td width=20%>" >> $MFILE
		echo "      <ul>" >> $MFILE
		echo "        <li>Used  	 : $rusedram GB </li>" >> $MFILE
		echo "        <li>Used SWAP  : $rusedswap</li>" >> $MFILE
		echo "        <li>Free 		 : $rfreeram GB</li>"  >> $MFILE
		echo "        <li>Total 	 : $rtotalram GB</li>" >> $MFILE
		echo "      </ul>" >> $MFILE
		echo "    </td>" >> $MFILE
		echo "</tr>" >> $MFILE
	fi


fi
 
done

echo "</tr></table>" >> $MFILE
echo "</BODY></HTML>" >> $MFILE

		

if [ ! -z "$DRTY" ]
then
	echo "found unreachable server $DRTY will check in 30s again" >> "$LOGDEST" 
	sleep 30
	handleNet `echo $DRTY`
	fi	

	




if grep "Ping status" $MFILE 
then 
	SFLAG=0
else
        SFLAG=1
fi


if [[ "$SFLAG" -eq "0" ]] ; then 
		if [[ "$nFLAG" -ge "1" || "$dFLAG" -ge  "1" || "$dFLAG1"  -ge  "1" && "$dFLAG2"  -ge "1" ]] ; then  
			/usr/sbin/sendmail -t < $MFILE
			echo "Found Issue sent Mail on on $(date)" >> "$LOGDEST" 
			echo "CPU: $dFLAG FreeMem: $dFLAG1  SWAP: $dFLAG2  NET: $nFLAG  SZ: $SFLAG"  >> "$LOGDEST" 

			unset dFLAG dFLAG1 dFLAG2 nFLAG SFLAG
			echo "$dFLAG $dFLAG1 $dFLAG2 $nFLAG" >> $MFILE
			unset FLAG FLAG1 FLAG2 DRTY SFLAG
			echo "$FLAG $FLAG1 $FLAG2 $DRTY" >> $MFILE
			echo "" >> "$LOGDEST" 

		else 

			echo "All servers are running Fine on $(date)" >> "$LOGDEST" 
			unset dFLAG dFLAG1 dFLAG2 nFLAG SFLAG
			echo "$dFLAG $dFLAG1 $dFLAG2 $nFLAG" >> $MFILE
			
			echo "$FLAG $FLAG1 $FLAG2 $DRTY"  >> $MFILE

		fi
else 
		
	echo "All servers are running Fine on $(date)" >> "$LOGDEST" 
	unset dFLAG dFLAG1 dFLAG2 nFLAG SFLAG
	unset FLAG FLAG1 FLAG2 DRTY 

fi 

} 

handleNet()
{
unset DRTY
for i in $@
do
ping $i -c 1 -q  > /dev/null 2>&1
X="$?"
if [ "$X" -ne 0 ]
		then
			nFLAG="${nFLAG}$X"
			export DRTY="${DRTY} $i"
		fi
done
return 0
}


makemeservice()
{

handleNet `echo $Q_HOST`
while :
					do
						if [ ! -z "$DRTY"  ]
						then
							main
							sleep 50 
						else	
							main
							sleep $STIME
						fi
					done
}



if [ "${1}" = "service" ]
		then
			 makemeservice
		else
			main
		fi
