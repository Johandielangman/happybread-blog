#!bin/bash

echo "Starting Image Sync"
mkdir -p ./static/images
cp -r ./images/* ./static/images/
echo "Finished Syncing"