import 'package:flutter/material.dart';

import '../../data/blog_posts.dart';
import '../../theme.dart';

/// Mirrors BlogPage.tsx — all posts are bundled (same BLOG_POSTS data).
class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blog & Guides')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: blogPosts.length,
        itemBuilder: (context, i) {
          final p = blogPosts[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BlogPostScreen(post: p))),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(p.category,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary700)),
                        ),
                        const Spacer(),
                        Text('${p.date} • ${p.readingTime}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.gray500)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p.title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gray900)),
                    const SizedBox(height: 6),
                    Text(p.excerpt,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.gray600)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BlogPostScreen extends StatelessWidget {
  final BlogPost post;
  const BlogPostScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(post.category, style: const TextStyle(fontSize: 14))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(post.title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: AppColors.gray900)),
          const SizedBox(height: 6),
          Text('${post.date} • ${post.readingTime} read',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.gray500)),
          const SizedBox(height: 16),
          ...post.content.map((b) {
            switch (b.type) {
              case 'h2':
                return Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 6),
                  child: Text(b.text,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gray900)),
                );
              case 'ul':
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: b.items
                        .map((i) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text('•  ',
                                      style: TextStyle(
                                          color: AppColors.primary600,
                                          fontWeight: FontWeight.w700)),
                                  Expanded(
                                    child: Text(i,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.6,
                                            color: AppColors.gray600)),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                );
              default:
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(b.text,
                      style: const TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: AppColors.gray600)),
                );
            }
          }),
        ],
      ),
    );
  }
}
