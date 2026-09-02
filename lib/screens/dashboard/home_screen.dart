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
        setState(() =>
            _categories = rows.map(Category.fromJson).toList());
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
        'high_price' => await q
            .order('reward_per_worker', ascending: false)
            .limit(50),
        'low_price' =>
          await q.order('reward_per_worker', ascending: true).limit(50),
        _ => await q
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
        page = page
            .where((j) => !j.isFull && !done.contains(j.id))
            .toList();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.success50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  fmtMoney(profile?.earningBalance),
                  style: const TextStyle(
                      color: AppColors.earnGreen,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
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
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _catChip('all', 'All'),
                          ..._categories.map((c) => _catChip(c.name, c.name)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Sort:',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.gray500)),
                        const SizedBox(width: 8),
                        _sortChip('latest', 'Latest'),
                        _sortChip('high_price', 'High Price'),
                        _sortChip('low_price', 'Low Price'),
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
                child: EmptyView(Icons.work_off_outlined, 'No jobs available',
                    subtitle: 'Check back later for new tasks.'),
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

  Widget _catChip(String value, String label) {
    final selected = _category == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) {
          setState(() => _category = value);
          _loadJobs();
        },
        selectedColor: AppColors.primary600,
        labelStyle:
            TextStyle(color: selected ? Colors.white : AppColors.gray600),
        backgroundColor: Colors.white,
        side: BorderSide(
            color: selected ? AppColors.primary600 : AppColors.gray200),
      ),
    );
  }

  Widget _sortChip(String value, String label) {
    final selected = _sort == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _sort = value);
          _loadJobs();
        },
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected ? AppColors.primary600 : AppColors.gray500,
          ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(job.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  if (job.rewardPerWorker >= 0.1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8F7DC),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('TOP JOB',
                          style: TextStyle(
                              color: AppColors.earnGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.gray600, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(fmtMoney(job.rewardPerWorker),
                      style: const TextStyle(
                          color: AppColors.earnGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 16)),
                  const SizedBox(width: 12),
                  Icon(Icons.people_outline,
                      size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text('${job.filledSlots}/${job.totalSlots}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gray500)),
                  const Spacer(),
                  if (job.isPremiumOnly)
                    const Icon(Icons.workspace_premium,
                        size: 16, color: AppColors.accent500),
                  const SizedBox(width: 6),
                  Text(job.category,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.gray500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
