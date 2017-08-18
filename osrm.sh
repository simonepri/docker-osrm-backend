#!/bin/sh
OSRM_DATA_PATH="/data"

_sig() {
  kill -TERM $child 2>/dev/null
}

trap _sig SIGKILL SIGTERM SIGHUP SIGINT EXIT

if [ ! -f $OSRM_DATA_PATH/$OSRM_MAP_NAME.osrm.hsgr ]; then
  if [ ! -f $OSRM_DATA_PATH/$OSRM_MAP_NAME.osm.pbf ]; then
    echo "Downloading $OSRM_MAP_NAME from $MAP_URL"
    wget -O $OSRM_DATA_PATH/$OSRM_MAP_NAME.osm.pbf $MAP_URL
    reteval=$?
    if [ ${reteval} -ne 0 ]; then
      echo "$OSRM_MAP_NAME download to $OSRM_DATA_PATH/$OSRM_MAP_NAME.osm.pbf failed"
      exit 1;
    fi
    FILESIZE=$(stat -c%s "$OSRM_DATA_PATH/$OSRM_MAP_NAME.osm.pbf")
    echo "$OSRM_MAP_NAME downloaded to $OSRM_DATA_PATH/$OSRM_MAP_NAME.osm.pbf ($FILESIZE bytes) bytes"
  fi
  
  echo "Extracting the Road Network from $OSRM_DATA_PATH/$OSRM_MAP_NAME.osm.pbf using $OSRM_PROFILE profile"
  osrm-extract -p /opt/$OSRM_PROFILE.lua $OSRM_DATA_PATH/$OSRM_MAP_NAME.osm.pbf
  reteval=$?
  if [ ${reteval} -ne 0 ]; then
    echo "$OSRM_MAP_NAME extraction to $OSRM_DATA_PATH/$OSRM_MAP_NAME.osrm failed"
    exit 1;
  fi
  FILESIZE=$(stat -c%s "$OSRM_DATA_PATH/$OSRM_MAP_NAME.osrm")
  echo "$OSRM_MAP_NAME extracted to $OSRM_DATA_PATH/$OSRM_MAP_NAME.osrm ($FILESIZE bytes) bytes"
  
  echo "Deleting $OSRM_DATA_PATH/$OSRM_MAP_NAME.osm.pbf"
  rm $OSRM_DATA_PATH/$OSRM_MAP_NAME.osm.pbf
    
  echo "Creating the Hierarchy from $OSRM_DATA_PATH/$OSRM_MAP_NAME.osrm"
  osrm-contract $OSRM_DATA_PATH/$OSRM_MAP_NAME.osrm
  if [ ${reteval} -ne 0 ]; then
    echo "$OSRM_MAP_NAME hierarchy precomputation to $OSRM_DATA_PATH/$OSRM_MAP_NAME.osrm.hsgr failed"
    exit 1;
  fi
  FILESIZE=$(stat -c%s "$OSRM_DATA_PATH/$OSRM_MAP_NAME.osrm.hsgr")
  echo "$OSRM_MAP_NAME hierarchy precomputed to $OSRM_DATA_PATH/$OSRM_MAP_NAME.osrm.hsgr ($FILESIZE bytes) bytes"
  
  echo "$OSRM_MAP_NAME.osm.pbf pre-processing ended"
fi

echo "Starting routing engine HTTP server"
osrm-routed $OSRM_DATA_PATH/$OSRM_MAP_NAME.osrm $OSRM_PARAMS &
child=$!
wait "$child"
