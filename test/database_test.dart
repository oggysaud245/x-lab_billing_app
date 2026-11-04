import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xlab_billing/core/db/app_database.dart';
import 'package:xlab_billing/shared/controllers/app_state.dart';
import 'package:xlab_billing/shared/models/app_settings.dart';
import 'package:xlab_billing/shared/models/billing_profile.dart';
import 'package:xlab_billing/shared/models/organization.dart';
import 'package:xlab_billing/shared/models/receipt_profile.dart';
import 'package:xlab_billing/shared/models/receipt_settings.dart';
import 'package:xlab_billing/shared/models/product_category.dart';
import 'package:xlab_billing/shared/repositories/product_repository.dart';
import 'package:xlab_billing/shared/repositories/settings_repository.dart';
import 'package:xlab_billing/shared/repositories/unit_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('createSchema creates tables and seeds defaults', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await createSchema(db);
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final names = tables.map((r) => r['name']).toSet().toList();
    expect(names, containsAll([
      'organizations',
      'units',
      'products',
      'invoices',
      'invoice_items',
      'printer_configurations',
      'receipt_settings',
      'app_settings',
      'print_jobs',
    ]));
    final next = await db
        .query('app_settings', where: 'key = ?', whereArgs: ['invoice_next']);
    expect(next.first['value'], '1');
    await db.close();
  });

  test('SettingsRepository.save persists language and settings to app_settings', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await createSchema(db);
    final repo = SettingsRepository(open: () async => db);

    await repo.save({
      'app_language': 'ne',
      'invoice_language': 'ne',
      'bottom_margin_on_receipt': '1',
    });

    final loaded = await repo.load();
    expect(loaded.appLanguage, AppLanguage.ne);
    expect(loaded.invoiceLanguageMode, InvoiceLanguageMode.ne);
    expect(loaded.bottomMarginOnReceipt, isTrue);
    await db.close();
  });

  test('SettingsRepository persists multiple ReceiptProfiles and activeId', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await createSchema(db);
    final repo = SettingsRepository(open: () async => db);

    final p1 = ReceiptProfile(
      id: 'p1',
      name: 'Retail EN',
      organization: Organization.empty.copyWith(
        nameEn: 'Kaicho Group Pvt Ltd',
        panNumber: '1234567',
      ),
      invoiceLanguageMode: InvoiceLanguageMode.en,
      receipt: ReceiptSettings.defaults.copyWith(showPanVat: true),
    );
    final p2 = ReceiptProfile(
      id: 'p2',
      name: 'Wholesale NE',
      organization: Organization.empty.copyWith(
        nameNe: 'काइचो ग्रुप प्रा लि',
        panNumber: '9999999',
      ),
      invoiceLanguageMode: InvoiceLanguageMode.ne,
      useBikramSambat: true,
      receipt: ReceiptSettings.defaults.copyWith(
        showPanVat: true,
        thankNe: 'फेरि आउनुहोला',
      ),
    );

    await repo.saveProfiles([p1, p2], 'p2');
    final (loaded, activeId) = await repo.loadProfiles();

    expect(activeId, 'p2');
    expect(loaded, hasLength(2));
    expect(loaded[0].name, 'Retail EN');
    expect(loaded[0].organization.panNumber, '1234567');
    expect(loaded[1].name, 'Wholesale NE');
    expect(loaded[1].invoiceLanguageMode, InvoiceLanguageMode.ne);
    expect(loaded[1].receipt.thankNe, 'फेरि आउनुहोला');
    await db.close();
  });

  test('SettingsRepository persists multiple BillingProfiles and activeId', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await createSchema(db);
    final repo = SettingsRepository(open: () async => db);

    const b1 = BillingProfile(
      id: 'b1',
      name: 'Retail 13% VAT',
      taxEnabled: true,
      taxPercent: 1300,
      defaultDiscountPercent: 5,
      invoicePrefix: 'RTL-',
      invoiceDigits: 5,
    );
    const b2 = BillingProfile(
      id: 'b2',
      name: 'Wholesale Tax-Free',
      taxEnabled: false,
      taxPercent: 0,
      defaultDiscountPercent: 10,
      invoicePrefix: 'WSL-',
      invoiceDigits: 6,
      fiscalYearPrefix: true,
    );

    await repo.saveBillingProfiles([b1, b2], 'b2');
    final (loaded, activeId) = await repo.loadBillingProfiles();

    expect(activeId, 'b2');
    expect(loaded, hasLength(2));
    expect(loaded[0].name, 'Retail 13% VAT');
    expect(loaded[0].taxEnabled, isTrue);
    expect(loaded[0].taxPercent, 1300);
    expect(loaded[0].invoicePrefix, 'RTL-');
    expect(loaded[1].name, 'Wholesale Tax-Free');
    expect(loaded[1].defaultDiscountPercent, 10);
    expect(loaded[1].fiscalYearPrefix, isTrue);
    await db.close();
  });

  test('AppState detects duplicate receipt and billing profile names', () async {
    final app = AppState();
    const p1 = ReceiptProfile(
      id: 'p1',
      name: 'Counter A',
      organization: Organization.empty,
      receipt: ReceiptSettings.defaults,
    );
    const p2 = ReceiptProfile(
      id: 'p2',
      name: 'Counter B',
      organization: Organization.empty,
      receipt: ReceiptSettings.defaults,
    );
    await app.saveProfile(p1);
    await app.saveProfile(p2);

    expect(app.hasReceiptProfileName('Counter A', defaultName: 'Default'), isTrue);
    expect(app.hasReceiptProfileName('counter a', defaultName: 'Default'), isTrue);
    expect(app.hasReceiptProfileName('Counter A', excludeId: 'p1', defaultName: 'Default'), isFalse);
    expect(app.hasReceiptProfileName('Counter C', defaultName: 'Default'), isFalse);

    const b1 = BillingProfile(id: 'b1', name: 'Standard VAT');
    const b2 = BillingProfile(id: 'b2', name: 'Tax Free');
    await app.saveBillingProfile(b1);
    await app.saveBillingProfile(b2);

    expect(app.hasBillingProfileName('Standard VAT', defaultName: 'Default'), isTrue);
    expect(app.hasBillingProfileName('standard vat', defaultName: 'Default'), isTrue);
    expect(app.hasBillingProfileName('Standard VAT', excludeId: 'b1', defaultName: 'Default'), isFalse);
    expect(app.hasBillingProfileName('Export', defaultName: 'Default'), isFalse);
  });

  test('ProductRepository.addCategory adds and persists standalone categories', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await createSchema(db);
    try {
      final repo = ProductRepository(open: () async => db);

      final initialCats = await repo.categories();
      expect(initialCats, isEmpty);

      await repo.addCategory('Beverages');
      final afterAdd = await repo.categories();
      expect(afterAdd.map((c) => c.key), contains('Beverages'));

      // Insert a product with another category to verify union with products table
      await db.insert('products', {
        'name_en': 'Chips',
        'name_ne': 'चिप्स',
        'rate_paisa': 5000,
        'unit_id': 1,
        'category': 'Snacks',
        'created_at': 1000,
        'updated_at': 1000,
      });
      final merged = await repo.categories();
      expect(merged.map((c) => c.key), containsAll(['Beverages', 'Snacks']));

      // Duplicate check - case insensitive
      await repo.addCategory('beverages');
      final afterDup = await repo.categories();
      expect(afterDup.where((c) => c.key.toLowerCase() == 'beverages').length, 1);
    } finally {
      await db.close();
    }
  });

  test('ProductRepository edit and delete category updates products and persistence', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await createSchema(db);
    try {
      final repo = ProductRepository(open: () async => db);

      await repo.addCategory('Drinks');
      await db.insert('products', {
        'name_en': 'Coke',
        'name_ne': 'कोक',
        'rate_paisa': 6000,
        'unit_id': 1,
        'category': 'Drinks',
        'created_at': 1000,
        'updated_at': 1000,
      });

      expect(await repo.countProductsInCategory('Drinks'), 1);

      // Edit category: 'Drinks' -> 'Beverages'
      await repo.updateCategory('Drinks', 'Beverages');
      final afterEdit = await repo.categories();
      expect(afterEdit.map((c) => c.key), contains('Beverages'));
      expect(afterEdit.map((c) => c.key), isNot(contains('Drinks')));
      expect(await repo.countProductsInCategory('Beverages'), 1);
      expect(await repo.countProductsInCategory('Drinks'), 0);

      // Delete category: 'Beverages'
      await repo.deleteCategory('Beverages');
      final afterDelete = await repo.categories();
      expect(afterDelete.map((c) => c.key), isNot(contains('Beverages')));
      expect(await repo.countProductsInCategory('Beverages'), 0);

      // Coke now has empty category
      final prodRows = await db.query('products', where: 'name_en = ?', whereArgs: ['Coke']);
      expect(prodRows.first['category'], '');
    } finally {
      await db.close();
    }
  });

  test('ProductRepository handles bilingual ProductCategory (nameEn and nameNe)', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await createSchema(db);
    try {
      final repo = ProductRepository(open: () async => db);

      const cat = ProductCategory(nameEn: 'Bakery', nameNe: 'बेकरी');
      await repo.addCategory(cat);

      final cats = await repo.categories();
      expect(cats.length, 1);
      expect(cats.first.nameEn, 'Bakery');
      expect(cats.first.nameNe, 'बेकरी');
      expect(cats.first.displayName(nepali: false), 'Bakery');
      expect(cats.first.displayName(nepali: true), 'बेकरी');

      // Insert product under 'Bakery'
      await db.insert('products', {
        'name_en': 'Bread',
        'name_ne': 'पाउरोटी',
        'rate_paisa': 4500,
        'unit_id': 1,
        'category': 'Bakery',
        'created_at': 1000,
        'updated_at': 1000,
      });

      expect(await repo.countProductsInCategory(cat), 1);
      expect(await repo.countProductsInCategory('Bakery'), 1);
      expect(await repo.countProductsInCategory('बेकरी'), 1);

      // Update category: change Nepali name
      const updatedCat = ProductCategory(nameEn: 'Bakery Goods', nameNe: 'बेकरी सामान');
      await repo.updateCategory(cat, updatedCat);

      final afterUpdate = await repo.categories();
      expect(afterUpdate.length, 1);
      expect(afterUpdate.first.nameEn, 'Bakery Goods');
      expect(afterUpdate.first.nameNe, 'बेकरी सामान');

      // Product's category column was updated to new key
      expect(await repo.countProductsInCategory(updatedCat), 1);
      final prod = await db.query('products', where: 'name_en = ?', whereArgs: ['Bread']);
      expect(prod.first['category'], 'Bakery Goods');

      // Delete category
      await repo.deleteCategory(updatedCat);
      final afterDelete = await repo.categories();
      expect(afterDelete, isEmpty);
      final prodAfterDelete = await db.query('products', where: 'name_en = ?', whereArgs: ['Bread']);
      expect(prodAfterDelete.first['category'], '');
    } finally {
      await db.close();
    }
  });

  test('UnitRepository update, delete, and countProductsUsingUnit', () async {
    final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await createSchema(db);
    final unitRepo = UnitRepository(open: () async => db);

    final customUnit = await unitRepo.addCustom(
      nameEn: 'Box Large',
      nameNe: 'ठूलो बाकस',
      abbrevEn: 'lbox',
      abbrevNe: 'ठूबा',
    );
    expect(customUnit.isCustom, isTrue);

    // Check count when no products use it
    expect(await unitRepo.countProductsUsingUnit(customUnit.id), 0);

    // Insert a product using customUnit
    await db.insert('products', {
      'name_en': 'Big Item',
      'name_ne': 'ठूलो सामान',
      'rate_paisa': 10000,
      'unit_id': customUnit.id,
      'category': '',
      'created_at': 1000,
      'updated_at': 1000,
    });
    expect(await unitRepo.countProductsUsingUnit(customUnit.id), 1);

    // Update unit
    final updatedUnit = customUnit.copyWith(
      nameEn: 'Crate',
      abbrevEn: 'crt',
    );
    await unitRepo.update(updatedUnit);
    final fetched = await unitRepo.byId(customUnit.id);
    expect(fetched.nameEn, 'Crate');
    expect(fetched.abbrevEn, 'crt');

    // Delete custom unit (after removing using product)
    await db.delete('products', where: 'unit_id = ?', whereArgs: [customUnit.id]);
    expect(await unitRepo.countProductsUsingUnit(customUnit.id), 0);
    await unitRepo.delete(customUnit.id);
    final allUnits = await unitRepo.list();
    expect(allUnits.any((u) => u.id == customUnit.id), isFalse);

    // Standard unit cannot be updated or deleted
    final stdUnit = (await unitRepo.list()).firstWhere((u) => !u.isCustom);
    final attemptedUpdate = stdUnit.copyWith(nameEn: 'Modified Piece');
    await unitRepo.update(attemptedUpdate);
    final unchanged = await unitRepo.byId(stdUnit.id);
    expect(unchanged.nameEn, stdUnit.nameEn);

    await unitRepo.delete(stdUnit.id);
    final stillExists = await unitRepo.byId(stdUnit.id);
    expect(stillExists.id, stdUnit.id);

    await db.close();
  });
}
