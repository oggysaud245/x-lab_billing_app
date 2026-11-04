/// One place that constructs repositories/services bound to the app's
/// database, so screens stay small and tests can swap implementations.
library;

import '../core/db/app_database.dart';
import 'repositories/invoice_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/unit_repository.dart';
import 'services/invoice_service.dart';

class AppWiring {
  const AppWiring._();

  static ProductRepository get products =>
      ProductRepository(open: () => AppDatabase.open);

  static UnitRepository get units =>
      UnitRepository(open: () => AppDatabase.open);

  static InvoiceRepository get invoices =>
      InvoiceRepository(open: () => AppDatabase.open);

  static InvoiceService get invoiceService => InvoiceService(
        openDb: () => AppDatabase.open,
        invoices: invoices,
      );
}
