#!/bin/sh

data=$(varnishstat -j)
wget --post-data=$data --header='Content-Type:application/json' 'http://varnish.atlas-ml.org:80/'
