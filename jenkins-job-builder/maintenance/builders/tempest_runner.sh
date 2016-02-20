#!/bin/bash -xe

REPORT_PATH="${REPORT_PREFIX}/${ENV_NAME}_${SNAPSHOT_NAME}"
echo "$REPORT_PATH" > ./param.pm
echo "$BUILD_URL" > ./build_url

git clone https://github.com/Mirantis/mos-integration-tests
cd mos-integration-tests

echo 'from mos_tests.environment.devops_client import DevopsClient' > temp.py
echo "print DevopsClient.get_admin_node_ip('$ENV_NAME')" >> temp.py
MASTER_NODE_IP=`python temp.py`
echo "$MASTER_NODE_IP"

cd ..

virtualenv venv
source venv/bin/activate
sudo docker build -t rally-tempest custom-scripts/rally-tempest/
sudo docker save -o ./dimage rally-tempest
echo '' > ~/.ssh/known_hosts
sshpass -p 'r00tme' scp -o "StrictHostKeyChecking no" dimage root@"$MASTER_NODE_IP":/root/rally

echo '#!/bin/bash -xe' > ssh_scr.sh
echo 'docker load -i /root/rally' >> ssh_scr.sh

wget https://raw.githubusercontent.com/Mirantis/mos-ci-deployment-scripts/master/jenkins-job-builder/product/superjobs/RallyTempest/rally_tempest_prepare_host.sh
cat rally_tempest_prepare_host.sh >> ssh_scr.sh
echo '' >> ssh_scr.sh

echo 'docker images | grep rally > temp.txt' >> ssh_scr.sh
echo 'awk '\''{print $3}'\'' temp.txt > ans' >> ssh_scr.sh
echo 'ID=`cat ans`' >> ssh_scr.sh
echo 'echo $ID' >> ssh_scr.sh

echo 'docker run -tid -v /var/lib/rally-tempest-container-home-dir:/home/rally --net host "$ID" > dock.id' >> ssh_scr.sh
echo 'DOCK_ID=`cat dock.id`' >> ssh_scr.sh
#     echo 'echo '\''export OS_AUTH_URL=http://10.109.7.3:5000/v2.0'\'' >> /var/lib/rally-tempest-container-home-dir/openrc' >> ssh_scr.sh
echo 'OAU=`fgrep OS_AUTH_URL /var/lib/rally-tempest-container-home-dir/openrc` && OAUV2="$OAU"v2.0 && echo "$OAUV2" >> /var/lib/rally-tempest-container-home-dir/openrc' >> ssh_scr.sh
echo 'docker exec "$DOCK_ID" setup-tempest' >> ssh_scr.sh

#temp_fix

#echo 'OS_AUTH=`fgrep OS_AUTH_URL /var/lib/rally-tempest-container-home-dir/openrc`' >> ssh_scr.sh
#echo '$OS_AUTH_URL_V="$OS_AUTH"v2.0' >> ssh_scr.sh
#echo 'echo "$OS_AUTH_URL_V" >> /var/lib/rally-tempest-container-home-dir/openrc' >> ssh_scr.sh
echo 'docker exec "$DOCK_ID" bash -c "source /home/rally/openrc && rally verify start --system-wide"' >> ssh_scr.sh




echo 'docker exec "$DOCK_ID" bash -c "rally verify results --json --output-file output.json" ' >> ssh_scr.sh
echo 'docker exec "$DOCK_ID" bash -c "rm -rf rally_json2junit && git clone https://github.com/EduardFazliev/rally_json2junit.git && python rally_json2junit/rally_json2junit/results_parser.py output.json" ' >> ssh_scr.sh
chmod +x ssh_scr.sh
sshpass -p 'r00tme' scp -o "StrictHostKeyChecking no" ssh_scr.sh root@"$MASTER_NODE_IP":/root/
echo 'chmod +x /root/ssh_scr.sh && /bin/bash -xe /root/ssh_scr.sh > /root/log.log' | sshpass -p 'r00tme' ssh -T root@"$MASTER_NODE_IP"
sshpass -p 'r00tme' scp -o "StrictHostKeyChecking no" root@"$MASTER_NODE_IP":/root/log.log ./
sshpass -p 'r00tme' scp -o "StrictHostKeyChecking no" root@"$MASTER_NODE_IP":/var/lib/rally-tempest-container-home-dir/verification.xml ./
deactivate