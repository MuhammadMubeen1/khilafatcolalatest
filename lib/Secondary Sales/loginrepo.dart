import 'package:hive/hive.dart';
import 'package:khilfatcola/model/user_model.dart';

class UserRepository {
  static late Box<UserModel> userBox;

  // Initialize Hive box
  static Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    userBox = await Hive.openBox<UserModel>('userBox');
  }

  // Get current user
  static UserModel? getCurrentUser() {
    try {
      return userBox.get('currentUser');
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Get DealershipId directly
  static String? getDealershipId() {
    final user = getCurrentUser();
    return user?.DealershipId;
  }

  // Get user role
  static String? getUserRole() {
    final user = getCurrentUser();
    return user?.role;
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return getCurrentUser() != null;
  }

  // Logout user
  static Future<void> logout() async {
    await userBox.delete('currentUser');
  }
}
