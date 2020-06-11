const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');

const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');
const debug = require('debug');
const jobs = require('./routes/jobs');
const projects = require('./routes/projects');
const clusters = require('./routes/cluster');

const PORT = 8080;

const app = express();

app.use(cors());
app.use(bodyParser.json({ limit: '100mb', extended: true }));

app.use((req, res, next) => {
  debug.log(req.method, ' ', req.path, ' ', req.body);
  debug.log(`received at ${Date.now()}`);
  next();
});

const options = {
  customCss: '.swagger-ui .topbar { display: none }',
};

const swaggerDocument = YAML.load('./doc/swagger.yml');

app.use('/api/doc', swaggerUi.serve, swaggerUi.setup(swaggerDocument, options));

app.use('/api', jobs);
app.use('/api', projects);
app.use('/api', clusters);

module.exports = app.listen(PORT, () => {
  debug.log(`URL de l'api : http://localhost:${PORT}/api \nURL de la documentation swagger : http://localhost:${PORT}/api/doc`);
});
