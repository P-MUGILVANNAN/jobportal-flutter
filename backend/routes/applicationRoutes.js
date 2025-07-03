const express = require('express');
const router = express.Router();
const multer = require('multer');
const storage = multer.memoryStorage();
const upload = multer({ storage: storage });

const {
  applyForJob,
  getApplicationsByUserId,
  getAllApplications,
} = require('../controllers/ApplicationController');

// Routes
router.post('/apply', upload.single('resume'), applyForJob);
router.get('/applications/user/:email', getApplicationsByUserId);
router.get('/applications', getAllApplications);

module.exports = router;
