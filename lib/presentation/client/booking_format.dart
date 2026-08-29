import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_lang.dart';
import '../../core/l10n/app_strings.dart';
import '../../data/catalog_seed.dart';
import '../../domain/models/crm_models.dart';
import '../../domain/models/shop_models.dart';

String formatEta(int minutes, AppStrings s) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) {
    return '${s.etaAbout} $rest ${s.minutesShort}';
  }
  if (rest == 0) {
    return '${s.etaAbout} $hours ${s.hoursShort}';
  }
  return '${s.etaAbout} $hours ${s.hoursShort} $rest ${s.minutesShort}';
}

const _weekdays = [
  L('пн', 'Mon', 'пн', 'pon.'),
  L('вт', 'Tue', 'вт', 'wt.'),
  L('ср', 'Wed', 'ср', 'śr.'),
  L('чт', 'Thu', 'чт', 'czw.'),
  L('пт', 'Fri', 'пт', 'pt.'),
  L('сб', 'Sat', 'сб', 'sob.'),
  L('нд', 'Sun', 'вс', 'niedz.'),
];

const _monthsShort = [
  L('січ', 'Jan', 'янв', 'sty'),
  L('лют', 'Feb', 'фев', 'lut'),
  L('бер', 'Mar', 'мар', 'mar'),
  L('кві', 'Apr', 'апр', 'kwi'),
  L('тра', 'May', 'мая', 'maj'),
  L('чер', 'Jun', 'июн', 'cze'),
  L('лип', 'Jul', 'июл', 'lip'),
  L('сер', 'Aug', 'авг', 'sie'),
  L('вер', 'Sep', 'сен', 'wrz'),
  L('жов', 'Oct', 'окт', 'paź'),
  L('лис', 'Nov', 'ноя', 'lis'),
  L('гру', 'Dec', 'дек', 'gru'),
];

const _monthsLong = [
  L('січня', 'January', 'января', 'stycznia'),
  L('лютого', 'February', 'февраля', 'lutego'),
  L('березня', 'March', 'марта', 'marca'),
  L('квітня', 'April', 'апреля', 'kwietnia'),
  L('травня', 'May', 'мая', 'maja'),
  L('червня', 'June', 'июня', 'czerwca'),
  L('липня', 'July', 'июля', 'lipca'),
  L('серпня', 'August', 'августа', 'sierpnia'),
  L('вересня', 'September', 'сентября', 'września'),
  L('жовтня', 'October', 'октября', 'października'),
  L('листопада', 'November', 'ноября', 'listopada'),
  L('грудня', 'December', 'декабря', 'grudnia'),
];

String formatSlotDay(DateTime date, DateTime now, AppStrings s, AppLang lang) {
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;
  if (diff == 0) return s.today;
  if (diff == 1) return s.tomorrow;
  final wd = _weekdays[date.weekday - 1].of(lang);
  final mo = _monthsShort[date.month - 1].of(lang);
  return '$wd ${date.day} $mo';
}

String formatWhen(DateTime date, AppLang lang) {
  final mo = _monthsLong[date.month - 1].of(lang);
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '${date.day} $mo, $hh:$mm';
}

const _monthsTitle = [
  L('Січень', 'January', 'Январь', 'Styczeń'),
  L('Лютий', 'February', 'Февраль', 'Luty'),
  L('Березень', 'March', 'Март', 'Marzec'),
  L('Квітень', 'April', 'Апрель', 'Kwiecień'),
  L('Травень', 'May', 'Май', 'Maj'),
  L('Червень', 'June', 'Июнь', 'Czerwiec'),
  L('Липень', 'July', 'Июль', 'Lipiec'),
  L('Серпень', 'August', 'Август', 'Sierpień'),
  L('Вересень', 'September', 'Сентябрь', 'Wrzesień'),
  L('Жовтень', 'October', 'Октябрь', 'Październik'),
  L('Листопад', 'November', 'Ноябрь', 'Listopad'),
  L('Грудень', 'December', 'Декабрь', 'Grudzień'),
];

String formatMonthYear(DateTime date, AppLang lang) =>
    '${_monthsTitle[date.month - 1].of(lang)} ${date.year}';

List<String> weekdayHeaders(AppLang lang) => [
      for (final day in _weekdays) day.of(lang),
    ];

String formatClock(DateTime date) => DateFormat('HH:mm').format(date);

ServiceWork workById(String id) {
  return catalogWorks.firstWhere((item) => item.id == id);
}

List<ServiceWork> worksFor(ShopProfile shop, {Set<String>? sphereWorkIds}) {
  final ids = sphereWorkIds == null || sphereWorkIds.isEmpty
      ? shop.workIds
      : shop.workIds.where(sphereWorkIds.contains);
  return [for (final id in ids) workById(id)];
}

String specialtyLabel(AppStrings s, MasterSpecialty spec) {
  return switch (spec) {
    MasterSpecialty.electrician => s.specElectrician,
    MasterSpecialty.motorist => s.specMotorist,
    MasterSpecialty.chassis => s.specChassis,
    MasterSpecialty.maintenance => s.specMaintenance,
  };
}

String categoryLabel(AppStrings s, RepairCategory category) {
  return switch (category) {
    RepairCategory.diagnostics => s.catDiag,
    RepairCategory.chassis => s.catChassis,
    RepairCategory.electrical => s.catElectrical,
    RepairCategory.maintenance => s.catMaintenance,
    RepairCategory.engine => s.catEngine,
  };
}

IconData galleryIcon(IconKey key) {
  return switch (key) {
    IconKey.bay => Icons.garage_outlined,
    IconKey.engine => Icons.settings_suggest_outlined,
    IconKey.chips => Icons.memory_outlined,
    IconKey.paint => Icons.format_paint_outlined,
    IconKey.lift => Icons.view_week_outlined,
    IconKey.night => Icons.nights_stay_outlined,
  };
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
