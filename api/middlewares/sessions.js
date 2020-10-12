const { matchedData } = require('express-validator/filter');
const debug = require('debug')('session');

async function getAllSessions(req, res, next) {
  await req.client.query('SELECT * FROM sessions')
    .then((results) => { req.result = results.rows; })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'getAllSessions',
      };
    });
  next();
}

async function getSessionStatus(req, res, next) {
  await req.client.query('SELECT * FROM view_sessions_status')
    .then((results) => { req.result = results.rows; })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'getSessionStatus',
      };
    });
  next();
}

async function insertSession(req, res, next) {
  const params = matchedData(req);

  const { host } = params;

  await req.client.query(
    'INSERT INTO sessions (host, start_date) VALUES ( $1 , NOW()) RETURNING id',
    [host],
  )
    .then((results) => { req.result = results.rows; })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'insertSession',
      };
    });
  next();
}

async function closeSession(req, res, next) {
  debug('closeSession');
  const params = matchedData(req);

  const { id } = params;
  debug(id);

  await req.client.query(
    "UPDATE sessions SET status = 'closed', end_date=NOW() WHERE id=$1",
    [id],
  )
    .catch((error) => {
      debug(error);
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'closeSession',
      };
    });
  next();
  debug('fin');
}

module.exports = {
  getAllSessions,
  getSessionStatus,
  insertSession,
  closeSession,
};
