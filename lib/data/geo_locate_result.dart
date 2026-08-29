enum LocateFail { servicesOff, denied, deniedForever, unavailable }

class LocateResult {
  const LocateResult.ok(this.lat, this.lng) : fail = null;
  const LocateResult.fail(this.fail)
      : lat = null,
        lng = null;

  final double? lat;
  final double? lng;
  final LocateFail? fail;

  bool get isOk => fail == null && lat != null && lng != null;
}
