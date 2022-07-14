FROM varnish

# FROM varnish:fresh-alpine


USER root

# alpine version
# RUN apk add --no-cache --upgrade curl bash net-snmp jq

# debian version
RUN apt-get update; apt-get -y install curl snmpd snmp jq vim python3

# remove later
RUN apt-get install libsnmp-dev -y

# uncomment later
# USER varnish

# COPY default.vcl /etc/varnish/

COPY Monitoring/sender.sh /usr/local/bin/

COPY Monitoring/snmpd.conf /etc/snmp/
COPY Monitoring/snmp.conf /etc/snmp/

RUN rm /usr/share/snmp/mibs/*
RUN curl https://raw.githubusercontent.com/hardaker/net-snmp/master/mibs/SNMPv2-SMI.txt -o /usr/share/snmp/mibs/SNMPv2-SMI.txt
RUN curl https://raw.githubusercontent.com/hardaker/net-snmp/master/mibs/SNMPv2-TC.txt -o /usr/share/snmp/mibs/SNMPv2-TC.txt 
RUN curl https://raw.githubusercontent.com/hardaker/net-snmp/master/mibs/INET-ADDRESS-MIB.txt -o /usr/share/snmp/mibs/INET-ADDRESS-MIB.txt
RUN mkdir -p /usr/share/snmp/mibs/squid
COPY Monitoring/SQUID-MIB.txt /usr/share/snmp/mibs/squid

# COPY Monitoring/snmpd_sender.sh /usr/local/bin/
COPY Monitoring/snmpd_sender.py /usr/local/bin/

ENV MIBS=ALL
EXPOSE 161/udp
EXPOSE 161/tcp
EXPOSE 3401/udp