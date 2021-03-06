#!/bin/bash

source /opt/bin/functions.sh

export GEOMETRY="$SCREEN_WIDTH""x""$SCREEN_HEIGHT""x""$SCREEN_DEPTH"
echo "
{
  \"capabilities\": [
    {
      \"platform\": \"LINUX\",
      \"seleniumProtocol\": \"WebDriver\",
      \"browserName\": \"firefox\",
      \"maxInstances\": 2,
      \"version\": $FIREFOX_VERSION,
      \"cleanSession\": true
    }
  ],
  \"configuration\": {
    \"timeout\": 600000,
    \"browserTimeout\": 600000,
    \"maxSession\": 3,
    \"port\": 5555,
    \"registerCycle\":10000,
    \"register\": true,
    \"unregisterIfStillDownAfter\": 10000,
    \"hubPort\": 4444,
    \"hubHost\": $HUB_PORT_4444_TCP_ADDR,
    \"nodePolling\": 7000,
    \"nodeStatusCheckTimeout\": 10000,
    \"downPollingLimit\": 5
  }

}" > /opt/selenium/config.json

if [ ! -e /opt/selenium/config.json ]; then
  echo No Selenium Node configuration file, the node-base image is not intended to be run directly. 1>&2
  exit 1
fi

if [ -z "$HUB_PORT_4444_TCP_ADDR" ]; then
  echo Not linked with a running Hub container 1>&2
  exit 1
fi

function shutdown {
  kill -s SIGTERM $NODE_PID
  wait $NODE_PID
}

REMOTE_HOST_PARAM=""
if [ ! -z "$REMOTE_HOST" ]; then
  echo "REMOTE_HOST variable is set, appending -remoteHost"
  REMOTE_HOST_PARAM="-remoteHost $REMOTE_HOST"
fi

if [ ! -z "$SE_OPTS" ]; then
  echo "appending selenium options: ${SE_OPTS}"
fi

# TODO: Look into http://www.seleniumhq.org/docs/05_selenium_rc.jsp#browser-side-logs

SERVERNUM=$(get_server_num)
env | cut -f 1 -d "=" | sort > asroot
  sudo -E -u seluser -i env | cut -f 1 -d "=" | sort > asseluser
  sudo -E -i -u seluser \
  $(for E in $(grep -vxFf asseluser asroot); do echo $E=$(eval echo \$$E); done) \
  DISPLAY=$DISPLAY \
  echo java ${JAVA_OPTS} -cp /opt/selenium/selenium-video-node-1.7.jar:/opt/selenium/selenium-server-standalone-2.53.0.jar org.openqa.grid.selenium.GridLauncher -servlets com.aimmac23.node.servlet.VideoRecordingControlServlet -proxy com.aimmac23.hub.proxy.VideoProxy\
           -role wd \
           -hub http://$HUB_PORT_4444_TCP_ADDR:$HUB_PORT_4444_TCP_PORT/grid/register \
           ${REMOTE_HOST_PARAM} \
           -nodeConfig /opt/selenium/config.json \
           ${SE_OPTS}
  xvfb-run -n $SERVERNUM --server-args="-screen 0 $GEOMETRY -ac +extension RANDR" \
  java ${JAVA_OPTS} -cp /opt/selenium/selenium-video-node-1.7.jar:/opt/selenium/selenium-server-standalone-2.53.0.jar org.openqa.grid.selenium.GridLauncher -servlets com.aimmac23.node.servlet.VideoRecordingControlServlet -proxy com.aimmac23.hub.proxy.VideoProxy\
    -role wd \
    -hub http://$HUB_PORT_4444_TCP_ADDR:$HUB_PORT_4444_TCP_PORT/grid/register \
    ${REMOTE_HOST_PARAM} \
    -nodeConfig /opt/selenium/config.json \
    ${SE_OPTS} &
NODE_PID=$!


trap shutdown SIGTERM SIGINT
for i in $(seq 1 10)
do
  xdpyinfo -display $DISPLAY >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    break
  fi
  echo Waiting xvfb...
  sleep 0.5
done

fluxbox -display $DISPLAY &

x11vnc -forever -usepw -shared -rfbport 5900 -display $DISPLAY &

wait $NODE_PID
