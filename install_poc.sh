#!/bin/bash

HTMLGW_FQDN=htmlgw.cyberarkdemo.com
STOREPASS=Cyberark1 #default value - changed during script
GUACPASS=changeit
OFFLINE=Yes
CATALINA_HOME=/opt/tomcat
TOMCAT="./dependencies/apache-tomcat-7.0.96.tar.gz"
HTMLGWRPM="CARKpsmgw-10.10.0.2.el7.x86_64.rpm"
URL=http://apache.crihan.fr/dist/tomcat/tomcat-7/v7.0.96/bin/$TOMCAT
TEMPDIR=/tmp/HTMLGW

echo -e "*************************************** Installation Wizard ***************************************\n"

read -p 'Fully Qualified Domain Name (FQDN) of this HTML5 Gateway, same as in PVWA configuration (example : htmlgw.cyberarkdemo.com) : ' HTMLGW_FQDN
read -sp 'Password for the self-signed certificate : ' STOREPASS
echo

mkdir $TEMPDIR
chmod 744 $TEMPDIR
cp -R * $TEMPDIR/
firewall-cmd --permanent --add-forward-port=port=443:proto=tcp:toport=8443
firewall-cmd --reload

if  [[ $OFFLINE = "Yes" ]]; then
      yum -y --nogpgcheck localinstall $TEMPDIR/dependencies/*.rpm
else
      yum -y install cairo libpng libjpeg java java-devel openssl
fi

echo -e "*************************************** Installing Dependencies ***************************************\n"

#yum update
cd /opt/
if  [ ! -f "$TEMPDIR/$TOMCAT" ]; then
	echo -e "Downloading tomcat ...\n"
	wget -P "$TEMPDIR/ $URL"
fi
tar -xvf $TEMPDIR/$TOMCAT -C /opt/
groupadd tomcat
useradd -M -s /bin/nologin -g tomcat -d $CATALINA_HOME tomcat
FOLD_TMP=$(echo "${TOMCAT%.tar.gz}")
mv /opt/$FOLD_TMP/ $CATALINA_HOME/

echo -e "*************************************** Configuring Tomcat ***************************************\n"

chown -R tomcat:tomcat $CATALINA_HOME
cp -v $TEMPDIR/tomcat.service /etc/systemd/system/
cp -v $TEMPDIR/server.xml $CATALINA_HOME/conf/
sed -i "s/Cyberark1/$STOREPASS/g" $CATALINA_HOME/conf/server.xml
chmod +x /etc/systemd/system/tomcat.service
chown root:root /etc/systemd/system/tomcat.service
systemctl daemon-reload
systemctl start tomcat
systemctl enable tomcat
keytool -genkey -alias CYBERARK -keyalg RSA -keystore /opt/tomcat/keystore -ext "san=dns:$HTMLGW_FQDN" -dname "CN=$HTMLGW_FQDN, OU=POC, O=Cyberark, L=Unknown, ST=Unknown, C=FR" -storepass $STOREPASS -keypass $STOREPASS
#keytool -genkey -alias user_to_tomcat -keyalg RSA -keystore "$CATALINA_HOME"/keystore -ext san=dns:"$HTMLGW_FQDN"
openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout $CATALINA_HOME/key.pem -out $CATALINA_HOME/cert.crt -passin pass:$STOREPASS -subj "/C=FR/ST=POC/L=POC/O=POC/OU=POC/CN=$HTMLGW_FQDN"
keytool -import -noprompt -alias tomcat -keystore $CATALINA_HOME/keystore -trustcacerts -file $CATALINA_HOME/cert.crt -storepass $STOREPASS
service tomcat stop && service tomcat start

echo -e "*************************************** Installing HTML5 Gateway for PSM ***************************************\n"
cp $TEMPDIR/psmgwparms /var/tmp/
rpm -i $TEMPDIR/$HTMLGWRPM
service tomcat stop && service tomcat start

echo -e "*************************************** Configured HTML5 Gateway for PSM ***************************************\n"


JAVADIR=$(readlink -f /usr/bin/java | sed "s:bin/java::")
keytool -import -noprompt -alias webapp_guacd_cert -keystore $JAVADIR/lib/security/cacerts -trustcacerts -file $CATALINA_HOME/cert.crt -storepass $GUACPASS
cp -v $TEMPDIR/guacd.conf /etc/guacamole/
/etc/init.d/guacd restart
service tomcat stop && service tomcat start

echo -e "*************************************** Installation Completed ***************************************\n"
