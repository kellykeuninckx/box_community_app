/// Officiële IPF-gewichtsklassen (sinds 2019).
class WeightClass {
  static const menLimits = [59, 66, 74, 83, 93, 105, 120];
  static const womenLimits = [47, 52, 57, 63, 69, 76, 84];

  static String forWeight(String gender, double bodyweightKg) {
    final limits = gender == 'M' ? menLimits : womenLimits;

    for (final limit in limits) {
      if (bodyweightKg <= limit) return '-$limit kg';
    }

    return gender == 'M' ? '120+ kg' : '84+ kg';
  }
}