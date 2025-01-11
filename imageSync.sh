#!bin/bash

echo "Starting Image Sync"
mkdir -p ./static/images
cp -ruf ./images/* ./static/images/
echo "Finished Syncing"