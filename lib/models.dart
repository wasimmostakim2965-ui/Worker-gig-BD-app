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
          DateTime.tryParse(premiumExpiresAt!)
                  ?.isAfter(DateTime.now()) ==
              true);

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as String,
        username: (j['username'] ?? '') as String,
        fullName: (j['full_name'] ?? '') as String,
        avatarUrl: (j['avatar_url'] ?? '') as String,
        phone: (j['phone'] ?? '') as String,
        earningBalance: _num(j['earning_balance']),
        depositBalance: _num(j['deposit_balance']),
        status: (j['status'] ?? 'active') as String,
        isVerified: (j['is_verified'] ?? false) as bool,
        isPremium: (j['is_premium'] ?? false) as bool,
        premiumExpiresAt: j['premium_expires_at'] as String?,
        referralCode: j['referral_code'] as String?,
        totalEarned: _num(j['total_earned']),
        totalDeposit: _num(j['total_deposit']),
        totalWithdraw: _num(j['total_withdraw']),
        tasksCompleted: (j['tasks_completed'] ?? 0) as int,
        jobsPosted: (j['jobs_posted'] ?? 0) as int,
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
        id: j['id'] as String,
        name: (j['name'] ?? '') as String,
        subcategories: ((j['subcategories'] as List?) ?? [])
            .map((e) => e.toString())
            .toList(),
        displayOrder: (j['display_order'] ?? 0) as int,
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
        id: j['id'] as String,
        userId: (j['user_id'] ?? '') as String,
        title: (j['title'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        category: (j['category'] ?? '') as String,
        subcategory: (j['subcategory'] ?? '') as String,
        url: (j['url'] ?? '') as String,
        proofInstructions: (j['proof_instructions'] ?? '') as String,
        screenshotCount: (j['screenshot_count'] ?? 0) as int,
        screenshotInstructions:
            (j['screenshot_instructions'] ?? '') as String,
        imageUrl: (j['image_url'] ?? '') as String,
        rewardPerWorker: _num(j['reward_per_worker']),
        totalSlots: (j['total_slots'] ?? 0) as int,
        filledSlots: (j['filled_slots'] ?? 0) as int,
        status: (j['status'] ?? 'active') as String,
        isPremiumOnly: (j['is_premium_only'] ?? false) as bool,
        createdAt: (j['created_at'] ?? '') as String,
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
        id: j['id'] as String,
        jobId: (j['job_id'] ?? '') as String,
        workerId: (j['worker_id'] ?? '') as String,
        status: (j['status'] ?? 'pending') as String,
        proofUrl: (j['proof_url'] ?? '') as String,
        proofText: (j['proof_text'] ?? '') as String,
        submittedAt: j['submitted_at'] as String?,
        tipAmount: _num(j['tip_amount']),
        adminNote: j['admin_note'] as String?,
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
        id: j['id'] as String,
        userId: (j['user_id'] ?? '') as String,
        amount: _num(j['amount']),
        method: (j['method'] ?? '') as String,
        senderNumber: (j['sender_number'] ?? '') as String,
        transactionId: (j['transaction_id'] ?? '') as String,
        status: (j['status'] ?? 'pending') as String,
        adminNote: (j['admin_note'] ?? '') as String,
        createdAt: (j['created_at'] ?? '') as String,
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
        id: j['id'] as String,
        userId: (j['user_id'] ?? '') as String,
        amount: _num(j['amount']),
        method: (j['method'] ?? '') as String,
        accountNumber: (j['account_number'] ?? '') as String,
        status: (j['status'] ?? 'pending') as String,
        adminNote: (j['admin_note'] ?? '') as String,
        createdAt: (j['created_at'] ?? '') as String,
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
        id: j['id'] as String,
        title: (j['title'] ?? '') as String,
        message: (j['message'] ?? '') as String,
        type: (j['type'] ?? 'info') as String,
        isRead: (j['is_read'] ?? false) as bool,
        createdAt: (j['created_at'] ?? '') as String,
      );
}

double _num(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
