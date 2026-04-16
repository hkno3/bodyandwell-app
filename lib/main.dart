import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/article.dart';
import 'services/wordpress_api_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        title: 'Body and Well',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    BookmarkScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: '북마크',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

// AppProvider (북마크 관리)
class AppProvider extends ChangeNotifier {
  List<Article> _bookmarkedArticles = [];

  List<Article> get bookmarkedArticles => _bookmarkedArticles;

  AppProvider() {
    _loadBookmarks();
  }

  void toggleBookmark(Article article) {
    if (isBookmarked(article)) {
      _bookmarkedArticles.removeWhere((a) => a.id == article.id);
    } else {
      _bookmarkedArticles.add(article);
    }
    _saveBookmarks();
    notifyListeners();
  }

  bool isBookmarked(Article article) {
    return _bookmarkedArticles.any((a) => a.id == article.id);
  }

  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getStringList('bookmarks') ?? [];
      _bookmarkedArticles = bookmarksJson.map((json) {
        final data = jsonDecode(json);
        return Article(
          id: data['id'],
          title: data['title'],
          summary: data['summary'],
          category: data['category'],
          url: data['url'],
          publishDate: DateTime.parse(data['publishDate']),
        );
      }).toList();
    } catch (e) {
      print('북마크 로드 오류: $e');
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = _bookmarkedArticles.map((article) {
        return jsonEncode({
          'id': article.id,
          'title': article.title,
          'summary': article.summary,
          'category': article.category,
          'url': article.url,
          'publishDate': article.publishDate.toIso8601String(),
        });
      }).toList();
      await prefs.setStringList('bookmarks', bookmarksJson);
    } catch (e) {
      print('북마크 저장 오류: $e');
    }
  }
}

// 홈 화면: 신체 부위별 카테고리 버튼들
class HomeScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {'name': '머리/뇌', 'icon': '🧠', 'color': Colors.purple[300]},
    {'name': '눈', 'icon': '👁️', 'color': Colors.blue[300]},
    {'name': '귀', 'icon': '👂', 'color': Colors.orange[300]},
    {'name': '코/입', 'icon': '👃', 'color': Colors.pink[300]},
    {'name': '목/인후', 'icon': '🫱', 'color': Colors.teal[300]},
    {'name': '심장/혈관', 'icon': '❤️', 'color': Colors.red[300]},
    {'name': '폐/호흡기', 'icon': '🫁', 'color': Colors.cyan[300]},
    {'name': '위/소화기', 'icon': '🫃', 'color': Colors.amber[300]},
    {'name': '간/췌장', 'icon': '📍', 'color': Colors.brown[300]},
    {'name': '신장/비뇨기', 'icon': '🫘', 'color': Colors.indigo[300]},
    {'name': '피부', 'icon': '🤲', 'color': Colors.pinkAccent},
    {'name': '근육/관절', 'icon': '💪', 'color': Colors.green[300]},
    {'name': '손/팔', 'icon': '🤚', 'color': Colors.deepOrange[300]},
    {'name': '다리/발', 'icon': '🦵', 'color': Colors.lime[300]},
    {'name': '여성건강', 'icon': '👩', 'color': Colors.pinkAccent},
    {'name': '남성건강', 'icon': '👨', 'color': Colors.blueAccent},
    {'name': '전신/기타', 'icon': '👤', 'color': Colors.black},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Body and Well'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.web),
            onPressed: () async {
              await launchUrl(Uri.parse('https://bodyandwell.com'));
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '증상별 건강정보',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
            ),
            SizedBox(height: 8),
            Text(
              '아픈 부위를 선택하세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 8),
            Text(
              '원하는 증상이 없다면 상단 검색 버튼을 이용해보세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return CategoryCard(
                    name: category['name'],
                    icon: category['icon'],
                    color: category['color'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryDetailScreen(
                            categoryName: category['name'],
                            categoryIcon: category['icon'],
                            categoryColor: category['color'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 카테고리 카드 위젯
class CategoryCard extends StatelessWidget {
  final String name;
  final String icon;
  final Color? color;
  final VoidCallback onTap;

  const CategoryCard({
    Key? key,
    required this.name,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color?.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color ?? Colors.grey, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(fontSize: 40),
            ),
            SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// 카테고리 상세 화면 (무한 스크롤)
class CategoryDetailScreen extends StatefulWidget {
  final String categoryName;
  final String categoryIcon;
  final Color? categoryColor;

  const CategoryDetailScreen({
    Key? key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  }) : super(key: key);

  @override
  _CategoryDetailScreenState createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Article> _articles = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialArticles();
    
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreArticles();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

// 메인 앱에서 수정할 부분들

// 확장된 _isRelatedCategory 메서드 - 제목 기반 키워드 매칭
bool _isRelatedCategory(String articleTitle, String appCategory) {
  String lowerTitle = articleTitle.toLowerCase();
  
  switch (appCategory) {
    case '귀':
      return lowerTitle.contains('귀') || 
             lowerTitle.contains('청력') || 
             lowerTitle.contains('이명') ||
             lowerTitle.contains('중이염') ||
             lowerTitle.contains('외이염') ||
             lowerTitle.contains('내이염') ||
             lowerTitle.contains('귀에서') ||
             lowerTitle.contains('귀앓이') ||
             lowerTitle.contains('고막') ||
             lowerTitle.contains('귀지') ||
             lowerTitle.contains('귀울림') ||
             lowerTitle.contains('난청') ||
             lowerTitle.contains('청각') ||
             lowerTitle.contains('삐소리') ||
             lowerTitle.contains('삐 소리') ||
             lowerTitle.contains('돌발성난청') ||
             lowerTitle.contains('소음성난청') ||
             lowerTitle.contains('평형감각') ||
             lowerTitle.contains('어지럼증') ||
             lowerTitle.contains('현기증');

    case '눈':
      return lowerTitle.contains('눈') || 
             lowerTitle.contains('시력') || 
             lowerTitle.contains('백내장') ||
             lowerTitle.contains('녹내장') ||
             lowerTitle.contains('망막') ||
             lowerTitle.contains('안구') ||
             lowerTitle.contains('결막염') ||
             lowerTitle.contains('다래끼') ||
             lowerTitle.contains('근시') ||
             lowerTitle.contains('원시') ||
             lowerTitle.contains('난시') ||
             lowerTitle.contains('약시') ||
             lowerTitle.contains('사시') ||
             lowerTitle.contains('안구건조') ||
             lowerTitle.contains('각막') ||
             lowerTitle.contains('동공') ||
             lowerTitle.contains('홍채') ||
             lowerTitle.contains('시야') ||
             lowerTitle.contains('눈꺼풀') ||
             lowerTitle.contains('안검') ||
             lowerTitle.contains('눈물') ||
             lowerTitle.contains('시신경');

    case '머리/뇌':
      return lowerTitle.contains('머리') || 
             lowerTitle.contains('뇌') || 
             lowerTitle.contains('두통') ||
             lowerTitle.contains('편두통') ||
             lowerTitle.contains('치매') ||
             lowerTitle.contains('뇌졸중') ||
             lowerTitle.contains('알츠하이머') ||
             lowerTitle.contains('파킨슨') ||
             lowerTitle.contains('뇌경색') ||
             lowerTitle.contains('뇌출혈') ||
             lowerTitle.contains('뇌종양') ||
             lowerTitle.contains('뇌암') ||
             lowerTitle.contains('수막염') ||
             lowerTitle.contains('뇌염') ||
             lowerTitle.contains('간질') ||
             lowerTitle.contains('발작') ||
             lowerTitle.contains('기억력') ||
             lowerTitle.contains('건망증') ||
             lowerTitle.contains('집중력') ||
             lowerTitle.contains('두개골') ||
             lowerTitle.contains('정수리') ||
             lowerTitle.contains('이마');

    case '심장/혈관':
      return lowerTitle.contains('심장') || 
             lowerTitle.contains('혈관') || 
             lowerTitle.contains('고혈압') ||
             lowerTitle.contains('혈압') ||
             lowerTitle.contains('심혈관') ||
             lowerTitle.contains('심근경색') ||
             lowerTitle.contains('협심증') ||
             lowerTitle.contains('부정맥') ||
             lowerTitle.contains('심부전') ||
             lowerTitle.contains('심장병') ||
             lowerTitle.contains('심박수') ||
             lowerTitle.contains('맥박') ||
             lowerTitle.contains('혈류') ||
             lowerTitle.contains('혈액순환') ||
             lowerTitle.contains('동맥') ||
             lowerTitle.contains('정맥') ||
             lowerTitle.contains('혈전') ||
             lowerTitle.contains('빈혈') ||
             lowerTitle.contains('관상동맥') ||
             lowerTitle.contains('대동맥') ||
             lowerTitle.contains('정맥류') ||
             lowerTitle.contains('동맥경화');

    case '폐/호흡기':
      return lowerTitle.contains('폐') || 
             lowerTitle.contains('호흡') || 
             lowerTitle.contains('기관지') ||
             lowerTitle.contains('천식') ||
             lowerTitle.contains('기침') ||
             lowerTitle.contains('가래') ||
             lowerTitle.contains('폐렴') ||
             lowerTitle.contains('폐암') ||
             lowerTitle.contains('폐결핵') ||
             lowerTitle.contains('결핵') ||
             lowerTitle.contains('기흉') ||
             lowerTitle.contains('폐부종') ||
             lowerTitle.contains('폐기종') ||
             lowerTitle.contains('copd') ||
             lowerTitle.contains('호흡곤란') ||
             lowerTitle.contains('숨가쁨') ||
             lowerTitle.contains('기도') ||
             lowerTitle.contains('폐포') ||
             lowerTitle.contains('흉막') ||
             lowerTitle.contains('흉부') ||
             lowerTitle.contains('가슴') ||
             lowerTitle.contains('감기') ||
             lowerTitle.contains('독감');

    case '위/소화기':
      return lowerTitle.contains('위') || 
             lowerTitle.contains('소화') || 
             lowerTitle.contains('장') ||
             lowerTitle.contains('식도') ||
             lowerTitle.contains('십이지장') ||
             lowerTitle.contains('위염') ||
             lowerTitle.contains('위궤양') ||
             lowerTitle.contains('위암') ||
             lowerTitle.contains('대장') ||
             lowerTitle.contains('소장') ||
             lowerTitle.contains('직장') ||
             lowerTitle.contains('항문') ||
             lowerTitle.contains('대장염') ||
             lowerTitle.contains('과민성대장') ||
             lowerTitle.contains('변비') ||
             lowerTitle.contains('설사') ||
             lowerTitle.contains('복통') ||
             lowerTitle.contains('복부') ||
             lowerTitle.contains('배') ||
             lowerTitle.contains('소화불량') ||
             lowerTitle.contains('위산') ||
             lowerTitle.contains('역류') ||
             lowerTitle.contains('치질') ||
             lowerTitle.contains('대장암') ||
             lowerTitle.contains('헬리코박터');

    case '간/췌장':
      return lowerTitle.contains('간') || 
             lowerTitle.contains('췌장') || 
             lowerTitle.contains('담낭') ||
             lowerTitle.contains('담석') ||
             lowerTitle.contains('당뇨') ||
             lowerTitle.contains('간염') ||
             lowerTitle.contains('간경화') ||
             lowerTitle.contains('간암') ||
             lowerTitle.contains('지방간') ||
             lowerTitle.contains('간기능') ||
             lowerTitle.contains('췌장염') ||
             lowerTitle.contains('췌장암') ||
             lowerTitle.contains('당뇨병') ||
             lowerTitle.contains('혈당') ||
             lowerTitle.contains('인슐린') ||
             lowerTitle.contains('담즙') ||
             lowerTitle.contains('담관') ||
             lowerTitle.contains('황달') ||
             lowerTitle.contains('간수치') ||
             lowerTitle.contains('b형간염') ||
             lowerTitle.contains('c형간염') ||
             lowerTitle.contains('a형간염');

    case '신장/비뇨기':
      return lowerTitle.contains('신장') || 
             lowerTitle.contains('콩팥') || 
             lowerTitle.contains('방광') ||
             lowerTitle.contains('소변') ||
             lowerTitle.contains('요로') ||
             lowerTitle.contains('전립선') ||
             lowerTitle.contains('요실금') ||
             lowerTitle.contains('빈뇨') ||
             lowerTitle.contains('혈뇨') ||
             lowerTitle.contains('신부전') ||
             lowerTitle.contains('신장염') ||
             lowerTitle.contains('방광염') ||
             lowerTitle.contains('요로결석') ||
             lowerTitle.contains('신장결석') ||
             lowerTitle.contains('단백뇨') ||
             lowerTitle.contains('투석') ||
             lowerTitle.contains('크레아티닌') ||
             lowerTitle.contains('요관') ||
             lowerTitle.contains('요도') ||
             lowerTitle.contains('배뇨') ||
             lowerTitle.contains('야뇨');

    case '피부':
      return lowerTitle.contains('피부') || 
             lowerTitle.contains('아토피') || 
             lowerTitle.contains('습진') ||
             lowerTitle.contains('여드름') ||
             lowerTitle.contains('알레르기') ||
             lowerTitle.contains('가려움') ||
             lowerTitle.contains('무좀') ||
             lowerTitle.contains('건선') ||
             lowerTitle.contains('두드러기') ||
             lowerTitle.contains('피부염') ||
             lowerTitle.contains('백반증') ||
             lowerTitle.contains('기미') ||
             lowerTitle.contains('주근깨') ||
             lowerTitle.contains('점') ||
             lowerTitle.contains('사마귀') ||
             lowerTitle.contains('백선') ||
             lowerTitle.contains('피부암') ||
             lowerTitle.contains('흑색종') ||
             lowerTitle.contains('화상') ||
             lowerTitle.contains('상처') ||
             lowerTitle.contains('흉터') ||
             lowerTitle.contains('탈모') ||
             lowerTitle.contains('손톱') ||
             lowerTitle.contains('발톱') ||
             lowerTitle.contains('피부건조');

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
             lowerTitle.contains('통풍') ||
             lowerTitle.contains('골관절염') ||
             lowerTitle.contains('퇴행성관절염') ||
             lowerTitle.contains('추간판') ||
             lowerTitle.contains('골절') ||
             lowerTitle.contains('근육통') ||
             lowerTitle.contains('근염') ||
             lowerTitle.contains('건염') ||
             lowerTitle.contains('인대') ||
             lowerTitle.contains('힘줄') ||
             lowerTitle.contains('연골') ||
             lowerTitle.contains('요통') ||
             lowerTitle.contains('목디스크') ||
             lowerTitle.contains('허리디스크') ||
             lowerTitle.contains('섬유근육통');

    case '손/팔':
      return lowerTitle.contains('손') || 
             lowerTitle.contains('팔') || 
             lowerTitle.contains('어깨') ||
             lowerTitle.contains('팔꿈치') ||
             lowerTitle.contains('손목') ||
             lowerTitle.contains('손가락') ||
             lowerTitle.contains('오십견') ||
             lowerTitle.contains('테니스엘보') ||
             lowerTitle.contains('손저림') ||
             lowerTitle.contains('팔저림') ||
             lowerTitle.contains('엄지') ||
             lowerTitle.contains('검지') ||
             lowerTitle.contains('중지') ||
             lowerTitle.contains('약지') ||
             lowerTitle.contains('새끼손가락') ||
             lowerTitle.contains('손바닥') ||
             lowerTitle.contains('손등') ||
             lowerTitle.contains('상완') ||
             lowerTitle.contains('전완') ||
             lowerTitle.contains('어깨관절') ||
             lowerTitle.contains('골프엘보') ||
             lowerTitle.contains('수근관증후군') ||
             lowerTitle.contains('방아쇠수지');

    case '다리/발':
      return lowerTitle.contains('다리') || 
             lowerTitle.contains('발') || 
             lowerTitle.contains('무릎') ||
             lowerTitle.contains('발목') ||
             lowerTitle.contains('종아리') ||
             lowerTitle.contains('발가락') ||
             lowerTitle.contains('발뒤꿈치') ||
             lowerTitle.contains('하지정맥류') ||
             lowerTitle.contains('족저근막') ||
             lowerTitle.contains('발바닥') ||
             lowerTitle.contains('발등') ||
             lowerTitle.contains('허벅지') ||
             lowerTitle.contains('대퇴') ||
             lowerTitle.contains('하퇴') ||
             lowerTitle.contains('정강이') ||
             lowerTitle.contains('무릎관절') ||
             lowerTitle.contains('아킬레스건') ||
             lowerTitle.contains('발목염좌') ||
             lowerTitle.contains('무릎연골') ||
             lowerTitle.contains('십자인대') ||
             lowerTitle.contains('다리부종') ||
             lowerTitle.contains('무지외반증') ||
             lowerTitle.contains('편평족') ||
             lowerTitle.contains('굳은살');

    case '코/입':
      return lowerTitle.contains('코') || 
             lowerTitle.contains('입') || 
             lowerTitle.contains('비염') ||
             lowerTitle.contains('축농증') ||
             lowerTitle.contains('구내염') ||
             lowerTitle.contains('치아') ||
             lowerTitle.contains('잇몸') ||
             lowerTitle.contains('구취') ||
             lowerTitle.contains('콧물') ||
             lowerTitle.contains('코막힘') ||
             lowerTitle.contains('후각') ||
             lowerTitle.contains('냄새') ||
             lowerTitle.contains('코피') ||
             lowerTitle.contains('부비동') ||
             lowerTitle.contains('구강') ||
             lowerTitle.contains('혀') ||
             lowerTitle.contains('치과') ||
             lowerTitle.contains('입냄새') ||
             lowerTitle.contains('입술') ||
             lowerTitle.contains('구순포진') ||
             lowerTitle.contains('침') ||
             lowerTitle.contains('타액') ||
             lowerTitle.contains('미각') ||
             lowerTitle.contains('비중격');

    case '목/인후':
      return lowerTitle.contains('목') || 
             lowerTitle.contains('인후') || 
             lowerTitle.contains('편도') ||
             lowerTitle.contains('성대') ||
             lowerTitle.contains('갑상선') ||
             lowerTitle.contains('목소리') ||
             lowerTitle.contains('인후염') ||
             lowerTitle.contains('편도염') ||
             lowerTitle.contains('목감기') ||
             lowerTitle.contains('후두') ||
             lowerTitle.contains('쉰소리') ||
             lowerTitle.contains('음성') ||
             lowerTitle.contains('삼키기') ||
             lowerTitle.contains('목구멍') ||
             lowerTitle.contains('인두') ||
             lowerTitle.contains('편도선') ||
             lowerTitle.contains('갑상샘') ||
             lowerTitle.contains('림프절') ||
             lowerTitle.contains('임파선') ||
             lowerTitle.contains('경추') ||
             lowerTitle.contains('목뼈') ||
             lowerTitle.contains('목어깨');

    case '여성건강':
      return lowerTitle.contains('여성') || 
             lowerTitle.contains('생리') || 
             lowerTitle.contains('임신') ||
             lowerTitle.contains('갱년기') ||
             lowerTitle.contains('유방') ||
             lowerTitle.contains('자궁') ||
             lowerTitle.contains('난소') ||
             lowerTitle.contains('폐경') ||
             lowerTitle.contains('월경') ||
             lowerTitle.contains('생리통') ||
             lowerTitle.contains('생리불순') ||
             lowerTitle.contains('무월경') ||
             lowerTitle.contains('과다월경') ||
             lowerTitle.contains('자궁근종') ||
             lowerTitle.contains('자궁내막증') ||
             lowerTitle.contains('자궁암') ||
             lowerTitle.contains('자궁경부암') ||
             lowerTitle.contains('난소암') ||
             lowerTitle.contains('유방암') ||
             lowerTitle.contains('모유') ||
             lowerTitle.contains('수유') ||
             lowerTitle.contains('출산') ||
             lowerTitle.contains('분만') ||
             lowerTitle.contains('산후') ||
             lowerTitle.contains('질염') ||
             lowerTitle.contains('골반') ||
             lowerTitle.contains('피임') ||
             lowerTitle.contains('불임') ||
             lowerTitle.contains('산부인과');

    case '남성건강':
      return lowerTitle.contains('남성') || 
             lowerTitle.contains('전립선') || 
             lowerTitle.contains('발기') ||
             lowerTitle.contains('정력') ||
             lowerTitle.contains('남성호르몬') ||
             lowerTitle.contains('테스토스테론') ||
             lowerTitle.contains('조루') ||
             lowerTitle.contains('전립선염') ||
             lowerTitle.contains('전립선비대') ||
             lowerTitle.contains('전립선암') ||
             lowerTitle.contains('발기부전') ||
             lowerTitle.contains('성기능') ||
             lowerTitle.contains('성욕') ||
             lowerTitle.contains('정자') ||
             lowerTitle.contains('정액') ||
             lowerTitle.contains('고환') ||
             lowerTitle.contains('음낭') ||
             lowerTitle.contains('음경') ||
             lowerTitle.contains('포경') ||
             lowerTitle.contains('남성불임') ||
             lowerTitle.contains('정계정맥류') ||
             lowerTitle.contains('비뇨기과') ||
             lowerTitle.contains('남성갱년기');

    case '전신/기타':
      return lowerTitle.contains('건강') || 
             lowerTitle.contains('운동') || 
             lowerTitle.contains('영양') ||
             lowerTitle.contains('비타민') ||
             lowerTitle.contains('다이어트') ||
             lowerTitle.contains('체중') ||
             lowerTitle.contains('스트레스') ||
             lowerTitle.contains('면역') ||
             lowerTitle.contains('피로') ||
             lowerTitle.contains('수면') ||
             lowerTitle.contains('불면') ||
             lowerTitle.contains('비만') ||
             lowerTitle.contains('미네랄') ||
             lowerTitle.contains('면역력') ||
             lowerTitle.contains('감염') ||
             lowerTitle.contains('바이러스') ||
             lowerTitle.contains('세균') ||
             lowerTitle.contains('발열') ||
             lowerTitle.contains('열') ||
             lowerTitle.contains('오한') ||
             lowerTitle.contains('우울') ||
             lowerTitle.contains('불안') ||
             lowerTitle.contains('호르몬') ||
             lowerTitle.contains('내분비') ||
             lowerTitle.contains('암') ||
             lowerTitle.contains('종양') ||
             lowerTitle.contains('건강검진') ||
             lowerTitle.contains('검사') ||
             lowerTitle.contains('치료') ||
             lowerTitle.contains('의료');

    default:
      return false;
  }
}

  Future<void> _loadInitialArticles() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMoreData = true;
    });
    
    try {
      final wordpressService = WordPressApiService();
      final allArticles = await wordpressService.fetchLatestArticles(page: 1, perPage: 100);
      
      // 포함 카테고리 글 필터링
      _articles = allArticles.where((article) => 
        _isRelatedCategory(article.category, widget.categoryName)
      ).toList();
      
      print('${widget.categoryName}: ${_articles.length}개 글 로드 완료');
    } catch (e) {
      print('카테고리 글 로드 오류: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final wordpressService = WordPressApiService();
      final allArticles = await wordpressService.fetchLatestArticles(
        page: _currentPage + 1, 
        perPage: 50
      );
      
      if (allArticles.isNotEmpty) {
        // 해당 카테고리 글만 필터링해서 추가
        final newCategoryArticles = allArticles.where((article) => 
          _isRelatedCategory(article.category, widget.categoryName)
        ).toList();
        
        if (newCategoryArticles.isNotEmpty) {
          setState(() {
            _articles.addAll(newCategoryArticles);
            _currentPage++;
          });
          print('${widget.categoryName}: ${newCategoryArticles.length}개 글 추가 로드');
        }
        
        if (allArticles.length < 50) {
          _hasMoreData = false;
        }
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      print('추가 글 로드 오류: $e');
    }
    
    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.categoryIcon, style: TextStyle(fontSize: 24)),
            SizedBox(width: 8),
            Text(widget.categoryName),
          ],
        ),
        backgroundColor: widget.categoryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: widget.categoryColor),
                  SizedBox(height: 16),
                  Text('${widget.categoryName} 관련 글을 찾는 중...'),
                ],
              ),
            )
          : _articles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.categoryIcon, style: TextStyle(fontSize: 60)),
                      SizedBox(height: 16),
                      Text('${widget.categoryName} 관련 글이 없습니다'),
                      SizedBox(height: 8),
                      Text('다른 카테고리를 확인해보세요'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInitialArticles,
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _articles.length + (_hasMoreData ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _articles.length) {
                        return Container(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: _isLoadingMore
                                ? Column(
                                    children: [
                                      CircularProgressIndicator(color: widget.categoryColor),
                                      SizedBox(height: 8),
                                      Text('더 많은 글을 찾는 중...'),
                                    ],
                                  )
                                : Text('모든 글을 불러왔습니다.'),
                          ),
                        );
                      }
                      final article = _articles[index];
                      return ArticleCard(article: article);
                    },
                  ),
                ),
    );
  }
}

// ArticleCard 위젯
class ArticleCard extends StatelessWidget {
  final Article article;

  const ArticleCard({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: article.categoryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.article, size: 16, color: Colors.black),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                article.category,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        provider.isBookmarked(article) ? Icons.bookmark : Icons.bookmark_border,
                        color: provider.isBookmarked(article) ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => provider.toggleBookmark(article),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  article.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  article.summary,
                  style: TextStyle(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      article.timeAgo,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await launchUrl(Uri.parse(article.url));
                      },
                      child: Text('전체 글 보기 →'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 북마크 화면
class BookmarkScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('북마크'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.bookmarkedArticles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('북마크한 글이 없습니다'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.bookmarkedArticles.length,
            itemBuilder: (context, index) {
              final article = provider.bookmarkedArticles[index];
              return ArticleCard(article: article);
            },
          );
        },
      ),
    );
  }
}

// 설정 화면
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.web),
            title: Text('웹사이트 방문'),
            subtitle: Text('bodyandwell.com'),
            onTap: () async {
              await launchUrl(Uri.parse('https://bodyandwell.com'));
            },
          ),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('앱 정보'),
            subtitle: Text('Body and Well v1.0'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Body and Well'),
                  content: Text('신체 부위별 건강 정보 앱\n\n개발: Flutter\n버전: 1.0.0'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('확인'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// 검색 화면
class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Article> _searchResults = [];
  bool _isSearching = false;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final wordpressService = WordPressApiService();
      final results = await wordpressService.searchArticles(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('검색 오류: $e');
    }

    setState(() {
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('검색'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '증상이나 질병명을 검색하세요',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          Expanded(
            child: _isSearching
                ? Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('검색 결과가 없습니다'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final article = _searchResults[index];
                          return ArticleCard(article: article);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}