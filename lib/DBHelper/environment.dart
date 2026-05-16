class Environment {
  // local urls
  final apiUrl = 'http://192.168.0.100:8000/api/app/';
  final categoryImageUrl = 'http://192.168.0.100:8000/media/category_images/';

  final login = 'login/';

  // Categories
  final String fetchCategory = 'fetch-all-category/';
  final String createCategory = 'create-category/';
  final String updateCategory = 'update-category/';
  final String deleteCategory = 'delete-category/';

  // Products
  final String fetchProducts = 'fetch-all-products/list/';
  final String createProduct = 'create-products/';
  final String updateProduct = 'update-products/';
  final String deleteProduct = 'delete-products/';

  // Invoice
  String createInvoice = 'create-invoice/';
  String getInvoices = 'invoice/';
  String getInvoiceById = 'invoice/';
  String updateInvoice = 'update-invoice/';
  String cancelInvoice = 'cancel-invoice/';
  String dashboardStats = 'dashboard-stats/';
  String resolveOverpayment = 'invoice/';
  String getCustomerByMobile = 'customer/';

  // Payments
  String addInvoicePayment = 'payment-add-invoice/';
  String fetchInvoicePayments = 'fetch-payment-invoice/';

  // Employees  ← fixed
  final String fetchEmployees = 'get/employees/';
  final String addEmployee = 'add/employee/';
  final String updateEmployee = 'update/employee/';
  final String deleteEmployee = 'delete/employee/';

  // Profile
  final String getProfile = 'get/profile/';
  final String changePassword = 'change-password/';

  // ── Expense Category ──
  String fetchExpenseCategory = 'expense-category/list/';
  String createExpenseCategory = 'expense-category/create/';
  String updateExpenseCategory = 'expense-category/update/';
  String deleteExpenseCategory = 'expense-category/delete/';

  // ── Expense ──
  String fetchExpenses = 'expenses/get/';
  String createExpense = 'expenses/create/';
  String updateExpense = 'expenses/update/';
  String deleteExpense = 'expenses/delete/';

  // Purchase
  String createPurchase = 'create-purchase/';
  String getPurchase = 'purchase/';
  String getPurchaseById = 'purchase/';
  String updatePurchase = 'update-purchase/';
  String cancelPurchase = 'cancel-purchase/';
  String dashboardStatsPurchase = 'purchase-dashboard-stats/';

  // Payments
  String addPurchasePayment = 'payment-add-purchase/';
  String fetchPurchasePayments = 'fetch-payment-purchase/';

  String createShop = 'create-shop/';
  String shopCategories = 'shop/categories/';

  // reports
  String reportsSummary = 'reports/summary/';
  String fetchReportsSales = 'reports/sales/';
  String fetchReportsExpenses = 'reports/expenses/';
}
