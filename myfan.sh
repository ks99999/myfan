#!/usr/bin/env bash
source /etc/environment
. /hive/bin/colors
STATS_FILE=/run/hive/myfan
# Some functions
#
check_config() {
  if [ ! -f $YKEDA_AUTOFAN_CONF ]; then
    echo "${RED}No config $YKEDA_AUTOFAN_CONF${NOCOLOR}"
    exit 1
  fi
}

read_config() {
  if [[ -f $YKEDA_AUTOFAN_CONF ]]; then
    source $YKEDA_AUTOFAN_CONF
  fi
}

get_json_string() {
  JSON_RESPONSE=""
  while [ `echo $JSON_RESPONSE | wc -m` -eq 1 ]
  do
    echo -n "=get_json;" > $tty
    sleep 0.1
    if [ $read_cat -eq 1 ]
    then
      read JSON_RESPONSE < $tty
    else
        JSON_RESPONSE=`cat < $tty`
    fi
  done
}

get_json() {
  local jq_ret=1
  while [ $jq_ret -eq 1 ]
  do
    get_json_string
    PWM=`echo "$JSON_RESPONSE" | jq -r ".pwm[]" 2> /dev/null`
    if [ $? -ne 0 ]; then
        jq_ret=1
        continue
    fi
    TEMP=`echo "$JSON_RESPONSE" | jq -r ".temp[]" 2> /dev/null`
    if [ $? -ne 0 ]; then
        jq_ret=1
    fi
    jq_ret=0
  done
}

save_stats() {
  echo "PWM=$PWM" > $STATS_FILE
  echo "TEMP=$TEMP" >> $STATS_FILE
}

# 1 - +-PWM
# 2 - echo to console
adjust_pwm() {
        local adj=$1
        if [ -n "$MAX_FAN" ] && [ $(($PWM+$adj)) -gt $MAX_FAN ]
        then
                adj=$MAX_FAN
        fi
        if [ -n "$MIN_FAN" ] && [ $(($PWM+$adj)) -lt $MIN_FAN ]
        then
                adj=$MIN_FAN
        fi
        echo -n "=$adj;" > $tty
        [[ $adj -lt 0 ]] && echo "${GREEN}$2 $adj${NOCOLOR}" || echo "${RED}$2 $adj${NOCOLOR}"
}
# Check arduino in USB
read_cat=0
if [ -e /dev/ttyACM0 ]
then
        tty=/dev/ttyACM0
        read_cat=1
elif [ -e /dev/ttyUSB0 ]
then
        tty=/dev/ttyUSB0
else
        echo "Not found myfan controller"
        exit 1
fi
echo "Found myfan controller on $tty"
# Set some variables
# sleep timeout
SL=17.5
# Temperature threshold
T=1
PWM=0
TEMP=0
JSON_RESPONSE=""
# Setup USB-COM port
stty -F $tty 115200 cs8 -echo -hupcl
stty -F $tty min 0 time 1
sleep 0.1
echo -e "${NOCOLOR}"
# Get initial temps
G=`gpu-stats | jq -r '.temp[]' | sort -r | head -1`
M=`gpu-stats | jq ".mtemp[.mtemp|length] |= . + \"11\"" | jq -r '.mtemp[]?' | sort -r | head -1`
check_config
read_config
[[ -n "$MANUAL_FAN" ]] && (unbuffer echo -n "=$MANUAL_FAN;" > $tty; echo "$MANUAL_FAN")
while [ true ]
do
sleep 0.5
echo -n "."
sleep 0.5
echo -n "."
sleep 0.5
echo -n "."
sleep 0.5
echo -n "."
sleep 0.5
echo "."
get_json
save_stats
echo "PWM=$PWM"
echo "TEMP=$TEMP"
# make rotation
pG=$G
pM=$M
read_config
[[ ! -n $TARGET_MEM_TEMP ]] && TARGET_MEM_TEMP=110
[[ ! -n $TARGET_TEMP ]] && TARGET_TEMP=90
if [ $AUTO_ENABLED -eq 0 ]
then
        echo "MYFAN disabled"
        sleep $SL
        continue
fi
# Get current temperatures
G=`gpu-stats | jq -r '.temp[]' | sort -r | head -1`
M=`gpu-stats | jq ".mtemp[.mtemp|length] |= . + \"11\"" | jq -r '.mtemp[]?' | sort -r | head -1`
dG=$(($G-$pG))
dM=$(($M-pM))
echo -e "Target $TARGET_TEMP\t Core $G\t dG=$dG"
echo -e "Target $TARGET_MEM_TEMP\t Memory $M\t dM=$dM"
if [ -n "$MANUAL_FAN" ]
then
        echo -n "=$MANUAL_FAN;" > $tty
        sleep $SL
        continue
fi
# Check for dG temperature increasing
if [ $dG -gt 6 ]
then
        adjust_pwm "+14" "Fan (core)"
        sleep $SL
        continue
elif [ $dG -gt 3 ] && [ $dG -le 6 ]
then
        adjust_pwm "+9" "Fan (core)"
        sleep $SL
        continue
elif [ $dG -ge 2 ] && [ $dG -le 3 ]
then
        adjust_pwm "+5" "Fan (core)"
        sleep $SL
        continue
fi
# Check for HIGH GPU temperature
if [ $(($G-$T)) -gt $TARGET_TEMP ]
then
        adjust_pwm "+3" "Fan (core)"
# Check for HIGH MEMORY temperature
elif [ $(($M-$T)) -gt $TARGET_MEM_TEMP ]
then
        adjust_pwm "+3" "Fan (memory)"
# Check for DECREASE RPM possibility
elif [ $(($TARGET_TEMP-$G)) -gt $T ] && [ $(($TARGET_MEM_TEMP-$M)) -gt $T ]
then
        if [ $dG -le -3 ]
        then
                adjust_pwm "-10" "Fan fast drop (core & mem)"
        else    adjust_pwm "-2" "Fan (core & mem)"
        fi
fi
sleep $SL
done
