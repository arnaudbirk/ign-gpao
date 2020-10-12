export URL_API=localhost
export API_PORT=8080

if [ "$(docker ps -aq -f name=monitor-gpao)" ]; then
    echo "Suppression du container monitor-gpao"
    docker rm -f monitor-gpao
fi

npm start
