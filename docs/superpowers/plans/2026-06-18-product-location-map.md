# Product Location Map Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an in-app OpenStreetMap location view for the restaurant from the product home header.

**Architecture:** `ProductHomePage` owns the header action and pushes a focused `RestaurantLocationPage`. The map page uses `flutter_map` with OSM tiles and a static Braga Bandung coordinate, keeping map rendering separate from product listing logic.

**Tech Stack:** Flutter, widget tests, `flutter_map`, `latlong2`, OpenStreetMap tile URL.

---

### Task 1: Header Location Navigation

**Files:**
- Modify: `test/features/product/presentation/pages/product_home_page_test.dart`
- Modify: `lib/features/product/presentation/pages/product_home_page.dart`
- Create: `lib/features/product/presentation/pages/restaurant_location_page.dart`
- Modify: `pubspec.yaml`

- [ ] **Step 1: Write the failing widget test**

Create a widget test that pumps `ProductHomePage`, taps the location icon, and expects the restaurant map page title.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/features/product/presentation/pages/product_home_page_test.dart`

Expected: FAIL because the location icon/page does not exist yet.

- [ ] **Step 3: Add map dependencies**

Add `flutter_map` and `latlong2` to `pubspec.yaml`, then run `flutter pub get`.

- [ ] **Step 4: Implement the map page**

Create `RestaurantLocationPage` with an app bar, `FlutterMap`, OSM tile layer, marker at Braga Bandung, and a bottom information panel.

- [ ] **Step 5: Wire header action**

Add a location icon button beside logout in `ProductHomePage` and push `RestaurantLocationPage` on tap.

- [ ] **Step 6: Verify**

Run the focused widget test and `flutter analyze` or the narrowest analyzer command that works in the environment.
