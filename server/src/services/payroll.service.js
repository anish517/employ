/**
 * Minimal payroll service implementing core hourly calculation per docs.
 * This is intentionally self-contained and defensive; expand with thorough validation in full implementation.
 */
const Employee = require('../models/employee.model');
const Salary = require('../models/salary.model');

const mongoose = require('mongoose');
const Attendance = require('../models/attendance.model');
const Bonus = require('../models/bonus.model');
const Fine = require('../models/fine.model');
const Loan = require('../models/loan.model');
const LoanInstallment = require('../models/loanInstallment.model');
const CompanySettings = require('../models/companySettings.model');
const LeaveRequest = require('../models/leaveRequest.model');
const LeaveType = require('../models/leaveType.model');

async function parseMonthRange(month){
  // month format YYYY-MM
  const [y,m] = month.split('-').map(Number);
  const start = new Date(Date.UTC(y, m-1, 1));
  const end = new Date(Date.UTC(y, m, 1));
  return { start, end };
}

async function sumAttendanceHours(employeeId, month){
  const { start, end } = await parseMonthRange(month);
  const docs = await Attendance.find({ employeeId, date: { $gte: start, $lt: end } });
  const result = docs.reduce((acc, d) => {
    acc.regularHours += Number(d.workingHours || 0);
    acc.overtimeHours += Number(d.overtimeHours || 0);
    return acc;
  }, { regularHours: 0, overtimeHours: 0 });

  // Add paid approved leave days as regular hours based on company working hours
  const company = await CompanySettings.findOne();
  let dailyHours = 8;
  if(company && company.workingHours && company.workingHours.start && company.workingHours.end){
    const [sh, sm] = company.workingHours.start.split(':').map(Number);
    const [eh, em] = company.workingHours.end.split(':').map(Number);
    dailyHours = (eh + em/60) - (sh + sm/60);
    if(isNaN(dailyHours) || dailyHours <= 0) dailyHours = 8;
  }

  // find approved leave requests overlapping month
  const leaves = await LeaveRequest.find({ employeeId, status: 'Approved', $or:[ { startDate: { $gte: start, $lt: end } }, { endDate: { $gte: start, $lt: end } }, { startDate: { $lte: start }, endDate: { $gte: end } } ] });
  let paidLeaveDays = 0;
  for(const lr of leaves){
    const lt = await LeaveType.findById(lr.leaveTypeId);
    if(!lt || !lt.isPaid) continue;
    // compute overlap days
    const s = lr.startDate < start ? start : lr.startDate;
    const e = lr.endDate >= end ? new Date(end.getTime()-1) : lr.endDate;
    const days = Math.round((e - s) / (1000*60*60*24)) + 1;
    paidLeaveDays += Math.max(0, days);
  }

  const regularHours = Number((result.regularHours + (paidLeaveDays * dailyHours)).toFixed(2));
  const overtimeHours = Number((result.overtimeHours).toFixed(2));
  return { regularHours, overtimeHours };
}

async function sumBonusesAndFines(employeeId, month){
  const bonusDocs = await Bonus.find({ employeeId, month });
  const fineDocs = await Fine.find({ employeeId, month });
  const bonusTotal = bonusDocs.reduce((s,b)=>s+Number(b.amount||0),0);
  const fineTotal = fineDocs.reduce((s,f)=>s+Number(f.amount||0),0);
  return { bonusTotal, fineTotal };
}

async function applyLoanEMI(employeeId, month){
  const loan = await Loan.findOne({ employeeId, status: 'Active' });
  if(!loan) return { loanDeduction: 0, loanInstallmentCreated: false };

  // compute remaining balance
  const installments = await LoanInstallment.find({ loanId: loan._id });
  const paid = installments.reduce((s,i)=>s+Number(i.amountPaid||0),0);
  const remaining = Math.max(0, loan.totalAmount - paid);
  if(remaining <= 0){
    loan.status = 'Closed';
    await loan.save();
    return { loanDeduction: 0, loanInstallmentCreated: false };
  }

  const emi = Math.min(loan.emiAmount, remaining);
  const installment = new LoanInstallment({ loanId: loan._id, month, amountPaid: emi });
  await installment.save();

  const newPaid = paid + emi;
  const newRemaining = Math.max(0, loan.totalAmount - newPaid);
  if(newRemaining <= 0){
    loan.status = 'Closed';
    await loan.save();
  }

  return { loanDeduction: emi, loanInstallmentCreated: true };
}

async function generateSalary(employeeId, month, adminId = null){
  // idempotency: prevent duplicate salary
  const exists = await Salary.findOne({ employeeId, month });
  if(exists){
    const err = new Error('Salary already generated for this month');
    err.status = 409;
    err.code = 'CONFLICT';
    throw err;
  }

  const employee = await Employee.findById(employeeId);
  if(!employee) throw Object.assign(new Error('Employee not found'),{ status:404, code:'NOT_FOUND' });

  const { regularHours, overtimeHours } = await sumAttendanceHours(employeeId, month);
  const { bonusTotal, fineTotal } = await sumBonusesAndFines(employeeId, month);

  const overtimeMultiplier = 1.5; // in a real app, pull from company_settings
  const hourlyRate = employee.hourlyRate || 0;

  const regularPay = Number((hourlyRate * regularHours).toFixed(2));
  const overtimePay = Number((hourlyRate * overtimeMultiplier * overtimeHours).toFixed(2));
  const allowances = 0;
  const grossSalary = Number((regularPay + overtimePay + allowances + (bonusTotal||0)).toFixed(2));

  const tax = 0; // compute tax per company settings
  const loanResult = await applyLoanEMI(employeeId, month);
  const deductions = {
    tax,
    fine: fineTotal || 0,
    medical: 0,
    advanceSalary: 0,
    loanDeduction: loanResult.loanDeduction || 0
  };

  const totalDeductions = Object.values(deductions).reduce((s,v)=>s+Number(v||0),0);
  let netSalary = Number((grossSalary - totalDeductions).toFixed(2));
  if(netSalary < 0) {
    // cap logic: do not allow negative net salary
    netSalary = 0;
  }

  const salaryData = {
    employeeId,
    month,
    hourlyRate,
    regularHours,
    overtimeHours,
    overtimeMultiplier,
    regularPay,
    overtimePay,
    allowances,
    bonusTotal,
    grossSalary,
    deductions,
    netSalary,
    status: 'Finalized'
  };

  const salary = await Salary.create ? await Salary.create(salaryData) : (async ()=>{ const s = new Salary(salaryData); await s.save(); return s; })();

  // snapshot into salary_history
  const SalaryHistory = require('../models/salaryHistory.model');
  const snapshot = JSON.parse(JSON.stringify((salary.toObject && salary.toObject()) || salary));
  await SalaryHistory.create({ salaryId: salary._id || snapshot._id, employeeId: salary.employeeId || snapshot.employeeId, month: salary.month || snapshot.month, snapshot, payslipUrl: null });

  // audit log
  const AuditLog = require('../models/auditLog.model');
  await AuditLog.create({ adminId: adminId || null, action: 'GENERATE_SALARY', collectionName: 'salary', documentId: salary._id || snapshot._id, metadata: { month: salary.month || snapshot.month, employeeId: salary.employeeId || snapshot.employeeId } });

  return salary;
}

module.exports = { generateSalary };
