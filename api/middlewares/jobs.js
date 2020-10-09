const { matchedData } = require('express-validator/filter');
const debug = require('debug')('job');

async function getAllJobs(req, res, next) {
  await req.client.query('SELECT * FROM jobs')
    .then((results) => { req.result = results.rows; })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'getAlljobs',
      };
    });
  next();
}

async function getJobStatus(req, res, next) {
  await req.client.query('SELECT * FROM view_job_status')
    .then((results) => { req.result = results.rows; })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'getJobStatus',
      };
    });
  next();
}

async function getJob(req, res, next) {
  const params = matchedData(req);

  const { id } = params;
  await req.client.query('SELECT * FROM view_job WHERE job_id=$1', [id])
    .then((results) => { req.result = results.rows; })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'getJob',
      };
    });
  next();
}

async function getJobReady(req, res, next) {
  const params = matchedData(req);

  const id = params.id_session;
  try {
    await req.client.query('LOCK TABLE jobs IN EXCLUSIVE MODE');
    await req.client.query(
      "UPDATE jobs SET status = 'running', start_date=NOW(), id_session = $1 WHERE (select status from sessions where id =$1) = 'active' AND id = (SELECT id FROM jobs WHERE status = 'ready' LIMIT 1) RETURNING id, command", [id],
    )
      .then((results) => { req.result = results.rows; });
  } catch (error) {
    req.error = {
      msg: error.toString(),
      code: 500,
      function: 'getJobReady',
    };
  }
  next();
}

async function updateJobStatus(req, res, next) {
  const params = matchedData(req);
  const { id } = params;
  const { status } = params;
  const { returnCode } = params;
  const { log } = params;

  debug(`id = ${id}`);
  debug(`status = ${status}`);
  debug(`returnCode = ${returnCode}`);
  debug(`log = ${log}`);

  await req.client.query(
    'UPDATE jobs SET status = $1, log = $2, return_code = $4, end_date=NOW() WHERE id = $3', [status, log, id, returnCode],
  )
    .then((results) => { req.result = results.rows; })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'updateJobStatus',
      };
    });
  next();
}

module.exports = {
  getAllJobs,
  getJobStatus,
  getJobReady,
  getJob,
  updateJobStatus,
};
