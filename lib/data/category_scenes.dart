/// Wide cinematic workshop plates. Category thumbs stay in
/// `assets/categories/{id}.jpg`; these are full-bleed scene keys.
String categorySceneAsset(String? sphereId) {
  return 'assets/scenes/scene-${categorySceneKey(sphereId)}.jpg';
}

String categorySceneKey(String? sphereId) {
  switch (sphereId) {
    case 'paint':
    case 'bumper':
    case 'ppf':
    case 'ceramic':
    case 'carbon':
    case 'rims':
      return 'paint';
    case 'wrap':
      return 'wrap';
    case 'hydro':
      return 'hydro';
    case 'interior':
    case 'sound':
    case 'soundproof':
    case 'chem-clean':
      return 'interior';
    case 'engine':
    case 'turbo':
    case 'stage3':
    case 'injectors':
    case 'radiator':
    case 'dpf':
    case 'gearbox':
      return 'engine';
    case 'service':
    case 'lpg':
    case 'ac':
      return 'service';
    case 'wash':
      return 'wash';
    case 'welding':
    case 'body':
    case 'pdr':
    case 'anticor':
      return 'welding';
    case 'chassis':
    case 'steering':
    case 'cvjoint':
    case 'align':
      return 'chassis';
    case 'brakes':
    case 'clutch':
      return 'brakes';
    case 'tires':
      return 'tires';
    case 'diag':
    case 'electronics':
    case 'coding':
    case 'adas':
    case 'android':
    case 'srs':
    case 'alarm':
    case 'keys':
    case 'tuning':
    case 'mobile':
      return 'electronics';
    case 'glass':
    case 'lights':
      return 'glass';
    case 'exhaust':
      return 'exhaust';
    default:
      return 'workshop';
  }
}
