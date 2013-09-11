#!/bin/bash
################################################################################
#
# Mutate kippo base. This script will remove some obvious "kippo-signature" and
# add some randomness to the command set.
#
# Author: 
# Tor Inge Skaar
# The Honeynet Project - Norwegian Chapter (www.honeynor.no)
#
# Version: 0.1
#
################################################################################

#
# Generate a random integer between $1 (min) and $2 (max)
#
function rand {
	min=$1
	max=$2
	delta=$(( max - min + 1 ))
	len=${#delta}
	if [ $len -lt 5 ]; then
		len=5
	fi
	clen=$(( len * 2 ))
	alen=$(( len + 1 ))
	rseq=$( head -c ${clen} /dev/urandom | xxd -p | tr -d [:alpha:] | tr -d "\n" | sed 's/^[0]*//g' | awk "{print substr(\$0,0,${alen})}" )
	rnd1=$(( rseq % delta ))
	rnd2=$(( min + rnd1 ))
	echo $rnd2
}

################################################################################

if [ ! -d "honeyfs" ] || [ ! -d "kippo" ] || [ ! -f "kippo.tac" ]; then
	echo "This script must executed from kippo's root directory" >&2
	exit 1
fi

#echo -e "\nThis script will mutate ... It's only tested on version 0.4 of kippo"
#echo -n "Do you want to mutate your kippo? [y/N]: "
#read input
#answer=$( echo $input | tr [:upper:] [:lower:] )
#if [ "$answer" != "y" ] && [ "$answer" != "yes" ]; then
#	exit 1
#fi

txtcmd=$( cat kippo/core/honeypot.py | grep -i txtcmd | wc -l )
if [ $txtcmd -eq 0 ]; then
	echo "Your kippo version has no support for txtcmds. You should get the latest version from SVN: svn checkout http://kippo.googlecode.com/svn/trunk/ kippo-svn" >&2
	exit 1
fi

echo "* Mutating ifconfig"
mac="00:02:9c:"$( head -c 3 /dev/urandom | xxd -p | awk '{ print substr($0,0,2)":"substr($0,2,2)":"substr($0,4,2) }' )
ip="192.168.1."$( rand 2 254 )
eth0rx1=$( rand 1000000 100000000 )
eth0tx1=$( rand 1000000 100000000 )
eth0rx2=$(( eth0rx1 / 1000 / 1000 )) # Using SI insted of IEC simply because of ease of rounding.
eth0tx2=$(( eth0tx1 / 1000 / 1000 ))
lo_byte1=$( rand 10000 100000 )
lo_byte2=$(( lo_byte1 / 1000 ))
txt="eth0      Link encap:Ethernet  HWaddr ${mac}
          inet addr:${ip}  Bcast:192.168.1.255  Mask:255.255.255.0
          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
          RX packets:$(rand 1000 100000 ) errors:0 dropped:0 overruns:0 frame:0
          TX packets:$(rand 1000 100000 ) errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:1000
          RX bytes:${eth0rx1} (${eth0rx2} MB)  TX bytes:${eth0tx1} (${eth0tx2} MB)
          Interrupt:16

lo        Link encap:Local Loopback
          inet addr:127.0.0.1  Mask:255.0.0.0
          UP LOOPBACK RUNNING  MTU:16436  Metric:1
          RX packets:$(rand 100 10000) errors:0 dropped:0 overruns:0 frame:0
          TX packets:$(rand 100 10000) errors:0 dropped:0 overruns:0 carrier:0
          collisions:0 txqueuelen:0
          RX bytes:${lo_byte1} (${lo_byte2} KB)  TX bytes:${lo_byte1} (${lo_byte2} KB)"
echo "$txt" > txtcmds/sbin/ifconfig

echo "* Mutating last"
ip="192.168.1."$(rand 2 254)
max=$( date -d "48 hours ago" +%s )
min=$( date -d "30 days ago" +%s )
date=$( rand $min $max )
ts=$( rand 10 40 )
te=$(( ts + 18 ))
session=$( rand 0 9 )
txt="root     pts/${session}        ${ip} "$(date -d@${date} +"%a %b %e")" 08:${ts} - 08:${te}  (00:18)\n\nwtmp begins "$( date -d@${min} +"%a %b %e %H:%M:%S %Y") 
echo -e "$txt" > txtcmds/usr/bin/last

echo "* Mutating vi"
vierr[1]="E558: Terminal entry not found in terminfo"
vierr[2]="E518: Unknown option: ?"
vierr[3]="E82: Cannot allocate any buffer, exiting..."
vierr[4]="E95: Buffer with this name already exists"
vierr[5]="E101: More than two buffers in diff mode, don't know which one to use"
vierr[6]="E544: Keymap file not found"
vierr[7]="E655: Too many symbolic links (cycle?)"
vierr[8]="E624: Can't open file"
vierr[9]="E185: Cannot find color scheme"
rnd=$(rand 1 9)
echo ${vierr[${rnd}]} > txtcmds/usr/bin/vi

echo "* Mutating dice.py"
reqs=$( which xxd patch bzip2 | wc -l )
if [ $reqs -lt 3 ]; then
	echo "Missing requirements (xxd, patch or bzip2)" >&2
	echo "This mutation will not take place" >&2
else
	patch="425a68393141592653598e1848ec00016f5f80667070effef3e965dcaebf
efdfee50037e4dd71cba3a06b092484c9e94f4d4346d11ea00d1a01a0c41
934c9e534019247a9a6a7e89344f2868680d00034000069ea0094f54a99a
9ea7a47a9ea193200d0d0034640001a32038c99326231300264c1320068c
230043008a402a6d00d29e446a794f49a6803ca69a1e90d07a81ea3d4ba8
1be04eff1d8fb23aaa4129797c535a2c304444063824882627199fb4e443
1ed244a0239891792299a408a6171346730c324c81ce417a822749cb7cc5
485a91517c71b1c0575f3e13a26da364dc8e4fb6f9ce82e91026b6416e66
ce65b34e9867a7e07950dc8f2553d98a50e73e8c30a065ba668366a5b506
24edac0e53a410841183869dcc144ac85b9f86fbfd7a6a276e39e45f601a
0925a02d2a42832a6656ac8b93a73055c81f4d57ad246812a15d30c3882c
9d28ca3247280c84575384a022121ca3489d4b067262b2f37a84779d84a4
c08542a7acf49444e8b1ed094fbced2b30dde7e5a3a14d2f5da458dd2549
f66c389a9f411a48eddc6a2841c09951efee319942507de53e9b653f75ee
4511c2e1f2fa581eeb8216282ec2d39bb7aa6dbf022a6c54ca804dc409b0
b1a5b2b6873970827cc409da182b8f00a5b911812432796938d5a90634f0
fac50ee87d6a58fc8a68d04bd80e9673fa9a1e29db06c42526d9556bca1b
e83294124195945555555555d53aaeb0a410a04d97eebe0c413a942af372
ff7971e39f00a1722783ac91c6ce7a0d2ddaa3ea3c722482601323944bbd
4bccd737c63ee385f674e0d39eff81dc0ef032e6912876a09a7cc56c4dc1
2b3eeb2c1f95312fb4242e462a27ce767ed069cbfdc536d201fd2a491360
0d40b09ac1e76a8273ed88d774b03e912ca1cffc396a5a1111a850c74188
8209745a858a8a13af44c2749ccac12daa1a2ca5450a17d45c1994a572a5
6345c6c163f3c3c311e466683054c9f901de23b42c1e40df43730416cdd9
68cea1d60f1eaa65c7f135ea3729fdc8d4e287052c6b0a073c6d31cb799e
d27dd8c8f08717eb549eca2602fb03298589457a7ad1dd60993dc7cc8f66
cf192c855621429269ec043441158d46ca4d55229732e1a86bc41b82a0e4
ccf45c2b2e1350a4a74af4c64e65cc71db95df2d77d55f3c4025e0ce4c04
90c6a8dfae43a1c4ceb95e01501e217d0e8a6c487f8bb9229c2848470c24
7600"
	echo "$patch" > dice.diff.bz2.hex
	if [ ! -f "dice.diff.bz2.hex" ]; then
		echo "Failed to create temporary patch file" >&2
		exit 1
	fi
	cat dice.diff.bz2.hex | xxd -p -r | bzip2 -d | patch -p0 > /dev/null 2>&1 
	rm -f dice.diff.bz2.hex
fi

echo "* Adding netstat"
txt="Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:4000            0.0.0.0:*               LISTEN      13252/rpc.statd 
tcp        0      0 0.0.0.0:2049            0.0.0.0:*               LISTEN      -               
tcp        0      0 0.0.0.0:4002            0.0.0.0:*               LISTEN      13841/rpc.mountd
tcp        0      0 0.0.0.0:59012           0.0.0.0:*               LISTEN      -               
tcp        0      0 0.0.0.0:111             0.0.0.0:*               LISTEN      13236/portmap   
tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN      13579/sshd      "
echo "$txt" > txtcmds/bin/netstat
