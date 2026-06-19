import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_api.dart';
import '../../../shared/models/user_model.dart';

final profileApiProvider = Provider((_) => ProfileApi());

final userProvider = FutureProvider<UserModel>((ref) {
  return ref.watch(profileApiProvider).getCurrentUser();
});
