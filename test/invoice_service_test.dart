import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xlab_billing/core/db/app_database.dart';
import 'package:xlab_billing/shared/controllers/app_state.dart';
import 'package:xlab_billing/shared/controllers/billing_state.dart';
import 'package:xlab_billing/shared/models/app_settings.dart';
import 'package:xlab_billing/shared/models/invoice.dart';
import 'package:xlab_billing/shared/models/organization.dart';
import 'package:xlab_billing/shared/models/product.dart';
import 'package:xlab_billing/shared/models/receipt_profile.dart';
import 'package:xlab_billing/shared/models/receipt_settings.dart';
import 'package:xlab_billing/shared/models/unit.dart';
import 'package:xlab_billing/shared/repositories/invoice_repository.dart';
import 'package:xlab_billing/shared/services/invoice_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  group('InvoiceService.numberFor', () {
    test('default numbering: INV-<seq with digits>', () {
      final s = AppSettings.defaults;
      expect(InvoiceService.numberFor(s, 7, DateTime(2026, 1, 5)), 'INV-000007');
    });

    test('respects prefix + digit count', () {
      final s = AppSettings.defaults.copyWith(invoicePrefix: 'RCPT-', invoiceDigits: 4);
      expect(InvoiceService.numberFor(s, 12, DateTime(2026, 1, 5)), 'RCPT-0012');
    });

    test('adds fiscal year prefix when enabled', () {
      final s = AppSettings.defaults.copyWith(fiscalYearPrefix: true, invoicePrefix: 'INV-');
      final n = InvoiceService.numberFor(s, 3, DateTime(2026, 2, 10));
      expect(n, startsWith('INV-'));
      expect(n.split('-').length, greaterThanOrEqualTo(3));
    });
  });

  group('BillTotals', () {
    test('computes decimal-safe totals', () {
      final t = BillTotals.compute([
        CartLine(
          productId: 1,
          nameEn: 'A',
          nameNe: 'अ',
          skuSnapshot: '',
          unitSnapshotEn: 'pc',
          unitSnapshotNe: 'सं.',
          quantityMilli: 1500, // 1.5 units
          ratePaisa: 125000, // 1250 NPR
          position: 0,
        ),
      ]);
      // 1.5 x 1250.00 = 1875.00
      expect(t.subtotalPaisa, 187500);
      expect(t.grandTotal, 187500);
    });

    test('percent discount + tax', () {
      final t = BillTotals.compute(
        [
          CartLine(
            productId: 1,
            nameEn: 'A',
            nameNe: 'अ',
            skuSnapshot: '',
            unitSnapshotEn: 'pc',
            unitSnapshotNe: 'सं.',
            quantityMilli: 1000,
            ratePaisa: 125000,
            position: 0,
          ),
        ],
        discountType: DiscountType.percent,
        discountValue: 1000, // 10.00%
        taxRate: 1300, // 13%
      );
      // subtotal 125000; discount 12500; taxable 112500; tax 14625; total 127125
      expect(t.discountAmount, 12500);
      expect(t.taxAmount, 14625);
      expect(t.grandTotal, 127125);
    });

    test('computes totals accurately based on quantity decimals', () {
      // Raw quantity 1.255 (1255 milli), unit rate 100 NPR (10000 paisa)
      // When quantity decimal is 2:
      // Displayed quantity is 1.26, so total must be 1.26 x 100 = 126.00 (12600 paisa),
      // NOT 125.50 (12550 paisa).
      final t2 = BillTotals.compute(
        [
          const CartLine(
            productId: 1,
            nameEn: 'A',
            nameNe: 'अ',
            skuSnapshot: '',
            unitSnapshotEn: 'kg',
            unitSnapshotNe: 'किलो',
            quantityMilli: 1255,
            ratePaisa: 10000,
            position: 0,
          ),
        ],
        quantityPrecision: 2,
      );
      expect(t2.subtotalPaisa, 12600);
      expect(t2.grandTotal, 12600);

      // When quantity decimal is 0:
      // 1.5 units rounded to 0 decimals is 2 units. 2 x 100 = 200.00
      final t0 = BillTotals.compute(
        [
          const CartLine(
            productId: 1,
            nameEn: 'A',
            nameNe: 'अ',
            skuSnapshot: '',
            unitSnapshotEn: 'pc',
            unitSnapshotNe: 'सं.',
            quantityMilli: 1500,
            ratePaisa: 10000,
            position: 0,
          ),
        ],
        quantityPrecision: 0,
      );
      expect(t0.subtotalPaisa, 20000);
      expect(t0.grandTotal, 20000);
    });
  });

  group('BillingController.finalize & cross-page sync', () {
    test('finalize returns Invoice with populated invoiceNumber and bumps AppState.dataVersion', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await createSchema(db);
      final app = AppState();
      final billing = BillingController(app: app);
      const unit = Unit(
        id: 1,
        nameEn: 'pc',
        nameNe: 'थान',
        abbrevEn: 'pc',
        abbrevNe: 'थान',
        isCustom: false,
      );
      const prod = Product(
        id: 10,
        nameEn: 'Milk',
        nameNe: 'दूध',
        sku: 'MLK',
        descriptionEn: '',
        descriptionNe: '',
        ratePaisa: 7000,
        unitId: 1,
        category: '',
        isActive: true,
        createdAt: 0,
        updatedAt: 0,
      );
      billing.addProduct(prod, unit: unit);
      expect(app.dataVersion, 0);

      final repo = InvoiceRepository(open: () async => db);
      final service = InvoiceService(openDb: () async => db, invoices: repo);
      final saved = await billing.finalize(invoiceService: service);

      expect(saved.invoiceNumber, 'INV-000001');
      expect(saved.invoiceNumberSeq, 1);
      expect(app.dataVersion, 1);
      expect(billing.isEmpty, isTrue);

      await db.close();
    });

    test('BillingController respects quantityPrecision for cart totals and finalization', () async {
      final db = await AppDatabase.openAt(inMemoryDatabasePath);
      try {
        final app = AppState();
        await app.bootstrap();
        await app.setQuantityPrecision(2);
        final billing = BillingController(app: app);
        billing.syncFromSettings();

        const unit = Unit(
          id: 1,
          nameEn: 'kg',
          nameNe: 'किलो',
          abbrevEn: 'kg',
          abbrevNe: 'किलो',
          isCustom: false,
        );
        const prod = Product(
          id: 10,
          nameEn: 'Rice',
          nameNe: 'चामल',
          sku: 'RCE',
          descriptionEn: '',
          descriptionNe: '',
          ratePaisa: 10000,
          unitId: 1,
          category: '',
          isActive: true,
          createdAt: 0,
          updatedAt: 0,
        );

        billing.addProduct(prod, unit: unit);
        billing.setQuantity(0, 1255);

        expect(billing.lines[0].quantityMilli, 1260);
        expect(billing.lines[0].lineTotalPaisa, 12600);
        expect(billing.totals.subtotalPaisa, 12600);
        expect(billing.totals.grandTotal, 12600);

        final repo = InvoiceRepository(open: () async => db);
        final service = InvoiceService(openDb: () async => db, invoices: repo);
        final saved = await billing.finalize(invoiceService: service);

        expect(saved.items.length, 1);
        expect(saved.items[0].quantityMilli, 1260);
        expect(saved.items[0].lineTotalPaisa, 12600);
        expect(saved.totals.subtotalPaisa, 12600);
        expect(saved.totals.grandTotal, 12600);
      } finally {
        await AppDatabase.close();
      }
    });

    test('syncProduct and removeProductById update active cart lines immediately', () {
      final app = AppState();
      final billing = BillingController(app: app);
      const unit = Unit(
        id: 1,
        nameEn: 'pc',
        nameNe: 'थान',
        abbrevEn: 'pc',
        abbrevNe: 'थान',
        isCustom: false,
      );
      const prod = Product(
        id: 10,
        nameEn: 'Milk',
        nameNe: 'दूध',
        sku: 'MLK',
        descriptionEn: '',
        descriptionNe: '',
        ratePaisa: 7000,
        unitId: 1,
        category: '',
        isActive: true,
        createdAt: 0,
        updatedAt: 0,
      );
      billing.addProduct(prod, unit: unit, quantityMilli: 2000);
      expect(billing.totals.grandTotal, 14000);

      final updated = prod.copyWith(nameEn: 'Fresh Milk', ratePaisa: 8500);
      billing.syncProduct(updated, unit);
      expect(billing.lines.single.nameEn, 'Fresh Milk');
      expect(billing.totals.grandTotal, 17000);

      billing.removeProductById(10);
      expect(billing.isEmpty, isTrue);
    });

    test('addProduct cannot select the same product twice, and deselecting all products clears the cart', () {
      final app = AppState();
      final billing = BillingController(app: app);
      const unit = Unit(
        id: 1,
        nameEn: 'pc',
        nameNe: 'थान',
        abbrevEn: 'pc',
        abbrevNe: 'थान',
        isCustom: false,
      );
      const prod1 = Product(
        id: 10,
        nameEn: 'Milk',
        nameNe: 'दूध',
        sku: 'MLK',
        descriptionEn: '',
        descriptionNe: '',
        ratePaisa: 7000,
        unitId: 1,
        category: '',
        isActive: true,
        createdAt: 0,
        updatedAt: 0,
      );
      const prod2 = Product(
        id: 20,
        nameEn: 'Bread',
        nameNe: 'पाउरोटी',
        sku: 'BRD',
        descriptionEn: '',
        descriptionNe: '',
        ratePaisa: 5000,
        unitId: 1,
        category: '',
        isActive: true,
        createdAt: 0,
        updatedAt: 0,
      );

      billing.addProduct(prod1, unit: unit);
      expect(billing.lineCount, 1);
      expect(billing.hasProduct(10), isTrue);
      expect(billing.isProductSelected(prod1), isTrue);

      billing.addProduct(prod1, unit: unit);
      expect(billing.lineCount, 1);

      billing.addProduct(prod2, unit: unit);
      expect(billing.lineCount, 2);
      expect(billing.hasProduct(20), isTrue);

      billing.removeProductById(10);
      expect(billing.lineCount, 1);
      expect(billing.hasProduct(10), isFalse);
      expect(billing.hasProduct(20), isTrue);

      billing.removeProductById(20);
      expect(billing.isEmpty, isTrue);
      expect(billing.lineCount, 0);
    });

    test('finalizeBill snapshots receipt profile and matches profile filter', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await createSchema(db);
      final repo = InvoiceRepository(open: () async => db);
      final service = InvoiceService(openDb: () async => db, invoices: repo);

      final p1 = ReceiptProfile(
        id: 'prof_retail',
        name: 'Retail Counter',
        organization: Organization.empty.copyWith(
          nameEn: 'Retail Shop',
          panNumber: '1111111',
        ),
        receipt: ReceiptSettings.defaults,
      );
      final p2 = ReceiptProfile(
        id: 'prof_wholesale',
        name: 'Wholesale Depot',
        organization: Organization.empty.copyWith(
          nameEn: 'Wholesale Corp',
          panNumber: '2222222',
        ),
        receipt: ReceiptSettings.defaults,
      );

      final req = FinalizeRequest(
        lines: const [
          CartLine(
            productId: 1,
            nameEn: 'Item A',
            nameNe: 'सामान',
            skuSnapshot: '',
            unitSnapshotEn: 'pc',
            unitSnapshotNe: 'थान',
            quantityMilli: 1000,
            ratePaisa: 5000,
          ),
        ],
        discountType: DiscountType.none,
        discountValue: 0,
        taxRate: 0,
        otherCharges: 0,
        otherChargesNote: '',
        amountPaid: 5000,
        paymentMethod: PaymentMethod.cash,
        customer: const CustomerInfo(),
        notes: '',
      );

      final inv = await service.finalizeBill(
        req: req,
        settings: AppSettings.defaults,
        org: p1.organization,
        receipt: p1.receipt,
        receiptProfile: p1,
      );

      expect(inv.receiptProfileId, 'prof_retail');
      expect(inv.receiptProfileName, 'Retail Counter');
      expect(inv.profileDisplayTitle([p1, p2], 'Default'), 'Retail Counter');
      expect(inv.matchesReceiptProfile(p1, [p1, p2]), isTrue);
      expect(inv.matchesReceiptProfile(p2, [p1, p2]), isFalse);

      await db.close();
    });

    test('InvoiceRepository.list filters by fromMillis and toMillis', () async {
      final db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await createSchema(db);
      final repo = InvoiceRepository(open: () async => db);
      final service = InvoiceService(openDb: () async => db, invoices: repo);

      final p = ReceiptProfile(
        id: 'prof_test',
        name: 'Test Profile',
        organization: Organization.empty,
        receipt: ReceiptSettings.defaults,
      );
      final req = FinalizeRequest(
        lines: const [
          CartLine(
            productId: 1,
            nameEn: 'Item',
            nameNe: 'वस्तु',
            skuSnapshot: '',
            unitSnapshotEn: 'pc',
            unitSnapshotNe: 'थान',
            quantityMilli: 1000,
            ratePaisa: 1000,
          ),
        ],
        discountType: DiscountType.none,
        discountValue: 0,
        taxRate: 0,
        otherCharges: 0,
        otherChargesNote: '',
        amountPaid: 1000,
        paymentMethod: PaymentMethod.cash,
        customer: const CustomerInfo(),
        notes: '',
      );

      final inv = await service.finalizeBill(
        req: req,
        settings: AppSettings.defaults,
        org: p.organization,
        receipt: p.receipt,
        receiptProfile: p,
      );

      final createdAt = inv.createdAt;
      // In range
      final inRange = await repo.list(InvoiceFilter(
        fromMillis: createdAt - 1000,
        toMillis: createdAt + 1000,
      ));
      expect(inRange.length, 1);

      // Out of range (future)
      final futureRange = await repo.list(InvoiceFilter(
        fromMillis: createdAt + 5000,
        toMillis: createdAt + 10000,
      ));
      expect(futureRange, isEmpty);

      // Out of range (past)
      final pastRange = await repo.list(InvoiceFilter(
        fromMillis: createdAt - 10000,
        toMillis: createdAt - 5000,
      ));
      expect(pastRange, isEmpty);

      await db.close();
    });

    test('invoice transaction status supports processing, success, and canceled', () async {
      expect(InvoiceStatus.finalized, InvoiceStatus.success);
      expect(InvoiceStatus.voided, InvoiceStatus.canceled);
      expect(invoiceStatusFromCode('processing'), InvoiceStatus.processing);
      expect(invoiceStatusFromCode('success'), InvoiceStatus.success);
      expect(invoiceStatusFromCode('canceled'), InvoiceStatus.canceled);
      expect(invoiceStatusFromCode('finalized'), InvoiceStatus.success);
      expect(invoiceStatusFromCode('voided'), InvoiceStatus.canceled);

      final db = await AppDatabase.openAt(inMemoryDatabasePath);
      final repo = InvoiceRepository(open: () async => db);
      final service = InvoiceService(openDb: () async => db, invoices: repo);

      final p = ReceiptProfile(
        id: 'prof_test',
        name: 'Main',
        organization: Organization.empty.copyWith(nameEn: 'Test Org'),
        receipt: ReceiptSettings.defaults,
      );
      final req = FinalizeRequest(
        lines: const [
          CartLine(
            productId: 1,
            nameEn: 'Chiya',
            nameNe: 'चिया',
            skuSnapshot: 'C1',
            unitSnapshotEn: 'cup',
            unitSnapshotNe: 'कप',
            quantityMilli: 1000,
            ratePaisa: 2500,
          ),
        ],
        discountType: DiscountType.none,
        discountValue: 0,
        taxRate: 0,
        otherCharges: 0,
        otherChargesNote: '',
        amountPaid: 0,
        paymentMethod: PaymentMethod.cash,
        customer: const CustomerInfo(),
        notes: '',
      );

      // Create invoice with status processing
      final processingInv = await service.finalizeBill(
        req: req,
        settings: AppSettings.defaults,
        org: p.organization,
        receipt: p.receipt,
        receiptProfile: p,
        status: InvoiceStatus.processing,
      );
      expect(processingInv.status, InvoiceStatus.processing);

      // Update status to success (paid)
      await repo.updateInvoiceStatus(processingInv.id, InvoiceStatus.success);
      final updatedInv = await repo.byId(processingInv.id);
      expect(updatedInv?.status, InvoiceStatus.success);

      // Mark canceled
      await repo.updateInvoiceStatus(processingInv.id, InvoiceStatus.canceled);
      final canceledInv = await repo.byId(processingInv.id);
      expect(canceledInv?.status, InvoiceStatus.canceled);

      // Verify list filtering: excluded when includeVoided is false
      final listNoVoided = await repo.list(InvoiceFilter());
      expect(listNoVoided.any((i) => i.id == processingInv.id), isFalse);

      final listWithVoided = await repo.list(InvoiceFilter(includeVoided: true));
      expect(listWithVoided.any((i) => i.id == processingInv.id), isTrue);

      await db.close();
    });
  });
}
