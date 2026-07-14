import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/platform_service.dart';
import '../../services/profile_service.dart';
import '../../services/driver_preference_service.dart';
import '../../models/driver_reserve_preference.dart';
import '../../services/vehicle_service.dart';
import '../../utilities/forms/driver_form_catalogs.dart';
import '../../utilities/state/app_session.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _profileService = ProfileService();
  final _preferenceService = DriverPreferenceService();
  final _vehicleService = VehicleService();
  final _platformService = PlatformService();
  final _displayNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'Brasil');
  final _reservePercentageController = TextEditingController(text: '30');
  final _reservePerDeliveryController = TextEditingController(text: '0');
  final _vehicleBrandController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _platformNameController = TextEditingController();
  final _platformIncomeController = TextEditingController();
  final _platformDeliveriesController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _step = 0;
  bool _saving = false;
  String _platformType = 'platform';
  String _languageCode = 'pt-BR';
  String _currencyCode = 'BRL';
  String _vehicleType = vehicleTypes.first;
  List<String> _vehicleFuelTypes = const [];
  DriverReserveMode _reserveMode = DriverReserveMode.dailyPercent;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppSession>().profile;
    _displayNameController.text = profile?.displayName ?? '';
    _fullNameController.text = profile?.fullName ?? '';
    _phoneController.text = formatPhoneForDisplay(
      profile?.phone ?? '',
      profile?.country ?? 'Brasil',
    );
    _cityController.text = profile?.city ?? '';
    _stateController.text = profile?.state ?? '';
    _countryController.text = profile?.country ?? 'Brasil';
    _languageCode = profile?.languageCode ?? 'pt-BR';
    _currencyCode = profile?.currencyCode ?? 'BRL';
    final reserve = profile?.reservePreference;
    if (reserve != null) {
      _reserveMode = reserve.mode;
      _reservePercentageController.text = reserve.dailyPercentage
          .toStringAsFixed(
            reserve.dailyPercentage.truncateToDouble() ==
                    reserve.dailyPercentage
                ? 0
                : 1,
          );
      _reservePerDeliveryController.text = reserve.amountPerDelivery
          .toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _reservePercentageController.dispose();
    _reservePerDeliveryController.dispose();
    _vehicleBrandController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _platformNameController.dispose();
    _platformIncomeController.dispose();
    _platformDeliveriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Primeiros passos')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _step,
          onStepContinue: _handleContinue,
          onStepCancel: _step == 0
              ? null
              : () => setState(() {
                  _step -= 1;
                }),
          controlsBuilder: (context, details) {
            return Row(
              children: [
                FilledButton(
                  onPressed: _saving ? null : details.onStepContinue,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_step == 4 ? 'Entrar no app' : 'Continuar'),
                ),
                if (_step > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: _saving ? null : details.onStepCancel,
                    child: const Text('Voltar'),
                  ),
                ],
              ],
            );
          },
          steps: [
            Step(
              isActive: _step >= 0,
              title: const Text('Quem e voce'),
              subtitle: const Text('O basico para deixar o app com sua cara'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome exibido',
                    ),
                    validator: _step == 0 ? _required : null,
                  ),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                    ),
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Telefone',
                      helperText:
                          'Formato: ${phoneFormatForCountry(_countryController.text).example}',
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      CountryPhoneTextInputFormatter(
                        () => _countryController.text,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Step(
              isActive: _step >= 1,
              title: const Text('Sua regiao'),
              subtitle: const Text(
                'Usamos isso para organizar rankings e locais',
              ),
              content: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue:
                        driverPhoneFormats.any(
                          (format) => format.country == _countryController.text,
                        )
                        ? _countryController.text
                        : 'Brasil',
                    decoration: const InputDecoration(labelText: 'Pais'),
                    items: driverPhoneFormats
                        .map(
                          (format) => DropdownMenuItem(
                            value: format.country,
                            child: Text(format.country),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _countryController.text = value ?? 'Brasil';
                        _stateController.clear();
                        _cityController.clear();
                        _phoneController.text = formatPhoneForDisplay(
                          _phoneController.text,
                          _countryController.text,
                        );
                      });
                    },
                  ),
                  if (_countryController.text == 'Brasil')
                    DropdownButtonFormField<String>(
                      initialValue: brazilStates.contains(_stateController.text)
                          ? _stateController.text
                          : null,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: brazilStates
                          .map(
                            (state) => DropdownMenuItem(
                              value: state,
                              child: Text(state),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _stateController.text = value ?? '';
                          _cityController.clear();
                        });
                      },
                    )
                  else
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(labelText: 'Estado'),
                    ),
                  if (citiesForRegion(
                    country: _countryController.text,
                    state: _stateController.text,
                  ).isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue:
                          citiesForRegion(
                            country: _countryController.text,
                            state: _stateController.text,
                          ).contains(_cityController.text)
                          ? _cityController.text
                          : null,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      items:
                          citiesForRegion(
                                country: _countryController.text,
                                state: _stateController.text,
                              )
                              .map(
                                (city) => DropdownMenuItem(
                                  value: city,
                                  child: Text(city),
                                ),
                              )
                              .toList(),
                      validator: _step == 1 ? _required : null,
                      onChanged: (value) =>
                          setState(() => _cityController.text = value ?? ''),
                    )
                  else
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(labelText: 'Cidade'),
                      validator: _step == 1 ? _required : null,
                    ),
                ],
              ),
            ),
            Step(
              isActive: _step >= 2,
              title: const Text('Preferencias'),
              subtitle: const Text('Idioma, moeda e dinheiro para guardar'),
              content: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _languageCode,
                    decoration: const InputDecoration(labelText: 'Idioma'),
                    items: const [
                      DropdownMenuItem(
                        value: 'pt-BR',
                        child: Text('Portugues do Brasil'),
                      ),
                      DropdownMenuItem(value: 'en-US', child: Text('English')),
                      DropdownMenuItem(value: 'es-ES', child: Text('Espanol')),
                    ],
                    onChanged: (value) =>
                        setState(() => _languageCode = value ?? 'pt-BR'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _currencyCode,
                    decoration: const InputDecoration(labelText: 'Moeda'),
                    items: const [
                      DropdownMenuItem(
                        value: 'BRL',
                        child: Text('Real brasileiro'),
                      ),
                      DropdownMenuItem(
                        value: 'USD',
                        child: Text('Dolar americano'),
                      ),
                      DropdownMenuItem(value: 'EUR', child: Text('Euro')),
                    ],
                    onChanged: (value) =>
                        setState(() => _currencyCode = value ?? 'BRL'),
                  ),
                  DropdownButtonFormField<DriverReserveMode>(
                    initialValue: _reserveMode,
                    decoration: const InputDecoration(
                      labelText: 'Reserva automatica',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: DriverReserveMode.dailyPercent,
                        child: Text('% do lucro do dia'),
                      ),
                      DropdownMenuItem(
                        value: DriverReserveMode.perDeliveryFixed,
                        child: Text('Valor por entrega'),
                      ),
                      DropdownMenuItem(
                        value: DriverReserveMode.none,
                        child: Text('Sem reserva'),
                      ),
                    ],
                    onChanged: (value) => setState(
                      () => _reserveMode =
                          value ?? DriverReserveMode.dailyPercent,
                    ),
                  ),
                  if (_reserveMode == DriverReserveMode.dailyPercent)
                    TextFormField(
                      controller: _reservePercentageController,
                      decoration: const InputDecoration(
                        labelText: 'Percentual do lucro do dia',
                        suffixText: '%',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _step == 2 ? _validatePercent : null,
                    ),
                  if (_reserveMode == DriverReserveMode.perDeliveryFixed)
                    TextFormField(
                      controller: _reservePerDeliveryController,
                      decoration: const InputDecoration(
                        labelText: 'Valor por entrega',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _step == 2 ? _validateMoney : null,
                    ),
                ],
              ),
            ),
            Step(
              isActive: _step >= 3,
              title: const Text('Primeiro veiculo'),
              subtitle: const Text('Opcional, mas ajuda nos custos'),
              content: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _vehicleType,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: vehicleTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) => setState(
                      () => _vehicleType = value ?? vehicleTypes.first,
                    ),
                  ),
                  Autocomplete<String>(
                    initialValue: TextEditingValue(
                      text: _vehicleBrandController.text,
                    ),
                    optionsBuilder: (value) {
                      final query = value.text.trim().toLowerCase();
                      if (query.isEmpty) return vehicleBrands;
                      return vehicleBrands.where(
                        (brand) => brand.toLowerCase().contains(query),
                      );
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          if (controller.text != _vehicleBrandController.text) {
                            controller.text = _vehicleBrandController.text;
                          }
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Marca',
                            ),
                            onChanged: (value) =>
                                _vehicleBrandController.text = value,
                          );
                        },
                    onSelected: (value) {
                      _vehicleBrandController.text = value;
                      setState(() => _vehicleModelController.clear());
                    },
                  ),
                  Autocomplete<String>(
                    initialValue: TextEditingValue(
                      text: _vehicleModelController.text,
                    ),
                    optionsBuilder: (value) {
                      final models =
                          vehicleModelsByBrand[_vehicleBrandController.text
                              .trim()] ??
                          vehicleModelsByBrand.entries
                              .firstWhere(
                                (entry) =>
                                    entry.key.toLowerCase() ==
                                    _vehicleBrandController.text
                                        .trim()
                                        .toLowerCase(),
                                orElse: () => const MapEntry('', <String>[]),
                              )
                              .value;
                      final query = value.text.trim().toLowerCase();
                      if (query.isEmpty) return models;
                      return models.where(
                        (model) => model.toLowerCase().contains(query),
                      );
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          if (controller.text != _vehicleModelController.text) {
                            controller.text = _vehicleModelController.text;
                          }
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Modelo',
                            ),
                            onChanged: (value) =>
                                _vehicleModelController.text = value,
                          );
                        },
                    onSelected: (value) => _vehicleModelController.text = value,
                  ),
                  TextFormField(
                    controller: _vehicleYearController,
                    decoration: const InputDecoration(labelText: 'Ano'),
                    keyboardType: TextInputType.number,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 6),
                      child: Text(
                        'Combustivel',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fuelOptions
                        .map(
                          (fuel) => FilterChip(
                            label: Text(fuel),
                            selected: _vehicleFuelTypes.contains(fuel),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _vehicleFuelTypes = {
                                    ..._vehicleFuelTypes,
                                    fuel,
                                  }.toList();
                                } else {
                                  _vehicleFuelTypes = _vehicleFuelTypes
                                      .where((item) => item != fuel)
                                      .toList();
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Step(
              isActive: _step >= 4,
              title: const Text('Primeira plataforma'),
              subtitle: const Text('Opcional'),
              content: Column(
                children: [
                  TextFormField(
                    controller: _platformNameController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _platformType,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(
                        value: 'platform',
                        child: Text('Plataforma'),
                      ),
                      DropdownMenuItem(
                        value: 'restaurant',
                        child: Text('Restaurante'),
                      ),
                      DropdownMenuItem(value: 'market', child: Text('Mercado')),
                      DropdownMenuItem(value: 'other', child: Text('Outro')),
                    ],
                    onChanged: (value) =>
                        setState(() => _platformType = value ?? 'platform'),
                  ),
                  TextFormField(
                    controller: _platformIncomeController,
                    decoration: const InputDecoration(
                      labelText: 'Media diaria de ganhos',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  TextFormField(
                    controller: _platformDeliveriesController,
                    decoration: const InputDecoration(
                      labelText: 'Media diaria de entregas',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _errorMessage == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
    );
  }

  Future<void> _handleContinue() async {
    if (_step <= 2 && !_formKey.currentState!.validate()) {
      return;
    }

    if (_step < 4) {
      setState(() => _step += 1);
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      await _profileService.updateProfile(
        displayName: _displayNameController.text,
        fullName: _fullNameController.text,
        phone: normalizePhoneForStorage(
          _phoneController.text,
          _countryController.text,
        ),
        city: _cityController.text,
        state: _stateController.text,
        country: _countryController.text,
        completeOnboarding: true,
      );
      await _preferenceService.updateAppPreferences(
        languageCode: _languageCode,
        currencyCode: _currencyCode,
      );
      await _preferenceService.updateReservePreference(
        mode: _reserveMode,
        dailyPercentage: _parseDouble(
          _reservePercentageController.text,
          fallback: 30,
        ),
        amountPerDelivery: _parseDouble(
          _reservePerDeliveryController.text,
          fallback: 0,
        ),
      );

      if (_vehicleBrandController.text.trim().isNotEmpty &&
          _vehicleModelController.text.trim().isNotEmpty) {
        await _vehicleService.createVehicle(
          brand: _vehicleBrandController.text,
          model: _vehicleModelController.text,
          type: _vehicleType,
          year: _vehicleYearController.text,
          fuelTypes: _vehicleFuelTypes,
        );
      }

      if (_platformNameController.text.trim().isNotEmpty) {
        await _platformService.createPlatform(
          name: _platformNameController.text,
          type: _platformType,
          averageIncome: _platformIncomeController.text,
          averageDeliveries: _platformDeliveriesController.text,
        );
      }

      if (!mounted) return;
      await context.read<AppSession>().refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Onboarding concluido com sucesso.')),
      );
    } catch (error, stackTrace) {
      debugPrint('Onboarding failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      final message = switch (error) {
        PostgrestException() => error.message,
        AuthException() => error.message,
        _ => null,
      };

      if (!mounted) return;
      setState(() {
        _errorMessage = message == null || message.trim().isEmpty
            ? 'Nao foi possivel concluir o onboarding agora. Revise os dados e tente novamente.'
            : 'Nao foi possivel concluir o onboarding agora: $message';
      });
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio.';
    }
    return null;
  }

  String? _validatePercent(String? value) {
    final parsed = _parseDouble(value, fallback: -1);
    if (parsed < 0 || parsed > 100) {
      return 'Use um percentual entre 0 e 100.';
    }
    return null;
  }

  String? _validateMoney(String? value) {
    final parsed = _parseDouble(value, fallback: -1);
    if (parsed < 0) return 'Informe um valor valido.';
    return null;
  }

  double _parseDouble(String? value, {required double fallback}) {
    if (value == null) return fallback;
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
  }
}
