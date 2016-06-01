#!/bin/bash

: ${HADOOP_PREFIX:=/usr/local/hadoop}
: ${ZOO_HOME:=/usr/local/zookeeper}
: ${HBASE_HOME:=/usr/local/hbase}

rm /tmp/*.pid


$HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_PREFIX/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

sed s/HOSTNAME/$HOSTNAME/ /usr/local/hadoop/etc/hadoop/core-site.xml.template > /usr/local/hadoop/etc/hadoop/core-site.xml

# setting spark defaults
#echo spark.yarn.jar hdfs:///spark/spark-assembly-1.6.0-hadoop2.4.0.jar > $SPARK_HOME/conf/spark-defaults.conf
cp $SPARK_HOME/conf/metrics.properties.template $SPARK_HOME/conf/metrics.properties

service sshd start
$HADOOP_PREFIX/sbin/start-dfs.sh
$HADOOP_PREFIX/sbin/start-yarn.sh
$HBASE_HOME/bin/start-hbase.sh


#start creating database
echo "waiting 10 seconds and then start creating database schema"
sleep 10s
/usr/local/phoenix/bin/sqlline.py localhost /opt/interset/create.sql
/usr/local/phoenix/bin/psql.py -d ',' -t OBSERVED_ENTITY_RELATION_MINUTELY_COUNTS localhost /opt/interset/minutedata.csv

sed -i 's/tenantID = 0/tenantID = CA/g' /opt/interset/interset.conf
/opt/interset/analytics-dev/bin/training.sh /opt/interset/interset.conf
#/opt/interset/analytics-dev/bin/scoring.sh /opt/interset/interset.conf

if [[ $1 == "-d" ]]; then
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi

if [[ $1 == "-sqlline" ]]; then
  /usr/local/phoenix/hadoop2/bin/sqlline.py localhost
fi
