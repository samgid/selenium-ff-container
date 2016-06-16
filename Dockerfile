FROM selenium/node-firefox-debug:2.53.0
#ADD http://repo1.maven.org/maven2/com/aimmac23/selenium-video-node/1.9/selenium-video-node-1.9.jar /opt/selenium/
ADD https://aimmac23.com/public/maven-repository/com/aimmac23/selenium-video-node/1.7/selenium-video-node-1.7.jar /opt/selenium/
ADD http://selenium-release.storage.googleapis.com/2.53/selenium-server-standalone-2.53.0.jar /opt/selenium/
ADD config.json /opt/selenium/config.json

ENV ARIK 1
#==============================
# Scripts to run Selenium Node
#==============================
RUN echo \
{
  \"capabilities\": [
    {
      \"platform\": \"LINUX\",
      \"seleniumProtocol\": \"WebDriver\",
      \"browserName\": \"firefox\",
      \"maxInstances\": 2,
      \"version\": \"45\"
    }
   > /opt/selenium/config2.json

COPY generate_config /opt/selenium/generate_config
COPY entry_point.sh /opt/bin/entry_point.sh
RUN chmod +x /opt/bin/entry_point.sh

#Default port of VNC
EXPOSE 5900