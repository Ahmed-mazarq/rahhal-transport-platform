class ModificationKeys {
  // Identity
  static const String fullName = 'fullName';
  static const String nationalId = 'nationalId';
  static const String passportNumber = 'passportNumber';
  static const String nationality = 'nationality';
  static const String birthDate = 'birthDate';
  static const String passportExpiry = 'passportExpiry';
  static const String gender = 'gender';
  static const String phone = 'phone';
  static const String secondaryPhone = 'secondaryPhone';

  // Identity Images
  static const String passportFrontImage = 'passportFrontImage';
  static const String passportBackImage = 'passportBackImage';
  static const String driverPhoto = 'driverPhoto';

  // License Images
  static const String licenseFrontImage = 'licenseFrontImage';
  static const String licenseBackImage = 'licenseBackImage';

  // Vehicle
  static const String vehicleBrand = 'vehicleBrand';
  static const String vehicleModel = 'vehicleModel';
  static const String vehicleYear = 'vehicleYear';
  static const String vehicleColor = 'vehicleColor';
  static const String vehiclePlate = 'vehiclePlate';
  static const String vin = 'vin';
  static const String seats = 'seats';
  static const String vehicleType = 'vehicleType';
  static const String transmission = 'transmission';
  static const String fuelType = 'fuelType';
  static const String vehicleCategory = 'vehicleCategory';
  static const String vehicleRegistrationExpiry = 'vehicleRegistrationExpiry';
  static const String registrationNumber = 'registrationNumber';
  static const String plateCountry = 'plateCountry';

  // Vehicle Images
  static const String vehicleFrontImage = 'vehicleFrontImage';
  static const String vehicleBackImage = 'vehicleBackImage';
  static const String vehicleRightImage = 'vehicleRightImage';
  static const String vehicleLeftImage = 'vehicleLeftImage';
  static const String vehicleInteriorImage = 'vehicleInteriorImage';
  static const String vehiclePlateImage = 'vehiclePlateImage';
  static const String vehiclePhotos = 'vehiclePhotos';

  // Address
  static const String country = 'country';
  static const String province = 'province';
  static const String city = 'city';
  static const String district = 'district';
  static const String street = 'street';
  static const String detailedAddress = 'detailedAddress';
  static const String gpsLocation = 'gpsLocation';

  // License
  static const String licenseNumber = 'licenseNumber';
  static const String licenseIssueDate = 'licenseIssueDate';
  static const String licenseExpiryDate = 'licenseExpiryDate';
  static const String licenseType = 'licenseType';
  static const String licenseCountry = 'licenseCountry';
  static const String licensePhoto = 'licensePhoto';

  // Operating Areas
  static const String operatingAreas = 'operatingAreas';
  static const String operatingCities = 'operatingCities';

  // Insurance
  static const String insuranceCompany = 'insuranceCompany';
  static const String insuranceNumber = 'insuranceNumber';
  static const String policyNumber = 'policyNumber';
  static const String insuranceExpiry = 'insuranceExpiry';
  static const String coverage = 'coverage';
  static const String insurancePhoto = 'insurancePhoto';

  // Payment
  static const String bankName = 'bankName';
  static const String accountHolder = 'accountHolder';
  static const String accountNumber = 'accountNumber';
  static const String iban = 'iban';
  static const String ewalletName = 'ewalletName';
  static const String ewalletNumber = 'ewalletNumber';

  // Emergency Contact
  static const String emergencyContactName = 'emergencyContactName';
  static const String emergencyContactRelation = 'emergencyContactRelation';
  static const String emergencyContactPhone = 'emergencyContactPhone';

  // Mappings to UI Labels
  static const Map<String, String> labels = {
    fullName: 'الاسم الكامل',
    nationalId: 'الهوية الوطنية',
    passportNumber: 'رقم الجواز',
    nationality: 'الجنسية',
    birthDate: 'تاريخ الميلاد',
    passportExpiry: 'تاريخ انتهاء الجواز',
    gender: 'الجنس',
    phone: 'رقم الهاتف',
    secondaryPhone: 'رقم هاتف إضافي',
    passportFrontImage: 'صورة الجواز الأمامية',
    passportBackImage: 'صورة الجواز الخلفية',
    driverPhoto: 'الصورة الشخصية',
    licenseFrontImage: 'صورة الرخصة الأمامية',
    licenseBackImage: 'صورة الرخصة الخلفية',

    vehicleBrand: 'الشركة المصنعة',
    vehicleModel: 'الموديل',
    vehicleYear: 'سنة الصنع',
    vehicleColor: 'لون المركبة',
    vehiclePlate: 'رقم اللوحة',
    vin: 'رقم الهيكل (VIN)',
    seats: 'عدد المقاعد',
    vehicleType: 'نوع المركبة',
    transmission: 'ناقل الحركة',
    fuelType: 'نوع الوقود',
    vehicleCategory: 'فئة المركبة',
    vehicleRegistrationExpiry: 'تاريخ انتهاء الاستمارة',
    registrationNumber: 'رقم الاستمارة',
    plateCountry: 'بلد اللوحة',

    vehicleFrontImage: 'صورة المركبة الأمامية',
    vehicleBackImage: 'صورة المركبة الخلفية',
    vehicleRightImage: 'صورة المركبة الجانبية (يمين)',
    vehicleLeftImage: 'صورة المركبة الجانبية (يسار)',
    vehicleInteriorImage: 'صورة المركبة من الداخل',
    vehiclePlateImage: 'صورة لوحة المركبة',

    country: 'الدولة',
    province: 'المقاطعة/المحافظة',
    city: 'المدينة',
    district: 'الحي',
    street: 'الشارع',
    detailedAddress: 'العنوان التفصيلي',
    gpsLocation: 'الموقع الجغرافي',

    licenseNumber: 'رقم الرخصة',
    licenseIssueDate: 'تاريخ إصدار الرخصة',
    licenseExpiryDate: 'تاريخ انتهاء الرخصة',
    licenseType: 'نوع الرخصة',
    licenseCountry: 'بلد إصدار الرخصة',

    operatingAreas: 'مناطق العمل',
    operatingCities: 'المدن التشغيلية',

    insuranceCompany: 'شركة التأمين',
    insuranceNumber: 'رقم التأمين',
    policyNumber: 'رقم الوثيقة',
    insuranceExpiry: 'تاريخ الانتهاء',
    coverage: 'نوع التغطية',
    insurancePhoto: 'صورة وثيقة التأمين',

    bankName: 'اسم البنك',
    accountHolder: 'اسم صاحب الحساب',
    accountNumber: 'رقم الحساب',
    iban: 'رقم الآيبان',
    ewalletName: 'اسم المحفظة الإلكترونية',
    ewalletNumber: 'رقم المحفظة',

    emergencyContactName: 'اسم جهة الاتصال (للطوارئ)',
    emergencyContactRelation: 'صلة القرابة',
    emergencyContactPhone: 'رقم هاتف الطوارئ',
  };

  // Mappings to Firestore fields (for simple fields)
  static const Map<String, String> firestoreFields = {
    fullName: 'fullName',
    nationalId: 'nationalId',
    passportNumber: 'passportNumber',
    nationality: 'nationality',
    birthDate: 'dateOfBirth',
    passportExpiry: 'passportExpiry',
    gender: 'gender',
    phone: 'phone',
    secondaryPhone: 'alternativePhone',

    vehicleBrand: 'vehicleManufacturer',
    vehicleModel: 'vehicleModel',
    vehicleYear: 'vehicleYear',
    vehicleColor: 'vehicleColor',
    vehiclePlate: 'plateNumber',
    vin: 'vin',
    seats: 'seatCount',
    vehicleType: 'vehicleType',
    transmission: 'transmission',
    fuelType: 'fuelType',
    vehicleCategory: 'vehicleCategory',
    vehicleRegistrationExpiry: 'registrationExpiry',
    registrationNumber: 'registrationNumber',
    plateCountry: 'plateCountry',

    country: 'country',
    province: 'governorate',
    city: 'city',
    district: 'district',
    street: 'street',
    detailedAddress: 'detailedAddress',
    gpsLocation: 'gpsLocation',

    licenseNumber: 'licenseNumber',
    licenseIssueDate: 'licenseIssueDate',
    licenseExpiryDate: 'licenseExpiryDate',
    licenseType: 'licenseType',
    licenseCountry: 'licenseCountry',

    operatingAreas: 'operatingAreas',
    operatingCities: 'operatingCities',

    insuranceCompany: 'insuranceCompany',
    insuranceNumber: 'insuranceNumber',
    policyNumber: 'policyNumber',
    insuranceExpiry: 'insuranceExpiry',
    coverage: 'coverage',

    bankName: 'bankName',
    accountHolder: 'accountHolder',
    accountNumber: 'accountNumber',
    iban: 'iban',
    ewalletName: 'ewalletName',
    ewalletNumber: 'ewalletNumber',

    emergencyContactName: 'emergencyContactName',
    emergencyContactRelation: 'emergencyContactRelation',
    emergencyContactPhone: 'emergencyContactPhone',
  };

  // Mappings for Documents/Images
  static const Map<String, String> firestoreImages = {
    passportFrontImage: 'idFront',
    passportBackImage: 'idBack',
    driverPhoto: 'personalPhoto',
    licenseFrontImage: 'licenseFront',
    licenseBackImage: 'licenseBack',
    vehicleFrontImage: 'vehicleFront',
    vehicleBackImage: 'vehicleBack',
    vehicleRightImage: 'vehicleRight',
    vehicleLeftImage: 'vehicleLeft',
    vehicleInteriorImage: 'vehicleInterior',
    vehiclePlateImage: 'vehiclePlate',
    insurancePhoto: 'insuranceDoc',
  };

  // Backwards compatibility map (old UI string -> new ModificationKey)
  static const Map<String, String> legacyMap = {
    'Full Name': fullName,
    'National ID': nationalId,
    'Passport Number': passportNumber,
    'Nationality': nationality,
    'Birth Date': birthDate,
    'Passport Expiry': passportExpiry,
    'Gender': gender,
    'Phone': phone,
    'Passport Front Image': passportFrontImage,
    'Passport Back Image': passportBackImage,
    'Driver Photo': driverPhoto,
    'Vehicle Brand': vehicleBrand,
    'Vehicle Model': vehicleModel,
    'Manufacturing Year': vehicleYear,
    'Vehicle Color': vehicleColor,
    'Vehicle Plate': vehiclePlate,
    'VIN': vin,
    'Seats': seats,
    'Vehicle Type': vehicleType,
    'Transmission': transmission,
    'Fuel Type': fuelType,
    'Vehicle Category': vehicleCategory,
    'Vehicle Registration Expiry': vehicleRegistrationExpiry,
    'Vehicle Photos': vehiclePhotos,
    'Country': country,
    'Province': province,
    'City': city,
    'District': district,
    'Street': street,
    'Detailed Address': detailedAddress,
    'GPS Location': gpsLocation,
    'License Number': licenseNumber,
    'Issue Date': licenseIssueDate,
    'Expiry Date': licenseExpiryDate,
    'License Type': licenseType,
    'License Country': licenseCountry,
    'License Photo': licensePhoto,
    'Insurance Company': insuranceCompany,
    'Insurance Number': insuranceNumber,
    'Policy Number': policyNumber,
    'Expiry': insuranceExpiry,
    'Coverage': coverage,
    'Insurance Photo': insurancePhoto,
  };
}
