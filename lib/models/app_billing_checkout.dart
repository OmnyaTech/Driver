class AppBillingCheckout {
  const AppBillingCheckout({
    required this.url,
    required this.provider,
    required this.planType,
    required this.billingCycle,
    required this.externalReference,
  });

  final String url;
  final String provider;
  final String planType;
  final String billingCycle;
  final String externalReference;
}
