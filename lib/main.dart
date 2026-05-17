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

// 제목 + 요약 기반 키워드 매칭 (오매칭 방지를 위해 구체적 의학 용어 사용)
bool _isRelatedCategory(String articleTitle, String articleSummary, String appCategory) {
  String lowerText = (articleTitle + ' ' + articleSummary).toLowerCase();

  bool has(String keyword) => lowerText.contains(keyword);

  switch (appCategory) {
    case '귀':
      return has('이명') || has('난청') || has('중이염') || has('외이염') ||
             has('고막') || has('청력') || has('청각') || has('귀울림') ||
             has('돌발성난청') || has('소음성난청') || has('이석증') ||
             has('전정신경염') || has('메니에르') || has('삼출성중이염') ||
             has('귀통증') || has('청신경') || has('이관') || has('어지럼증') ||
             has('현기증') || has('귀지') || has('귀앓이') || has('귀에서');

    case '눈':
      return has('시력') || has('백내장') || has('녹내장') || has('망막') ||
             has('안구') || has('결막염') || has('다래끼') || has('근시') ||
             has('원시') || has('난시') || has('약시') || has('사시') ||
             has('안구건조') || has('각막') || has('시야') || has('눈꺼풀') ||
             has('안검') || has('눈물') || has('시신경') || has('황반변성') ||
             has('망막박리') || has('안압') || has('눈떨림') || has('각막염') ||
             has('포도막염') || has('비문증') || has('안와') || has('눈충혈') ||
             has('눈통증') || has('눈피로') || has('눈건조');

    case '머리/뇌':
      return has('두통') || has('편두통') || has('치매') || has('뇌졸중') ||
             has('알츠하이머') || has('파킨슨') || has('뇌경색') || has('뇌출혈') ||
             has('뇌종양') || has('뇌암') || has('수막염') || has('뇌염') ||
             has('간질') || has('뇌전증') || has('발작') || has('기억력') ||
             has('건망증') || has('집중력') || has('뇌압') || has('두개골') ||
             has('뇌혈관') || has('뇌신경') || has('뇌척수') || has('뇌막') ||
             has('뇌피질') || has('머리통증') || has('머리아픔') || has('두개내압');

    case '심장/혈관':
      return has('심장') || has('혈관') || has('고혈압') || has('혈압') ||
             has('심혈관') || has('심근경색') || has('협심증') || has('부정맥') ||
             has('심부전') || has('심장병') || has('심박수') || has('맥박') ||
             has('혈류') || has('혈액순환') || has('동맥') || has('정맥') ||
             has('혈전') || has('빈혈') || has('관상동맥') || has('대동맥') ||
             has('동맥경화') || has('심방세동') || has('심실') || has('판막') ||
             has('심내막염') || has('심낭염') || has('말초혈관') || has('하지정맥류') ||
             has('혈액점도') || has('저혈압') || has('콜레스테롤') || has('중성지방');

    case '폐/호흡기':
      return has('폐렴') || has('폐암') || has('폐결핵') || has('결핵') ||
             has('기관지') || has('천식') || has('기침') || has('가래') ||
             has('기흉') || has('폐부종') || has('폐기종') || has('copd') ||
             has('호흡곤란') || has('숨가쁨') || has('흉막') || has('흉부') ||
             has('감기') || has('독감') || has('인플루엔자') || has('폐섬유화') ||
             has('기관지확장증') || has('기관지염') || has('흉통') || has('객혈') ||
             has('호흡기') || has('산소포화도') || has('폐기능') || has('흉수');

    case '위/소화기':
      return has('위염') || has('위궤양') || has('위암') || has('위산') ||
             has('소화불량') || has('역류성식도염') || has('식도염') || has('식도암') ||
             has('십이지장') || has('대장염') || has('대장암') || has('대장내시경') ||
             has('과민성장증후군') || has('크론병') || has('변비') || has('설사') ||
             has('복통') || has('복부팽만') || has('헬리코박터') || has('위내시경') ||
             has('소화기') || has('치질') || has('항문') || has('직장암') ||
             has('장염') || has('구토') || has('메스꺼움') || has('위장') ||
             has('소화') || has('과민성대장') || has('궤양성대장염');

    case '간/췌장':
      return has('간염') || has('간경화') || has('간경변') || has('간암') ||
             has('지방간') || has('간수치') || has('간기능') || has('간독성') ||
             has('b형간염') || has('c형간염') || has('a형간염') || has('알코올성간') ||
             has('췌장염') || has('췌장암') || has('당뇨병') || has('혈당') ||
             has('인슐린') || has('담석') || has('담낭염') || has('황달') ||
             has('담관') || has('담즙') || has('당화혈색소') || has('공복혈당') ||
             has('인슐린저항성') || has('당뇨합병증') || has('췌장') || has('담낭');

    case '신장/비뇨기':
      return has('신장') || has('콩팥') || has('방광') || has('소변') ||
             has('요로') || has('전립선') || has('요실금') || has('빈뇨') ||
             has('혈뇨') || has('신부전') || has('신장염') || has('방광염') ||
             has('요로결석') || has('신장결석') || has('단백뇨') || has('투석') ||
             has('크레아티닌') || has('요관') || has('요도') || has('배뇨') ||
             has('야뇨') || has('잔뇨') || has('야간뇨') || has('전립선비대') ||
             has('전립선염') || has('방광결석') || has('만성신장병') || has('신장이식') ||
             has('과민성방광') || has('배뇨장애') || has('신우신염');

    case '피부':
      return has('피부') || has('아토피') || has('습진') || has('여드름') ||
             has('알레르기') || has('가려움') || has('무좀') || has('건선') ||
             has('두드러기') || has('피부염') || has('백반증') || has('기미') ||
             has('주근깨') || has('사마귀') || has('피부암') || has('흑색종') ||
             has('화상') || has('흉터') || has('탈모') || has('손톱') ||
             has('발톱') || has('피부건조') || has('지루성피부염') || has('모공') ||
             has('색소침착') || has('피부노화') || has('대상포진') || has('수두') ||
             has('켈로이드') || has('두피') || has('원형탈모') || has('지성피부');

    case '근육/관절':
      return has('근육') || has('관절') || has('척추') || has('허리') ||
             has('디스크') || has('관절염') || has('골다공증') || has('류마티스') ||
             has('통풍') || has('골관절염') || has('퇴행성관절염') || has('추간판') ||
             has('골절') || has('근육통') || has('건염') || has('인대') ||
             has('힘줄') || has('연골') || has('요통') || has('목디스크') ||
             has('허리디스크') || has('섬유근육통') || has('근염') || has('회전근개') ||
             has('반월상연골') || has('슬개골') || has('관절액') || has('연골연화증') ||
             has('척추측만') || has('척추관협착') || has('뼈') || has('골밀도');

    case '손/팔':
      return has('손목') || has('손가락') || has('손저림') || has('손떨림') ||
             has('팔꿈치') || has('팔저림') || has('어깨통증') || has('오십견') ||
             has('회전근개') || has('테니스엘보') || has('골프엘보') || has('수근관') ||
             has('방아쇠수지') || has('손목터널') || has('드퀘르벵') || has('손바닥') ||
             has('손등') || has('상완') || has('전완') || has('어깨관절') ||
             has('어깨충돌') || has('이두근') || has('삼두근') || has('손麻痺') ||
             has('손목골절') || has('쇄골') || has('견갑골') || has('팔골절');

    case '다리/발':
      return has('무릎') || has('발목') || has('종아리') || has('발가락') ||
             has('발뒤꿈치') || has('하지정맥류') || has('족저근막') || has('발바닥') ||
             has('허벅지') || has('대퇴') || has('정강이') || has('아킬레스건') ||
             has('발목염좌') || has('무릎연골') || has('십자인대') || has('다리부종') ||
             has('무지외반증') || has('편평족') || has('무릎통증') || has('족부') ||
             has('하지부종') || has('반월판') || has('슬개골') || has('발저림') ||
             has('발통증') || has('다리저림') || has('하지') || has('무릎관절');

    case '코/입':
      return has('비염') || has('축농증') || has('구내염') || has('치아') ||
             has('잇몸') || has('구취') || has('콧물') || has('코막힘') ||
             has('후각') || has('코피') || has('부비동') || has('구강') ||
             has('치과') || has('입냄새') || has('구순포진') || has('타액') ||
             has('미각') || has('비중격') || has('구강암') || has('혀') ||
             has('치주염') || has('충치') || has('치아교정') || has('임플란트') ||
             has('코골이') || has('수면무호흡') || has('구강건조') || has('편평태선');

    case '목/인후':
      return has('인후염') || has('편도염') || has('편도') || has('성대') ||
             has('갑상선') || has('갑상샘') || has('인후') || has('후두') ||
             has('인두') || has('편도선') || has('림프절') || has('임파선') ||
             has('경추') || has('목디스크') || has('목통증') || has('목쉼') ||
             has('연하곤란') || has('삼킴장애') || has('목소리') || has('쉰소리') ||
             has('음성') || has('갑상선암') || has('갑상선염') || has('갑상선기능') ||
             has('목뻣뻣') || has('목뻐근') || has('목어깨') || has('인후통');

    case '여성건강':
      return has('생리') || has('임신') || has('갱년기') || has('유방') ||
             has('자궁') || has('난소') || has('폐경') || has('월경') ||
             has('생리통') || has('생리불순') || has('무월경') || has('과다월경') ||
             has('자궁근종') || has('자궁내막증') || has('자궁암') || has('자궁경부암') ||
             has('난소암') || has('유방암') || has('모유') || has('수유') ||
             has('출산') || has('분만') || has('산후') || has('질염') ||
             has('골반') || has('피임') || has('불임') || has('산부인과') ||
             has('유방결절') || has('난소낭종') || has('자궁선근증') || has('조기폐경') ||
             has('임신성당뇨') || has('산후우울') || has('여성호르몬') || has('에스트로겐');

    case '남성건강':
      return has('전립선') || has('발기부전') || has('발기') || has('조루') ||
             has('남성호르몬') || has('테스토스테론') || has('전립선염') ||
             has('전립선비대') || has('전립선암') || has('성기능') || has('정자') ||
             has('정액') || has('고환') || has('음낭') || has('음경') ||
             has('포경') || has('남성불임') || has('정계정맥류') || has('남성갱년기') ||
             has('성욕') || has('정력') || has('남성건강') || has('비뇨기과') ||
             has('psa') || has('전립선특이항원') || has('조기사정');

    case '전신/기타':
      return has('건강검진') || has('면역력') || has('면역') || has('비타민') ||
             has('영양') || has('영양제') || has('다이어트') || has('체중') ||
             has('비만') || has('스트레스') || has('피로') || has('만성피로') ||
             has('수면') || has('불면') || has('수면장애') || has('운동') ||
             has('미네랄') || has('호르몬') || has('내분비') || has('바이러스') ||
             has('감염') || has('세균') || has('발열') || has('오한') ||
             has('우울') || has('불안') || has('공황') || has('정신건강') ||
             has('건강') || has('종합건강') || has('검진') || has('혈액검사') ||
             has('콜레스테롤') || has('중성지방') || has('혈액') || has('노화');

    default:
      return false;
  }
}

  Future<void> _loadInitialArticles() async {
    setState(() {
      _isLoading = true;
      _currentPage = 3;
      _hasMoreData = true;
    });

    try {
      final wordpressService = WordPressApiService();
      // 3페이지 병렬 요청으로 최대 300개 로드
      final results = await Future.wait([
        wordpressService.fetchLatestArticles(page: 1, perPage: 100),
        wordpressService.fetchLatestArticles(page: 2, perPage: 100),
        wordpressService.fetchLatestArticles(page: 3, perPage: 100),
      ]);

      final allArticles = results.expand((list) => list).toList();

      _articles = allArticles.where((article) =>
        _isRelatedCategory(article.category, article.summary, widget.categoryName)
      ).toList();

      print('${widget.categoryName}: ${_articles.length}개 글 로드 완료 (전체 ${allArticles.length}개 중)');

      // 글이 적어 화면을 못 채우면 글이 5개 이상 되거나 데이터가 없을 때까지 계속 로드
      while (_articles.length < 5 && _hasMoreData) {
        await _fetchNextPage();
      }
    } catch (e) {
      print('카테고리 글 로드 오류: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchNextPage() async {
    try {
      final wordpressService = WordPressApiService();
      final allArticles = await wordpressService.fetchLatestArticles(
        page: _currentPage + 1,
        perPage: 100,
      );

      if (allArticles.isNotEmpty) {
        final newCategoryArticles = allArticles.where((article) =>
          _isRelatedCategory(article.category, article.summary, widget.categoryName)
        ).toList();

        setState(() {
          _articles.addAll(newCategoryArticles);
          _currentPage++;
        });

        if (newCategoryArticles.isNotEmpty) {
          print('${widget.categoryName}: ${newCategoryArticles.length}개 글 추가 로드 (page ${_currentPage})');
        }

        if (allArticles.length < 100) {
          _hasMoreData = false;
        }
      } else {
        _hasMoreData = false;
      }
    } catch (e) {
      print('추가 글 로드 오류: $e');
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await _fetchNextPage();
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