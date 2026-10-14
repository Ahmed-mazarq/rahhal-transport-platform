class DocumentLabels {
  static const Map<String, String> labels = {
    'idFront': 'الجواز / الهوية - أمامي',
    'idBack': 'الجواز / الهوية - خلفي',
    'licenseFront': 'الرخصة - أمامي',
    'licenseBack': 'الرخصة - خلفي',
    'vehicleFront': 'المركبة - أمامي',
    'vehicleBack': 'المركبة - خلفي',
    'vehicleRight': 'المركبة - يمين',
    'vehicleLeft': 'المركبة - يسار',
    'vehicleInterior': 'المركبة - من الداخل',
    'vehiclePlate': 'لوحة المركبة',
    'personalPhoto': 'الصورة الشخصية',
    'companyRegistration': 'السجل التجاري',
    'companyTaxCertificate': 'الشهادة الضريبية',
    'companyAuthorization': 'تفويض الشركة',
    'managerId': 'هوية المدير',
    'commercialRegistration': 'السجل التجاري',
    'operatingLicense': 'رخصة التشغيل',
    'companyLogo': 'شعار الشركة',
    'officeFront': 'واجهة المكتب',
    'account_verification': 'بيانات الحساب',
  };

  static String getLabel(String key) {
    return labels[key] ?? key;
  }
}
