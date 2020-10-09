const router = require('express').Router();
const { body, param, query } = require('express-validator/check');

const validateParams = require('../../middlewares/validateParams');
const createErrorMsg = require('../../middlewares/createErrorMsg');
const validator = require('../../validator');
const dependencies = require('../../middlewares/dependencies');
const pgClient = require('../../middlewares/db/pgClient');
const returnMsg = require('../../middlewares/returnMsg');

router.get('/dependencies', [
    query('id_job')
      .exists().withMessage(createErrorMsg.getMissingParameterMsg('id_job'))
      .isInt({ min: 1 })
      .withMessage(createErrorMsg.getInvalidParameterMsg('id_job')),
  ],
  validateParams,
  pgClient.open,
  dependencies.getDependencies,
  pgClient.close,
  returnMsg);

module.exports = router;
