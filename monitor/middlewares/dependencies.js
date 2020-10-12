const axios = require('axios');

async function getDependencies(req, res, next) {
  const json = await axios.get(`${req.app.get('apiUrl')}/api/dependencies?id_job=${req.params.id}`);

  req.deps = json.data;
  next();
}

module.exports = {
  getDependencies,
};
