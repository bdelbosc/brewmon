# BrewMon: The Brew Dashboard

## About

BrewMon provides a customisable dashboard for beer fermentation with alerting support.

The fermentation metrics are coming from multiple sources, the first target is to support:

- [BrewPI](https://www.brewpi.com/) a great fermentation temperature controller that reports:
  - the wort (aka beer) temperature
  - the fermentation chamber (aka fridge) temperature
  - the room temperature
  - the beer setting temperature: the target temperature chosen by the brew master
  - the fridge setting temperature: the target temperature chosen by BrewPi to reach the beer setting
  - the state of the controller: cooling, heating, idling ...
  - Annotations when changing the beer setting or profile  

- [iSpindel](http://www.ispindel.de/) an amazing hydrometer that reports:
  - the wort gravity
  - the temperature of the wort
  - the battery level

This project is under active development.

## First screenshots

Here the first screenshots of the BrewMon dashboard just few minutes after soldering the iSpindel (the device is not yet calibrated
nor in the fermenter).

![brewmon screenshot 1](data/brewmon-screenshot1.gif)

![brewmon screenshot 2](data/brewmon-screenshot2.gif)

![brewmon screenshot 3](data/brewmon-screenshot3.gif)

An example of dashboard snapshot:

https://snapshot.raintank.io/dashboard/snapshot/Klzhv0csYbH4S39miAYi9Mi2H0yG4ERA


## Architecture

The solution relies on [Grafana](https://grafana.com/) which offers customisable dashboards, annotations and alerting.

The metrics are stored in an [InfluxDB](https://www.influxdata.com/time-series-platform/influxdb/) database.

BrewPi is patched to report metrics to InfluxDB in real time.

BrewMon provides a `bm-import` script to import existing BrewPi beer in CSV format into InfluxDB.

iSpindel is configured to report metrics to InfluxDB.


## Installation

### On RaspberryPi

One line installation on the Raspberry Pi running BrewPi in legacy version:
```bash
bash <(curl -Ss https://raw.githubusercontent.com/bdelbosc/brewmon/master/scripts/bm-install.sh)
```

This script will:
- install Debian packages for InfluxDB and Grafana, along with the BrewMon dashboard
- install the brewmon python package
- patch BrewPi script to report metrics into InfluxDB

### On amd64 architecture

Install [docker compose](https://docs.docker.com/compose/):
```bash
sudo -s
curl -fsSL get.docker.com -o get-docker.sh && sh get-docker.sh
pip install docker-compose
```

Then:
```
git clone https://github.com/bdelbosc/brewmon.git
cd brewmon/etc
docker-compose up -d
```

### Configuring iSpindel

Follow the iSpindel configuration:
- Connect the iSpindel to a computer and install the latest firmware (>= 5.8.5)
- Press the Wemos button and connect to the iSpindel AP
- Configure your Wifi access
- Select the InfluxDB reporting
  - use the BrewPi IP (or the IP where InfluxDB is installed) and the port 8086
  - use `brewmon` database

See below to check if you have data in InfluxDB coming from the iSpindel.

## Usage

### Grafana dashboard

Grafana starts with a provisioned InfluxDB data source and the BrewMon dashboard.

Grafana is accessible on port 3000 of your BrewPi for instance: [http://brewpi:3000/](http://brewpi:3000/).

You can login using the `admin` account with the default `admin` password.

The provisioned dashboard is named "BrewMon Template".
You need to create a copy to be able to edit the dasboard,
this can be done using the top menu: Settings > Save As...

Visit the [Getting started documentation](http://docs.grafana.org/guides/getting_started/) to learn more about Grafana. 

### Import existing BrewPi beer metrics

BrewPi saves beer metrics into CSV files under `/var/www/html/data/`.

To import a CSV file into InfluxDB use the `bm-import` script: 

```bash
# Import file into local influxdb http://localhost:8086/brewpi
bm-import /var/www/html/data/Kolsch/Kolsch.csv
# Importing beer 'Kolsch' from file: '/var/www/html/data/Kolsch/Kolsch.csv'
# 6869 rows imported from: Dec 02 2018 15:51:15 to Dec 11 2018 17:35:37

# For more options
bm-import --help
```

### Export/Import iSpindel metrics

You can export the iSpindel metrics stored in InfluxDB as a CSV file.

This can be done from the BrewPi (or the InfluxDB container): 
```bash
 influx -database 'brewmon' -execute 'SELECT * FROM "measurements"' -format 'csv' > /tmp/spindel.csv
```

This CSV file can be also imported into InfluxDB using `bm-import`:
```bash
bm-import --ispindel /tmp/ispindel.csv
# Importing iSpindel from file: '/tmp/ispindel.csv'
# 2918 rows imported
```


## Limitations

For now BrewMon is only tested on:
- Raspberry Pi 3B+
- Raspian 9.6
- BrewPi legacy version    
- iSpindel Firmware 6.0.2

Known limitations of Grafana (v5.4):
- The X Axis dates [are displayed only in American format](https://github.com/grafana/grafana/issues/1459) `mm/dd`
- [Mobile support is a bit limited](https://github.com/grafana/grafana/issues/8799)
- Snapshot
  - does not include annotations
  - can be exported as file using REST but the [import API does not exists](https://github.com/grafana/grafana/issues/10401).


## Development

### Rationales

Grafana and InfluxDB are light enough to run on the same RaspberryPi (RPI) used by BrewPi.

Grafana offers customisable dashboard with alerting capabilities, a dashboard and its content can be easily shared using [raintank.io](http://snapshot.raintank.io/info/) 
 
The storage is based on InfluxDB because:
- it is supported by iSpindel (not like Graphite)
- it is able to import existing data (not like Prometheus)
- it has an infinite retention by default (not like Graphite/Prometheus) 
- it supports the UDP protocol

InfluxDB can also be used for other metrics during mashing when using CraftBeer or simply to monitor the RPI OS.

BrewPi needs to be patched without creating any regression, for this reason the metrics are exported continuously using UDP.

Installation on Raspberry Pi relies on Debian package because at the moment there is no Grafana docker image for `armhf` architecture.

### InfluxDB database

The default database is named `brewmon` and there is one series per BrewPi beer and one series for iSpindel.

All date are stored in UTC, Grafana will manage your timezone.
 
From the RaspberryPi you can run [`influx`](https://docs.influxdata.com/influxdb/v1.7/tools/shell/) to get an interpreter:
```bash
ssh brewpi
influx
```
On docker just run

```bash
docker exec -it influxdb /usr/bin/influx
```

From there you can access the metrics:
```sql
-- Select the database and display timestamp as date
> USE brewmon
> precision rfc3339

-- List beers
> SHOW series
key
---
Kolsch,beer_name=Kolsch
measurements,source=iSpindel000

-- Show BrewPi annotation for a beer
> SELECT title FROM "Kolsch"
name: Kolsch
time                 title
----                 -----
2018-12-03T22:28:21Z Beer temp set to 18.7 in web interface
2018-12-04T10:20:12Z Beer temp set to 18.5 in web interface
2018-12-05T13:36:59Z Beer temp set to 19.0 in web interface

-- Delete some points, it requires time as nano second timestamp
> precision ns
> SELECT time, beer_temp FROM "Kolsch" WHERE beer_temp <= 18.0 and time > '2018-12-05'
name: Kolsch
time                beer_temp
----                ---------
1544007570000000000 15.93
1544007449000000000 17.33
1544007690000000000 17.85
> DELETE FROM "Kolsch" WHERE time = 1544007570000000000
> DELETE FROM "Kolsch" WHERE time = 1544007449000000000
> DELETE FROM "Kolsch" WHERE time = 1544007690000000000

-- Add an annotation using a timestamp in ns
> INSERT Kolsch,beer_name=Kolsch title="Some annotation" 1544007690000000000

-- Query the iSpindel data
> SELECT * FROM "measurements" WHERE time >= now() - 5m
name: measurements
time                           RSSI battery  gravity   interval source      temp_units temperature tilt
----                           ---- -------  -------   -------- ------      ---------- ----------- ----
2018-12-07T14:55:55.159109731Z -70  3.592284 2.844413  120      iSpindel000 C          20.4375     30.86859

-- Delete metrics related to a beer
DROP SERIES FROM "Kolsch"
```


## License

[GNU GENERAL PUBLIC LICENSE](https://www.gnu.org/licenses/gpl.txt)
