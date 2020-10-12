const router = require('express').Router();
const {
  query,
} = require('express-validator/check');

const validateParams = require('../../middlewares/validateParams');
const createErrorMsg = require('../../middlewares/createErrorMsg');
const sessions = require('../../middlewares/sessions');
const pgClient = require('../../middlewares/db/pgClient');
const returnMsg = require('../../middlewares/returnMsg');

router.get('/sessions',
  pgClient.open,
  sessions.getAllSessions,
  pgClient.close,
  returnMsg);

router.get('/sessions/status',
  pgClient.open,
  sessions.getSessionStatus,
  pgClient.close,
  returnMsg);

router.put('/session', [
  query('host')
    .exists().withMessage(createErrorMsg.getMissingParameterMsg('host'))],
validateParams,
pgClient.open,
sessions.insertSession,
pgClient.close,
returnMsg);

router.post('/session/close', [
  query('id')
    .exists().withMessage(createErrorMsg.getMissingParameterMsg('id'))],
validateParams,
pgClient.open,
sessions.closeSession,
pgClient.close,
returnMsg);

module.exports = router;
