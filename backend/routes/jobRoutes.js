const express = require('express');
const router = express.Router();
const jobController = require('../controllers/JobController');

// POST
router.post('/jobs', jobController.createJob);

// GET
router.get('/jobs', jobController.getAllJobs);
router.get('/jobs/:id', jobController.getJobById);

// PUT
router.put('/jobs/:id', jobController.updateJob);

// DELETE
router.delete('/jobs/:id', jobController.deleteJob);

module.exports = router;
