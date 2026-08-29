/// Shared bottom-nav index mapping for client shell.
library;

import '../../../app/providers.dart';

/// Bar slots: Feed · STO · Car · Categories · Bookings · Services
int clientBarIndexForTab(int tab) {
  return switch (tab) {
    ClientTabs.feed => 0,
    ClientTabs.shops => 1,
    ClientTabs.car => 2,
    ClientTabs.categories => 3,
    ClientTabs.bookings => 4,
    ClientTabs.help || ClientTabs.requests || ClientTabs.auction || ClientTabs.usa => 5,
    _ => 2,
  };
}

int clientTabForBarIndex(int index) {
  return switch (index) {
    0 => ClientTabs.feed,
    1 => ClientTabs.shops,
    2 => ClientTabs.car,
    3 => ClientTabs.categories,
    4 => ClientTabs.bookings,
    _ => -1, // services sheet
  };
}
