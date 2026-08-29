bool isEmergencySymptom(String? symptomId) => symptomId == 'roadside';

String workIdFor({required String want, String? symptom}) {
  if (want == 'diag') {
    return symptom == 'brakes' || symptom == 'noise'
        ? 'diag-chassis'
        : 'diag-comp';
  }
  if (want == 'coding') {
    return 'coding';
  }
  if (want == 'to') {
    return 'oil';
  }
  return switch (symptom) {
    'brakes' => 'pads',
    'engine' => 'plugs',
    'electrics' => 'battery',
    'noise' => 'align',
    'to' => 'oil',
    'headlight_pair' => 'coding',
    'underbody_cover' => 'align',
    'ecu_flash' => 'coding',
    _ => 'diag-comp',
  };
}
