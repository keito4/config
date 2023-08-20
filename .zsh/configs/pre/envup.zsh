PRE=$(dirname $(realpath $0))

if [ -f $PRE/.env ]; then
  source $PRE/.env
else
  echo 'No .env file found' 1>&2
fi

if [ -f $PRE/.env.secret ]; then
  source $PRE/.env.secret
else
  echo 'No .env.secret file found' 1>&2
fi

