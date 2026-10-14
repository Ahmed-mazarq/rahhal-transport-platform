import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/screens/passenger_layout_screen.dart';
import '../../features/driver/presentation/screens/driver_layout_screen.dart';
import '../../features/company/presentation/screens/company_layout_screen.dart';
import '../../features/company/presentation/screens/company_stats_screen.dart';
import '../../features/company/presentation/screens/company_documents_screen.dart';
import '../../features/company/presentation/screens/company_trip_creation_screen.dart';
import '../../features/company/presentation/screens/company_add_vehicle_screen.dart';
import '../../features/company/presentation/screens/company_add_driver_screen.dart';
import '../../features/company/presentation/screens/company_driver_assignment_screen.dart';
import '../../features/company/presentation/screens/company_booking_details_screen.dart';
import '../../features/company/presentation/screens/company_passenger_list_screen.dart';
import '../../features/company/presentation/screens/company_profile_screen.dart';
import '../../features/company/presentation/screens/company_roles_screen.dart';
import '../../features/company/presentation/screens/company_payment_methods_screen.dart';
import '../../features/company/presentation/screens/company_analytics_screen.dart';
import '../../features/company/presentation/screens/company_reports_screen.dart';
import '../../features/company/presentation/screens/company_performance_screen.dart';
import '../../features/company/presentation/screens/company_activity_log_screen.dart';

import '../../features/company/presentation/screens/company_notifications_screen.dart';
import '../../features/admin/presentation/screens/admin_layout_screen.dart';
import '../../features/admin/presentation/screens/admin_login_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_activity_timeline_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_user_details_screen.dart';
import '../../features/admin/presentation/screens/admin_creation_screen.dart';
import '../../features/admin/presentation/screens/admin_drivers_screen.dart';
import '../../features/admin/presentation/screens/admin_passengers_screen.dart';
import '../../features/admin/presentation/screens/admin_companies_screen.dart';
import '../../features/admin/presentation/screens/admin_trips_screen.dart';
import '../../features/admin/presentation/screens/admin_bookings_screen.dart';
import '../../features/admin/presentation/screens/admin_analytics_screen.dart';
import '../../features/admin/presentation/screens/admin_operations_screen.dart';
import '../../features/admin/presentation/screens/admin_documents_screen.dart';
import '../../features/admin/presentation/screens/admin_fleet_screen.dart';
import '../../features/admin/presentation/screens/admin_notification_manager_screen.dart';
import '../../features/support/presentation/screens/admin/admin_support_layout.dart';
import '../../features/support/presentation/screens/admin/admin_open_chat_screen.dart';
import '../../features/support/domain/models/support_conversation.dart';
import '../../features/admin/presentation/screens/document_viewer_screen.dart';
import '../../features/admin/presentation/screens/admin_booking_details_screen.dart';
import '../../features/common/models/verification_document.dart';

import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/presentation/screens/admin_notifications_screen.dart';
import '../../features/admin/presentation/screens/admin_live_trip_monitor_screen.dart';
import '../../features/admin/presentation/screens/admin_trip_details_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_approvals_screen.dart';
import '../../features/admin/presentation/screens/approval_details_screen.dart';
import '../../features/admin/presentation/screens/admin_roles_screen.dart';
import '../../features/admin/presentation/screens/admin_audit_screen.dart';
import '../../features/admin/presentation/screens/admin_live_operations_screen.dart';
import '../../features/admin/presentation/screens/admin_security_center_screen.dart';
import '../../features/admin/presentation/screens/admin_cms_screen.dart';
import '../../features/admin/presentation/screens/admin_feature_flags_screen.dart';
import '../../features/admin/presentation/screens/admin_geo_management_screen.dart';
import '../../features/admin/presentation/screens/admin_system_health_screen.dart';
import '../../features/admin/presentation/screens/admin_export_backup_screen.dart';
import '../../features/trips/presentation/screens/trips_screen.dart';
import '../../features/trips/presentation/screens/booking_payment_screen.dart';
import '../../features/trips/presentation/screens/booking_proof_screen.dart';
import '../../features/trips/presentation/screens/search_screen.dart';
import '../../features/trips/presentation/screens/trip_details_screen.dart';
import '../../features/trips/presentation/screens/booking_details_screen.dart';
import '../../features/trips/presentation/screens/live_tracking_screen.dart';
import '../../features/trips/presentation/screens/post_trip_rating_screen.dart';
import '../../features/trips/presentation/screens/booking_summary_screen.dart';
import '../../features/trips/presentation/screens/booking_success_screen.dart';
import '../../features/trips/presentation/screens/booking_chat_screen.dart';
import '../../features/passenger/presentation/screens/favorites_screen.dart';
import '../../features/parcel/presentation/screens/passenger_parcel_hub_screen.dart';
import '../../features/parcel/presentation/screens/parcel_details_screen.dart';
import '../../features/marketing/presentation/screens/passenger_offers_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/support/presentation/screens/passenger_support_screen.dart';
import '../../features/support/presentation/screens/faq_screen.dart';
import '../../features/support/presentation/screens/contact_info_screen.dart';

import '../../features/support/presentation/screens/support_chat_screen.dart';
import '../../features/support/presentation/screens/support_tickets_screen.dart';
import '../../features/support/presentation/screens/support_create_ticket_screen.dart';
import '../../features/support/presentation/screens/support_report_screen.dart';
import '../../features/support/presentation/screens/support_reports_screen.dart';
import '../../features/bookings/presentation/screens/passenger_tracking_screen.dart';

// Driver Support
import '../../features/driver_support/presentation/screens/driver_support_screen.dart';
import '../../features/driver_support/presentation/screens/driver_chat_screen.dart';
import '../../features/driver_support/presentation/screens/driver_tickets_screen.dart';
import '../../features/driver_support/presentation/screens/driver_create_ticket_screen.dart';
import '../../features/driver_support/presentation/screens/driver_report_screen.dart';
import '../../features/driver_support/presentation/screens/driver_faq_screen.dart';

import '../../features/support/presentation/screens/company_support_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/passenger/presentation/screens/passenger_profile_screen.dart';
import '../../features/passenger/presentation/screens/profile_management_screen.dart';
import '../../features/passenger/presentation/screens/emergency_contacts_screen.dart';
import '../../features/passenger/presentation/screens/trip_history_screen.dart';
import '../../features/trips/presentation/screens/my_bookings_screen.dart';
import '../../features/trips/domain/models/stop.dart';
import '../../features/trips/domain/models/seat.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/driver/presentation/screens/driver_vehicles_screen.dart';
import '../../features/driver/presentation/screens/driver_documents_screen.dart';
import '../../features/driver/presentation/screens/driver_stats_screen.dart';
import '../../features/driver/presentation/screens/driver_profile_screen.dart';
import '../../features/driver/presentation/screens/working_areas_screen.dart';
import '../../features/driver/presentation/screens/payment_methods_screen.dart';
import '../../features/driver/presentation/screens/create_trip_screen.dart';
import '../../features/driver/presentation/screens/manage_trip_stops_screen.dart';
import '../../features/driver/presentation/screens/driver_trips_screen.dart';
import '../../features/driver/presentation/screens/driver_bookings_screen.dart';
import '../../features/driver/presentation/screens/manage_trip_seats_screen.dart';
import '../../features/driver/presentation/screens/driver_live_trip_screen.dart';
import '../../features/driver/presentation/screens/driver_trip_details_screen.dart';
import '../../features/driver/presentation/screens/driver_booking_details_screen.dart';
import '../../features/driver/presentation/screens/profile_management_screen.dart'
    as driver;
import '../../features/driver/presentation/screens/add_vehicle_screen.dart';
import '../../features/driver/presentation/screens/vehicle_details_screen.dart';
import '../../features/driver/presentation/screens/driver_parcel_marketplace_screen.dart';
import '../../features/driver/presentation/screens/activity_log_screen.dart';

// Driver Support Import Removed
import '../../features/trips/domain/models/trip.dart';
import '../../features/trips/domain/models/booking.dart';
import '../../features/fleet/domain/models/vehicle.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/role_selector_screen.dart';
import '../../features/auth/presentation/screens/passenger_signup_screen.dart';
import '../../features/auth/presentation/screens/driver_signup_screen.dart';
import '../../features/auth/presentation/screens/company_signup_screen.dart';
import '../../features/auth/presentation/screens/pending_approval_screen.dart';
import '../../features/auth/presentation/screens/rejected_screen.dart';
import '../../features/auth/presentation/screens/suspended_screen.dart';
import '../../features/auth/presentation/screens/need_modification_screen.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../core/providers/system_config_provider.dart';
import '../../features/common/presentation/screens/maintenance_screen.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, _) => notifyListeners());
    _ref.listen(appSettingsProvider, (_, _) => notifyListeners());
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: notifier,
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/role-selector',
        builder: (context, state) => const RoleSelectorScreen(),
      ),
      GoRoute(
        path: '/signup-passenger',
        builder: (context, state) => const PassengerSignUpScreen(),
      ),
      GoRoute(
        path: '/signup-driver',
        builder: (context, state) => const DriverSignUpScreen(),
      ),
      GoRoute(
        path: '/signup-company',
        builder: (context, state) => const CompanySignUpScreen(),
      ),
      GoRoute(
        path: '/pending-approval',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/rejected-account',
        builder: (context, state) {
          final currentAuth = ref.read(authProvider);
          final user = (currentAuth is Authenticated) ? currentAuth.user : null;
          return RejectedScreen(rejectedReason: user?.rejectedReason);
        },
      ),
      GoRoute(
        path: '/blocked-account',
        builder: (context, state) => const SuspendedScreen(),
      ),
      GoRoute(
        path: '/need-modification',
        builder: (context, state) {
          return const NeedModificationScreen();
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const PassengerLayoutScreen(),
      ),
      GoRoute(
        path: '/driver-dashboard',
        builder: (context, state) => const DriverLayoutScreen(),
      ),
      GoRoute(
        path: '/company-dashboard',
        builder: (context, state) =>
            const CompanyLayoutScreen(), // Integrated Company stateful layout screen
      ),
      GoRoute(path: '/trips', builder: (context, state) => const TripsScreen()),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/search-results',
        builder: (context, state) => const TripsScreen(),
      ),
      GoRoute(
        path: '/trip-details/:id',
        builder: (context, state) =>
            TripDetailsScreen(tripId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking-details/:id',
        builder: (context, state) =>
            BookingDetailsScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking-summary/:id',
        builder: (context, state) {
          final rawSeats = state.extra;
          final selectedSeats = rawSeats is Iterable
              ? rawSeats.map((e) => e.toString()).toList()
              : <String>[];
          return BookingSummaryScreen(
            tripId: state.pathParameters['id']!,
            selectedSeats: selectedSeats,
          );
        },
      ),
      GoRoute(
        path: '/booking-success/:id',
        builder: (context, state) =>
            BookingSuccessScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking-payment/:id',
        builder: (context, state) =>
            BookingPaymentScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking-proof/:id',
        builder: (context, state) => BookingProofScreen(
          bookingId: state.pathParameters['id']!,
          paymentMethodId: state.uri.queryParameters['paymentMethodId'],
        ),
      ),
      GoRoute(
        path: '/booking-chat',
        builder: (context, state) {
          final booking = state.extra as Booking;
          return BookingChatScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/offers',
        builder: (context, state) => const PassengerOffersScreen(),
      ),
      GoRoute(
        path: '/track-trip/:id',
        builder: (context, state) =>
            LiveTrackingScreen(tripId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/passenger-tracking',
        builder: (context, state) => const PassengerTrackingScreen(),
      ),
      GoRoute(
        path: '/parcel-booking',
        builder: (context, state) =>
            const PassengerParcelHubScreen(initialTab: 0),
      ),
      GoRoute(
        path: '/parcel-tracking',
        builder: (context, state) =>
            const PassengerParcelHubScreen(initialTab: 1),
      ),
      GoRoute(
        path: '/parcel-details/:id',
        builder: (context, state) =>
            ParcelDetailsScreen(parcelId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/rate-trip/:tripId',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          final extraMap = state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null;
          final bookingId = extraMap?['bookingId'] as String?;
          final driverId = extraMap?['driverId'] as String?;
          return PostTripRatingScreen(
            tripId: tripId,
            bookingId: bookingId,
            driverId: driverId,
          );
        },
      ),
      GoRoute(
        path: '/passenger-profile',
        builder: (context, state) => const PassengerProfileScreen(),
      ),
      GoRoute(
        path: '/passenger/profile-management',
        builder: (context, state) => const ProfileManagementScreen(),
      ),
      GoRoute(
        path: '/driver/profile-management',
        builder: (context, state) => const driver.ProfileManagementScreen(),
      ),
      GoRoute(
        path: '/profile-management',
        redirect: (context, state) {
          final authState = ref.read(authProvider);
          if (authState is Authenticated && authState.user.role == 'driver') {
            return '/driver/profile-management';
          }
          return '/passenger/profile-management';
        },
      ),
      GoRoute(
        path: '/emergency-contacts',
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: '/trip-history',
        builder: (context, state) => const TripHistoryScreen(),
      ),
      GoRoute(
        path: '/my-bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/search-results-old', // Deprecated
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/create-trip',
        builder: (context, state) {
          final trip = state.extra as Trip?;
          return CreateTripScreen(initialTrip: trip);
        },
      ),
      GoRoute(
        path: '/manage-trip-stops',
        builder: (context, state) {
          final stops = state.extra is List<Stop>
              ? state.extra as List<Stop>
              : null;
          return ManageTripStopsScreen(initialStops: stops);
        },
      ),
      GoRoute(
        path: '/manage-trip-seats',
        builder: (context, state) {
          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            return ManageTripSeatsScreen(
              initialSeats: map['seats'] as List<Seat>?,
              vehicleSeatsCount: map['seatsCount'] as int?,
            );
          } else if (state.extra is List<Seat>) {
            return ManageTripSeatsScreen(
              initialSeats: state.extra as List<Seat>?,
            );
          }
          return const ManageTripSeatsScreen();
        },
      ),
      GoRoute(
        path: '/driver-trips',
        builder: (context, state) => const DriverTripsScreen(),
      ),
      GoRoute(
        path: '/driver-bookings',
        builder: (context, state) => const DriverBookingsScreen(),
      ),
      GoRoute(
        path: '/driver-live-trip',
        builder: (context, state) {
          final trip = state.extra as Trip;
          return DriverLiveTripScreen(trip: trip);
        },
      ),
      GoRoute(
        path: '/driver-trip-details/:id',
        builder: (context, state) {
          final trip = state.extra as Trip;
          return DriverTripDetailsScreen(trip: trip);
        },
      ),
      GoRoute(
        path: '/driver-booking-details/:id',
        builder: (context, state) {
          final bookingId = state.pathParameters['id'];
          if (bookingId == null || bookingId.isEmpty) {
            return const Scaffold(
              body: Center(
                child: Text(
                  'معرف الحجز مفقود',
                  style: TextStyle(fontFamily: 'Cairo'),
                ),
              ),
            );
          }
          return DriverBookingDetailsScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '/driver-vehicles',
        builder: (context, state) => const DriverVehiclesScreen(),
      ),
      GoRoute(
        path: '/driver-documents',
        builder: (context, state) => const DriverDocumentsScreen(),
      ),
      GoRoute(
        path: '/add-vehicle',
        builder: (context, state) {
          final vehicle = state.extra as Vehicle?;
          return AddVehicleScreen(initialVehicle: vehicle);
        },
      ),
      GoRoute(
        path: '/vehicle-details/:id',
        builder: (context, state) {
          final vehicle = state.extra as Vehicle;
          return VehicleDetailsScreen(vehicle: vehicle);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      GoRoute(
        path: '/driver-stats',
        builder: (context, state) => const DriverStatsScreen(),
      ),
      GoRoute(
        path: '/driver-activity',
        builder: (context, state) => const ActivityLogScreen(),
      ),
      GoRoute(
        path: '/driver-profile',
        builder: (context, state) => const DriverProfileScreen(),
      ),
      GoRoute(
        path: '/working-areas',
        builder: (context, state) => const WorkingAreasScreen(),
      ),
      GoRoute(
        path: '/driver-parcels',
        builder: (context, state) => const DriverParcelMarketplaceScreen(),
      ),
      GoRoute(
        path: '/payment-methods',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),

      // --- New Driver Support ---
      GoRoute(
        path: '/driver-support',
        builder: (context, state) => const DriverSupportScreen(),
        routes: [
          GoRoute(
            path: 'contact',
            builder: (context, state) =>
                const ContactInfoScreen(userType: 'driver'),
          ),
          GoRoute(
            path: 'chat',
            builder: (context, state) => DriverChatScreen(
              conversationId: state.uri.queryParameters['conversationId'],
              ticketId: state.uri.queryParameters['ticketId'],
            ),
          ),
          GoRoute(
            path: 'tickets',
            builder: (context, state) => const DriverTicketsScreen(),
          ),
          GoRoute(
            path: 'create-ticket',
            builder: (context, state) => const DriverCreateTicketScreen(),
          ),
          GoRoute(
            path: 'report',
            builder: (context, state) => const DriverReportScreen(),
          ),
          GoRoute(
            path: 'faq',
            builder: (context, state) => const DriverFaqScreen(),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) =>
                const SupportReportsScreen(userType: 'driver'),
          ),
        ],
      ),

      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),

      GoRoute(
        path: '/support',
        builder: (context, state) => const PassengerSupportScreen(),
        routes: [
          GoRoute(
            path: 'faq',
            builder: (context, state) => const FaqScreen(userType: 'passenger'),
          ),
          GoRoute(
            path: 'contact',
            builder: (context, state) =>
                const ContactInfoScreen(userType: 'passenger'),
          ),
          GoRoute(
            path: 'chat',
            builder: (context, state) => SupportChatScreen(
              userType: 'passenger',
              conversationId: state.uri.queryParameters['conversationId'],
              ticketId: state.uri.queryParameters['ticketId'],
            ),
          ),
          GoRoute(
            path: 'tickets',
            builder: (context, state) =>
                const SupportTicketsScreen(userType: 'passenger'),
          ),
          GoRoute(
            path: 'create-ticket',
            builder: (context, state) =>
                const SupportCreateTicketScreen(userType: 'passenger'),
          ),
          GoRoute(
            path: 'create-report',
            builder: (context, state) =>
                const SupportReportScreen(userType: 'passenger'),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) =>
                const SupportReportsScreen(userType: 'passenger'),
          ),
        ],
      ),
      GoRoute(
        path: '/company-support',
        builder: (context, state) => const CompanySupportScreen(),
        routes: [
          GoRoute(
            path: 'faq',
            builder: (context, state) => const FaqScreen(userType: 'company'),
          ),
          GoRoute(
            path: 'contact',
            builder: (context, state) =>
                const ContactInfoScreen(userType: 'company'),
          ),
          GoRoute(
            path: 'chat',
            builder: (context, state) => SupportChatScreen(
              userType: 'company',
              conversationId: state.uri.queryParameters['conversationId'],
              ticketId: state.uri.queryParameters['ticketId'],
            ),
          ),
          GoRoute(
            path: 'tickets',
            builder: (context, state) =>
                const SupportTicketsScreen(userType: 'company'),
          ),
          GoRoute(
            path: 'create-ticket',
            builder: (context, state) =>
                const SupportCreateTicketScreen(userType: 'company'),
          ),
          GoRoute(
            path: 'create-report',
            builder: (context, state) =>
                const SupportReportScreen(userType: 'company'),
          ),
          GoRoute(
            path: 'reports',
            builder: (context, state) =>
                const SupportReportsScreen(userType: 'company'),
          ),
        ],
      ),
      GoRoute(
        path: '/company-stats',
        builder: (context, state) => const CompanyStatsScreen(),
      ),
      GoRoute(
        path: '/admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminLayoutScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/dashboard',
                builder: (context, state) => const AdminDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'timeline',
                    builder: (context, state) =>
                        const AdminActivityTimelineScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 1: Users
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/approvals',
                builder: (context, state) => const AdminApprovalsScreen(),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    builder: (context, state) =>
                        ApprovalDetailsScreen(uid: state.pathParameters['id']!),
                  ),
                ],
              ),
              GoRoute(
                path: '/admin/users',
                builder: (context, state) => const AdminUsersScreen(),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      final user = state.extra as Map<String, dynamic>? ?? {};
                      return AdminUserDetailsScreen(userId: id, user: user);
                    },
                  ),
                  GoRoute(
                    path: 'create',
                    builder: (context, state) => const AdminCreationScreen(),
                  ),
                  GoRoute(
                    path: 'drivers',
                    builder: (context, state) => const AdminDriversScreen(),
                  ),
                  GoRoute(
                    path: 'passengers',
                    builder: (context, state) => const AdminPassengersScreen(),
                  ),
                  GoRoute(
                    path: 'companies',
                    builder: (context, state) => const AdminCompaniesScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 2: Operations
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/operations',
                builder: (context, state) => const AdminOperationsScreen(),
                routes: [
                  GoRoute(
                    path: 'trips',
                    builder: (context, state) => const AdminTripsScreen(),
                    routes: [
                      GoRoute(
                        path: 'details/:id',
                        builder: (context, state) {
                          final trip = state.extra as Trip;
                          return AdminTripDetailsScreen(trip: trip);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'live-monitor',
                    builder: (context, state) => AdminLiveTripMonitorScreen(
                      trip: state.extra as Map<String, dynamic>?,
                    ),
                  ),
                  GoRoute(
                    path: 'live-ops',
                    builder: (context, state) =>
                        const AdminLiveOperationsScreen(),
                  ),
                  GoRoute(
                    path: 'bookings',
                    builder: (context, state) => const AdminBookingsScreen(),
                    routes: [
                      GoRoute(
                        path: 'details/:id',
                        builder: (context, state) {
                          final booking = state.extra as Booking;
                          return AdminBookingDetailsScreen(booking: booking);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'documents',
                    builder: (context, state) => const AdminDocumentsScreen(),
                  ),
                  GoRoute(
                    path: 'document-viewer',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>? ?? {};
                      final documents =
                          extra['documents']
                              as List<
                                MapEntry<String, VerificationDocument>
                              >? ??
                          [];
                      final initialIndex = extra['initialIndex'] as int? ?? 0;
                      return DocumentViewerScreen(
                        documents: documents,
                        initialIndex: initialIndex,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'fleet',
                    builder: (context, state) => const AdminFleetScreen(),
                  ),

                  GoRoute(
                    path: 'support',
                    builder: (context, state) => const AdminSupportLayout(),
                    routes: [
                      GoRoute(
                        path: 'chat/:conversationId',
                        builder: (context, state) {
                          final conversation =
                              state.extra as SupportConversation?;
                          final conversationId =
                              state.pathParameters['conversationId']!;
                          if (conversation != null) {
                            return AdminOpenChatScreen(
                              conversation: conversation,
                            );
                          }
                          // In a full implementation, if extra is missing, you'd fetch the conversation.
                          // But for now, returning a fallback or making sure we always pass extra:
                          return AdminOpenChatScreen(
                            conversation: SupportConversation(
                              conversationId: conversationId,
                              participantIds: const [],
                              updatedAt: DateTime.now(),
                              createdAt: DateTime.now(),
                              userType: 'unknown',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'reports',
                    builder: (context, state) => const AdminReportsScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        const AdminNotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'notification-manager',
                    builder: (context, state) =>
                        const AdminNotificationManagerScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Analytics
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/analytics',
                builder: (context, state) => const AdminAnalyticsScreen(),
                routes: [
                  GoRoute(
                    path: 'geo',
                    builder: (context, state) =>
                        const AdminGeoManagementScreen(),
                  ),
                  GoRoute(
                    path: 'health',
                    builder: (context, state) =>
                        const AdminSystemHealthScreen(),
                  ),
                  GoRoute(
                    path: 'audit',
                    builder: (context, state) => const AdminAuditScreen(),
                  ),
                ],
              ),
            ],
          ),
          // Branch 4: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin/settings',
                builder: (context, state) => const AdminSettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'roles',
                    builder: (context, state) => const AdminRolesScreen(),
                  ),
                  GoRoute(
                    path: 'security',
                    builder: (context, state) =>
                        const AdminSecurityCenterScreen(),
                  ),
                  GoRoute(
                    path: 'cms',
                    builder: (context, state) => const AdminCMSScreen(),
                  ),
                  GoRoute(
                    path: 'feature-flags',
                    builder: (context, state) =>
                        const AdminFeatureFlagsScreen(),
                  ),
                  GoRoute(
                    path: 'export-backup',
                    builder: (context, state) =>
                        const AdminExportBackupScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/company-documents',
        builder: (context, state) => const CompanyDocumentsScreen(),
      ),
      GoRoute(
        path: '/company-trip-creation',
        builder: (context, state) => const CompanyTripCreationScreen(),
      ),
      GoRoute(
        path: '/company-add-vehicle',
        builder: (context, state) => const CompanyAddVehicleScreen(),
      ),
      GoRoute(
        path: '/company-add-driver',
        builder: (context, state) => const CompanyAddDriverScreen(),
      ),
      GoRoute(
        path: '/company-driver-assignment',
        builder: (context, state) => const CompanyDriverAssignmentScreen(),
      ),
      GoRoute(
        path: '/company-booking-details',
        builder: (context, state) => const CompanyBookingDetailsScreen(),
      ),
      GoRoute(
        path: '/company-passenger-list',
        builder: (context, state) => const CompanyPassengerListScreen(),
      ),
      GoRoute(
        path: '/company-profile',
        builder: (context, state) => const CompanyProfileScreen(),
      ),
      GoRoute(
        path: '/company-roles',
        builder: (context, state) => const CompanyRolesScreen(),
      ),
      GoRoute(
        path: '/company-payment-methods',
        builder: (context, state) => const CompanyPaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/company-analytics',
        builder: (context, state) => const CompanyAnalyticsScreen(),
      ),
      GoRoute(
        path: '/company-reports',
        builder: (context, state) => const CompanyReportsScreen(),
      ),
      GoRoute(
        path: '/company-performance',
        builder: (context, state) => const CompanyPerformanceScreen(),
      ),
      GoRoute(
        path: '/company-activity-log',
        builder: (context, state) => const CompanyActivityLogScreen(),
      ),

      GoRoute(
        path: '/company-notifications',
        builder: (context, state) => const CompanyNotificationsScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final settingsAsync = ref.read(appSettingsProvider);
      final loc = state.matchedLocation;

      // If initializing, stay on splash
      if (authState is AuthInitial) {
        return null;
      }

      final bool loggedIn = authState is Authenticated;
      final bool loggingIn =
          loc == '/login' ||
          loc == '/admin-login' ||
          loc == '/role-selector' ||
          loc == '/signup-passenger' ||
          loc == '/signup-driver' ||
          loc == '/signup-company' ||
          loc == '/pending-approval' ||
          loc == '/rejected-account' ||
          loc == '/blocked-account' ||
          loc == '/need-modification';

      // Maintenance Mode Check
      final settings = settingsAsync.value;
      if (settings != null && settings.maintenanceMode) {
        final role = (authState is Authenticated) ? authState.user.role : null;
        final isAdmin = role == 'admin' || role == 'super_admin';

        if (!settings.allowAdminBypass || !isAdmin) {
          if (loc != '/maintenance') return '/maintenance';
          return null; // Already on maintenance
        }
      } else if (loc == '/maintenance') {
        return '/'; // Exit maintenance screen if mode is off
      }

      if (!loggedIn) {
        // If not logged in and not heading to a public route, redirect to login
        if (!loggingIn && loc != '/') {
          if (loc.startsWith('/admin')) {
            return '/admin-login';
          }
          return '/login';
        }
        return null;
      }

      if (loggedIn) {
        final user = authState.user;
        final role = user.role;
        final status = user.status;

        final isApprovalStatusScreen =
            loc == '/pending-approval' ||
            loc == '/rejected-account' ||
            loc == '/blocked-account' ||
            loc == '/need-modification';

        // ADMIN ROUTE PROTECTION
        if (loc.startsWith('/admin') && loc != '/admin-login') {
          if (role != 'admin' && role != 'super_admin') {
            // Redirect to appropriate existing destination based on role
            if (role == 'passenger') return '/dashboard';
            if (role == 'driver') return '/driver-dashboard';
            if (role == 'company') return '/company-dashboard';
            return '/';
          }
        }

        if (role == 'driver' || role == 'company') {
          if (status == 'pending_review' && loc != '/pending-approval') {
            return '/pending-approval';
          }
          if (status == 'rejected' && loc != '/rejected-account') {
            return '/rejected-account';
          }
          if (status == 'blocked' && loc != '/blocked-account') {
            return '/blocked-account';
          }
          if (status == 'need_modification' && loc != '/need-modification') {
            return '/need-modification';
          }
          if (status == 'registering') {
            if (role == 'driver' && loc == '/signup-driver') return null;
            if (role == 'company' && loc == '/signup-company') return null;
            return role == 'driver' ? '/signup-driver' : '/signup-company';
          }
          if (status == 'approved' && isApprovalStatusScreen) {
            // Already approved, don't stay on status screens
            return role == 'driver'
                ? '/driver-dashboard'
                : '/company-dashboard';
          }
        }
      }

      // If logged in and heading to login/signup or splash, redirect to appropriate dashboard
      if (loggingIn || loc == '/') {
        final user = authState.user;
        final role = user.role;
        final status = user.status;

        // If not approved and trying to go to root/login, redirect will be handled above
        if (role == 'driver' || role == 'company') {
          if (status != 'approved') {
            return null; // Let the above checks catch it on next frame if needed, though they ran already
          }
        }

        if (role == 'passenger') {
          return '/dashboard';
        } else if (role == 'driver') {
          return '/driver-dashboard';
        } else if (role == 'company') {
          return '/company-dashboard';
        } else if (role == 'admin' || role == 'super_admin') {
          return '/admin/dashboard';
        }
      }

      return null;
    },
  );
});
