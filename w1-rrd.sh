#!/bin/bash
#

RRD_DIR=/var/lib/rrd

RRD_AUSSEN=${RRD_DIR}/aussen.rrd
RRD_AUFENTH=${RRD_DIR}/aufenth.rrd
RRD_VERWALT=${RRD_DIR}/verwalt.rrd
RRD_UFBUERO=${RRD_DIR}/ufbuero.rrd

SENSOR_AUSSEN=10-0008025fdbf2
SENSOR_AUFENTH=10-0008025fed39
SENSOR_VERWALT=10-0008025ff6a5
SENSOR_UFBUERO=10-0008025fece9

PIC_DAY_AUSSEN=/usr/share/nginx/html/temp/aussen_day.png
PIC_DAY_AUFENTH=/usr/share/nginx/html/temp/aufenth_day.png
PIC_DAY_VERWALT=/usr/share/nginx/html/temp/verwalt_day.png
PIC_DAY_UFBUERO=/usr/share/nginx/html/temp/ufbuero_day.png

function read_sensor_data {
  SENS=$1
  SENS_DATA=`cat /sys/bus/w1/devices/${SENS}/w1_slave`
  SENS_DATA=`echo ${SENS_DATA} | grep crc | grep YES`
  if [ -n "${SENS_DATA}" ]; then
    SENS_DATA=`echo ${SENS_DATA} | cut -d '=' -f3 | awk '{print $1/1000}'`
  fi
}

function usage() {
cat << EOF
usage: $0 options

This script creates or updates rrd-data or creates graphs

OPTIONS:
   -h      Show this message
   -c      Creates rrd-databases
   -u      Updates Rrd-Databases using the w1 Values
   -g      Creates graphs for Webserver
EOF
}

function create_rrd() {
  FILE=$1
  if [ -f ${FILE} ]; then
    rm ${FILE}
  fi
  /usr/bin/rrdtool create ${FILE} --step 60 \
    DS:temp:GAUGE:240:-25:100 \
    RRA:AVERAGE:0.5:1:2160 \
    RRA:AVERAGE:0.5:5:2016 \
    RRA:AVERAGE:0.5:15:2880 \
    RRA:AVERAGE:0.5:60:8760 \
    RRA:MIN:0.5:1:2160 \
    RRA:MIN:0.5:5:2016 \
    RRA:MIN:0.5:15:2880 \
    RRA:MIN:0.5:60:8760 \
    RRA:MAX:0.5:1:2160 \
    RRA:MAX:0.5:5:2016 \
    RRA:MAX:0.5:15:2880 \
    RRA:MAX:0.5:60:8760
}

function create_rrd_databases() {
  echo "Creating RRD-Databases"
  create_rrd ${RRD_AUSSEN}
  create_rrd ${RRD_AUFENTH}
  create_rrd ${RRD_VERWALT}
  create_rrd ${RRD_UFBUERO}
}

function update_data() {
  DATABASE=$1
  VALUE=$2
  #echo "Writing Value ${VALUE} in Database ${DATABASE}"
  /usr/bin/rrdtool update ${DATABASE} ${VALUE}
}

function update_rrd_databases() {
  #echo "Updating Data in RRD-Database"

  read_sensor_data ${SENSOR_AUSSEN}
  update_data ${RRD_AUSSEN} N:${SENS_DATA}  

  read_sensor_data ${SENSOR_AUFENTH}
  update_data ${RRD_AUFENTH} N:${SENS_DATA}  

  read_sensor_data ${SENSOR_VERWALT}
  update_data ${RRD_VERWALT} N:${SENS_DATA}  

  read_sensor_data ${SENSOR_UFBUERO}
  update_data ${RRD_UFBUERO} N:${SENS_DATA}  
}

function make_graph() {
  RRD=$1
  PNG=$2
  echo "Creating GRAPH ${PNG} using Database ${RRD}"
  /usr/bin/rrdtool graph ${PNG} -a PNG -b 1024 --start -129600 -A \
    -l -10 -u 40 -t "Temperatur" \
    --vertical-label "Grad Celsius" -w 600 -h 200 \
    DEF:g1=${RRD}:temp:AVERAGE \
    DEF:gmin=${RRD}:temp:MIN \
    DEF:gmax=${RRD}:temp:MAX \
    VDEF:g1a=g1,LAST \
    VDEF:gmina=gmin,MINIMUM \
    VDEF:gmaxa=gmax,MAXIMUM \
    LINE2:g1#ff0000:"Temperatur" \
    GPRINT:g1a:"aktuell\: %5.2lf °C" \
    GPRINT:gmina:"tiefste\: %5.2lf °C" \
    GPRINT:gmaxa:"höchste\: %5.2lf °C" 
}

function create_rrd_graph() {
  echo "Creating RRD-Pictures"
  make_graph ${RRD_AUSSEN} ${PIC_DAY_AUSSEN}
  make_graph ${RRD_AUFENTH} ${PIC_DAY_AUFENTH}
  make_graph ${RRD_VERWALT} ${PIC_DAY_VERWALT}
  make_graph ${RRD_UFBUERO} ${PIC_DAY_UFBUERO}
}


while getopts "hcug" OPTION
do
  case $OPTION in
    h)
      usage
      exit 1
      ;;
    c)
      create_rrd_databases
      exit 0
      ;;
    u)
      update_rrd_databases
      exit 0
      ;;
    g)
      create_rrd_graph
      exit 0
      ;;
    ?)
      usage
      exit 0
      ;;
  esac
done
usage

