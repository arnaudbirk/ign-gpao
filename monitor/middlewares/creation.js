const debug = require('debug')('creation');
const gpaoInterface = require('ejs-electron-ign-gpao');

let gpaoInterfaceData = {};
const jsFolder = '.';

function getNewProject(req, res, next) {
  req.body = gpaoInterfaceData;
  next();
}

function postNewProject(req, res, next) {
  let page = '';
  let body = '';
  req.on('data', (chunk) => {
    body += chunk;
  });
  req.on('end', () => {
    gpaoInterfaceData = JSON.parse(body);
    page = `${gpaoInterface.viewFolder()}/pages/creation`;
    gpaoInterfaceData.js_folder = jsFolder;
    gpaoInterfaceData.page = page;
    req.body = gpaoInterfaceData;
    next();
  });
  req.on('error', (e) => {
    debug(`problem with request: ${e.message}`);
  });
}

function validate(req, res, next) {
  const result = gpaoInterface.validate(req.body);

  if (!result.valid) {
    const messagelist = [];
    Array.prototype.forEach.call(result.errors, (error) => {
      const submessagelist = gpaoInterface.analyzeError(error, req.body);
      Array.prototype.forEach.call(submessagelist, (submessage) => {
        messagelist.push(submessage);
      });
    });
    req.body.page = messagelist.find((x) => x !== undefined);
    next();
  } else {
    next();
  }
}

function header(req) {
  // code propre quand express-useragent sera debogge
  // const useragent = require('express-useragent');
  /* ua = useragent.parse(req.headers['user-agent']);
    if (!ua['isElectron']) { */
  if (!req.headers['user-agent'].includes('Electron')) {
    return '../partials/header';
  }
  return `${gpaoInterface.viewFolder()}/partials/header`;
}

module.exports = {
  getNewProject,
  postNewProject,
  validate,
  header,
};
