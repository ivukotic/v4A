#!/bin/bash
echo "released on 2025-11-20"
echo "site: $SITE, instance: $INSTANCE"
echo "getting mapping..."

while true; do
    ma=$(curl -s "https://raw.githubusercontent.com/ivukotic/v4A/frontier/configurations/configurations.json")
    
    # Check if curl was successful
    if [ $? -eq 0 ] && [ -n "$ma" ]; then
        echo "Download successful!"
        break
    else
        echo "Retrying..."
        sleep 10  # Wait for 10 seconds before retrying
    fi
done

# get value of file for a given SITE and INSTANCE 
config=$(echo "$ma" | jq -r --arg site $SITE --arg instance $INSTANCE \
'  . as $root
  | (
      $root.sites
      | map(select(.name == $site))
      | .[0] as $siteObj
      | if $siteObj then
          ($siteObj.instances // [] | map(select(.name == $instance)) | .[0]) as $instObj
          | ($instObj.file // $siteObj.file // $root.file)
        else
          $root.file
        end
    )
' )

echo "Value of $SITE.$INSTANCE: $config"
nfile=$(echo "$config" | jq -r '.file')

curl --fail --show-error --location --silent \
  "https://raw.githubusercontent.com/ivukotic/v4A/frontier/configurations/$nfile.vcl" \
  -o "/tmp/$nfile.vcl"

if [ $? -ne 0 ] || [ ! -s "/tmp/$nfile.vcl" ]; then
    echo "Failed to download configuration file $nfile.vcl"
    exit 1
fi

source /usr/local/bin/reconfiguration.sh "$nfile" &

echo "Starting Varnish on port $VARNISH_PORT"
echo "Using $VARNISH_MEM memory, and $VARNISH_TRANSIENT_MEM and config file $nfile.vcl"

/usr/sbin/varnishd -F -f /tmp/$nfile.vcl -a http=:$VARNISH_PORT,HTTP -p max_restarts=8 -p nuke_limit=5000 -s malloc,$VARNISH_MEM -s Transient=malloc,$VARNISH_TRANSIENT_MEM
