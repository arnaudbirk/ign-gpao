const chai = require('chai');
const chaiHttp = require('chai-http');
const server = require('..');

const should = chai.should();
chai.use(chaiHttp);
let idCluster;
let idJob;

describe('Jobs', () => {
  before((done) => {
    // on ajoute une ressource
    chai.request(server)
      .put('/api/cluster')
      .query({ host: 'a name' })
      .end((err, res) => {
        should.equal(err, null);
        res.should.have.status(200);
        res.body.should.be.an('array');
        idCluster = res.body[0].id;
        chai.request(server)
          .put('/api/project')
          .send({
            projects: [
              {
                name: 'Chantier 1',
                jobs: [
                  {
                    name: 'jobs 1',
                    command: 'touch file1',
                  },
                ],
              },
            ],
          })
          .end((err2, res2) => {
            should.equal(err2, null);
            res2.should.have.status(200);
            done();
          });
      });
    // il faut aussi ajouter un chantier avec au moins un job ready
  });

  after((done) => {
    server.close();
    done();
  });

  describe('Get jobs', () => {
    it('should return an array', (done) => {
      chai.request(server)
        .get('/api/jobs')
        .end((err, res) => {
          should.equal(err, null);
          res.should.have.status(200);
          res.body.should.be.an('array');
          done();
        });
    });
  });

  describe('Get job/ready', () => {
    it('should return an error', (done) => {
      chai.request(server)
        .get('/api/job/ready')
        .query({ id_cluster: -1 })
        .end((err, res) => {
          should.equal(err, null);
          res.should.have.status(400);
          res.body.status.should.equal("Le paramètre 'id_cluster' est invalide.");
          done();
        });
    });
  });

  describe('Get job/ready', () => {
    it('should return an array', (done) => {
      chai.request(server)
        .get('/api/job/ready')
        .query({ id_cluster: idCluster })
        .end((err, res) => {
          should.equal(err, null);
          res.should.have.status(200);
          res.body.should.be.an('array');
          idJob = res.body[0].id;
          done();
        });
    });
  });

  describe('Post job', () => {
    it('should return an error', (done) => {
      chai.request(server)
        .post('/api/job')
        .query({ id: -1, status: 'failed', returnCode: 0 })
        .send({ log: 'string' })
        .end((err, res) => {
          should.equal(err, null);
          res.should.have.status(400);
          res.body.status.should.equal("Le paramètre 'id' est invalide.");
          done();
        });
    });
  });

  describe('Post job', () => {
    it('should return succed', (done) => {
      chai.request(server)
        .post('/api/job')
        .query({ id: idJob, status: 'failed', returnCode: 0 })
        .send({ log: 'string' })
        .end((err, res) => {
          should.equal(err, null);
          res.should.have.status(200);
          done();
        });
    });
  });
});
