import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article.dart';

class WordPressApiService {
  static const String baseUrl = 'https://bodyandwell.com';
  static const String apiEndpoint = '$baseUrl/wp-json/wp/v2/posts';
  
  // 싱글톤 패턴
  static final WordPressApiService _instance = WordPressApiService._internal();
  factory WordPressApiService() => _instance;
  WordPressApiService._internal();

  // WordPress에서 페이지별 글 가져오기 (무한 스크롤용)
  Future<List<Article>> fetchLatestArticles({int page = 1, int perPage = 20}) async {
    try {
      print('WordPress API에서 ${page}페이지 글 가져오는 중...');
      
      final response = await http.get(
        Uri.parse('$apiEndpoint?page=$page&per_page=$perPage&orderby=date&order=desc'),
        headers: {
          'User-Agent': 'BodyAndWell-App/1.0',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('${page}페이지: ${jsonData.length}개 글 가져오기 성공!');
        
        final articles = jsonData.map((json) => _parseWordPressPost(json)).toList();
        return articles;
      } else if (response.statusCode == 400) {
        // 페이지 범위 초과 (더 이상 글이 없음)
        print('마지막 페이지 도달: ${page}페이지');
        return [];
      } else {
        print('API 호출 실패: ${response.statusCode}');
        return page == 1 ? _getSampleArticles() : [];
      }
    } catch (e) {
      print('WordPress API 오류: $e');
      return page == 1 ? _getSampleArticles() : [];
    }
  }

  // WordPress 포스트를 Article 객체로 변환
  Article _parseWordPressPost(Map<String, dynamic> json) {
    // 제목 추출 (HTML 태그 제거)
    final title = _cleanHtml(json['title']['rendered'] ?? '');
    
    // 내용에서 요약 생성 (HTML 태그 제거)
    final content = _cleanHtml(json['content']['rendered'] ?? '');
    final excerpt = _cleanHtml(json['excerpt']['rendered'] ?? '');
    
    // 요약 텍스트 생성 (excerpt 우선, 없으면 content에서 추출)
    String summary = '';
    if (excerpt.isNotEmpty && excerpt.length > 10) {
      summary = excerpt.length > 200 ? excerpt.substring(0, 200) + '...' : excerpt;
    } else if (content.isNotEmpty) {
      summary = content.length > 200 ? content.substring(0, 200) + '...' : content;
    } else {
      summary = '건강 정보를 확인해보세요.';
    }
    
    // 카테고리 자동 분류
    final category = _categorizeContent(title, content);
    
    // 발행 날짜
    final publishDate = DateTime.tryParse(json['date'] ?? '') ?? DateTime.now();
    
    // 글 URL
    final url = json['link'] ?? '$baseUrl/?p=${json['id']}';
    
    return Article(
      id: json['id'].toString(),
      title: title.isNotEmpty ? title : '제목 없음',
      summary: summary,
      category: category,
      url: url,
      publishDate: publishDate,
    );
  }

  // HTML 태그 제거 및 텍스트 정리
  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '') // HTML 태그 제거
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8230;', '...')
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll(RegExp(r'\s+'), ' ') // 여러 공백을 하나로
        .trim();
  }

// 1. wordpress_api_service.dart에서 _categorizeContent 메서드 간소화
String _categorizeContent(String title, String content) {
  // 그냥 원본 제목을 그대로 반환 (분류하지 않음)
  return title; // 또는 'general' 같은 기본값
}

// 2. 메인 앱의 _isRelatedCategory 메서드 - 키워드 매칭으로 중복 허용
bool _isRelatedCategory(String articleTitle, String appCategory) {
  String lowerTitle = articleTitle.toLowerCase();
  
  switch (appCategory) {
    case '귀':
      return lowerTitle.contains('귀') || 
             lowerTitle.contains('청력') || 
             lowerTitle.contains('이명') ||
             lowerTitle.contains('중이염') ||
             lowerTitle.contains('외이염') ||
             lowerTitle.contains('삐소리') ||
             lowerTitle.contains('삐 소리') ||
             lowerTitle.contains('난청') ||
             lowerTitle.contains('고막');

    case '눈':
      return lowerTitle.contains('눈') || 
             lowerTitle.contains('시력') || 
             lowerTitle.contains('백내장') ||
             lowerTitle.contains('녹내장') ||
             lowerTitle.contains('망막') ||
             lowerTitle.contains('안구') ||
             lowerTitle.contains('결막염') ||
             lowerTitle.contains('다래끼');

    case '머리/뇌':
      return lowerTitle.contains('머리') || 
             lowerTitle.contains('뇌') || 
             lowerTitle.contains('두통') ||
             lowerTitle.contains('편두통') ||
             lowerTitle.contains('치매') ||
             lowerTitle.contains('뇌졸중') ||
             lowerTitle.contains('어지럼') ||
             lowerTitle.contains('현기증');

    case '심장/혈관':
      return lowerTitle.contains('심장') || 
             lowerTitle.contains('혈관') || 
             lowerTitle.contains('고혈압') ||
             lowerTitle.contains('혈압') ||
             lowerTitle.contains('심근경색') ||
             lowerTitle.contains('협심증') ||
             lowerTitle.contains('부정맥') ||
             lowerTitle.contains('심혈관');

    case '폐/호흡기':
      return lowerTitle.contains('폐') || 
             lowerTitle.contains('호흡') || 
             lowerTitle.contains('기관지') ||
             lowerTitle.contains('천식') ||
             lowerTitle.contains('기침') ||
             lowerTitle.contains('폐렴') ||
             lowerTitle.contains('가래') ||
             lowerTitle.contains('감기');

    case '위/소화기':
      return lowerTitle.contains('위') || 
             lowerTitle.contains('소화') || 
             lowerTitle.contains('장') ||
             lowerTitle.contains('식도') ||
             lowerTitle.contains('변비') ||
             lowerTitle.contains('설사') ||
             lowerTitle.contains('복통') ||
             lowerTitle.contains('위염');

    case '간/췌장':
      return lowerTitle.contains('간') || 
             lowerTitle.contains('췌장') || 
             lowerTitle.contains('당뇨') ||
             lowerTitle.contains('혈당') ||
             lowerTitle.contains('간염') ||
             lowerTitle.contains('지방간') ||
             lowerTitle.contains('담석') ||
             lowerTitle.contains('인슐린');

    case '신장/비뇨기':
      return lowerTitle.contains('신장') || 
             lowerTitle.contains('콩팥') || 
             lowerTitle.contains('방광') ||
             lowerTitle.contains('소변') ||
             lowerTitle.contains('요로') ||
             lowerTitle.contains('전립선') ||
             lowerTitle.contains('요실금') ||
             lowerTitle.contains('빈뇨');

    case '피부':
      return lowerTitle.contains('피부') || 
             lowerTitle.contains('아토피') || 
             lowerTitle.contains('습진') ||
             lowerTitle.contains('여드름') ||
             lowerTitle.contains('알레르기') ||
             lowerTitle.contains('가려움') ||
             lowerTitle.contains('무좀') ||
             lowerTitle.contains('건선');

    case '근육/관절':
      return lowerTitle.contains('근육') || 
             lowerTitle.contains('관절') || 
             lowerTitle.contains('뼈') ||
             lowerTitle.contains('척추') ||
             lowerTitle.contains('허리') ||
             lowerTitle.contains('디스크') ||
             lowerTitle.contains('관절염') ||
             lowerTitle.contains('골다공증') ||
             lowerTitle.contains('류마티스') ||
             lowerTitle.contains('통풍');

    case '손/팔':
      return lowerTitle.contains('손') || 
             lowerTitle.contains('팔') || 
             lowerTitle.contains('어깨') ||
             lowerTitle.contains('팔꿈치') ||
             lowerTitle.contains('손목') ||
             lowerTitle.contains('손가락') ||
             lowerTitle.contains('오십견') ||
             lowerTitle.contains('테니스엘보');

    case '다리/발':
      return lowerTitle.contains('다리') || 
             lowerTitle.contains('발') || 
             lowerTitle.contains('무릎') ||
             lowerTitle.contains('발목') ||
             lowerTitle.contains('종아리') ||
             lowerTitle.contains('발가락') ||
             lowerTitle.contains('발뒤꿈치') ||
             lowerTitle.contains('하지정맥류');

    case '코/입':
      return lowerTitle.contains('코') || 
             lowerTitle.contains('입') || 
             lowerTitle.contains('비염') ||
             lowerTitle.contains('축농증') ||
             lowerTitle.contains('구내염') ||
             lowerTitle.contains('치아') ||
             lowerTitle.contains('잇몸') ||
             lowerTitle.contains('구취');

    case '목/인후':
      return lowerTitle.contains('목') || 
             lowerTitle.contains('인후') || 
             lowerTitle.contains('편도') ||
             lowerTitle.contains('성대') ||
             lowerTitle.contains('갑상선') ||
             lowerTitle.contains('목소리') ||
             lowerTitle.contains('인후염') ||
             lowerTitle.contains('편도염');

    case '여성건강':
      return lowerTitle.contains('여성') || 
             lowerTitle.contains('생리') || 
             lowerTitle.contains('임신') ||
             lowerTitle.contains('갱년기') ||
             lowerTitle.contains('유방') ||
             lowerTitle.contains('자궁') ||
             lowerTitle.contains('난소') ||
             lowerTitle.contains('폐경');

    case '남성건강':
      return lowerTitle.contains('남성') || 
             lowerTitle.contains('전립선') || 
             lowerTitle.contains('발기') ||
             lowerTitle.contains('정력') ||
             lowerTitle.contains('남성호르몬') ||
             lowerTitle.contains('테스토스테론');

    case '전신/기타':
      return lowerTitle.contains('건강') || 
             lowerTitle.contains('운동') || 
             lowerTitle.contains('영양') ||
             lowerTitle.contains('비타민') ||
             lowerTitle.contains('다이어트') ||
             lowerTitle.contains('체중') ||
             lowerTitle.contains('스트레스') ||
             lowerTitle.contains('면역');

    default:
      return false;
  }
}

  // 카테고리별 글 가져오기 (무한 스크롤용)
  Future<List<Article>> fetchArticlesByCategory(String category, {int page = 1, int perPage = 50}) async {
    try {
      print('WordPress API에서 "$category" 카테고리 ${page}페이지 검색 중...');
      
      final response = await http.get(
        Uri.parse('$apiEndpoint?page=$page&per_page=$perPage&orderby=date&order=desc'),
        headers: {
          'User-Agent': 'BodyAndWell-App/1.0',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        print('${page}페이지: ${jsonData.length}개 글 가져와서 필터링 중...');
        
        // 모든 글을 Article로 변환
        final allArticles = jsonData.map((json) => _parseWordPressPost(json)).toList();
        
        // 해당 카테고리에 맞는 글만 필터링
        final filteredArticles = allArticles.where((article) => article.category == category).toList();
        
        print('$category 카테고리: ${filteredArticles.length}개 글 필터링 완료');
        return filteredArticles;
        
      } else if (response.statusCode == 400) {
        print('$category 카테고리 마지막 페이지 도달: ${page}페이지');
        return [];
      } else {
        print('$category 카테고리 API 호출 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('$category 카테고리 API 오류: $e');
      return [];
    }
  }

  // 검색 기능
  Future<List<Article>> searchArticles(String query) async {
    try {
      // WordPress 검색 API 사용
      final response = await http.get(
        Uri.parse('$apiEndpoint?search=${Uri.encodeComponent(query)}&per_page=20'),
        headers: {
          'User-Agent': 'BodyAndWell-App/1.0',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((json) => _parseWordPressPost(json)).toList();
      } else {
        // 검색 실패시 로컬 필터링
        final allArticles = await fetchLatestArticles(page: 1, perPage: 50);
        final lowercaseQuery = query.toLowerCase();
        return allArticles.where((article) {
          return article.title.toLowerCase().contains(lowercaseQuery) ||
                 article.summary.toLowerCase().contains(lowercaseQuery) ||
                 article.category.toLowerCase().contains(lowercaseQuery);
        }).toList();
      }
    } catch (e) {
      print('검색 오류: $e');
      return [];
    }
  }

  // API 연결 테스트
  Future<bool> testApiConnection() async {
    try {
      final response = await http.head(Uri.parse(apiEndpoint)).timeout(Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 샘플 데이터 (API 연동 실패시 대체용)
  List<Article> _getSampleArticles() {
    return [
      Article(
        id: 'sample_1',
        title: '[API 연동 준비중] bodyandwell.com 연결 대기',
        summary: 'WordPress REST API 연동이 완료되면 실제 bodyandwell.com의 최신 글들이 여기에 표시됩니다. 현재는 연결을 시도하고 있습니다.',
        category: '전신/기타',
        url: 'https://bodyandwell.com',
        publishDate: DateTime.now().subtract(Duration(minutes: 1)),
      ),
      Article(
        id: 'sample_2',
        title: '[테스트] 앱이 정상 작동하고 있습니다',
        summary: 'Body and Well 앱이 성공적으로 실행되었습니다. WordPress와의 연결이 완료되면 실제 건강 정보 글들을 확인할 수 있습니다.',
        category: '전신/기타',
        url: 'https://bodyandwell.com',
        publishDate: DateTime.now().subtract(Duration(minutes: 5)),
      ),
      Article(
        id: 'sample_3',
        title: '[안내] 실시간 트래픽 증대 시스템 준비 완료',
        summary: 'RSS Aggregator와 WordPress REST API 연동이 완료되면, 앱 사용자들이 글을 클릭할 때마다 bodyandwell.com으로 직접 이동하여 사이트 트래픽이 증가합니다.',
        category: '전신/기타',
        url: 'https://bodyandwell.com',
        publishDate: DateTime.now().subtract(Duration(minutes: 10)),
      ),
    ];
  }
}