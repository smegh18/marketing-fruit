class Course {
  final int id;
  final String name;
  final String slug;
  final String permalink;
  final String image;
  final String content;
  final String duration;
  final String instructorName;
  final List<Section> sections;
  final int countStudents;

  Course({
    required this.id,
    required this.name,
    required this.slug,
    required this.permalink,
    required this.image,
    required this.content,
    required this.duration,
    required this.instructorName,
    required this.sections,
    required this.countStudents,
  });

  factory Course.fromJson(Map<String, dynamic> json) => Course(
    id: json['id'],
    name: json['name'] ?? '',
    slug: json['slug'] ?? '',
    permalink: json['permalink'] ?? '',
    image: json['image'] ?? '',
    content: json['content'] ?? '',
    duration: json['duration'] ?? '',
    instructorName: json['instructor']?['name'] ?? '',
    countStudents: json['count_students'] ?? 0,
    sections: json['sections'] != null
        ? (json['sections'] as List)
        .map((e) => Section.fromJson(e))
        .toList()
        : [],
  );
}

class Section {
  final int id;
  final String title;
  final List<SectionItem> items;

  Section({
    required this.id,
    required this.title,
    required this.items,
  });

  factory Section.fromJson(Map<String, dynamic> json) => Section(
    id: json['id'],
    title: json['title'] ?? '',
    items: json['items'] != null
        ? (json['items'] as List)
        .map((item) => SectionItem.fromJson(item))
        .toList()
        : [],
  );
}

class SectionItem {
  final int id;
  final String type; // "lp_lesson" or "lp_quiz"
  final String title;
  final bool preview;
  final bool locked;

  SectionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.preview,
    required this.locked,
  });

  factory SectionItem.fromJson(Map<String, dynamic> json) => SectionItem(
    id: json['id'],
    type: json['type'] ?? '',
    title: json['title'] ?? '',
    preview: json['preview'] ?? false,
    locked: json['locked'] ?? false,
  );
}

class Lesson {
  final int id;
  final String title;
  final String content;

  Lesson({required this.id, required this.title, required this.content});

  factory Lesson.fromJson(Map<String, dynamic> json) {
    // Title: use 'name' or 'title' fields
    String title = '';
    if (json['title'] is Map && json['title']?['rendered'] != null) {
      title = json['title']['rendered'];
    } else if (json['name'] != null) {
      title = json['name'];
    } else if (json['title'] != null) {
      title = json['title'].toString();
    }

    // Content: use 'content' as string or 'content.rendered'
    String content = '';
    if (json['content'] is Map && json['content']?['rendered'] != null) {
      content = json['content']['rendered'];
    } else if (json['content'] != null) {
      content = json['content'].toString();
    }

    return Lesson(
      id: json['id'],
      title: title,
      content: content,
    );
  }
}


class Quiz {
  final int id;
  final String title;
  final List<dynamic> questions;

  Quiz({required this.id, required this.title, required this.questions});

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
    id: json['id'],
    title: (json['title'] is Map && json['title']?['rendered'] != null)
        ? json['title']['rendered']
        : (json['title'] != null ? json['title'].toString() : (json['name'] ?? '')),
    questions: json['questions'] ?? [],
  );
}
