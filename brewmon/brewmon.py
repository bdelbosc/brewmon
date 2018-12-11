#!/usr/bin/env python
# -*- coding: utf-8 -*-
""" BrewMon lib
"""
from datetime import datetime

from influxdb import InfluxDBClient
from pytz import reference
from pytz import timezone

LOCAL_TIME = reference.LocalTimezone()

DEFAULT_DATABASE = "brewmon"
DEFAULT_HOST = "localhost"
DEFAULT_TCP_PORT = 8086
DEFAULT_UDP_PORT = 4444

STATE_IDLE = "0"
STATE_OFF = "1"
STATE_DOOR_OPEN = "2"
STATE_HEATING = "3"
STATE_COOLING = "4"
STATE_WAITING_TO_COOL = "5"
STATE_WAITING_TO_HEAT = "6"
STATE_WAITING_FOR_PEAK = "7"
STATE_COOLING_MIN_TIME = "8"
STATE_HEATING_MIN_TIME = "9"


class BrewMon(object):
    fields = ['beer_temp', 'beer_setting_temp', 'fridge_temp', 'fridge_setting_temp', 'room_temp',
              'state_idle', 'state_heating', 'state_cooling', 'state_waiting_for_peak',
              'state_cooling_min_time', 'state_heating_min_time',
              'state_waiting_to_cool', 'state_waiting_to_heat', 'state_off', 'state_door_open', 'title',
              'tags']

    def __init__(self, host=DEFAULT_HOST, port=DEFAULT_TCP_PORT, database=DEFAULT_DATABASE, udp=False, verbose=False,
                 batch_size=100, time_precision="s"):
        self.udp = udp
        self.verbose = verbose
        self.points = []
        self.batch_size = batch_size
        self.time_precision = time_precision
        if udp:
            if port == DEFAULT_TCP_PORT:
                port = DEFAULT_UDP_PORT
            if verbose:
                print("# Connect to influxdb udp://" + host + ":" + str(port) + "/" + database)
            self.client = InfluxDBClient(host, database=database, use_udp=True, udp_port=port)
        else:
            if verbose:
                print("# Connect to influxdb http://" + host + ":" + str(port) + "/" + database)
            self.client = InfluxDBClient(host, port, database=database)

    def publish_line(self, beer_name, line):
        self.publish_row(beer_name, line.split(';'))

    def publish_row(self, beer_name, row):
        point = get_beer_point(beer_name, row)
        if self.verbose:
            print(point)
        self.publish_point(point)

    def publish_point(self, point):
        self.client.write_points([point], time_precision=self.time_precision)

    def publish_points(self, points):
        self.client.write_points(points, time_precision=self.time_precision)

    def add_beer_row(self, beer_name, row):
        self.points.append(get_beer_point(beer_name, row))
        if len(self.points) > self.batch_size:
            self.flush()

    def add_ispindel_row(self, row):
        self.points.append(get_ispindel_point(row))
        if len(self.points) > self.batch_size:
            self.flush()

    def flush(self):
        if len(self.points) > 0:
            if self.verbose:
                print("flush")
            self.publish_points(self.points)
            self.points = []


def get_beer_point(beer_name, row):
    time = get_epoch(row[0])
    tags = {"beer_name": beer_name}
    fields = {'beer_temp': float(row[1]),
              'beer_setting_temp': float(row[2]),
              'fridge_temp': float(row[4]),
              'fridge_setting_temp': float(row[5]),
              'room_temp': float(row[8])}
    fields.update(get_states(row[7]))
    fields.update(get_beer_annotation(row[3]))
    return {
        "measurement": beer_name,
        "tags": tags,
        "time": time,
        "fields": fields
    }


def get_states(state):
    if state == STATE_IDLE:
        return {"state_idle": 1}
    if state == STATE_HEATING:
        return {"state_heating": 1}
    if state == STATE_COOLING:
        return {"state_cooling": 1}
    if state == STATE_WAITING_FOR_PEAK:
        return {"state_idle": 1, "state_waiting_for_peak": 1}
    if state == STATE_WAITING_TO_COOL:
        return {"state_idle": 1, "state_waiting_to_cool": 1}
    if state == STATE_WAITING_TO_HEAT:
        return {"state_idle": 1, "state_waiting_to_heat": 1}
    if state == STATE_COOLING_MIN_TIME:
        return {"state_cooling": 1, "state_cooling_min_time": 1}
    if state == STATE_HEATING_MIN_TIME:
        return {"state_heating": 1, "state_heating_min_time": 1}
    if state == STATE_OFF:
        return {"state_off": 1}
    if state == STATE_DOOR_OPEN:
        return {"state_door_open": 1}
    print("Unknown state: " + state)
    return {}


def get_beer_annotation(text):
    annotation = None
    if text and text != 'null':
        annotation = text
    return {"title": annotation, "tags": "brewpi"}


def get_utc_datetime(time):
    # this is crazy ...
    dt = datetime.strptime(time, "%b %d %Y %H:%M:%S")
    local_tz = timezone(LOCAL_TIME.tzname(dt))
    return local_tz.normalize(local_tz.localize(dt))


def get_epoch(time):
    dt = get_utc_datetime(time)
    utc_naive = dt.replace(tzinfo=None) - dt.utcoffset()
    return int((utc_naive - datetime(1970, 1, 1)).total_seconds())

def get_ispindel_point(row):
    time = int(row[1])
    tags = {"source": row[6]}
    fields = {'RSSI': float(row[2]),
              'battery': float(row[3]),
              'gravity': float(row[4]),
              'interval': int(row[5]),
              'temp_unit': row[7],
              'temperature': float(row[8]),
              'tilt': float(row[9])}
    return {
        "measurement": row[0],
        "tags": tags,
        "time": time,
        "fields": fields
    }
