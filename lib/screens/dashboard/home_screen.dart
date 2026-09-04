import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'job_detail_screen.dart';

/// Mirrors DashboardHome: active job feed with category filter, search and
/// sort, hiding jobs the worker already did or that are full.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _jobCols =
      'id,user_id,title,description,category,subcategory,url,proof_instructions,'
      'screenshot_count,screenshot_instructions,image_url,reward_per_worker,'
      'total_slots,filled_slots,status,is_premium_only,created_at';

  final _searchCtrl = TextEditingController();
  List<Job> _jobs = [];
  List<Category> _categories = [];
  bool _loading = true;
  String _category = 'all';
  String _sort = 'latest';

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadJobs();
  }

  Future<void> _loadCategories() async {
    try {
      final rows = await _db
          .from('categories')
          .select()
          .eq('is_active', true)
          .order('display_order');
      if (mounted) {
        setState(() => _categories = rows.map(Category.fromJson).toList());
      }
    } catch (_) {}
  }

  Future<void> _loadJobs() async {
    setState(() => _loading = true);
    try {
      var q = _db.from('jobs').select(_jobCols).eq('status', 'active');
      if (_category != 'all') q = q.eq('category', _category);
      final search = _searchCtrl.text.trim();
      if (search.isNotEmpty) {
        q = q.or('title.ilike.%$search%,description.ilike.%$search%');
      }
      final rows = switch (_sort) {
        'high_price' =>
          await q.order('reward_per_worker', ascending: false).limit(50),
        'low_price' =>
          await q.order('reward_per_worker', ascending: true).limit(50),
        _ =>
          await q
              .order('is_premium_only', ascending: false)
              .order('created_at', ascending: false)
              .limit(50),
      };
      var page = rows.map(Job.fromJson).toList();

      if (!mounted) return;
      // Hide jobs this worker already did (one task per worker per job).
      final profile = context.read<AuthService>().profile;
      if (profile != null && page.isNotEmpty) {
        final mine = await _db
            .from('tasks')
            .select('job_id')
            .eq('worker_id', profile.id)
            .inFilter('job_id', page.map((j) => j.id).toList());
        final done = mine.map((t) => t['job_id']).toSet();
        page = page.where((j) => !j.isFull && !done.contains(j.id)).toList();
      }
      if (mounted) setState(() => _jobs = page);
    } catch (e) {
      debugPrint('Load jobs error: $e');
      if (mounted) setState(() => _jobs = []);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthService>().profile;
    return Scaffold(
      appBar: AppBar(
        title: const WGLogo(size: 30),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fmtMoney(profile?.earningBalance),
                  style: const TextStyle(
                    color: AppColors.earnGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchCtrl,
                      onSubmitted: (_) => _loadJobs(),
                      decoration: InputDecoration(
                        hintText: 'Search jobs...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward, size: 20),
                          onPressed: _loadJobs,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 8),
                    // Two dropdowns side by side — like the web filter row.
                    Row(
                      children: [
                        Expanded(
                          child: _FilterDropdown(
                            value: _category,
                            items: [
                              const DropdownMenuItem(
                                value: 'all',
                                child: Text('All Categories'),
                              ),
                              ..._categories.map(
                                (c) => DropdownMenuItem(
                                  value: c.name,
                                  child: Text(c.name),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _category = v ?? 'all');
                              _loadJobs();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _FilterDropdown(
                            value: _sort,
                            items: const [
                              DropdownMenuItem(
                                value: 'latest',
                                child: Text('Latest'),
                              ),
                              DropdownMenuItem(
                                value: 'high_price',
                                child: Text('High Price'),
                              ),
                              DropdownMenuItem(
                                value: 'low_price',
                                child: Text('Low Price'),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() => _sort = v ?? 'latest');
                              _loadJobs();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(child: LoadingView())
            else if (_jobs.isEmpty)
              const SliverFillRemaining(
                child: EmptyView(
                  Icons.work_off_outlined,
                  'No jobs available',
                  subtitle: 'Check back later for new tasks.',
                ),
              )
            else
              SliverList.separated(
                itemCount: _jobs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _JobCard(job: _jobs[i], onDone: _loadJobs),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

/// Matches the web filter selects: rounded bordered box, small text.
class _FilterDropdown extends StatelessWidget {
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.gray600,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onDone;
  const _JobCard({required this.job, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
          );
          onDone();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Title + TOP JOB badge (like DashboardHome.tsx)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (job.rewardPerWorker >= 0.1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8F7DC),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'TOP JOB',
                        style: TextStyle(
                          color: AppColors.earnGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // 2. "3 OF 10" + green progress bar ... $ 0.050 (like the web)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${job.filledSlots} OF ${job.totalSlots}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 96,
                        height: 6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: job.totalSlots > 0
                                ? (job.filledSlots / job.totalSlots).clamp(
                                    0.0,
                                    1.0,
                                  )
                                : 0,
                            backgroundColor: AppColors.gray200,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.earnGreen,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    fmtMoney(job.rewardPerWorker),
                    style: const TextStyle(
                      color: AppColors.earnGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
