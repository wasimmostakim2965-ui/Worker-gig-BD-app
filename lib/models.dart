// Data models mirroring src/types/index.ts of the website.

class Profile {
  final String id;
  final String username;
  final String fullName;
  final String avatarUrl;
  final String phone;
  final double earningBalance;
  final double depositBalance;
  final String status; // active | suspended | blocked | admin
  final bool isVerified;
  final bool isPremium;
  final String? premiumExpiresAt;
  final String? referralCode;
  final double totalEarned;
  final double totalDeposit;
  final double totalWithdraw;
  final int tasksCompleted;
  final int jobsPosted;

  const Profile({
    required this.id,
    this.username = '',
    this.fullName = '',
    this.avatarUrl = '',
    this.phone = '',
    this.earningBalance = 0,
    this.depositBalance = 0,
    this.status = 'active',
    this.isVerified = false,
    this.isPremium = false,
    this.premiumExpiresAt,
    this.referralCode,
    this.totalEarned = 0,
    this.totalDeposit = 0,
    this.totalWithdraw = 0,
    this.tasksCompleted = 0,
    this.jobsPosted = 0,
  });

  bool get isAdmin => status == 'admin';
  bool get isActive => status == 'active';

  bool get premiumActive =>
      isPremium &&
      (premiumExpiresAt == null ||
          DateTime.tryParse(premiumExpiresAt!)?.isAfter(DateTime.now()) ==
              true);

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    id: _str(j['id']),
    username: _str(j['username']),
    fullName: _str(j['full_name']),
    avatarUrl: _str(j['avatar_url']),
    phone: _str(j['phone']),
    earningBalance: _num(j['earning_balance']),
    depositBalance: _num(j['deposit_balance']),
    status: (j['status'] ?? 'active') as String,
    isVerified: _toBool(j['is_verified']),
    isPremium: _toBool(j['is_premium']),
    premiumExpiresAt: _strOrNull(j['premium_expires_at']),
    referralCode: _strOrNull(j['referral_code']),
    totalEarned: _num(j['total_earned']),
    totalDeposit: _num(j['total_deposit']),
    totalWithdraw: _num(j['total_withdraw']),
    tasksCompleted: _toInt(j['tasks_completed']),
    jobsPosted: _toInt(j['jobs_posted']),
  );
}

class Category {
  final String id;
  final String name;
  final List<String> subcategories;
  final int displayOrder;

  const Category({
    required this.id,
    required this.name,
    this.subcategories = const [],
    this.displayOrder = 0,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: _str(j['id']),
    name: _str(j['name']),
    subcategories: ((j['subcategories'] as List?) ?? [])
        .map((e) => e.toString())
        .toList(),
    displayOrder: _toInt(j['display_order']),
  );
}

class Job {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String subcategory;
  final String url;
  final String proofInstructions;
  final int screenshotCount;
  final String screenshotInstructions;
  final String imageUrl;
  final double rewardPerWorker;
  final int totalSlots;
  final int filledSlots;
  final String status;
  final bool isPremiumOnly;
  final String createdAt;

  const Job({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.category = '',
    this.subcategory = '',
    this.url = '',
    this.proofInstructions = '',
    this.screenshotCount = 0,
    this.screenshotInstructions = '',
    this.imageUrl = '',
    this.rewardPerWorker = 0,
    this.totalSlots = 0,
    this.filledSlots = 0,
    this.status = 'active',
    this.isPremiumOnly = false,
    this.createdAt = '',
  });

  bool get isFull => filledSlots >= totalSlots;

  factory Job.fromJson(Map<String, dynamic> j) => Job(
    id: _str(j['id']),
    userId: _str(j['user_id']),
    title: _str(j['title']),
    description: _str(j['description']),
    category: _str(j['category']),
    subcategory: _str(j['subcategory']),
    url: _str(j['url']),
    proofInstructions: _str(j['proof_instructions']),
    screenshotCount: _toInt(j['screenshot_count']),
    screenshotInstructions: _str(j['screenshot_instructions']),
    imageUrl: _str(j['image_url']),
    rewardPerWorker: _num(j['reward_per_worker']),
    totalSlots: _toInt(j['total_slots']),
    filledSlots: _toInt(j['filled_slots']),
    status: (j['status'] ?? 'active') as String,
    isPremiumOnly: _toBool(j['is_premium_only']),
    createdAt: _str(j['created_at']),
  );
}

class TaskItem {
  final String id;
  final String jobId;
  final String workerId;
  final String status; // pending | submitted | approved | rejected
  final String proofUrl; // JSON array of screenshot URLs, or single URL
  final String proofText;
  final String? submittedAt;
  final double tipAmount;
  final String? adminNote;
  final Job? job;

  const TaskItem({
    required this.id,
    required this.jobId,
    required this.workerId,
    this.status = 'pending',
    this.proofUrl = '',
    this.proofText = '',
    this.submittedAt,
    this.tipAmount = 0,
    this.adminNote,
    this.job,
  });

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
    id: _str(j['id']),
    jobId: _str(j['job_id']),
    workerId: _str(j['worker_id']),
    status: (j['status'] ?? 'pending') as String,
    proofUrl: _str(j['proof_url']),
    proofText: _str(j['proof_text']),
    submittedAt: _strOrNull(j['submitted_at']),
    tipAmount: _num(j['tip_amount']),
    adminNote: _strOrNull(j['admin_note']),
    job: j['jobs'] is Map<String, dynamic>
        ? Job.fromJson(j['jobs'] as Map<String, dynamic>)
        : null,
  );
}

class DepositRequest {
  final String id;
  final String userId;
  final double amount;
  final String method;
  final String senderNumber;
  final String transactionId;
  final String status;
  final String adminNote;
  final String createdAt;
  final Profile? user;

  const DepositRequest({
    required this.id,
    required this.userId,
    this.amount = 0,
    this.method = '',
    this.senderNumber = '',
    this.transactionId = '',
    this.status = 'pending',
    this.adminNote = '',
    this.createdAt = '',
    this.user,
  });

  factory DepositRequest.fromJson(Map<String, dynamic> j) => DepositRequest(
    id: _str(j['id']),
    userId: _str(j['user_id']),
    amount: _num(j['amount']),
    method: _str(j['method']),
    senderNumber: _str(j['sender_number']),
    transactionId: _str(j['transaction_id']),
    status: (j['status'] ?? 'pending') as String,
    adminNote: _str(j['admin_note']),
    createdAt: _str(j['created_at']),
    user: j['profiles'] is Map<String, dynamic>
        ? Profile.fromJson(j['profiles'] as Map<String, dynamic>)
        : null,
  );
}

class WithdrawalRequest {
  final String id;
  final String userId;
  final double amount;
  final String method;
  final String accountNumber;
  final String status;
  final String adminNote;
  final String createdAt;
  final Profile? user;

  const WithdrawalRequest({
    required this.id,
    required this.userId,
    this.amount = 0,
    this.method = '',
    this.accountNumber = '',
    this.status = 'pending',
    this.adminNote = '',
    this.createdAt = '',
    this.user,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> j) =>
      WithdrawalRequest(
        id: _str(j['id']),
        userId: _str(j['user_id']),
        amount: _num(j['amount']),
        method: _str(j['method']),
        accountNumber: _str(j['account_number']),
        status: (j['status'] ?? 'pending') as String,
        adminNote: _str(j['admin_note']),
        createdAt: _str(j['created_at']),
        user: j['profiles'] is Map<String, dynamic>
            ? Profile.fromJson(j['profiles'] as Map<String, dynamic>)
            : null,
      );
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // info | success | warning | error
  final bool isRead;
  final String createdAt;

  const AppNotification({
    required this.id,
    this.title = '',
    this.message = '',
    this.type = 'info',
    this.isRead = false,
    this.createdAt = '',
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: _str(j['id']),
    title: _str(j['title']),
    message: _str(j['message']),
    type: (j['type'] ?? 'info') as String,
    isRead: _toBool(j['is_read']),
    createdAt: _str(j['created_at']),
  );
}

double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String _str(dynamic v) => v?.toString() ?? '';

String? _strOrNull(dynamic v) => v == null ? null : v.toString();

int _toInt(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

bool _toBool(dynamic v) => v is bool ? v : (v == 't' || v == 'true');
