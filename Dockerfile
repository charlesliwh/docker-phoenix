FROM sequenceiq/hadoop-docker:2.7.1
MAINTAINER SequenceIQ



#Java
RUN curl -LO 'http://download.oracle.com/otn-pub/java/jdk/8u91-b14/jdk-8u91-linux-x64.rpm' -H 'Cookie: oraclelicense=accept-securebackup-cookie'
RUN rpm -i jdk-8u91-linux-x64.rpm
RUN rm jdk-8u91-linux-x64.rpm

ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin
RUN rm /usr/bin/java && ln -s $JAVA_HOME/bin/java /usr/bin/java

# Zookeeper
ENV ZOOKEEPER_VERSION 3.4.6
RUN curl -s http://mirror.csclub.uwaterloo.ca/apache/zookeeper/zookeeper-$ZOOKEEPER_VERSION/zookeeper-$ZOOKEEPER_VERSION.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./zookeeper-$ZOOKEEPER_VERSION zookeeper
ENV ZOO_HOME /usr/local/zookeeper
ENV PATH $PATH:$ZOO_HOME/bin
RUN mv $ZOO_HOME/conf/zoo_sample.cfg $ZOO_HOME/conf/zoo.cfg
RUN mkdir /tmp/zookeeper

# HBase
ENV HBASE_MAJOR 1.1
ENV HBASE_MINOR 5 
ENV HBASE_VERSION "${HBASE_MAJOR}.${HBASE_MINOR}"
RUN	if [ $HBASE_MAJOR == 0.98 ]; then \
		curl -s http://apache.mirror.gtcomm.net/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-hadoop2-bin.tar.gz | tar -xz -C /usr/local/ && \
		cd /usr/local && ln -s ./hbase-$HBASE_VERSION-hadoop2 hbase; \
	elif [ $HBASE_MAJOR == 1.0 ]; then \
		curl -s http://apache.mirror.gtcomm.net/hbase/hbase-$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz | tar -xz -C /usr/local/ && \
		cd /usr/local && ln -s ./hbase-$HBASE_VERSION hbase; \
	else \
		curl -s http://apache.mirror.gtcomm.net/hbase/$HBASE_VERSION/hbase-$HBASE_VERSION-bin.tar.gz | tar -xz -C /usr/local/ && \
		cd /usr/local && ln -s ./hbase-$HBASE_VERSION hbase; \
	fi
ENV HBASE_HOME /usr/local/hbase
ENV PATH $PATH:$HBASE_HOME/bin

# Phoenix
ENV PHOENIX_VERSION 4.7.0
RUN curl -s http://apache.mirror.vexxhost.com/phoenix/phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR/bin/phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-bin.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-bin phoenix
ENV PHOENIX_HOME /usr/local/phoenix
ENV PATH $PATH:$PHOENIX_HOME/bin
RUN ln -s $PHOENIX_HOME/phoenix-core-$PHOENIX_VERSION-HBase-$HBASE_MAJOR.jar $HBASE_HOME/lib/phoenix.jar
RUN ln -s $PHOENIX_HOME/phoenix-$PHOENIX_VERSION-HBase-$HBASE_MAJOR-server.jar $HBASE_HOME/lib/phoenix-server.jar

# Spark
ENV SPARK_VERSION 1.6.0
ENV SPARK_HADOOP hadoop2.4 
RUN curl -s http://d3kbcqa49mib13.cloudfront.net/spark-1.6.0-bin-hadoop2.4.tgz | tar -xz -C /usr/local
#RUN curl -s http://apache.mirror.gtcomm.net/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-$SPARK_HADOOP.tgz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s ./spark-$SPARK_VERSION-bin-$SPARK_HADOOP spark
ENV SPARK_HOME /usr/local/spark

ADD spark-defaults.conf $SPARK_HOME/conf/spark-defaults.conf

# HBase and Phoenix configuration files
RUN rm $HBASE_HOME/conf/hbase-site.xml
RUN rm $HBASE_HOME/conf/hbase-env.sh
ADD hbase-site.xml $HBASE_HOME/conf/hbase-site.xml
ADD hbase-env.sh $HBASE_HOME/conf/hbase-env.sh

# bootstrap-phoenix
ADD bootstrap-phoenix.sh /etc/bootstrap-phoenix.sh
RUN chown root:root /etc/bootstrap-phoenix.sh
RUN chmod 700 /etc/bootstrap-phoenix.sh

CMD ["/etc/bootstrap-phoenix.sh", "-bash"]

# expose Zookeeper and Phoenix queryserver ports
EXPOSE 2181 8765
