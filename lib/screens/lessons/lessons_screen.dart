import 'package:flutter/material.dart';
import 'widgets/lessons_header.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: const [
            LessonsHeader(),
            // TODO: Add other sections
            // LessonsTargetAudience(),
            // LessonsBenefits(),
            // LessonsTeasers(),
            // LessonsPackages(),
            // LessonsConstructor(),
            // LessonsAuthor(),
            // LessonsFaq(),
            // LessonsCTA(),
            // LessonsFooter(),
          ],
        ),
      ),
    );
  }
}
