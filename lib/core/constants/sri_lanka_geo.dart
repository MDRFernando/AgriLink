class GeoDsDivision {
  const GeoDsDivision({required this.name, required this.villages});

  final String name;
  final List<String> villages;
}

class GeoDistrict {
  const GeoDistrict({
    required this.name,
    required this.province,
    required this.dsDivisions,
  });

  final String name;
  final String province;
  final List<GeoDsDivision> dsDivisions;
}

/// Administrative locations used for crop planning (district → DS Division → village).
abstract final class SriLankaGeo {
  static const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static String monthLabel(int month) {
    if (month < 1 || month > 12) return 'Month $month';
    return months[month - 1];
  }

  static List<String> get provinces =>
      districts.map((d) => d.province).toSet().toList()..sort();

  static List<GeoDistrict> districtsForProvince(String province) =>
      districts.where((d) => d.province == province).toList();

  static GeoDistrict? districtByName(String name) {
    for (final d in districts) {
      if (d.name == name) return d;
    }
    return null;
  }

  static const districts = [
    GeoDistrict(
      name: 'Colombo',
      province: 'Western Province',
      dsDivisions: [
        GeoDsDivision(name: 'Colombo', villages: ['Pettah', 'Slave Island', 'Fort']),
        GeoDsDivision(name: 'Homagama', villages: ['Homagama', 'Godagama', 'Kottawa']),
      ],
    ),
    GeoDistrict(
      name: 'Gampaha',
      province: 'Western Province',
      dsDivisions: [
        GeoDsDivision(name: 'Negombo', villages: ['Negombo', 'Katuwapitiya', 'Dalupotha']),
        GeoDsDivision(name: 'Minuwangoda', villages: ['Minuwangoda', 'Divulapitiya', 'Kopiwatta']),
      ],
    ),
    GeoDistrict(
      name: 'Kandy',
      province: 'Central Province',
      dsDivisions: [
        GeoDsDivision(name: 'Kandy Four Gravets', villages: ['Kandy', 'Asgiriya', 'Katukele']),
        GeoDsDivision(name: 'Udunuwara', villages: ['Gelioya', 'Danture', 'Handessa']),
      ],
    ),
    GeoDistrict(
      name: 'Nuwara Eliya',
      province: 'Central Province',
      dsDivisions: [
        GeoDsDivision(name: 'Nuwara Eliya', villages: ['Nuwara Eliya', 'Hawa Eliya', 'Pedro']),
        GeoDsDivision(name: 'Walapane', villages: ['Walapane', 'Nildandahinna', 'Ragala']),
      ],
    ),
    GeoDistrict(
      name: 'Galle',
      province: 'Southern Province',
      dsDivisions: [
        GeoDsDivision(name: 'Galle Four Gravets', villages: ['Galle', 'Kaluwella', 'Magalle']),
        GeoDsDivision(name: 'Elpitiya', villages: ['Elpitiya', 'Pitigala', 'Nawadagala']),
      ],
    ),
    GeoDistrict(
      name: 'Jaffna',
      province: 'Northern Province',
      dsDivisions: [
        GeoDsDivision(name: 'Jaffna', villages: ['Jaffna', 'Nallur', 'Chundikuli']),
        GeoDsDivision(name: 'Valikamam East', villages: ['Kopay', 'Atchuvely', 'Puttur']),
      ],
    ),
    GeoDistrict(
      name: 'Batticaloa',
      province: 'Eastern Province',
      dsDivisions: [
        GeoDsDivision(name: 'Manmunai North', villages: ['Batticaloa', 'Koddaimunai', 'Tissaveerasingam']),
        GeoDsDivision(name: 'Eravur Pattu', villages: ['Chenkalady', 'Vantharumoolai', 'Kommathurai']),
      ],
    ),
    GeoDistrict(
      name: 'Kurunegala',
      province: 'North Western Province',
      dsDivisions: [
        GeoDsDivision(
          name: 'Kurunegala',
          villages: ['Kurunegala', 'Malkaduwawa', 'Wehera'],
        ),
        GeoDsDivision(
          name: 'Mawathagama',
          villages: ['Mawathagama', 'Pilessa', 'Wewagedara'],
        ),
        GeoDsDivision(
          name: 'Polgahawela',
          villages: ['Polgahawela', 'Pothuhera', 'Alawwa'],
        ),
      ],
    ),
    GeoDistrict(
      name: 'Puttalam',
      province: 'North Western Province',
      dsDivisions: [
        GeoDsDivision(name: 'Puttalam', villages: ['Puttalam', 'Palavi', 'Madampe']),
        GeoDsDivision(name: 'Chilaw', villages: ['Chilaw', 'Munneswaram', 'Kakkapalliya']),
      ],
    ),
    GeoDistrict(
      name: 'Anuradhapura',
      province: 'North Central Province',
      dsDivisions: [
        GeoDsDivision(name: 'Nuwaragam Palatha East', villages: ['Anuradhapura', 'Stage I', 'Stage II']),
        GeoDsDivision(name: 'Kekirawa', villages: ['Kekirawa', 'Habarana', 'Ganewalpola']),
      ],
    ),
    GeoDistrict(
      name: 'Polonnaruwa',
      province: 'North Central Province',
      dsDivisions: [
        GeoDsDivision(name: 'Thamankaduwa', villages: ['Polonnaruwa', 'Kaduruwela', 'Gallella']),
        GeoDsDivision(name: 'Hingurakgoda', villages: ['Hingurakgoda', 'Minneriya', 'Jayanthipura']),
      ],
    ),
    GeoDistrict(
      name: 'Badulla',
      province: 'Uva Province',
      dsDivisions: [
        GeoDsDivision(name: 'Badulla', villages: ['Badulla', 'Hali-Ela', 'Kendagolla']),
        GeoDsDivision(name: 'Bandarawela', villages: ['Bandarawela', 'Ettampitiya', 'Makulella']),
      ],
    ),
    GeoDistrict(
      name: 'Ratnapura',
      province: 'Sabaragamuwa Province',
      dsDivisions: [
        GeoDsDivision(name: 'Ratnapura', villages: ['Ratnapura', 'Batugedara', 'Muwagama']),
        GeoDsDivision(name: 'Embilipitiya', villages: ['Embilipitiya', 'Udawalawa', 'Panamura']),
      ],
    ),
  ];
}
