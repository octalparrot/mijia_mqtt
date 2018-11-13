# mijia_mqtt
Simple script to report temperature, humidity and battery level of Xiaomi Mijia Bluetooth Temperature and Humidity Sensor to MQTT. Requires gatttool, mosquitto_pub, bc and xxd tools to be installed.

I'm running this from cron on an Intel Compute Stick.

Temperatures returned are Celsius degrees.

## Usage

```
./mijia_mqtt.sh -a [address] -n [sensor name]

Mandatory arguments:

-a  | --address           Bluetooth MAC address of sensor.
-n  | --name              Name of the sensor to use for MQTT.

Optional arguments:

-b  | --broker            MQTT broker address. Default 127.0.0.1.
-r  | --retries           Number of max retry attempts. Default 6 times.
-p  | --prefix            MQTT topic prefix. Default homeauto/xiaomi.
-d  | --debug             Enable debug printouts.
-h  | --help
```

## Example

This queries Mijia sensor that has address 4c:65:a8:d9:3e:76 and reports the results to the MQTT broker at 192.168.99.13 using subtopic lab and printing the debug output:

```
root@green:~/src/mijia_mqtt# ./mijia_mqtt.sh -a 4c:65:a8:d9:3e:76 -n lab -b 192.168.99.13 -d
Querying 4c:65:a8:d9:3e:76 for temperature and humidity data.
Querying 4c:65:a8:d9:3e:76 for battery data.
Temperature: 21.2, Humidity: 59.2, Battery: 97
```

At the same time listening to the topic with mosquitto on another machine yields:

```
olli@homeserver:~$ mosquitto_sub -h 192.168.99.13 -v -t 'homeauto/#'
homeauto/xiaomi/lab/temperature 21.2
homeauto/xiaomi/lab/humidity 59.2
homeauto/xiaomi/lab/battery 97
```
