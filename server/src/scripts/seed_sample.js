require('dotenv').config();
const connectDB = require('../config/db');
const Employee = require('../models/employee.model');
const CompanySettings = require('../models/companySettings.model');
const Attendance = require('../models/attendance.model');

async function run(){
  await connectDB();
  let company = await CompanySettings.findOne();
  if(!company){
    company = new CompanySettings({ companyName: 'Acme Co', currency: 'NPR', workingHours: { start: '09:00', end: '17:00' }, overtimeMultiplier: 1.5 });
    await company.save();
    console.log('Created company settings');
  }
  let emp = await Employee.findOne({ email: 'ram@company.com' });
  if(!emp){
    emp = new Employee({ fullName: 'Ram Bahadur', phone: '9800000000', email: 'ram@company.com', joiningDate: new Date(), employmentType: 'Full-time', hourlyRate: 350, employeeId: 'EMP-0001' });
    await emp.save();
    console.log('Created employee', emp._id);
  }
  // create attendance for first 5 working days of July 2026
  const dates = ['2026-07-01','2026-07-02','2026-07-03','2026-07-04','2026-07-05'];
  for(const d of dates){
    await Attendance.findOneAndUpdate({ employeeId: emp._id, date: new Date(d) }, { $set: { status: 'Present', checkIn: new Date(d+'T09:00'), checkOut: new Date(d+'T17:00'), workingHours: 8, overtimeHours: 0 } }, { upsert: true });
  }
  console.log('Seeded attendance for sample employee');
  process.exit(0);
}
run().catch(err=>{ console.error(err); process.exit(1); });
