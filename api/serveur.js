const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const os = require('os');

const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');
const debug = require('debug');
const jobs = require('./routes/jobs');
const projects = require('./routes/projects');
const sessions = require('./routes/sessions');
const nodes = require('./routes/nodes');
const dependencies = require('./routes/dependencies');

const PORT = 8080;

const app = express();

app.use(cors());
app.use(bodyParser.json());

app.use((req, res, next) => {
  debug.log(req.method, ' ', req.path, ' ', req.body);
  debug.log(`received at ${Date.now()}`);
  next();
});

const options = {
  customCss: '.swagger-ui .topbar { display: none }',
};

const swaggerDocument = YAML.load('./doc/swagger.yml');
const hostname = os.hostname();
swaggerDocument.servers[0].url = `http://${hostname}:${PORT}/api`;

app.use('/api/doc', swaggerUi.serve, swaggerUi.setup(swaggerDocument, options));

app.use('/api', jobs);
app.use('/api', projects);
app.use('/api', sessions);
app.use('/api', nodes);
app.use('/api', dependencies);

module.exports = app.listen(PORT, () => {
  debug.log(`URL de l'api : http://localhost:${PORT}/api \nURL de la documentation swagger : http://localhost:${PORT}/api/doc`);
});
