const axios = require('axios');

async function getSessions(req, res, next) {
  const json = await axios.get(`${req.app.get('apiUrl')}/api/sessions`);

  const sessions = json.data;
  req.sessions = sessions;
  next();
}

module.exports = {
  getSessions,
};
