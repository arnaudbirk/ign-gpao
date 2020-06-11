const { matchedData } = require('express-validator/filter');
const debug = require('debug')('job');

async function getAllClusters(req, res, next) {
  await req.client.query('SELECT * FROM cluster')
    .then((results) => { req.result = results.rows; })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'getAllClusters',
      };
    });
  next();
}

async function insertCluster(req, res, next) {
  const params = matchedData(req);

  const { host } = params;

  await req.client.query(
    'LOCK TABLE cluster IN EXCLUSIVE MODE',
  )
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'insertCluster',
      };
    });
  await req.client.query(
    'INSERT INTO cluster (host, id_thread, active, available) VALUES ( $1 , (select count(id) from cluster where host = $2 AND available = \'True\'), true, true ) RETURNING id',
    [host, host],
  )
    .then((results) => { req.result = results.rows; })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'insertCluster',
      };
    });
  next();
}

async function unavailableCluster(req, res, next) {
  const params = matchedData(req);
  const { id } = params;
  debug('update ', id);
  await req.client.query('UPDATE cluster SET available=\'False\' WHERE id=$1', [id])
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'updateCluster',
      };
    });
  next();
}

module.exports = {
  getAllClusters,
  insertCluster,
  unavailableCluster,
};
