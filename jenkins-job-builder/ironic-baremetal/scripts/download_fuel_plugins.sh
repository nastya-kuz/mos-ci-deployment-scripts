export PLUGINS_PATH=$(pwd)/fuel_plugins

PLUGINS_ARCHIVE=${PLUGINS_ARCHIVE:-"http://cz7776.bud.mirantis.net:8080/jenkins/job/build_plugins/lastSuccessfulBuild/artifact/*zip*/archive.zip"}
TMPFILE=$(mktemp)
wget $PLUGINS_ARCHIVE -O $TMPFILE
unzip -jo $TMPFILE '*.rpm' -d $PLUGINS_PATH
rm $TMPFILE

# Get rabbit plugin separately
TMPFILE=$(mktemp)
wget https://plugin-ci.fuel-infra.org/job/9.0.fuel-plugin.detach-rabbitmq.build/lastSuccessfulBuild/artifact/*zip*/archive.zip -O $TMPFILE
unzip -jo $TMPFILE '*.rpm' -d $PLUGINS_PATH
rm $TMPFILE
