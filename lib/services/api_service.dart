import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  late final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiV3,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Accept': 'application/json'},
    validateStatus: (status) => true,
  ));

  late final Dio _mainDio = Dio(BaseOptions(
    baseUrl: AppConfig.mainUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json'},
    validateStatus: (status) => true,
  ));

  Future<Options> _authOptions() async {
    final token = await AuthService.instance.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  void _check(Response r) {
    if (r.statusCode != null && r.statusCode! >= 400 && r.data is! Map) {
      throw ApiException('เกิดข้อผิดพลาด (${r.statusCode})');
    }
    final status = r.data?['status'];
    if (status != 200 && status != null) {
      throw ApiException(r.data?['message'] ?? 'เกิดข้อผิดพลาด');
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<void> forgotPassword(String email) async {
    final r = await _dio.post('/forgot-password',
        data: FormData.fromMap({'email': email}));
    _check(r);
  }

  Future<String> verifyOtp(String email, String otp) async {
    final r = await _dio.post('/verify-otp',
        data: FormData.fromMap({'email': email, 'otp': otp}));
    _check(r);
    return r.data['data']['reset_token'] as String;
  }

  Future<void> resetPassword(String email, String resetToken, String newPassword) async {
    final r = await _dio.post('/reset-password',
        data: FormData.fromMap({
          'email': email,
          'reset_token': resetToken,
          'new_password': newPassword,
        }));
    _check(r);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await _dio.post('/login', data: FormData.fromMap({
      'email': email,
      'password': password,
    }));
    _check(r);
    return r.data['data'] as Map<String, dynamic>;
  }

  /// ดึง profile ล่าสุดจาก server แล้ว update local cache
  Future<void> refreshProfile() async {
    try {
      final token = await AuthService.instance.getToken();
      if (token == null) return;
      final r = await _dio.post('/update_userprofile',
          data: FormData.fromMap({'token': token}));
      if (r.data['status'] == 200) {
        final profile = r.data['data']['profile'] as Map<String, dynamic>;
        await AuthService.instance.saveSession(token, profile);
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final r = await _dio.post('/register', data: FormData.fromMap({
      'name': name,
      'email': email,
      'password': password,
    }));
    _check(r);
    return r.data['data'] as Map<String, dynamic>;
  }

  // ── Public ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getCourseDetail(int id) async {
    final token = await AuthService.instance.getToken();
    final r = await _dio.get('/course-detail/$id',
        queryParameters: token != null ? {'token': token} : null);
    _check(r);
    return r.data['data'] as Map<String, dynamic>;
  }

  Future<List<dynamic>> getSlideShows() async {
    final r = await _dio.get('/slide-shows');
    _check(r);
    return r.data['data'] as List<dynamic>;
  }

  Future<List<dynamic>> getDepartments() async {
    final r = await _dio.get('/departments');
    _check(r);
    return r.data['data'] as List<dynamic>;
  }

  Future<List<dynamic>> getCourses({int departmentId = 0}) async {
    final r = await _dio.get(
      '/courses',
      queryParameters: departmentId > 0 ? {'department_id': departmentId} : null,
    );
    _check(r);
    return r.data['data'] as List<dynamic>;
  }

  Future<List<dynamic>> getBanks() async {
    final r = await _dio.get('/banks');
    _check(r);
    return r.data['data'] as List<dynamic>;
  }

  Future<List<dynamic>> getPackages() async {
    final r = await _dio.get('/packages');
    _check(r);
    return r.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getPackageById(int id) async {
    final r = await _dio.get('/packages/$id');
    _check(r);
    return r.data['data'] as Map<String, dynamic>;
  }

  // ── Protected ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMe() async {
    final r = await _dio.get('/me', options: await _authOptions());
    _check(r);
    return r.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? hbd,
    String? address,
    String? receiverName,
    String? receiverPhone,
    String? province,
    String? district,
    String? subdistrict,
    String? zipCode,
    String? addressDetail,
    File? avatar,
  }) async {
    final map = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      if (hbd != null) 'hbd': hbd,
      if (address != null) 'address': address,
      if (receiverName != null) 'receiver_name': receiverName,
      if (receiverPhone != null) 'receiver_phone': receiverPhone,
      if (province != null) 'province': province,
      if (district != null) 'district': district,
      if (subdistrict != null) 'subdistrict': subdistrict,
      if (zipCode != null) 'zip_code': zipCode,
      if (addressDetail != null) 'address_detail': addressDetail,
    };
    if (avatar != null) {
      map['avatar'] = await MultipartFile.fromFile(
        avatar.path,
        filename: avatar.path.split('/').last,
      );
    }
    final r = await _dio.post(
      '/me/update',
      data: FormData.fromMap(map),
      options: await _authOptions(),
    );
    _check(r);
    return r.data['data'] as Map<String, dynamic>;
  }

  Future<void> sendPhoneOtp(String phone) async {
    final r = await _dio.post(
      '/send-phone-otp',
      data: FormData.fromMap({'phone': phone}),
      options: await _authOptions(),
    );
    _check(r);
  }

  Future<Map<String, dynamic>> verifyPhoneOtp(String phone, String otp,
      {String phoneCode = ''}) async {
    final map = <String, String>{'phone': phone, 'otp': otp};
    if (phoneCode.isNotEmpty) map['phone_phoneCode'] = phoneCode;
    final r = await _dio.post(
      '/verify-phone-otp',
      data: FormData.fromMap(map),
      options: await _authOptions(),
    );
    _check(r);
    return r.data['data'] as Map<String, dynamic>;
  }

  Future<void> updateBiometricEnabled(bool enabled) async {
    await _dio.post(
      '/me/update',
      data: FormData.fromMap({'biometric_enabled': enabled ? 1 : 0}),
      options: await _authOptions(),
    );
  }

  Future<List<dynamic>> getMyCourses() async {
    final r = await _dio.get('/my-courses', options: await _authOptions());
    _check(r);
    return r.data['data'] as List<dynamic>;
  }

  Future<List<dynamic>> getPendingOrders() async {
    final r = await _dio.get('/pending-orders', options: await _authOptions());
    _check(r);
    return r.data['data'] as List<dynamic>;
  }

  // ตรวจสอบคูปอง — คืน { coupon_id, coupon_price }
  Future<Map<String, dynamic>> checkCoupon(String coupon, int courseId) async {
    final token = await AuthService.instance.getToken();
    final r = await _mainDio.post('/api/check_coupon', data: {
      'token': token,
      'coupon': coupon,
      'course_id': courseId,
    });
    if ((r.data?['status'] ?? 0) != 200) {
      throw ApiException(r.data?['message'] ?? 'คูปองไม่สามารถใช้ได้');
    }
    return {
      'coupon_id': r.data['data']['id'],
      'coupon_price': r.data['data']['coupon_price'],
    };
  }

  // ซื้อคอร์สเดี่ยว — ใช้ api/bil_course
  Future<void> submitCoursePayment({
    required int courseId,
    required int bankId,
    required int amount,
    required String date,
    required String time,
    required File slipImage,
    int? couponId,
  }) async {
    final token = await AuthService.instance.getToken();
    final map = <String, dynamic>{
      'token': token,
      'course_id': courseId,
      'bankname': bankId,
      'totalmoney': amount,
      'day': date,
      'timer': time,
      'image': await MultipartFile.fromFile(
        slipImage.path, filename: slipImage.path.split('/').last,
      ),
      if (couponId != null) 'coupon_id': couponId,
    };
    final r = await _mainDio.post('/api/bil_course', data: FormData.fromMap(map));
    debugPrint('[bil_course] status=${r.data?['status']} msg=${r.data?['message']} err=${r.data?['error']}');
    if ((r.data?['status'] ?? 0) != 200) {
      final msg = r.data?['message'] ?? 'เกิดข้อผิดพลาด';
      final err = r.data?['error'];
      throw ApiException(err != null ? '$msg\n($err)' : msg);
    }
  }

  // ซื้อแพ็กเกจสุดคุ้ม — ใช้ api/bill_submit_course_pack (สร้าง submitcourses ทันที)
  Future<void> submitPackagePayment({
    required int packId,
    required int bankId,
    required int amount,
    required String date,
    required String time,
    required File slipImage,
  }) async {
    final token = await AuthService.instance.getToken();
    final map = <String, dynamic>{
      'token': token,
      'pack_id': packId,
      'bankname': bankId,
      'totalmoney': amount,
      'day': date,
      'timer': time,
      'image': await MultipartFile.fromFile(
        slipImage.path, filename: slipImage.path.split('/').last,
      ),
    };
    final r = await _mainDio.post('/api/bill_submit_course_pack', data: FormData.fromMap(map));
    if ((r.data?['status'] ?? 0) != 200) {
      throw ApiException(r.data?['message'] ?? 'เกิดข้อผิดพลาด');
    }
  }

  // POST /api_v3/upload-media  — อัปโหลดรูปหรือเสียงไปเก็บที่ Laravel
  // คืน { url, type, filename }
  Future<Map<String, dynamic>> uploadChatMedia(File file) async {
    final r = await _dio.post(
      '/upload-media',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      }),
      options: await _authOptions(),
    );
    _check(r);
    return r.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getReviews(int courseId) async {
    final r = await _dio.get('/courses/$courseId/reviews');
    _check(r);
    return (r.data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<String> submitReview(int courseId, int rating, String text) async {
    final r = await _dio.post(
      '/courses/$courseId/reviews',
      data: FormData.fromMap({'rating': rating, 'review_text': text}),
      options: await _authOptions(),
    );
    _check(r);
    return r.data['message'] as String;
  }

  Future<String> getSignedVideoUrl(int videoId) async {
    final r = await _dio.get(
      '/video-url/$videoId',
      options: await _authOptions(),
    );
    return r.data['data']['url'] as String;
  }

  Future<List<dynamic>> getArticles() async {
    final r = await _mainDio.get('/api/get_articles_app/');
    return (r.data['data']?['blog'] as List<dynamic>?) ?? [];
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final r = await _dio.post(
      '/me/change-password',
      data: FormData.fromMap({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
      options: await _authOptions(),
    );
    _check(r);
  }

  Future<List<dynamic>> getMessages() async {
    final r = await _dio.get('/messages', options: await _authOptions());
    _check(r);
    return r.data['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> sendMessage(String text) async {
    final r = await _dio.post(
      '/messages',
      data: FormData.fromMap({'text': text}),
      options: await _authOptions(),
    );
    _check(r);
    return r.data['data'] as Map<String, dynamic>;
  }

  // GET https://learnsbuy.com/api/get_file_app/{courseId}
  // คืน { file: [...], video: [...] }
  Future<Map<String, dynamic>> getFileApp(int courseId) async {
    final r = await _mainDio.get('/api/get_file_app/$courseId');
    return (r.data['data'] as Map<String, dynamic>?) ?? {};
  }

  // POST /api/get_point_v2  → คืน point ปัจจุบัน
  Future<int> getPoint() async {
    final token = await AuthService.instance.getToken();
    if (token == null) return 0;
    final r = await _mainDio.post('/api/get_point_v2',
        data: {'token': token});
    return (r.data['data'] as num?)?.toInt() ?? 0;
  }

  // POST /api/del_point_v4  → ตัด point 1 ครั้ง คืน point ที่เหลือ
  Future<int> deductPoint() async {
    final token = await AuthService.instance.getToken();
    if (token == null) return 0;
    final r = await _mainDio.post('/api/del_point_v4',
        data: {'token': token});
    return (r.data['data'] as num?)?.toInt() ?? 0;
  }

  // ── Exam V2 ───────────────────────────────────────────────────────────────

  /// GET api_v3/exam-v2/list/{courseId} — list exercises for a course (optional auth for best score)
  Future<List<dynamic>> getExamList(int courseId) async {
    Options? opts;
    try { opts = await _authOptions(); } catch (_) {}
    final r = await _dio.get('/exam-v2/list/$courseId',
        options: opts);
    return (r.data['exercises'] as List<dynamic>?) ?? [];
  }

  /// GET api_v3/exam-v2/{id} — get exercise with questions (public)
  Future<Map<String, dynamic>> getExamDetail(int id) async {
    Options? opts;
    try { opts = await _authOptions(); } catch (_) {}
    final r = await _dio.get('/exam-v2/$id', options: opts);
    return r.data as Map<String, dynamic>;
  }

  /// POST api_v3/exam-v2/{id}/submit — submit attempt (requires auth)
  Future<Map<String, dynamic>> submitExam(
      int id, List<Map<String, int?>> answers, int timeTaken) async {
    final r = await _dio.post(
      '/exam-v2/$id/submit',
      data: {'answers': answers, 'time_taken': timeTaken},
      options: await _authOptions(),
    );
    return r.data as Map<String, dynamic>;
  }

  /// GET api_v3/exam-v2/{id}/history — get attempt history (requires auth)
  Future<Map<String, dynamic>> getExamHistory(int id) async {
    final r = await _dio.get(
      '/exam-v2/$id/history',
      options: await _authOptions(),
    );
    return r.data as Map<String, dynamic>;
  }
}
