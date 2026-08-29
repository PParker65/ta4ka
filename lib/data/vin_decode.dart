class VinDecode {
  const VinDecode({
    required this.vin,
    required this.make,
    required this.region,
    this.year,
    this.modelHint = '',
  });

  final String vin;
  final String make;
  final String region;
  final int? year;
  final String modelHint;

  bool get ok => make.isNotEmpty;
}

const _wmi = <String, (String, String)>{
  'WBA': ('BMW', 'DE'),
  'WBS': ('BMW M', 'DE'),
  'WBY': ('BMW', 'DE'),
  'WBX': ('BMW', 'DE'),
  'WVW': ('Volkswagen', 'DE'),
  'WV1': ('Volkswagen', 'DE'),
  'WV2': ('Volkswagen', 'DE'),
  'WAU': ('Audi', 'DE'),
  'WA1': ('Audi', 'DE'),
  'WUA': ('Audi', 'DE'),
  'WDD': ('Mercedes-Benz', 'DE'),
  'W1K': ('Mercedes-Benz', 'DE'),
  'WDC': ('Mercedes-Benz', 'DE'),
  'WP0': ('Porsche', 'DE'),
  'WP1': ('Porsche', 'DE'),
  'TMB': ('Škoda', 'CZ'),
  'TMH': ('Škoda', 'CZ'),
  'VSS': ('SEAT', 'ES'),
  'VF1': ('Renault', 'FR'),
  'VF3': ('Peugeot', 'FR'),
  'VF7': ('Citroën', 'FR'),
  'SAJ': ('Jaguar', 'UK'),
  'SAL': ('Land Rover', 'UK'),
  'JHM': ('Honda', 'JP'),
  'JH4': ('Acura', 'JP'),
  'JT2': ('Toyota', 'JP'),
  'JTD': ('Toyota', 'JP'),
  'JTE': ('Toyota', 'JP'),
  'JN1': ('Nissan', 'JP'),
  'JN8': ('Nissan', 'JP'),
  'JF1': ('Subaru', 'JP'),
  'JM1': ('Mazda', 'JP'),
  'KMH': ('Hyundai', 'KR'),
  'KNA': ('Kia', 'KR'),
  'U5Y': ('Kia', 'SK'),
  'UU1': ('Dacia', 'RO'),
  'XTA': ('Lada', 'RU'),
  'Y6D': ('ZAZ', 'UA'),
  '1G1': ('Chevrolet', 'US'),
  '1FA': ('Ford', 'US'),
  '1FM': ('Ford', 'US'),
  '1C3': ('Chrysler', 'US'),
  '2T1': ('Toyota', 'CA'),
  '3VW': ('Volkswagen', 'MX'),
  'NMT': ('Toyota', 'TR'),
  'ZFA': ('Fiat', 'IT'),
  'ZFF': ('Ferrari', 'IT'),
  'YV1': ('Volvo', 'SE'),
  'YS3': ('Saab', 'SE'),
};

const _yearCode = <String, int>{
  'A': 2010, 'B': 2011, 'C': 2012, 'D': 2013, 'E': 2014,
  'F': 2015, 'G': 2016, 'H': 2017, 'J': 2018, 'K': 2019,
  'L': 2020, 'M': 2021, 'N': 2022, 'P': 2023, 'R': 2024,
  'S': 2025, 'T': 2026, 'V': 2027, 'W': 2028, 'X': 2029,
  'Y': 2030, '1': 2001, '2': 2002, '3': 2003, '4': 2004,
  '5': 2005, '6': 2006, '7': 2007, '8': 2008, '9': 2009,
};

VinDecode decodeVin(String raw) {
  final vin = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (vin.length < 3) {
    return VinDecode(vin: vin, make: '', region: '');
  }
  final wmi = vin.substring(0, 3);
  final hit = _wmi[wmi];
  int? year;
  if (vin.length >= 10) {
    year = _yearCode[vin[9]];
  }
  var hint = '';
  if (vin.length >= 8) {
    hint = vin.substring(3, 8);
  }
  return VinDecode(
    vin: vin,
    make: hit?.$1 ?? '',
    region: hit?.$2 ?? '',
    year: year,
    modelHint: hint,
  );
}
