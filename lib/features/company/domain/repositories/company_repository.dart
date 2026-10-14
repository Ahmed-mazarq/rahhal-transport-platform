import '../models/company.dart';
import '../models/employee.dart';
import '../models/branch.dart';
import '../../../../features/trips/domain/models/trip.dart';
import '../../../../features/trips/domain/models/booking.dart';
import '../../../../features/fleet/domain/models/vehicle.dart';

abstract class CompanyRepository {
  Future<Company> getCompany(String companyId);
  Future<void> updateCompany(Company company);

  Future<List<Employee>> getEmployees(String companyId);
  Future<void> addEmployee(Employee employee);
  Future<void> updateEmployee(Employee employee);
  Future<void> deleteEmployee(String employeeId);

  Future<List<Branch>> getBranches(String companyId);
  Future<void> addBranch(Branch branch);
  Future<void> updateBranch(Branch branch);
  Future<void> deleteBranch(String branchId);

  Future<List<Trip>> getCompanyTrips(String companyId);
  Future<List<Vehicle>> getCompanyVehicles(String companyId);
  Future<List<Booking>> getCompanyBookings(String companyId);
}
