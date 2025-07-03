const express = require('express');
const router = express.Router();
const { registerUser, loginUser, getUserProfile, updateProfile } = require('../controllers/UserController');
const authenticateUser = require('../middleware/authenticateUser');
const authorizeRoles = require('../middleware/authorizeRoles');

router.post('/register', registerUser);
router.post('/login', loginUser);
router.get('/profile',authenticateUser, getUserProfile);
router.put('/update-profile', authenticateUser, updateProfile);

module.exports = router;