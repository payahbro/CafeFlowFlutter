# Product New Bubble Notification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show an in-app bubble notification when product lists detect newly added products, and stop truncating home/catalog product results to 8/10 items.

**Architecture:** Add a small product notification model/tracker at presentation level, expose pending new-product notifications from home and management controllers, and render them through a reusable bubble widget. First list load establishes a baseline; later reloads compare product ids and surface the newest unseen product.

**Tech Stack:** Flutter, ChangeNotifier controllers, flutter_test widget tests.

---

### Task 1: Product Home Controller New Product Detection

**Files:**
- Modify: `lib/features/product/presentation/cubit/product_home_controller.dart`
- Test: `test/features/product/presentation/cubit/product_home_controller_test.dart`

- [ ] **Step 1: Write failing tests**

Add tests proving first load does not notify, second load with a new id does notify, and featured products are no longer limited to 8.

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/product/presentation/cubit/product_home_controller_test.dart`

- [ ] **Step 3: Implement minimal controller state**

Add a `newProductNotification` getter, compare product ids between loads, clear notification when dismissed, and remove `.take(8)`.

- [ ] **Step 4: Verify tests pass**

Run: `flutter test test/features/product/presentation/cubit/product_home_controller_test.dart`

### Task 2: Product Catalog Limit Fix

**Files:**
- Modify: `lib/features/product/presentation/cubit/product_catalog_controller.dart`
- Test: `test/features/product/presentation/cubit/product_catalog_controller_test.dart`

- [ ] **Step 1: Write failing test**

Add a test proving local search can return more than 10 products from the fetched batch.

- [ ] **Step 2: Run test**

Run: `flutter test test/features/product/presentation/cubit/product_catalog_controller_test.dart`

- [ ] **Step 3: Implement minimal limit change**

Change the default local query limit from 10 to 50 so the already fetched remote batch is not truncated to 10.

- [ ] **Step 4: Verify tests pass**

Run: `flutter test test/features/product/presentation/cubit/product_catalog_controller_test.dart`

### Task 3: Management Controller New Product Detection

**Files:**
- Modify: `lib/features/product/presentation/cubit/product_management_controller.dart`
- Test: `test/features/product/presentation/cubit/product_management_controller_test.dart`

- [ ] **Step 1: Write failing tests**

Add tests proving first load does not notify and create/reload surfaces the created product as a new-product notification.

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/product/presentation/cubit/product_management_controller_test.dart`

- [ ] **Step 3: Implement minimal controller state**

Add `newProductNotification`, update `createProduct` to return `bool`, detect new ids after reload, and clear notification on demand.

- [ ] **Step 4: Verify tests pass**

Run: `flutter test test/features/product/presentation/cubit/product_management_controller_test.dart`

### Task 4: Reusable Bubble UI

**Files:**
- Create: `lib/features/product/presentation/widgets/new_product_bubble.dart`
- Modify: `lib/features/product/presentation/pages/product_home_page.dart`
- Modify: `lib/features/product/presentation/pages/product_management_page.dart`
- Test: `test/features/product/presentation/pages/product_home_page_test.dart`
- Test: `test/features/product/presentation/pages/product_management_page_test.dart`

- [ ] **Step 1: Write failing widget tests**

Add tests that the home page and management page render the new-product bubble when controller notification state is set by a reload.

- [ ] **Step 2: Run tests**

Run: `flutter test test/features/product/presentation/pages/product_home_page_test.dart test/features/product/presentation/pages/product_management_page_test.dart`

- [ ] **Step 3: Implement bubble widget and page overlays**

Create a floating Material bubble with title, product name, close button, and optional tap callback. Render it in a Stack over both pages.

- [ ] **Step 4: Verify tests pass**

Run: `flutter test test/features/product/presentation/pages/product_home_page_test.dart test/features/product/presentation/pages/product_management_page_test.dart`

### Task 5: Final Verification

**Files:**
- All modified files

- [ ] **Step 1: Run focused tests**

Run: `flutter test test/features/product/presentation/cubit/product_home_controller_test.dart test/features/product/presentation/cubit/product_catalog_controller_test.dart test/features/product/presentation/cubit/product_management_controller_test.dart test/features/product/presentation/pages/product_home_page_test.dart test/features/product/presentation/pages/product_management_page_test.dart`

- [ ] **Step 2: Run static analysis**

Run: `flutter analyze`

- [ ] **Step 3: Report git limitation**

Git currently reports dubious ownership for `C:/projects/CafeFlowFlutter`, so commits are skipped unless safe.directory is configured by the user.
