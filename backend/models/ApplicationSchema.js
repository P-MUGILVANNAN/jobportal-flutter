const mongoose = require('mongoose');

const applicationSchema = new mongoose.Schema({
  jobId: {
    type: mongoose.Schema.Types.ObjectId, // assuming jobs are stored in a separate collection
    required: true,
    ref: 'Job',
  },
  jobTitle: {
    type: String,
    required: true,
  },
  name: {
    type: String,
    required: true,
    trim: true,
  },
  email: {
    type: String,
    required: true,
    lowercase: true,
    match: [/^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/, 'Please enter a valid email'],
  },
  phone: {
    type: String,
    required: true,
    match: [/^[0-9]{10}$/, 'Please enter a valid 10-digit phone number'],
  },
  skills: {
    type: [String],
    required: true,
  },
  tenthMark: {
    type: Number,
    required: true,
  },
  twelfthMark: {
    type: Number,
    required: true,
  },
  qualification: {
    type: String,
    required: true,
  },
  degreePercentage: {
    type: Number,
    required: true,
  },
  willingToRelocate: {
    type: Boolean,
    default: false,
  },
  resume: {
    fileName: { type: String, required: true },
    fileUrl: { type: String }, // Store uploaded file URL or path
  },
  appliedAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Application', applicationSchema);
