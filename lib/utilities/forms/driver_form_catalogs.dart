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

const vehicleModelsByBrand = <String, List<String>>{
  'Yamaha': ['Factor', 'Fazer', 'Fluo', 'NMax', 'XMax', 'XTZ', 'MT-03'],
  'Honda': ['Biz', 'CG 160', 'PCX', 'Pop', 'XRE', 'City', 'Civic', 'HR-V'],
  'Chevrolet': [
    'Celta',
    'Classic',
    'Cobalt',
    'Corsa',
    'Onix',
    'Prisma',
    'Spin',
  ],
  'Peugeot': ['206', '207', '208', '2008', 'Partner'],
  'Renault': ['Clio', 'Duster', 'Kangoo', 'Kwid', 'Logan', 'Sandero'],
  'Fiat': ['Argo', 'Cronos', 'Fiorino', 'Mobi', 'Palio', 'Strada', 'Uno'],
  'Citroen': ['C3', 'C4 Cactus', 'Jumpy', 'Berlingo'],
  'Volkswagen': ['Fox', 'Gol', 'Polo', 'Saveiro', 'T-Cross', 'Up'],
  'Toyota': ['Corolla', 'Etios', 'Hilux', 'Yaris'],
  'Hyundai': ['HB20', 'Creta', 'i30', 'Tucson'],
  'Ford': ['Courier', 'EcoSport', 'Fiesta', 'Ka', 'Ranger'],
  'Nissan': ['Kicks', 'March', 'Sentra', 'Versa'],
  'Jeep': ['Compass', 'Renegade'],
  'Shineray': ['Jet', 'Worker', 'XY'],
  'Dafra': ['Citycom', 'Horizon', 'Next'],
};

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
