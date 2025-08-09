#!/bin/bash

# pull config changes
echo -e "Pulling from Git repo..."
cd /apps/
git pull

# loop through each folder inside /apps/stacks
for app_dir in /apps/stacks/*/; do
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
cd -
