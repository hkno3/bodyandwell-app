import 'package:flutter/material.dart';

class Article {
  final String id;
  final String title;
  final String summary;
  final String category;
  final String url;
  final DateTime publishDate;

  Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.url,
    required this.publishDate,
  });

  // 시간 표시용 텍스트
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(publishDate);
    
    if (difference.inDays > 7) {
      return '${publishDate.month}/${publishDate.day}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  // 카테고리별 아이콘
  IconData get categoryIcon {
    switch (category) {
      case '당뇨':
        return Icons.favorite;
      case '고혈압':
        return Icons.monitor_heart;
      case '피부질환':
        return Icons.face;
      case '영양':
        return Icons.restaurant;
      case '운동':
        return Icons.fitness_center;
      case '심혈관':
        return Icons.favorite_border;
      case '정신건강':
        return Icons.psychology;
      case '소화기':
        return Icons.restaurant_menu;
      case '호흡기':
        return Icons.air;
      case '면역':
        return Icons.shield;
      default:
        return Icons.article;
    }
  }

  // 카테고리별 색상
  Color get categoryColor {
    switch (category) {
      case '당뇨':
        return Colors.red[300]!;
      case '고혈압':
        return Colors.orange[300]!;
      case '피부질환':
        return Colors.pink[300]!;
      case '영양':
        return Colors.green[300]!;
      case '운동':
        return Colors.blue[300]!;
      case '심혈관':
        return Colors.purple[300]!;
      case '정신건강':
        return Colors.teal[300]!;
      case '소화기':
        return Colors.brown[300]!;
      case '호흡기':
        return Colors.cyan[300]!;
      case '면역':
        return Colors.indigo[300]!;
      default:
        return Colors.grey[300]!;
    }
  }

  // JSON 변환 (북마크 저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'category': category,
      'url': url,
      'publishDate': publishDate.toIso8601String(),
    };
  }

  // JSON에서 Article 생성 (북마크 로드용)
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      summary: json['summary'] ?? '',
      category: json['category'] ?? '',
      url: json['url'] ?? '',
      publishDate: DateTime.tryParse(json['publishDate'] ?? '') ?? DateTime.now(),
    );
  }
}