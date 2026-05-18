import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CourseModel {
  final String flashLabel;
  final String courseName;
  final double rating;
  final int students;
  final int price;
  final Color bgStart;
  final Color bgEnd;
  final IconData icon;
  final List<String> tags;
  final String? imageUrl;

  const CourseModel({
    required this.flashLabel,
    required this.courseName,
    required this.rating,
    required this.students,
    required this.price,
    required this.bgStart,
    required this.bgEnd,
    required this.icon,
    this.tags = const [],
    this.imageUrl,
  });
}

class CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback? onTap;

  const CourseCard({super.key, required this.course, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/course'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: _buildInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final hasImage = course.imageUrl != null && course.imageUrl!.isNotEmpty;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.network(
              course.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradientBg(),
            )
          else
            _gradientBg(),
          if (!hasImage) ...[
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                course.flashLabel,
                style: GoogleFonts.sarabun(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
            Center(
              child: Icon(course.icon, color: Colors.white.withOpacity(0.3), size: 64),
            ),
          ],
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.priceRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                course.price.toString().replaceAllMapped(
                    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},'),
                style: GoogleFonts.sarabun(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  'ホ',
                  style: GoogleFonts.sarabun(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBg() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [course.bgStart, course.bgEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.courseName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.sarabun(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, color: AppTheme.warning, size: 14),
            const SizedBox(width: 2),
            Text(
              '${course.rating}',
              style: GoogleFonts.sarabun(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${_formatNumber(course.students)} students',
              style: GoogleFonts.sarabun(fontSize: 12, color: AppTheme.textLight),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'ホ',
                  style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'ครูพี่โฮม',
              style: GoogleFonts.sarabun(fontSize: 11, color: AppTheme.textMedium),
            ),
            if (course.tags.isNotEmpty) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    course.tags.first,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.sarabun(
                      fontSize: 10,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class PackageCard extends StatelessWidget {
  final String label;
  final String title;
  final String price;
  final Color bgStart;
  final Color bgEnd;
  final VoidCallback? onTap;

  const PackageCard({
    super.key,
    required this.label,
    required this.title,
    required this.price,
    required this.bgStart,
    required this.bgEnd,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [bgStart, bgEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ครูพี่โฮม',
                  style: GoogleFonts.sarabun(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    price,
                    style: GoogleFonts.sarabun(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.sarabun(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
