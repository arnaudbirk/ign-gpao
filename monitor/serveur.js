const express = require('express');
const debug = require('debug');

const app = express();

const PORT = 8000;

const URL_API = process.env.URL_API || 'localhost';
const URL_API_PORT = process.env.URL_API_PORT || 8080;

module.exports = {
  URL_API,
  URL_API_PORT,
};

// set the view engine to ejs
app.set('view engine', 'ejs');

const routes = require('./routes');

app.use('/vendor', express.static(__dirname + '/resources/vendor'));
app.use('/css', express.static(__dirname + '/resources/css'));
app.use('/js', express.static(__dirname + '/resources/js'));

// use res.render to load up an ejs view file
app.use('/', routes);
app.api_url = `http://${URL_API}:${URL_API_PORT}`;
debug.log(`URL de l'API : ${app.api_url}`);

app.listen(PORT);
debug.log(`URL du moniteur : http://${URL_API}:${PORT}`);
