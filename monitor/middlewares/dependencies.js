const axios = require('axios');

async function getDependencies(req, res, next) {
  const json = await axios.get(`${req.app.api_url}/api/dependencies?id_job=${req.params.id}`);

  req.deps = json.data;
  next();
}

module.exports = {
  getDependencies,
};
