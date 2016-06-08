FROM selenium/node-firefox-debug:2.53.0
ADD http://repo1.maven.org/maven2/com/aimmac23/selenium-video-node/1.9/selenium-video-node-1.9.jar /opt/selenium/
ADD http://selenium-release.storage.googleapis.com/index.html?path=2.53/selenium-server-standalone-2.53.0.jar /opt/selenium/
ADD config.json /opt/selenium/config.json


#==============================
# Scripts to run Selenium Node
#==============================
COPY entry_point.sh /opt/bin/entry_point.sh
RUN chmod +x /opt/bin/entry_point.sh

#Default port of VNC
EXPOSE 5900