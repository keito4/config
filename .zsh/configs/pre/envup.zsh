if [ -f .env ]; then
  export $(sed '/^ *#/ d' .env)
else
  echo 'No .env file found' 1>&2
fi

if [ -f .env.secret ]; then
  export $(sed '/^ *#/ d' .env.secret)
else
  echo 'No .env.secret file found' 1>&2
fi

