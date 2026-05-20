#!/bin/bash

echo "built: ${BUILD_DATE:-unknown}"
echo "site: $SITE, instance: $INSTANCE"
echo "getting configuration..."

ulimit -n 131072

while true; do
    ma=$(curl -s "https://raw.githubusercontent.com/ivukotic/v4A/cvmfs/configurations/configurations.json")
    
    # Check if curl was successful
    if [ $? -eq 0 ] && [ -n "$ma" ]; then
        echo "Download successful!"
        break
    else
        echo "Retrying..."
        sleep 5  # Wait for 5 seconds before retrying
    fi
done

# get config for SITE.INSTANCE
config=$(echo "$ma" | jq -c --arg site "$SITE" --arg instance "$INSTANCE" \
    'first(.sites[] | select(.name == $site) | select(any(.instances[]?; .name == $instance)))' 2>/dev/null)

# Check if the value exists
if [ -z "$config" ] || [ "$config" == "null" ]; then
    echo "No value found for $SITE.$INSTANCE, using default value"
    nfile=$(echo "$ma" | jq -r '.file')
    echo "Default value: $nfile"
else
    echo "Value of $SITE.$INSTANCE: $config"
    nfile=$(echo "$config" | jq -r '.file // empty')
    if [ -z "$nfile" ]; then
        nfile=$(echo "$ma" | jq -r '.file')
    fi
fi

curl -s "https://raw.githubusercontent.com/ivukotic/v4A/cvmfs/configurations/$nfile.vcl" -o /tmp/$nfile.vcl

/usr/local/bin/reconfiguration.sh "$nfile" &
RECONFIG_PID=$!

echo "Starting Varnish on port $VARNISH_PORT"
echo "Using $VARNISH_MEM memory, transient memory $VARNISH_TRANSIENT_MEM and config file $nfile.vcl"

exec /usr/sbin/varnishd -F -f /tmp/$nfile.vcl -a http=:$VARNISH_PORT,HTTP -p max_restarts=8 -p nuke_limit=5000 -s malloc,$VARNISH_MEM -s Transient=malloc,$VARNISH_TRANSIENT_MEM
