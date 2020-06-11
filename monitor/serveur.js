const express = require('express');
const gpaoInterface = require('ejs-electron-ign-gpao');
const debug = require('debug')('monitor');

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

const path = require('path');
const routes = require('./routes');

// java scripts visible from html code
app.use(express.static(gpaoInterface.scriptFolder()));

// use res.render to load up an ejs view file
app.use('/', routes);

const appDir = path.dirname(require.main.filename);
debug('server root:', appDir);
debug(`URL du moniteur : http://${URL_API}:${PORT}`);

app.listen(PORT);
