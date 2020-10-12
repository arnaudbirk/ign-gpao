const { matchedData } = require('express-validator/filter');

const debug = require('debug')('project');

async function insertProject(name, req) {
  debug(`Insertion du projet ${name}`);
  let idProject;
  try {
    const results = await req.client.query('INSERT INTO projects (name) VALUES ($1) RETURNING id', [name]);
    idProject = results.rows[0].id;
    req.idProjects.push(idProject);
  } catch (error) {
    req.error = {
      msg: error.toString(),
      code: 500,
      function: 'insertProject',
    };
    debug('Erreur dans insertProject');
  }
  debug('Fin insertion projet');
  return idProject;
}

async function insertJob(name, command, idProject, req) {
  debug(`Insertion du job ${name}`);
  let idJob;
  try {
    const results = await req.client.query('INSERT INTO jobs (name, command, id_project) VALUES ($1, $2, $3) RETURNING id', [name, command, idProject]);
    idJob = results.rows[0].id;
    req.idJobs.push(idJob);
  } catch (error) {
    req.error = {
      msg: error.toString(),
      code: 500,
      function: 'insertJob',
    };
    debug('Erreur dans insertJob');
  }
  debug('Fin insertion job');
  return idJob;
}

async function insertJobDependency(upstream, downstream, req) {
  debug(`Insertion  de la dependance entre le job ${upstream} et ${downstream}`);
  await req.client.query(
    'INSERT INTO jobdependencies (upstream, downstream) VALUES ($1, $2)', [upstream, downstream],
  )
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'insertJobDependency',
      };
    });
  debug('Fin insertion job dependence');
}

async function insertProjectDependency(upstream, downstream, req) {
  debug(`Insertion  de la dependance entre le projet ${upstream} et ${downstream}`);
  await req.client.query(
    'INSERT INTO projectdependencies (upstream, downstream) VALUES ($1, $2)', [upstream, downstream],
  )
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'insertProjectDependency',
      };
    });
  debug('Fin insertion project dependence');
}

async function insertProjectFromJson(req, res, next) {
  const { projects } = req.body;

  req.idProjects = [];
  req.idJobs = [];

  /* eslint-disable no-restricted-syntax */
  for (const project of projects) {
    /* eslint-disable no-await-in-loop */
    const idProject = await insertProject(project.name, req);
    debug(`id_project = ${idProject}`);
    /* eslint-disable no-restricted-syntax */
    for (const job of project.jobs) {
      /* eslint-disable no-await-in-loop */
      const idJob = await insertJob(job.name, job.command, idProject, req);
      debug(`id_job = ${idJob}`);
      // Si il y a des dépendances entre les jobs
      if (job.deps) {
        /* eslint-disable no-restricted-syntax */
        for (const dep of job.deps) {
          const upstream = req.idJobs[dep.id];
          const downstream = idJob;
          /* eslint-disable no-await-in-loop */
          await insertJobDependency(upstream, downstream, req);
        }
      }
    }
    if (project.deps) {
      /* eslint-disable no-restricted-syntax */
      for (const dep of project.deps) {
        const upstream = req.idProjects[dep.id];
        const downstream = idProject;
        /* eslint-disable no-await-in-loop */
        await insertProjectDependency(upstream, downstream, req);
      }
    }
  }
  next();
}

async function getAllProjects(req, res, next) {
  await req.client.query('SELECT * FROM projects')
    .then((results) => {
      req.result = results.rows;
    })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'getAllProjects',
      };
    });
  next();
}

async function deleteProject(req, res, next) {
  const params = matchedData(req);
  const { id } = params;
  debug('id : ', id);
  await req.client.query('DELETE FROM projects WHERE id=$1', [id])
    .then((results) => {
      req.result = results.rows;
    })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 404,
        function: 'deleteProject',
      };
    });
  next();
}

async function getProjectStatus(req, res, next) {
  await req.client.query('SELECT * FROM view_project_status')
    .then((results) => {
      req.result = results.rows;
    })
    .catch((error) => {
      req.error = {
        msg: error.toString(),
        code: 500,
        function: 'getProjectStatus',
      };
    });
  next();
}

module.exports = {
  insertProjectFromJson,
  getAllProjects,
  getProjectStatus,
  deleteProject,
};
