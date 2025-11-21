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
            ma=$(curl -s "https://raw.githubusercontent.com/ivukotic/v4A/frontier/configurations/configurations.json")
            
            # Check if curl was successful
            if [ $? -eq 0 ] && [ -n "$ma" ]; then
                echo "Download successful!"
                break
            else
                echo "Retrying..."
                sleep 5  # Wait for 5 seconds before retrying
            fi
        done

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

        if [ "$current_version" == "$nfile" ]; then
            # echo "Skipping this loop iteration as $current_version matches $nfile..."
            sleep 60 
        else
            echo "Version mismatch, proceeding with reconfiguration..."
            curl --fail --show-error --location --silent \
              "https://raw.githubusercontent.com/ivukotic/v4A/frontier/configurations/$nfile.vcl" \
              -o "/tmp/$nfile.vcl"

            if [ $? -ne 0 ] || [ ! -s "/tmp/$nfile.vcl" ]; then
                echo "Failed to download configuration file $nfile.vcl"
                continue
            fi

            varnishadm vcl.load $nfile /tmp/$nfile.vcl && varnishadm vcl.use $nfile && current_version="$nfile"
        fi
    fi

    # Sleep for 1 minute
    sleep 60
done
