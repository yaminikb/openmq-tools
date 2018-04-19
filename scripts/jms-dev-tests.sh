#!/bin/sh -x

echo $PWD
echo $WORKSPACE 
ls

S1AS_HOME=$WORKSPACE/glassfish5/glassfish
export S1AS_HOME

APS_HOME=$WORKSPACE/appserver/tests/appserv-tests
export APS_HOME

#Download latest Glassfish nightly build
GF_BUILD=https://download.oracle.com/glassfish/5.0.1/nightly
GF_BUNDLE=latest-glassfish.zip

#Dowload upstream MQ artifact
MQ_BUILD=$WORKSPACE/mq/dist/bundles
export MQ_BUILD
MQ_BUNDLE=mq5_1_1.zip
export MQ_BUNDLE

#Install GlassFish
echo "cd workspace $WORKSPACE"
cd ${WORKSPACE}
wget -q $GF_BUILD/$GF_BUNDLE 
echo "unzip $GF_BUNDLE"
unzip -q $GF_BUNDLE
rm -f GF_BUNDLE

#Overwrite MQ installation in GlassFish
cd ${WORKSPACE}/glassfish5
rm -rf mq
wget -q $MQ_BUILD/$MQ_BUNDLE
unzip -q $MQ_BUNDLE

cd ${WORKSPACE}/glassfish5/glassfish/modules
cp -f ${WORKSPACE}/glassfish5/mq/lib/jms.jar javax.jms-api.jar
cd ${WORKSPACE}/glassfish5/glassfish/lib/install/applications

rm -rf jmsra
mkdir jmsra
cd jmsra
cp ${WORKSPACE}/glassfish5/mq/lib/imqjmsra.rar .
jar vxf imqjmsra.rar

#Turn security manager before running the tests
echo "$S1AS_HOME/bin/asadmin start-domain"
time $S1AS_HOME/bin/asadmin start-domain 
echo "$S1AS_HOME/bin/asadmin create-jvm-options -Djava.security.manager"
$S1AS_HOME/bin/asadmin create-jvm-options -Djava.security.manager
echo "$S1AS_HOME/bin/asadmin stop-domain"
$S1AS_HOME/bin/asadmin stop-domain

cd $APS_HOME/devtests/jms

#Trigger the tests
#TODO: Remove the javac1.7 setting when ant 1.9.x or 1.10.x is available.
#      (The current ant 1.8.4 is not compatible with JDK 8)
#ant -Dbuild.compiler=javac1.7 all
ant all

echo "$S1AS_HOME/bin/asadmin list-domains"
$S1AS_HOME/bin/asadmin list-domains

echo "Done with the test"


