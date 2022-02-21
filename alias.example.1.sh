# The base docker image has no plugins installed however. Since you likely need to install plugins and configure them for your environment, you will minimally want to mount the config and plugins directories to persistent storage. 

# create a directory for the config files
mkdir -p $HOME/sp/config

# alias the command
alias sp="docker run \
  -it \
  --rm \
  --name steampipe \
  --mount type=bind,source=$HOME/sp/config,target=/home/steampipe/.steampipe/config  \
  --mount type=volume,source=steampipe_plugins,target=/home/steampipe/.steampipe/plugins   \
  turbot/steampipe"