const express = require('express');
const debug = require('debug');

const app = express();

const URL_MONITOR = process.env.URL_MONITOR || 'localhost';
const MONITOR_PORT = process.env.MONITOR_PORT || 8000;

const URL_API = process.env.URL_API || 'localhost';
const API_PORT = process.env.API_PORT || 8080;

const SERVER = process.env.SERVER || 'localhost';
const SERVER_URL=`http://${SERVER}:${API_PORT}`;

app.set('apiUrl', `http://${URL_API}:${API_PORT}`);
app.set('apiMonitor', `http://${URL_MONITOR}:${MONITOR_PORT}`);
app.set('server', SERVER_URL);

const routes = require('./routes');

// set the view engine to ejs
app.set('view engine', 'ejs');

app.use('/vendor', express.static(`${__dirname}/resources/vendor`));
app.use('/css', express.static(`${__dirname}/resources/css`));
app.use('/js', express.static(`${__dirname}/resources/js`));

// use res.render to load up an ejs view file
app.use('/', routes);
debug.log(`URL de l'API : ${app.get('apiUrl')}`);

app.listen(MONITOR_PORT);
debug.log(`URL du monitor : ${app.get('apiMonitor')}`);
