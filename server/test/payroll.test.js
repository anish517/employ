const { expect } = require('chai');
const sinon = require('sinon');
const proxyquire = require('proxyquire');

describe('payroll.service generateSalary', () => {
  let payroll;
  before(() => {
    // create stubs for dependencies
    const EmployeeStub = { findById: sinon.stub() };
    const SalaryStub = function(obj){
      Object.assign(this, obj);
      this.save = async ()=>{ /* pretend saved */ };
      this.toObject = ()=> Object.assign({}, obj, { _id: 'fakeSalaryId' });
    };
    SalaryStub.findOne = sinon.stub().resolves(null);
    SalaryStub.create = sinon.stub().callsFake(async (obj)=> Object.assign({ _id: 'fakeSalaryId' }, obj));

    const AttendanceStub = { find: sinon.stub() };
    const BonusStub = { find: sinon.stub() };
    const FineStub = { find: sinon.stub() };
    const LoanStub = { findOne: sinon.stub().resolves(null) };
    const LoanInstallmentStub = { find: sinon.stub().resolves([]) };
    const CompanySettingsStub = { findOne: sinon.stub().resolves({ workingHours: { start: '09:00', end: '17:00' }, overtimeMultiplier: 1.5 }) };
    const LeaveRequestStub = { find: sinon.stub().resolves([]) };
    const LeaveTypeStub = { findById: sinon.stub().resolves(null) };

    // set behavior for a sample employee
    EmployeeStub.findById.resolves({ _id: 'EMP1', hourlyRate: 100 });
    AttendanceStub.find.resolves([{ workingHours: 160, overtimeHours: 10 }]);
    BonusStub.find.resolves([{ amount: 1000 }]);
    FineStub.find.resolves([{ amount: 200 }]);

    payroll = proxyquire('../src/services/payroll.service', {
      '../models/employee.model': EmployeeStub,
      '../models/salary.model': SalaryStub,
      '../models/attendance.model': AttendanceStub,
      '../models/bonus.model': BonusStub,
      '../models/fine.model': FineStub,
      '../models/loan.model': LoanStub,
      '../models/loanInstallment.model': LoanInstallmentStub,
      '../models/companySettings.model': CompanySettingsStub,
      '../models/leaveRequest.model': LeaveRequestStub,
      '../models/leaveType.model': LeaveTypeStub,
      '../models/salaryHistory.model': { create: async ()=>{} },
      '../models/auditLog.model': { create: async ()=>{} }
    });
  });

  it('calculates net salary correctly without loan', async () => {
    const salary = await payroll.generateSalary('EMP1', '2026-07');
    // regularPay = 100 * 160 = 16000
    // overtimePay = 100 * 1.5 * 10 = 1500
    // bonus = 1000, fine = 200
    // gross = 16000 + 1500 + 1000 = 18500
    // deductions = 200 -> net = 18300
    expect(salary.netSalary).to.equal(18300);
    expect(salary.regularPay).to.equal(16000);
    expect(salary.overtimePay).to.equal(1500);
  });
});
