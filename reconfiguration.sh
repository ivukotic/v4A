#!/bin/bash

# Generate a random number between 0 and 59
x=$((RANDOM % 60))
echo "Random minute selected: $x"

current_version="$1"

echo "Current version: $current_version"

# Infinite loop
while true; do
    # Get the current minute
    current_minute=$(date +%M)

    # Check if the current minute matches x
    if [ "$current_minute" -eq "$x" ]; then
        # echo "Downloading file at minute $x..."
        while true; do
            ma=$(curl -s "https://raw.githubusercontent.com/ivukotic/v4A/frontier/configurations/mapping.json")
            
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
        if [ -z "$config" ] || [ "$config" == null ]; then
            echo "No value found for $SITE.$INSTANCE, using default value"
            config=$(echo "$ma" | jq -r '.default')
            echo "Default value: $config"
            nfile=$(echo "$config" | jq -r '.file')
            version=$(echo "$config" | jq -r '.version')
        else
            echo "Value of $SITE.$INSTANCE: $config"
            nfile=$(echo "$config" | jq -r '.file')
            version=$(echo "$config" | jq -r '.version')
        fi

        if [ "$current_version" == "$version" ]; then
            # echo "Skipping this loop iteration as $1 matches $version..."
            sleep 60 
        else
            echo "Version mismatch, proceeding with reconfiguration..."
            curl "https://raw.githubusercontent.com/ivukotic/v4A/frontier/configurations/$nfile.vcl" -o /tmp/$nfile.vcl
            
            TIME=$(date +%s)
            varnishadm vcl.load varnish_$TIME /tmp/$nfile.vcl && varnishadm vcl.use varnish_$TIME && current_version="$version"
        fi



    fi

    # Sleep for 1 minute
    sleep 60
done