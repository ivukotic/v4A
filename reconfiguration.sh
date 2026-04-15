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

        if [ "$current_version" == "$nfile" ]; then
            # echo "Skipping this loop iteration as $current_version matches $nfile..."
            sleep 60 
        else
            echo "Version mismatch, proceeding with reconfiguration..."
            curl "https://raw.githubusercontent.com/ivukotic/v4A/cvmfs/configurations/$nfile.vcl" -o /tmp/$nfile.vcl

            varnishadm vcl.load $nfile /tmp/$nfile.vcl && varnishadm vcl.use $nfile && current_version="$nfile"
        fi

    fi

    # Sleep for 1 minute
    sleep 60
done