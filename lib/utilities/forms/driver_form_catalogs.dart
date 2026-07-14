import 'package:flutter/services.dart';

class CountryPhoneFormat {
  const CountryPhoneFormat({
    required this.country,
    required this.dialCode,
    required this.example,
    required this.maxNationalDigits,
  });

  final String country;
  final String dialCode;
  final String example;
  final int maxNationalDigits;
}

const driverPhoneFormats = <CountryPhoneFormat>[
  CountryPhoneFormat(
    country: 'Brasil',
    dialCode: '+55',
    example: '+55 (62) 99999-9999',
    maxNationalDigits: 11,
  ),
  CountryPhoneFormat(
    country: 'Estados Unidos',
    dialCode: '+1',
    example: '+1 (555) 555-1234',
    maxNationalDigits: 10,
  ),
  CountryPhoneFormat(
    country: 'Portugal',
    dialCode: '+351',
    example: '+351 912 345 678',
    maxNationalDigits: 9,
  ),
];

const brazilStates = <String>[
  'Acre',
  'Alagoas',
  'Amapa',
  'Amazonas',
  'Bahia',
  'Ceara',
  'Distrito Federal',
  'Espirito Santo',
  'Goias',
  'Maranhao',
  'Mato Grosso',
  'Mato Grosso do Sul',
  'Minas Gerais',
  'Para',
  'Paraiba',
  'Parana',
  'Pernambuco',
  'Piaui',
  'Rio de Janeiro',
  'Rio Grande do Norte',
  'Rio Grande do Sul',
  'Rondonia',
  'Roraima',
  'Santa Catarina',
  'Sao Paulo',
  'Sergipe',
  'Tocantins',
];

const goiasCities = <String>[
  'Abadia de Goias',
  'Abadiania',
  'Acreuna',
  'Aguas Lindas de Goias',
  'Alexania',
  'Alto Paraiso de Goias',
  'Anapolis',
  'Aparecida de Goiania',
  'Aragarcas',
  'Bela Vista de Goias',
  'Bom Jesus de Goias',
  'Caldas Novas',
  'Campo Limpo de Goias',
  'Campos Belos',
  'Carmo do Rio Verde',
  'Catalao',
  'Ceres',
  'Cidade Ocidental',
  'Cristalina',
  'Formosa',
  'Goianapolis',
  'Goianesia',
  'Goiania',
  'Goianira',
  'Goias',
  'Goiatuba',
  'Hidrolandia',
  'Inhumas',
  'Ipameri',
  'Itaberai',
  'Itumbiara',
  'Jaragua',
  'Jatai',
  'Luziania',
  'Morrinhos',
  'Neropolis',
  'Niquelandia',
  'Novo Gama',
  'Padre Bernardo',
  'Pirenopolis',
  'Pires do Rio',
  'Planaltina',
  'Porangatu',
  'Quirinopolis',
  'Rio Verde',
  'Rubiataba',
  'Santa Helena de Goias',
  'Santo Antonio do Descoberto',
  'Senador Canedo',
  'Trindade',
  'Uruacu',
  'Valparaiso de Goias',
];

const vehicleTypes = <String>[
  'Moto',
  'Carro',
  'Bicicleta',
  'Van',
  'Patinete',
  'Caminhao',
  'Outro',
];

const fuelOptions = <String>[
  'Gasolina',
  'Gasolina Aditivada',
  'Etanol',
  'Diesel',
  'Diesel S10',
  'GNV',
  'Eletrico',
  'Hibrido',
  'Sem combustivel',
  'Outro',
];

const vehicleModelsByTypeAndBrand = <String, Map<String, List<String>>>{
  'Moto': {
    'BMW': [
      'C 400',
      'F 750 GS',
      'F 850 GS',
      'G 310 GS',
      'G 310 R',
      'R 1250 GS',
    ],
    'Dafra': ['Apache', 'Citycom', 'Cruisym', 'Horizon', 'Maxsym', 'Next'],
    'Ducati': ['Diavel', 'Hypermotard', 'Monster', 'Multistrada', 'Scrambler'],
    'Haojue': ['DK 150', 'DR 160', 'Lindy', 'Master Ride', 'Nex'],
    'Harley-Davidson': [
      'Fat Bob',
      'Fat Boy',
      'Iron 883',
      'Sportster',
      'Street Bob',
    ],
    'Honda': [
      'ADV',
      'Biz',
      'CG 125',
      'CG 150',
      'CG 160',
      'Elite',
      'PCX',
      'Pop',
      'Twister',
      'XRE',
    ],
    'Kawasaki': ['Ninja', 'Versys', 'Vulcan', 'Z300', 'Z400', 'Z650', 'Z900'],
    'KTM': ['Duke', 'EXC', 'RC', 'Adventure'],
    'Royal Enfield': [
      'Classic',
      'Continental GT',
      'Himalayan',
      'Hunter',
      'Meteor',
    ],
    'Shineray': ['Denver', 'Jet', 'Phoenix', 'Worker', 'XY'],
    'Suzuki': ['Burgman', 'GSX', 'Hayabusa', 'Intruder', 'V-Strom', 'Yes'],
    'Triumph': [
      'Bonneville',
      'Rocket',
      'Scrambler',
      'Speed Twin',
      'Tiger',
      'Trident',
    ],
    'Yamaha': [
      'Crosser',
      'Factor',
      'Fazer',
      'Fluo',
      'Lander',
      'MT-03',
      'NMax',
      'R3',
      'XMax',
      'XTZ',
    ],
  },
  'Carro': {
    'Audi': ['A3', 'A4', 'Q3', 'Q5', 'Q7'],
    'BMW': ['Serie 1', 'Serie 3', 'X1', 'X3', 'X5'],
    'BYD': ['Dolphin', 'Dolphin Mini', 'King', 'Seal', 'Song Plus', 'Tan'],
    'Caoa Chery': [
      'Arrizo',
      'iCar',
      'Tiggo 2',
      'Tiggo 5X',
      'Tiggo 7',
      'Tiggo 8',
    ],
    'Chevrolet': [
      'Agile',
      'Astra',
      'Celta',
      'Classic',
      'Cobalt',
      'Corsa',
      'Cruze',
      'Montana',
      'Onix',
      'Prisma',
      'S10',
      'Spin',
      'Tracker',
    ],
    'Citroen': ['Aircross', 'Berlingo', 'C3', 'C4', 'C4 Cactus', 'Jumpy'],
    'Fiat': [
      'Argo',
      'Cronos',
      'Doblo',
      'Fiorino',
      'Idea',
      'Mobi',
      'Palio',
      'Pulse',
      'Siena',
      'Strada',
      'Toro',
      'Uno',
    ],
    'Ford': [
      'Courier',
      'EcoSport',
      'Fiesta',
      'Focus',
      'Fusion',
      'Ka',
      'Maverick',
      'Ranger',
    ],
    'Honda': ['City', 'Civic', 'CR-V', 'Fit', 'HR-V', 'WR-V'],
    'Hyundai': ['Creta', 'HB20', 'HB20S', 'i30', 'Santa Fe', 'Tucson'],
    'Jeep': ['Commander', 'Compass', 'Renegade', 'Wrangler'],
    'Kia': ['Bongo', 'Carnival', 'Cerato', 'Sportage'],
    'Mercedes-Benz': ['Classe A', 'Classe C', 'GLA', 'Sprinter', 'Vito'],
    'Mitsubishi': ['ASX', 'Eclipse Cross', 'L200', 'Outlander', 'Pajero'],
    'Nissan': ['Frontier', 'Kicks', 'Livina', 'March', 'Sentra', 'Versa'],
    'Peugeot': ['206', '207', '208', '2008', '3008', 'Partner'],
    'Renault': [
      'Captur',
      'Clio',
      'Duster',
      'Kangoo',
      'Kwid',
      'Logan',
      'Oroch',
      'Sandero',
    ],
    'Toyota': [
      'Bandeirante',
      'Corolla',
      'Corolla Cross',
      'Etios',
      'Hilux',
      'SW4',
      'Yaris',
    ],
    'Volkswagen': [
      'Amarok',
      'Fox',
      'Gol',
      'Golf',
      'Nivus',
      'Parati',
      'Polo',
      'Saveiro',
      'T-Cross',
      'Taos',
      'Up',
      'Virtus',
      'Voyage',
    ],
    'Volvo': ['XC40', 'XC60', 'XC90'],
  },
  'Van': {
    'Citroen': ['Jumper', 'Jumpy'],
    'Fiat': ['Doblo', 'Ducato', 'Fiorino', 'Scudo'],
    'Ford': ['Transit'],
    'Hyundai': ['H-1', 'HR'],
    'Iveco': ['Daily'],
    'JAC': ['T8', 'V260'],
    'Kia': ['Besta', 'Bongo'],
    'Mercedes-Benz': ['Sprinter', 'Vito'],
    'Peugeot': ['Boxer', 'Expert', 'Partner'],
    'Renault': ['Kangoo', 'Master'],
    'Volkswagen': ['Delivery', 'Kombi'],
  },
  'Caminhao': {
    'Agrale': ['A7500', 'Marrua'],
    'Ford': ['Cargo', 'F-4000'],
    'Hyundai': ['HR'],
    'Iveco': ['Daily', 'Tector'],
    'MAN': ['TGX'],
    'Mercedes-Benz': ['Accelo', 'Actros', 'Atego', 'Axor'],
    'Scania': ['P Series', 'R Series', 'S Series'],
    'Volkswagen': ['Constellation', 'Delivery', 'Worker'],
    'Volvo': ['FH', 'FM', 'VM'],
  },
  'Bicicleta': {
    'Audax': ['AD', 'Havok', 'Ventus'],
    'Caloi': ['Explorer', 'Moab', 'Supra', 'Velox', 'Vulcan'],
    'Cannondale': ['Bad Boy', 'Quick', 'Trail'],
    'Giant': ['ATX', 'Escape', 'Talon'],
    'Oggi': ['Agile', 'Big Wheel', 'Cattura', 'Hacker'],
    'Sense': ['Fun', 'Impact', 'One', 'Rock'],
    'Specialized': ['Rockhopper', 'Sirrus', 'Turbo'],
    'Trek': ['Domane', 'Marlin', 'Verve'],
  },
  'Patinete': {
    'Atrio': ['ES', 'Fun'],
    'Foston': ['S09', 'S10'],
    'GoBoard': ['Go S1', 'Go S2'],
    'Multilaser': ['Urban', 'Volts'],
    'Ninebot': ['E2', 'F2', 'G30', 'Max'],
    'Xiaomi': ['Essential', 'Mi Electric Scooter', 'Pro 2', 'Scooter 4'],
  },
};

Map<String, List<String>> vehicleModelsByBrandForType(String type) {
  return vehicleModelsByTypeAndBrand[type] ?? const {};
}

List<String> vehicleBrandsForType(String type) {
  return (vehicleModelsByBrandForType(type).keys.toList()..sort())
    ..add('Outros');
}

List<String> vehicleModelsFor({required String type, required String brand}) {
  if (_normalize(brand) == 'outros') return const ['Outros'];
  final brands = vehicleModelsByBrandForType(type);
  final exact = brands[brand.trim()];
  if (exact != null) return [...exact, 'Outros'];
  final models = brands.entries
      .firstWhere(
        (entry) => _normalize(entry.key) == _normalize(brand),
        orElse: () => const MapEntry('', <String>[]),
      )
      .value;
  if (models.isEmpty) return const ['Outros'];
  return [...models, 'Outros'];
}

Map<String, List<String>> get vehicleModelsByBrand {
  final merged = <String, List<String>>{};
  for (final byBrand in vehicleModelsByTypeAndBrand.values) {
    byBrand.forEach((brand, models) {
      merged[brand] = {...?merged[brand], ...models}.toList()..sort();
    });
  }
  return merged;
}

List<String> get vehicleBrands => vehicleModelsByBrand.keys.toList()..sort();

CountryPhoneFormat phoneFormatForCountry(String country) {
  return driverPhoneFormats.firstWhere(
    (item) => _normalize(item.country) == _normalize(country),
    orElse: () => driverPhoneFormats.first,
  );
}

List<String> citiesForRegion({required String country, required String state}) {
  if (_normalize(country) == 'brasil' && _normalize(state) == 'goias') {
    return goiasCities;
  }
  return const [];
}

String normalizePhoneForStorage(String value, String country) {
  final format = phoneFormatForCountry(country);
  var digits = value.replaceAll(RegExp(r'\D'), '');
  final countryDigits = format.dialCode.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith(countryDigits) &&
      digits.length > countryDigits.length) {
    digits = digits.substring(countryDigits.length);
  }
  if (digits.length > format.maxNationalDigits) {
    digits = digits.substring(0, format.maxNationalDigits);
  }
  return digits;
}

String formatPhoneForDisplay(String value, String country) {
  final format = phoneFormatForCountry(country);
  final digits = normalizePhoneForStorage(value, country);

  if (format.country == 'Brasil') {
    if (digits.length <= 2) return '${format.dialCode} ($digits';
    final ddd = digits.substring(0, 2);
    final rest = digits.substring(2);
    if (rest.length <= 5) return '${format.dialCode} ($ddd) $rest';
    return '${format.dialCode} ($ddd) ${rest.substring(0, 5)}-${rest.substring(5)}';
  }

  return '${format.dialCode} $digits'.trim();
}

class CountryPhoneTextInputFormatter extends TextInputFormatter {
  const CountryPhoneTextInputFormatter(this.countryProvider);

  final String Function() countryProvider;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = formatPhoneForDisplay(newValue.text, countryProvider());
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

String _normalize(String value) {
  return value
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');
}
