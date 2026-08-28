abstract final class AppRoutes {
  static const splash = '/';
  static const roleSelection = '/role-selection';
  static const login = '/login';
  static const register = '/register';
  static const profileSetup = '/profile-setup';

  static const farmerHome = '/farmer';
  static const farmerAddProduction = '/farmer/add-production';
  static const farmerProductionDetail = '/farmer/production/:id';
  static const farmerDemand = '/farmer/demand';
  static const farmerOrderDetail = '/farmer/orders/:id';

  static const businessHome = '/business';
  static const businessMarketplace = '/business/marketplace';
  static const businessProductionDetail = '/business/production/:id';
  static const businessInterests = '/business/interests';
  static const businessDemand = '/business/demand';
  static const businessOrderDetail = '/business/orders/:id';
  static const businessPay = '/business/orders/:id/pay';
  static const businessDeliveryMethod = '/business/orders/:id/delivery';
  static const businessAddress = '/business/orders/:id/address';
  static const businessMatches = '/business/orders/:id/transport';
  static const businessConfirmTransport = '/business/jobs/:id/confirm';
  static const businessTracking = '/business/tracking/:id';
  static const businessReceive = '/business/jobs/:id/receive';
  static const businessIssue = '/business/jobs/:id/issue';
  static const notifications = '/notifications';

  static const transporterHome = '/transporter';
  static const transporterJobDetail = '/transporter/jobs/:id';

  static const governmentHome = '/government';
  static const governmentAnalytics = '/government/analytics';
  static const governmentReports = '/government/reports';
  static const governmentAlerts = '/government/alerts';
  static const governmentLogistics = '/government/logistics';
}
