const { matchedData } = require('express-validator/filter');
const debug = require('debug')('dependencies');

async function getDependencies(req, res, next) {
  debug('getDependencies');
  const params = matchedData(req);

  const id = params.id_job;
  await req.client.query('SELECT * FROM view_dependencies WHERE dep_down=$1', [id])
    .then((results) => { req.result = results.rows; })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'getDependencies',
      };
    });
  next();
}

module.exports = {
  getDependencies,
};
