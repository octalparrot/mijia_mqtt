#!/bin/bash


SENSOR_ADDRESS=""
SENSOR_NAME=""
DEBUG=0

readonly USAGE="
$0 -a [address] -n [sensor name]

Mandatory arguments:

-a  | --address           Bluetooth MAC address of sensor.
-n  | --name              Name of the sensor to use for MQTT.

Optional arguments:

-r  | --retries           Number of max retry attempts. Default $MAXRETRY times.
-d  | --debug             Enable debug printouts.
-h  | --help
"

debug_print() {
	if [ $DEBUG -eq 1 ]; then
		echo "$@"
	fi
}

print_usage() {
	echo "${USAGE}"
}

parse_command_line_parameters() {
	while [[ $# -gt 0 ]]
	do
		key="$1"

		case $key in
			-a|--address)
			SENSOR_ADDRESS="$2"
			shift; shift
    			;;
			-n|--name)
			SENSOR_NAME="$2"
			shift; shift
			;;
			-r|--retries)
			MAXRETRY="$2"
			shift; shift
			;;
			-d|--debug)
			DEBUG=1
			shift; shift
			;;
			-h|--help)
			print_usage
			exit 0
			;;
    			*)
			# Unknown parameter
			print_usage
			exit 1
			;;
		esac
	done

	if [ -z $SENSOR_ADDRESS ]; then
		echo "Sensor address is mandatory parameter."
		print_usage
		exit 2
	fi

}

main() {

local retry=0
while true
do
    debug_print "Querying $SENSOR_ADDRESS for temperature and humidity data."
    data=$(timeout 20 gatttool -b $SENSOR_ADDRESS --char-write-req --handle=0x10 -n 0100 --listen | grep "Notification handle" -m 2)
    rc=$?
    if [ ${rc} -eq 0 ]; then
        break
    fi
    if [ $retry -eq $MAXRETRY ]; then
	debug_print "$MAXRETRY attemps made, aborting."
        break
    fi
    retry=$((retry+1))
    debug_print "Connection failed, retrying $retry/$MAXRETRY... "
    sleep 5
done

retry=0
while true
do
    debug_print "Querying $SENSOR_ADDRESS for battery data."
    battery=$(timeout 20 gatttool -b $SENSOR_ADDRESS --char-read --handle=0x18)
    rc=$?
    if [ ${rc} -eq 0 ]; then
        break
    fi
    if [ $retry -eq $MAXRETRY ]; then
	debug_print "$MAXRETRY attemps made, aborting."
        break
    fi
    retry=$((retry+1))
    debug_print "Connection failed, retrying $retry/$MAXRETRY... "
    sleep 5
done
battery=$(echo $battery | cut -f 2 -d":" | tr '[:lower:]' '[:upper:]')

temp=$(echo $data | tail -1 | grep -oP 'value: \K.*' | xxd -r -p | cut -f 1 -d" " | cut -f 2 -d"=")
humid=$(echo $data | tail -1 | grep -oP 'value: \K.*' | xxd -r -p | cut -f 2 -d" " | cut -f 2 -d"=" | tr -d '\0')
batt=$(echo "ibase=16; $battery" | bc)

debug_print "Temperature: $temp, Humidity: $humid, Battery: $batt"


# Do validity check and publish
if [[ "$temp" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]
then
echo    Temp:"$temp"
fi

if [[ "$humid" =~ ^[0-9]+(\.[0-9]+)?$ ]]
then
echo    Humid:"$humid"
fi

if [[ "$batt" =~ ^[0-9]+(\.[0-9]+)?$ ]]
then
echo    Batt:"$batt"
fi
}

parse_command_line_parameters $@
main

