export SERVER_HOSTNAME=$HOSTNAME

docker-compose -f docker-compose.yml up -d --scale client-gpao=0
