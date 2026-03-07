#!/bin/bash

# save current directory
CURR_PWD=$(pwd)

# pull config changes
echo -e "Pulling from Git repo..."
cd /docker/
git pull

# loop through each folder inside /docker/
for app_dir in /docker/*/; do
        cd "$app_dir" || continue

        echo -e "\nProcessing $app_dir..."

        # pull latest images
        docker compose pull

        # stop containers and remove volumes
        docker compose down -v

        # start containers in detached mode
        docker compose up -d

        echo "Done with $app_dir!"
done

# complete
echo -e "\nAll done!\n"
cd $CURR_PWD
