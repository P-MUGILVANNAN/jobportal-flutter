const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const bodyParser = require('body-parser');
const userRoutes = require('./routes/userRoutes');
const jobRoutes = require('./routes/jobRoutes');
const applicationRoutes = require('./routes/applicationRoutes');

const app = express();
dotenv.config();
app.use(cors());
app.use(express.json());
app.use(bodyParser.json());

// db connection
mongoose.connect(process.env.MONGO_URI)
.then(()=>{
    console.log("Database connected...");
})
.catch((err)=>{
    console.log("Error connecting database",err);
})

// use Routes
app.use('/api/users',userRoutes);
app.use('/api', jobRoutes);
app.use('/api',applicationRoutes);

app.get("/",(req,res)=>{
    res.send("Express app is running");
});

app.listen(process.env.PORT,()=>{
    console.log("Server is listening on",process.env.PORT);
});