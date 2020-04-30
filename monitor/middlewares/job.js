async function getJobs (req, res, next){

    const axios = require('axios');
    const serveur = require('../serveur');
    
    json = await axios.get('http://'+serveur.URL_API+':'+serveur.URL_API_PORT+'/api/jobs', {proxy:false})
  
    req.body = json.data
    next()
  }

module.exports = {
    getJobs
}