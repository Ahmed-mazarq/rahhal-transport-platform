import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/company.dart';
import '../../domain/models/employee.dart';
import '../../domain/models/branch.dart';
import '../../domain/repositories/company_repository.dart';
import '../../../../features/trips/domain/models/trip.dart';
import '../../../../features/trips/domain/models/booking.dart';
import '../../../../features/fleet/domain/models/vehicle.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  final FirebaseFirestore _firestore;

  CompanyRepositoryImpl(this._firestore);

  @override
  Future<Company> getCompany(String companyId) async {
    try {
      final doc = await _firestore.collection('companies').doc(companyId).get();
      if (doc.exists && doc.data() != null) {
        return Company.fromJson({'id': doc.id, ...doc.data()!});
      }

      // Fallback for new companies
      return Company(
        id: companyId,
        name: 'شركة نقل جديدة',
        phoneNumber: '',
        managerName: '',
        managerPhone: '',
        country: 'اليمن',
        city: 'صنعاء',
        address: '',
        joinedDate: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to fetch company profile: $e');
    }
  }

  @override
  Future<void> updateCompany(Company company) async {
    await _firestore
        .collection('companies')
        .doc(company.id)
        .set(company.toJson(), SetOptions(merge: true));
  }

  @override
  Future<List<Employee>> getEmployees(String companyId) async {
    final query = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('employees')
        .get();
    return query.docs
        .map((doc) => Employee.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  @override
  Future<void> addEmployee(Employee employee) async {
    final doc = _firestore
        .collection('companies')
        .doc(employee.companyId)
        .collection('employees')
        .doc();
    final newEmp = Employee(
      id: doc.id,
      companyId: employee.companyId,
      fullName: employee.fullName,
      phoneNumber: employee.phoneNumber,
      role: employee.role,
      status: employee.status,
      joinedDate: employee.joinedDate,
    );
    await doc.set(newEmp.toJson());
  }

  @override
  Future<void> updateEmployee(Employee employee) async {
    await _firestore
        .collection('companies')
        .doc(employee.companyId)
        .collection('employees')
        .doc(employee.id)
        .update(employee.toJson());
  }

  @override
  Future<void> deleteEmployee(String employeeId) async {
    final query = await _firestore
        .collectionGroup('employees')
        .where(FieldPath.documentId, isEqualTo: employeeId)
        .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<List<Branch>> getBranches(String companyId) async {
    final query = await _firestore
        .collection('companies')
        .doc(companyId)
        .collection('branches')
        .get();
    return query.docs
        .map((doc) => Branch.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  @override
  Future<void> addBranch(Branch branch) async {
    final doc = _firestore
        .collection('companies')
        .doc(branch.companyId)
        .collection('branches')
        .doc();
    final newBranch = Branch(
      id: doc.id,
      companyId: branch.companyId,
      name: branch.name,
      city: branch.city,
      address: branch.address,
      managerName: branch.managerName,
      phoneNumber: branch.phoneNumber,
      status: branch.status,
    );
    await doc.set(newBranch.toJson());
  }

  @override
  Future<void> updateBranch(Branch branch) async {
    await _firestore
        .collection('companies')
        .doc(branch.companyId)
        .collection('branches')
        .doc(branch.id)
        .update(branch.toJson());
  }

  @override
  Future<void> deleteBranch(String branchId) async {
    final query = await _firestore
        .collectionGroup('branches')
        .where(FieldPath.documentId, isEqualTo: branchId)
        .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Future<List<Trip>> getCompanyTrips(String companyId) async {
    final query = await _firestore
        .collection('trips')
        .where('ownerId', isEqualTo: companyId)
        .get();
    return query.docs
        .map((doc) => Trip.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  @override
  Future<List<Vehicle>> getCompanyVehicles(String companyId) async {
    final query = await _firestore
        .collection('vehicles')
        .where('companyId', isEqualTo: companyId)
        .get();
    return query.docs
        .map((doc) => Vehicle.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  @override
  Future<List<Booking>> getCompanyBookings(String companyId) async {
    final query = await _firestore
        .collection('bookings')
        .where('companyId', isEqualTo: companyId)
        .get();
    return query.docs
        .map((doc) => Booking.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }
}
