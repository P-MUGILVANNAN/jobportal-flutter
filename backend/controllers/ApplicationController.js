const Application = require('../models/ApplicationSchema');
const cloudinary = require('../config/cloudinary');

// POST: Apply for Job
const applyForJob = async (req, res) => {
  try {
    const { applicationData } = req.body;
    const parsedData = JSON.parse(applicationData);

    if (!req.file) {
      return res.status(400).json({ error: 'Resume file is required' });
    }

    // Upload resume to Cloudinary
    cloudinary.uploader.upload_stream(
      {
        resource_type: 'raw',
        folder: 'resumes',
        public_id: parsedData.name.replace(/ /g, '_') + '_resume',
      },
      async (error, result) => {
        if (error) return res.status(500).json({ error: 'Cloudinary upload failed' });

        // Save to DB
        const newApp = new Application({
          jobId: parsedData.jobId,
          jobTitle: parsedData.jobTitle,
          name: parsedData.name,
          email: parsedData.email,
          phone: parsedData.phone,
          skills: parsedData.skills,
          tenthMark: parsedData.tenthMark,
          twelfthMark: parsedData.twelfthMark,
          qualification: parsedData.qualification,
          degreePercentage: parsedData.degreePercentage,
          willingToRelocate: parsedData.willingToRelocate,
          resume: {
            fileName: req.file.originalname,
            fileUrl: result.secure_url,
          },
        });

        const savedApp = await newApp.save();
        res.status(200).json({ message: 'Application submitted successfully', application: savedApp });
      }
    ).end(req.file.buffer);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Something went wrong' });
  }
};

// GET: Applications by user email
const getApplicationsByUserId = async (req, res) => {
  try {
    const { email } = req.params;
    const applications = await Application.find({ email }).sort({ appliedAt: -1 });
    res.status(200).json(applications);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch user applications' });
  }
};

// GET: All Applications
const getAllApplications = async (req, res) => {
  try {
    const applications = await Application.find().sort({ appliedAt: -1 });
    res.status(200).json(applications);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch all applications' });
  }
};

module.exports = {
  applyForJob,
  getApplicationsByUserId,
  getAllApplications,
};
