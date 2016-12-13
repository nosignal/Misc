#!/bin/bash

debug=false

function usage()
{
cat << _EOF_
usage:
 $(basename $0) -c controller -v ofdpa_version [-dkh]

arguments:
 -c     OpenFlow controller IP
 -v     OFDPA version (EX: i12, 3.0)
 -d     Start with debug mode
 -k     Kill ofdpa agent
 -h     Print Help (this message) and exit

_EOF_
}

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	OIFS=$IFS
	IFS='.'
	ip=($ip)
	IFS=$OIFS
	[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
	    && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
	stat=$?
    fi
    return $stat
}

function include_debug()
{
    echo -n "Entering debug mode...... "
    KERNEL_MODS=/lib/modules/`uname -r`/ofdpa
    insmod $KERNEL_MODS/linux-kernel-bde.ko dmasize=32M maxpayload=128
    insmod $KERNEL_MODS/linux-user-bde.ko
}

function kill_ofagent()
{
    echo -n "Killing old agent...... "
    killall -q brcm-indigo-ofdpa-ofagent
    killall -q ofagentapp
    sleep 10
    echo "Done."
}

function clean_up_flow()
{
    echo -n "Cleaning up flows...... "
    cd /usr/bin/ofdpa*/examples/
    ./client_cfg_purge 2>/dev/null 1>/dev/null
    echo "Done."
}

while getopts "c:v:dkh" flag
do
    case $flag in
        c)
            ip=$OPTARG
            if ! valid_ip $ip; then
                echo "ip address is not valid!"
                exit 1
            fi
            ;;
        v)
            version=$OPTARG
            ;;
        d)
            debug=true
            ;;
        k)
            kill_ofagent
            exit 1
            ;;
        h)
            usage
            exit 1
            ;;
        *)
            exit 1
            ;;
    esac
done

if [ $OPTIND -eq 1 ] || [ -z $ip ] || [ -z $version ]
then
    usage
    exit 1
fi

kill_ofagent
clean_up_flow

case $version in
    i12)
        echo -n "Starting OFDPA...... "
        brcm-indigo-ofdpa-ofagent -t $ip:6653
        echo "Done."
        ;;
    3.0)
	if $debug; then
            include_debug
            launcher ofagentapp -a2 -d4 -c1 -c2 -c3 -c4 -c5 --controller=$ip:6653
        else
            echo -n "Starting OFDPA...... "
            (launcher ofagentapp --controller=$ip:6653 &) 2>/dev/null 1>/dev/null
            echo "Done."
        fi
        ;;
    *)
        echo "No such verion $version, try i12 or 3.0"
        exit 1
        ;;
esac
