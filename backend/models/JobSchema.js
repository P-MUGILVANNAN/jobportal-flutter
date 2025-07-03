const mongoose = require('mongoose');

const JobSchema = new mongoose.Schema({
  company: {
    type: String,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  role: {
    type: String,
    required: true,
  },
  location: {
    type: String,
    required: true,
  },
  experience: {
    type: String,
    required: true,
    enum: ['Fresher', '1+ years', '2+ years', '3+ years', '4+ years', '5+ years', '6+ years', '7+ years', '8+ years', '9+ years', '10+ years', '11+ years', '12+ years', '13+ years', '14+ years', '15+ years'],
  },
  skills: {
    type: Array,
    required: true,
  },
  salary: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
  image: {
    type: String,
    default: 'https://via.placeholder.com/100',
  },
  postingDate: {
    type: String,
    required: true,
  },
});

module.exports = mongoose.model('Job', JobSchema);
