#!/bin/sh

/sbin/ifconfig end0 192.168.2.2
/sbin/httpd -h /srv/www -p 80 
