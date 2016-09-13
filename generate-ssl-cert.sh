#!/bin/bash

domain=$1
email=$2
appid=$3
appdomain=$4

#To be sure that r/w access
mkdir -p /etc/letsencrypt/
chown -R jelastic:jelastic /etc/letsencrypt/

cd /opt/letsencrypt
git pull origin master

iptables -I INPUT -p tcp -m tcp --dport 9999 -j ACCEPT
iptables -t nat -I PREROUTING -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 9999

#Request for certificates - test certs
#./letsencrypt-auto certonly --standalone --test-cert --break-my-certs $domain --standalone-supported-challenges http-01 --http-01-port 9999 --renew-by-default --email $email --agree-tos
/opt/letsencrypt/letsencrypt-auto certonly --standalone --test-cert --break-my-certs --domain $domain --standalone-supported-challenges tls-sni-01 --tls-sni-01-port 9999 --renew-by-default --email $email --agree-tos
#Request for certificates - valid certs
#./letsencrypt-auto certonly --standalone $domain --standalone-supported-challenges tls-sni-01 --tls-sni-01-port 9999 --renew-by-default --email $email --agree-tos

iptables -t nat -D PREROUTING -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 9999
iptables -D INPUT -p tcp -m tcp --dport 9999 -j ACCEPT

#To be sure that r/w access
mkdir -p /tmp/
chmod -R 777 /tmp/
appdomain=$(cut -d"." -f2- <<< $appdomain)

echo appid = $appid
echo appdomain = $appdomain
#Upload 3 certificate files
uploadresult=$(curl -F "appid=$appid" -F "fid=privkey.pem" -F "file=@$certdir/privkey.pem" -F "fid=fullchain.pem" -F "file=@$certdir/fullchain.pem" -F "fid=cert.pem" -F "file=@$certdir/cert.pem" http://app.$appdomain/xssu/rest/upload)

#Save urls to certificate files
echo $uploadresult | awk -F '{"file":"' '{print $2}' | awk -F ":\"" '{print $1}' | sed 's/","name"//g' >> /tmp/privkey.url
echo $uploadresult | awk -F '{"file":"' '{print $3}' | awk -F ":\"" '{print $1}' | sed 's/","name"//g' >> /tmp/fullchain.url
echo $uploadresult | awk -F '{"file":"' '{print $4}' | awk -F ":\"" '{print $1}' | sed 's/","name"//g' >> /tmp/cert.url

#installing ssl cert via JEM
#sed -i '/function doDownloadKeys/a return 0;#letsenctemp' /usr/lib/jelastic/modules/keystore.module
#jem ssl install
#sed -i  '/letsenctemp/d' /usr/lib/jelastic/modules/keystore.module
