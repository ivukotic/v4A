FROM alpine:latest

# Install curl
RUN apk add --no-cache bash curl jq

# Copy the shell script into the container
COPY tester.sh /tester.sh
RUN chmod +x /tester.sh

# Set the entrypoint to run the shell script
ENTRYPOINT ["/tester.sh"]
