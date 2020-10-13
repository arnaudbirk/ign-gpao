const router = require('express').Router();
const { body, param } = require('express-validator/check');

const validateParams = require('../../middlewares/validateParams');
const createErrorMsg = require('../../middlewares/createErrorMsg');
const validator = require('../../validator');
const project = require('../../middlewares/project');
const pgClient = require('../../middlewares/db/pgClient');
const returnMsg = require('../../middlewares/returnMsg');

router.put('/project',
  body()
    .exists().withMessage(createErrorMsg.getMissingParameterMsg('body'))
    .custom(validator.checkProjectSchema)
    .withMessage(createErrorMsg.getInvalidProjectSchema())
    .custom(validator.checkProjectDependencies)
    .withMessage(createErrorMsg.getInvalidProjectDependencies())
    .custom(validator.checkJobDependencies)
    .withMessage(createErrorMsg.getInvalidJobsDependencies()),
  validateParams,
  pgClient.open,
  project.insertProjectFromJson,
  pgClient.close,
  returnMsg);

router.delete('/project/:id',
  param('id')
    .exists().withMessage(createErrorMsg.getMissingParameterMsg('id'))
    .isInt({ min: 1 })
    .withMessage(createErrorMsg.getInvalidParameterMsg('id')),
  validateParams,
  pgClient.open,
  project.deleteProject,
  pgClient.close,
  returnMsg);

router.get('/projects',
  pgClient.open,
  project.getAllProjects,
  pgClient.close,
  returnMsg);

router.get('/projects/status',
  pgClient.open,
  project.getProjectStatus,
  pgClient.close,
  returnMsg);

router.get('/projects/status_global',
  pgClient.open,
  project.getProjectStatusGlobal,
  pgClient.close,
  returnMsg);

module.exports = router;
