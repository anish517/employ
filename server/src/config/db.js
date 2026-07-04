const mongoose = require('mongoose');

async function connectDB(){
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/ems';
  await mongoose.connect(uri, { useNewUrlParser: true, useUnifiedTopology: true });
  console.log('Connected to MongoDB');
}

module.exports = connectDB;
