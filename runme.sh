echo "site: $SITE, instance: $INSTANCE"
echo "getting mapping..."

while true; do
    ma=$(curl -s "https://raw.githubusercontent.com/ivukotic/v4A/frontier-autoconfig/configurations/mapping.json")
    
    # Check if curl was successful
    if [ $? -eq 0 ] && [ -n "$ma" ]; then
        echo "Download successful!"
        break
    else
        echo "Retrying..."
        sleep 5  # Wait for 5 seconds before retrying
    fi
done

# get value of SITE.INSTANCE 
config=$(echo "$ma" | jq -r --arg site "$SITE" --arg instance "$INSTANCE" '.[$site][$instance]')

# Check if the value exists
if [ -z "$config" ]; then
    echo "No value found for $SITE.$INSTANCE, using default value"
    config=$(echo "$ma" | jq -r '.default.file')
    echo "Default value: $config"
    nfile=$(echo "$config" | jq -r '.file')
    version=$(echo "$config" | jq -r '.version')
else
    echo "Value of $SITE.$INSTANCE: $config"
    nfile=$(echo "$config" | jq -r '.file')
    version=$(echo "$config" | jq -r '.version')
fi

curl "https://raw.githubusercontent.com/ivukotic/v4A/frontier-autoconfig/configurations/$nfile.vcl" -o /tmp/$nfile.vcl

source /usr/local/bin/reconfiguration.sh $version &

echo "Starting Varnish on port $VARNISH_PORT"
echo "Using $VARNISH_MEM memory, and $VARNISH_TRANSIENT_MEM"

/usr/sbin/varnishd -F -f /tmp/$nfile.vcl -a http=:$VARNISH_PORT,HTTP -a proxy=:8443,PROXY -p feature=+http2 -p max_restarts=8 -s malloc,$VARNISH_MEM -s Transient=malloc,$VARNISH_TRANSIENT_MEM
