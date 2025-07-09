// Bu dosya, uygulamanın tüm modül verilerini yönetir
// Hem sabit modül içeriklerini hem de kullanıcının ilerlemesini takip eder

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/module.dart';
import '../models/progress.dart';

class DataService {
  static const String _progressKey = 'user_progress';
  static const String _moduleProgressKey = 'module_progress_';

  // Singleton pattern - uygulama boyunca tek bir instance kullanacağız
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  // Kullanıcının genel ilerlemesini döndürür
  Future<Progress> getUserProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_progressKey);

    if (progressJson != null) {
      return Progress.fromJson(jsonDecode(progressJson));
    }

    // İlk kez açılıyorsa başlangıç durumu oluştur
    return Progress.initial();
  }

  // Kullanıcının ilerlemesini kaydeder
  Future<void> saveUserProgress(Progress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  // Belirli bir modülün ilerlemesini günceller
  Future<void> updateModuleProgress(
    int moduleId,
    ModuleProgress moduleProgress,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_moduleProgressKey$moduleId',
      jsonEncode(moduleProgress.toJson()),
    );

    // Genel ilerlemeyi de güncelle
    final progress = await getUserProgress();
    final updatedModuleProgress = Map<int, ModuleProgress>.from(
      progress.moduleProgress,
    );
    updatedModuleProgress[moduleId] = moduleProgress;

    // Tamamlanan modül sayısını hesapla
    final completedModules =
        updatedModuleProgress.values.where((p) => p.isCompleted).length;
    final overallProgress = (completedModules / 11) * 100;

    final updatedProgress = progress.copyWith(
      moduleProgress: updatedModuleProgress,
      overallProgress: overallProgress,
      lastUpdated: DateTime.now(),
    );

    await saveUserProgress(updatedProgress);
  }

  // Tüm modüllerin listesini döndürür (statik veri)
  List<Module> getAllModules() {
    return _moduleData;
  }

  // Belirli bir modülü ID ile getirir
  Module? getModuleById(int id) {
    try {
      return _moduleData.firstWhere((module) => module.id == id);
    } catch (e) {
      return null;
    }
  }

  // Mevcut hafta modülünü döndürür
  Future<Module?> getCurrentWeekModule() async {
    final progress = await getUserProgress();
    return getModuleById(progress.currentWeek);
  }
}

// Uygulama içerisindeki tüm modül verilerini burada tanımlıyoruz
// Bu veriler rehberden aldığımız 11 haftalık planı temsil eder
final List<Module> _moduleData = [
  // Hafta 1: Dart Temelleri - Programlamanın en temel yapı taşları
  Module(
    id: 1,
    weekNumber: 1,
    title: "Dart Temelleri",
    description:
        "Programlamanın en temel yapı taşlarını Dart dilinde öğrenin. Değişkenler, veri tipleri, operatörler ve temel kontrol yapıları.",
    goals: [
      "Dart dilinin temel sözdizimini kavramak",
      "Değişkenler ve veri tiplerini öğrenmek",
      "Operatörler ve ifadeleri kullanmak",
      "Kontrol akış yapılarını (if/else, döngüler) kavramak",
      "Listeler ve Haritalar ile çalışmak",
      "Fonksiyon tanımlama ve kullanma",
    ],
    topics: [
      Topic(
        title: "Değişkenler ve Veri Tipleri",
        content:
            "Dart'ta tamsayı (int), ondalık (double), metin (String) ve mantıksal (bool) veri tiplerini öğrenin. Değişkenlerle verileri depolamayı ve Null Safety özelliğini kavrayın.",
        keyPoints: [
          "int: Tamsayı değerler (-42, 0, 123)",
          "double: Ondalık sayılar (3.14, -2.5)",
          "String: Metin verileri ('Merhaba', \"Dünya\")",
          "bool: Mantıksal değerler (true, false)",
          "var: Otomatik tip belirleme",
          "Null Safety: Değişkenler varsayılan olarak null olamaz",
        ],
      ),
      Topic(
        title: "Operatörler ve İfadeler",
        content:
            "Aritmetik, karşılaştırma ve mantıksal operatörleri kullanarak ifadeler oluşturmayı öğrenin.",
        keyPoints: [
          "Aritmetik: +, -, *, /, % (mod)",
          "Karşılaştırma: ==, !=, <, >, <=, >=",
          "Mantıksal: && (ve), || (veya), ! (değil)",
          "Atama: =, +=, -=, *=, /=",
        ],
      ),
    ],
    codeExamples: [
      CodeExample(
        title: "Değişken Tanımlama",
        code: """
void main() {
  // Farklı veri tipleri ile değişken tanımlama
  String isim = 'Ahmet';
  int yas = 25;
  double boy = 1.75;
  bool evliMi = false;
  
  // var ile otomatik tip belirleme
  var sehir = 'İstanbul';
  var puan = 85;
  
  print('İsim: \$isim, Yaş: \$yas');
  print('Boy: \$boy, Evli mi: \$evliMi');
}
""",
        explanation:
            "Bu örnek, Dart'ta farklı veri tipleri ile değişken tanımlamayı gösterir.",
      ),
      CodeExample(
        title: "Operatörler",
        code: """
void main() {
  int a = 10;
  int b = 3;
  
  // Aritmetik operatörler
  print('Toplama: \${a + b}');
  print('Çıkarma: \${a - b}');
  print('Çarpma: \${a * b}');
  print('Bölme: \${a / b}');
  print('Mod: \${a % b}');
  
  // Karşılaştırma operatörleri
  print('a > b: \${a > b}');
  print('a == b: \${a == b}');
}
""",
        explanation:
            "Dart'ta aritmetik ve karşılaştırma operatörlerinin kullanımını gösterir.",
      ),
    ],
    resources: [
      "https://dart.dev/language/variables",
      "https://dart.dev/language/operators",
    ],
    quiz: Quiz(
      moduleId: 1,
      questions: [
        Question(
          question: "Dart'ta hangi veri tipi ondalık sayıları temsil eder?",
          options: ["int", "double", "String", "bool"],
          correctAnswer: 1,
          explanation:
              "double veri tipi ondalık sayıları (3.14, -2.5 gibi) temsil eder.",
        ),
        Question(
          question: "Null Safety özelliği neyi sağlar?",
          options: [
            "Değişkenlerin hızlı çalışmasını",
            "Değişkenlerin varsayılan olarak null olmamasını",
            "Değişkenlerin otomatik silinmesini",
            "Değişkenlerin şifrelenmesini",
          ],
          correctAnswer: 1,
          explanation:
              "Null Safety, değişkenlerin varsayılan olarak null olamayacağını garanti eder, bu da olası hataları önler.",
        ),
        Question(
          question:
              "Dart'ta String interpolation (metin enterpolasyonu) nasıl yapılır?",
          options: [
            "\$değişken_adı",
            "{değişken_adı}",
            "%değişken_adı",
            "@değişken_adı",
          ],
          correctAnswer: 0,
          explanation:
              "Dart'ta String interpolation için \$ sembolü kullanılır. Örnek: 'Merhaba \$isim'",
        ),
        Question(
          question: "List (dizi) tanımlamanın doğru yolu hangisidir?",
          options: [
            "List<int> sayilar = [1, 2, 3];",
            "Array<int> sayilar = [1, 2, 3];",
            "int[] sayilar = [1, 2, 3];",
            "Vector<int> sayilar = [1, 2, 3];",
          ],
          correctAnswer: 0,
          explanation:
              "Dart'ta List<TipAdı> sözdizimi kullanılır. Örnek: List<int> sayilar = [1, 2, 3];",
        ),
        Question(
          question:
              "Aşağıdaki mantıksal operatörlerden hangisi 'VE' işlemini yapar?",
          options: ["||", "&&", "!", "=="],
          correctAnswer: 1,
          explanation:
              "&& operatörü mantıksal VE işlemini yapar. Her iki koşul da true olmalıdır.",
        ),
        Question(
          question:
              "var anahtar kelimesi ile tanımlanan değişkenin tipi ne zaman belirlenir?",
          options: [
            "Çalışma zamanında",
            "Derleme zamanında",
            "Hiçbir zaman",
            "Kullanıcı tarafından belirlenir",
          ],
          correctAnswer: 1,
          explanation:
              "var ile tanımlanan değişkenin tipi, atanan değere göre derleme zamanında belirlenir.",
        ),
      ],
    ),
  ),

  // Hafta 2: Nesne Yönelimli Programlama
  Module(
    id: 2,
    weekNumber: 2,
    title: "Nesne Yönelimli Programlama",
    description:
        "Dart'ta sınıflar, nesneler, kalıtım ve diğer OOP kavramlarını öğrenin.",
    goals: [
      "Sınıf ve nesne kavramlarını anlamak",
      "Yapıcı metotları (constructor) kullanmak",
      "Kalıtım (inheritance) prensibini kavramak",
      "Soyut sınıflar ve arayüzlerle çalışmak",
      "Mixin kullanımını öğrenmek",
    ],
    topics: [
      Topic(
        title: "Sınıflar ve Nesneler",
        content:
            "Dart'ta sınıf tanımlama ve nesneler oluşturma prensiplerini öğrenin.",
        keyPoints: [
          "class anahtar kelimesi ile sınıf tanımlama",
          "Özellikler (properties) ve yöntemler (methods)",
          "Nesne oluşturma ve kullanma",
          "this anahtar kelimesi",
        ],
      ),
    ],
    codeExamples: [
      CodeExample(
        title: "Basit Sınıf Örneği",
        code: """
class Kisi {
  String isim;
  int yas;
  
  // Constructor (yapıcı metot)
  Kisi(this.isim, this.yas);
  
  // Metot tanımlama
  void tanit() {
    print('Merhaba, ben \$isim, \$yas yaşındayım.');
  }
}

void main() {
  // Nesne oluşturma
  Kisi kisi1 = Kisi('Ali', 30);
  kisi1.tanit();
}
""",
        explanation:
            "Bu örnek, Dart'ta basit bir sınıf tanımlama ve nesne oluşturma işlemini gösterir.",
      ),
    ],
    resources: [
      "https://dart.dev/language/classes",
      "https://dart.dev/language/constructors",
    ],
    quiz: Quiz(
      moduleId: 2,
      questions: [
        Question(
          question:
              "Dart'ta sınıf tanımlamak için hangi anahtar kelime kullanılır?",
          options: ["class", "object", "struct", "interface"],
          correctAnswer: 0,
          explanation:
              "Dart'ta sınıf tanımlamak için 'class' anahtar kelimesi kullanılır.",
        ),
        Question(
          question: "Constructor (yapıcı metot) ne işe yarar?",
          options: [
            "Sınıfı siler",
            "Nesne oluşturulurken çalışır ve başlangıç değerlerini atar",
            "Sınıfın adını değiştirir",
            "Sadece private değişkenleri tanımlar",
          ],
          correctAnswer: 1,
          explanation:
              "Constructor, nesne oluşturulurken çalışır ve başlangıç değerlerini atar.",
        ),
        Question(
          question: "this anahtar kelimesi neyi ifade eder?",
          options: [
            "Üst sınıfı (parent class)",
            "Mevcut nesneyi (current object)",
            "Yeni bir nesne",
            "Statik bir değişken",
          ],
          correctAnswer: 1,
          explanation:
              "this anahtar kelimesi, mevcut nesneyi (current object) ifade eder.",
        ),
        Question(
          question:
              "Kalıtım (inheritance) için hangi anahtar kelime kullanılır?",
          options: ["implements", "extends", "with", "inherits"],
          correctAnswer: 1,
          explanation:
              "Dart'ta kalıtım için 'extends' anahtar kelimesi kullanılır.",
        ),
        Question(
          question: "Private (özel) bir değişken nasıl tanımlanır?",
          options: [
            "private int _sayi;",
            "int _sayi;",
            "protected int sayi;",
            "internal int sayi;",
          ],
          correctAnswer: 1,
          explanation:
              "Dart'ta değişken adının başına _ (underscore) konarak private yapılır.",
        ),
      ],
    ),
  ),

  // Hafta 3: Asenkron Programlama
  Module(
    id: 3,
    weekNumber: 3,
    title: "Asenkron Programlama",
    description:
        "Dart'ta Future, async/await, Stream kavramları ve asenkron programlama teknikleri.",
    goals: [
      "Future ve async/await kavramlarını anlamak",
      "Stream yapısını öğrenmek",
      "Asenkron veri işleme teknikleri",
      "Error handling (hata yönetimi)",
      "Isolate kullanımı",
      "Asenkron programlama best practices",
    ],
    topics: [
      Topic(
        title: "Future ve Async/Await",
        content:
            "Dart'ta asenkron işlemler için Future sınıfı ve async/await anahtar kelimeleri kullanımı.",
        keyPoints: [
          "Future<T> sınıfı kullanımı",
          "async fonksiyon tanımlama",
          "await ile asenkron bekleme",
          "Future.delayed() ile zamanlama",
          "Multiple Future'lar ile çalışma",
        ],
      ),
      Topic(
        title: "Stream Yapısı",
        content:
            "Sürekli veri akışları için Stream sınıfı ve StreamController kullanımı.",
        keyPoints: [
          "Stream<T> sınıfı",
          "StreamController kullanımı",
          "Listen() ile dinleme",
          "Stream transformations",
          "Broadcast streams",
        ],
      ),
    ],
    codeExamples: [
      CodeExample(
        title: "Future ve Async/Await",
        code: """
Future<String> fetchData() async {
  // 2 saniye bekle
  await Future.delayed(Duration(seconds: 2));
  return "Veri yüklendi!";
}

Future<void> main() async {
  print('Veri yükleniyor...');
  
  try {
    String sonuc = await fetchData();
    print(sonuc);
  } catch (e) {
    print('Hata: \$e');
  }
}
""",
        explanation:
            "Bu örnek, async/await kullanarak asenkron veri yükleme işlemini gösterir.",
      ),
      CodeExample(
        title: "Stream Kullanımı",
        code: """
Stream<int> sayiUret() async* {
  for (int i = 1; i <= 5; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}

void main() async {
  print('Sayılar üretiliyor...');
  
  await for (int sayi in sayiUret()) {
    print('Sayı: \$sayi');
  }
  
  print('Tamamlandı!');
}
""",
        explanation:
            "Bu örnek, Stream kullanarak sürekli veri akışı oluşturmayı gösterir.",
      ),
    ],
    resources: [
      "https://dart.dev/codelabs/async-await",
      "https://dart.dev/tutorials/language/streams",
    ],
    quiz: Quiz(
      moduleId: 3,
      questions: [
        Question(
          question: "async fonksiyon hangi veri tipini döndürür?",
          options: ["String", "Future<T>", "Stream<T>", "void"],
          correctAnswer: 1,
          explanation:
              "async fonksiyonlar her zaman Future<T> tipinde değer döndürür.",
        ),
        Question(
          question: "await anahtar kelimesi hangi durumda kullanılır?",
          options: [
            "Sadece main() fonksiyonunda",
            "Async fonksiyonlar içinde",
            "Sınıf constructor'larında",
            "Static metodlarda",
          ],
          correctAnswer: 1,
          explanation:
              "await anahtar kelimesi sadece async fonksiyonlar içinde kullanılabilir.",
        ),
        Question(
          question: "Stream'den veri okumak için hangi yöntem kullanılır?",
          options: ["read()", "get()", "listen()", "fetch()"],
          correctAnswer: 2,
          explanation:
              "Stream'den veri okumak için listen() metodu kullanılır.",
        ),
        Question(
          question: "Future.delayed() ne işe yarar?",
          options: [
            "Veri tabanı bağlantısı",
            "Belirli süre bekletme",
            "Dosya okuma",
            "Ağ isteği",
          ],
          correctAnswer: 1,
          explanation:
              "Future.delayed() belirli bir süre bekletmek için kullanılır.",
        ),
      ],
    ),
  ),

  // Hafta 4: Flutter'a Giriş
  Module(
    id: 4,
    weekNumber: 4,
    title: "Flutter'a Giriş",
    description:
        "Flutter framework'ünün temel yapısı, widget sistemi ve ilk uygulama geliştirme.",
    goals: [
      "Flutter framework'ünü anlamak",
      "Widget ağacı kavramı",
      "Stateless ve Stateful widget'lar",
      "Build metodu ve lifecycle",
      "Material Design temel kavramları",
      "İlk Flutter uygulaması geliştirmek",
    ],
    topics: [
      Topic(
        title: "Flutter Framework Temelleri",
        content: "Flutter'ın çalışma prensibi, widget tree ve render sistemi.",
        keyPoints: [
          "Widget tree kavramı",
          "Render tree ve element tree",
          "Hot reload özelliği",
          "Dart VM ve Flutter engine",
          "Platform channels",
        ],
      ),
      Topic(
        title: "Widget Yaşam Döngüsü",
        content:
            "StatelessWidget ve StatefulWidget arasındaki farklar ve lifecycle metodları.",
        keyPoints: [
          "StatelessWidget özellikleri",
          "StatefulWidget lifecycle",
          "initState() ve dispose()",
          "build() metodu",
          "setState() kullanımı",
        ],
      ),
    ],
    codeExamples: [
      CodeExample(
        title: "İlk Flutter Uygulaması",
        code: """
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Merhaba Flutter'),
      ),
      body: Center(
        child: Text(
          'Merhaba Dünya!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
""",
        explanation: "Bu kod, temel Flutter uygulama yapısını gösterir.",
      ),
      CodeExample(
        title: "StatefulWidget Örneği",
        code: """
class Sayac extends StatefulWidget {
  @override
  _SayacState createState() => _SayacState();
}

class _SayacState extends State<Sayac> {
  int _sayac = 0;

  void _sayacArttir() {
    setState(() {
      _sayac++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Sayaç: \$_sayac'),
        ElevatedButton(
          onPressed: _sayacArttir,
          child: Text('Artır'),
        ),
      ],
    );
  }
}
""",
        explanation:
            "Bu örnek, StatefulWidget ile durumlu widget oluşturmayı gösterir.",
      ),
    ],
    resources: [
      "https://flutter.dev/docs/development/ui/widgets-intro",
      "https://flutter.dev/docs/development/ui/widgets",
    ],
    quiz: Quiz(
      moduleId: 4,
      questions: [
        Question(
          question: "Flutter'da her şey nedir?",
          options: ["Class", "Widget", "Function", "Object"],
          correctAnswer: 1,
          explanation:
              "Flutter'da her şey widget'tır. UI elemanları, layout'lar, hepsi widget.",
        ),
        Question(
          question: "StatelessWidget ne zaman kullanılır?",
          options: [
            "Durum değişikliği olmayan widget'lar için",
            "Animasyonlar için",
            "Sadece text göstermek için",
            "Database işlemleri için",
          ],
          correctAnswer: 0,
          explanation:
              "StatelessWidget, durum değişikliği olmayan widget'lar için kullanılır.",
        ),
        Question(
          question: "setState() metodunun amacı nedir?",
          options: [
            "Widget'ı yeniden oluşturmak",
            "Durum değişikliğini bildirmek",
            "Animation başlatmak",
            "Memory temizleme",
          ],
          correctAnswer: 1,
          explanation:
              "setState() durum değişikliğini bildirir ve widget'ın yeniden çizilmesini sağlar.",
        ),
        Question(
          question: "Flutter'da hot reload ne işe yarar?",
          options: [
            "Uygulamayı yeniden başlatır",
            "Kodu değiştirmeden çalıştırır",
            "Değişiklikleri anında gösterir",
            "Sadece debug modunda çalışır",
          ],
          correctAnswer: 2,
          explanation:
              "Hot reload, kod değişikliklerini uygulamayı yeniden başlatmadan anında gösterir.",
        ),
      ],
    ),
  ),

  // Hafta 5: Temel Widget'lar
  Module(
    id: 5,
    weekNumber: 5,
    title: "Temel Widget'lar",
    description:
        "Flutter'da en çok kullanılan widget'lar ve layout sistemleri.",
    goals: [
      "Text, Container, Row, Column widget'ları",
      "Layout sistemini anlamak",
      "Padding, Margin kavramları",
      "Flex ve Expanded kullanımı",
      "Decoration ve styling",
      "Responsive design temelleri",
    ],
    topics: [
      Topic(
        title: "Layout Widget'ları",
        content: "Row, Column, Container, Padding ve diğer layout widget'ları.",
        keyPoints: [
          "Row ve Column kullanımı",
          "MainAxis ve CrossAxis",
          "Container özellikleri",
          "Padding ve Margin",
          "Expanded ve Flexible",
        ],
      ),
      Topic(
        title: "Styling ve Decoration",
        content:
            "Widget'ları şekillendirme, renklendirme ve dekorasyon teknikleri.",
        keyPoints: [
          "BoxDecoration kullanımı",
          "BorderRadius ve Border",
          "Gradient efektleri",
          "Shadow (gölge) ekleme",
          "Color ve Theme kullanımı",
        ],
      ),
    ],
    codeExamples: [
      CodeExample(
        title: "Layout Widget'ları",
        code: """
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Merhaba Flutter!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      ),
    ),
    SizedBox(height: 20),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Container(
            height: 50,
            color: Colors.red,
            child: Center(child: Text('1')),
          ),
        ),
        Expanded(
          child: Container(
            height: 50,
            color: Colors.green,
            child: Center(child: Text('2')),
          ),
        ),
      ],
    ),
  ],
)
""",
        explanation:
            "Bu örnek, temel layout widget'larının kullanımını gösterir.",
      ),
      CodeExample(
        title: "Decoration ve Styling",
        code: """
Container(
  width: 200,
  height: 100,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue, Colors.purple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(15),
    boxShadow: [
      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.5),
        spreadRadius: 2,
        blurRadius: 5,
        offset: Offset(0, 3),
      ),
    ],
  ),
  child: Center(
    child: Text(
      'Styled Container',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    ),
  ),
)
""",
        explanation:
            "Bu örnek, Container widget'ının decoration özelliklerini gösterir.",
      ),
    ],
    resources: [
      "https://flutter.dev/docs/development/ui/widgets/layout",
      "https://flutter.dev/docs/cookbook/design/themes",
    ],
    quiz: Quiz(
      moduleId: 5,
      questions: [
        Question(
          question: "Row widget'ında çocuk widget'lar hangi yönde sıralanır?",
          options: ["Dikey", "Yatay", "Diagonal", "Rastgele"],
          correctAnswer: 1,
          explanation:
              "Row widget'ında çocuk widget'lar yatay (horizontal) yönde sıralanır.",
        ),
        Question(
          question: "Column widget'ında MainAxisAlignment.center ne yapar?",
          options: [
            "Yatay ortalar",
            "Dikey ortalar",
            "Köşelere yerleştirir",
            "Eşit dağıtır",
          ],
          correctAnswer: 1,
          explanation:
              "Column'da MainAxisAlignment.center, widget'ları dikey olarak ortalar.",
        ),
        Question(
          question: "Expanded widget'ının amacı nedir?",
          options: [
            "Widget'ı büyütmek",
            "Boş alanı eşit paylaştırmak",
            "Animation eklemek",
            "Renk değiştirmek",
          ],
          correctAnswer: 1,
          explanation:
              "Expanded, mevcut boş alanı child widget'lar arasında paylaştırır.",
        ),
        Question(
          question: "Container widget'ında padding ve margin farkı nedir?",
          options: [
            "Aynı şey",
            "Padding içeride, margin dışarıda",
            "Padding dışarıda, margin içeride",
            "Sadece renk farkı",
          ],
          correctAnswer: 1,
          explanation:
              "Padding container içindeki boşluk, margin dışındaki boşluktur.",
        ),
      ],
    ),
  ),

  // Hafta 6: State Management
  Module(
    id: 6,
    weekNumber: 6,
    title: "State Management",
    description:
        "Flutter'da durum yönetimi teknikleri, Provider, Riverpod, Bloc pattern.",
    goals: [
      "State management kavramını anlamak",
      "Provider kullanımı",
      "ChangeNotifier pattern",
      "Consumer ve Selector kullanımı",
      "Global state management",
      "Best practices",
    ],
    topics: [
      Topic(
        title: "Provider Pattern",
        content: "Provider paketi ile state management.",
        keyPoints: [
          "Provider kurulum",
          "ChangeNotifier sınıfı",
          "Consumer widget",
          "Provider.of() kullanımı",
          "MultiProvider",
        ],
      ),
    ],
    codeExamples: [
      CodeExample(
        title: "Provider ile Counter",
        code: """
class CounterProvider extends ChangeNotifier {
  int _count = 0;
  
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners();
  }
}

// Widget'ta kullanım
Consumer<CounterProvider>(
  builder: (context, counter, child) {
    return Text('Sayaç: \${counter.count}');
  },
)
""",
        explanation: "Provider ile state management örneği.",
      ),
    ],
    resources: ["https://pub.dev/packages/provider"],
    quiz: Quiz(
      moduleId: 6,
      questions: [
        Question(
          question: "Provider pattern'in amacı nedir?",
          options: [
            "Widget styling",
            "State management",
            "Routing",
            "Animation",
          ],
          correctAnswer: 1,
          explanation: "Provider pattern, state management için kullanılır.",
        ),
        Question(
          question:
              "ChangeNotifier sınıfında değişiklik bildirimini hangi metod yapar?",
          options: ["notify()", "notifyListeners()", "update()", "refresh()"],
          correctAnswer: 1,
          explanation:
              "ChangeNotifier sınıfında notifyListeners() metodu değişiklik bildirimini yapar.",
        ),
        Question(
          question: "Consumer widget'ının amacı nedir?",
          options: [
            "Veri üretmek",
            "Widget'ı yeniden inşa etmek",
            "State değişikliklerini dinlemek",
            "Animasyon yapmak",
          ],
          correctAnswer: 2,
          explanation:
              "Consumer widget, state değişikliklerini dinleyerek widget'ı yeniden inşa eder.",
        ),
      ],
    ),
  ),

  // Hafta 7: Navigasyon
  Module(
    id: 7,
    weekNumber: 7,
    title: "Navigasyon",
    description: "Flutter'da sayfalar arası geçiş, routing ve navigation.",
    goals: [
      "Navigator sınıfı",
      "Route tanımlama",
      "Named routes",
      "Veri aktarımı",
      "Bottom navigation",
      "Drawer widget",
    ],
    topics: [
      Topic(
        title: "Basic Navigation",
        content: "Navigator.push ve Navigator.pop kullanımı.",
        keyPoints: [
          "Navigator.push()",
          "Navigator.pop()",
          "MaterialPageRoute",
          "Veri gönderme",
          "Geri dönüş değeri",
        ],
      ),
    ],
    codeExamples: [
      CodeExample(
        title: "Basic Navigation",
        code: """
// Yeni sayfaya git
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SecondPage(),
  ),
);

// Geri dön
Navigator.pop(context);
""",
        explanation: "Temel navigasyon işlemleri.",
      ),
    ],
    resources: ["https://flutter.dev/docs/cookbook/navigation"],
    quiz: Quiz(
      moduleId: 7,
      questions: [
        Question(
          question: "Navigator.push() ne yapar?",
          options: [
            "Sayfa kapatır",
            "Yeni sayfa açar",
            "Veri gönderir",
            "Widget oluşturur",
          ],
          correctAnswer: 1,
          explanation: "Navigator.push() yeni bir sayfa açar.",
        ),
      ],
    ),
  ),

  // Hafta 8: HTTP İletişimi
  Module(
    id: 8,
    weekNumber: 8,
    title: "HTTP İletişimi",
    description:
        "REST API'ler ile iletişim, JSON işleme, http paket kullanımı.",
    goals: [
      "HTTP istekleri (GET, POST, PUT, DELETE)",
      "JSON parse etme",
      "Future ile async işlemler",
      "Error handling",
      "API entegrasyonu",
      "Model sınıfları",
    ],
    topics: [
      Topic(
        title: "HTTP Requests",
        content: "http paketi ile API istekleri.",
        keyPoints: [
          "GET request",
          "POST request",
          "JSON decode/encode",
          "Error handling",
          "Headers kullanımı",
        ],
      ),
    ],
    codeExamples: [
      CodeExample(
        title: "HTTP GET Request",
        code: """
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> fetchUser() async {
  final response = await http.get(
    Uri.parse('https://jsonplaceholder.typicode.com/users/1'),
  );
  
  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load user');
  }
}
""",
        explanation: "HTTP GET request örneği.",
      ),
    ],
    resources: ["https://pub.dev/packages/http"],
    quiz: Quiz(
      moduleId: 8,
      questions: [
        Question(
          question: "HTTP GET request hangi amaçla kullanılır?",
          options: [
            "Veri silme",
            "Veri güncelleme",
            "Veri getirme",
            "Veri ekleme",
          ],
          correctAnswer: 2,
          explanation: "HTTP GET request veri getirmek için kullanılır.",
        ),
      ],
    ),
  ),

  // Hafta 9: Yerel Depolama
  Module(
    id: 9,
    weekNumber: 9,
    title: "Yerel Depolama",
    description: "SharedPreferences, SQLite, Hive ile yerel veri saklama.",
    goals: [
      "SharedPreferences kullanımı",
      "SQLite database",
      "Hive NoSQL database",
      "File system işlemleri",
      "Secure storage",
      "Veri senkronizasyonu",
    ],
    topics: [
      Topic(
        title: "SharedPreferences",
        content: "Basit key-value çiftleri saklama.",
        keyPoints: [
          "SharedPreferences kurulumu",
          "String, int, bool kaydetme",
          "Veri okuma",
          "Veri silme",
          "Async işlemler",
        ],
      ),
    ],
    codeExamples: [
      CodeExample(
        title: "SharedPreferences Kullanımı",
        code: """
// Veri kaydetme
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setString('username', 'John');
await prefs.setInt('score', 100);

// Veri okuma
String? username = prefs.getString('username');
int? score = prefs.getInt('score');
""",
        explanation: "SharedPreferences ile veri saklama.",
      ),
    ],
    resources: ["https://pub.dev/packages/shared_preferences"],
    quiz: Quiz(
      moduleId: 9,
      questions: [
        Question(
          question: "SharedPreferences ne tür verileri saklar?",
          options: [
            "Sadece String",
            "Sadece int",
            "Basit key-value çiftleri",
            "Kompleks objeler",
          ],
          correctAnswer: 2,
          explanation: "SharedPreferences basit key-value çiftlerini saklar.",
        ),
      ],
    ),
  ),

  // Hafta 10: İleri Seviye Konular
  Module(
    id: 10,
    weekNumber: 10,
    title: "İleri Seviye Konular",
    description: "Custom widgets, animations, performance optimization.",
    goals: [
      "Custom widget geliştirme",
      "Animation sistemi",
      "Performance optimization",
      "Custom painters",
      "Platform channels",
      "Best practices",
    ],
    topics: [
      Topic(
        title: "Custom Widgets",
        content: "Kendi widget'larınızı oluşturma.",
        keyPoints: [
          "StatelessWidget extend etme",
          "StatefulWidget extend etme",
          "Widget parametreleri",
          "Callback fonksiyonları",
          "Widget composition",
        ],
      ),
    ],
    codeExamples: [
      CodeExample(
        title: "Custom Widget",
        code: """
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  
  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.color = Colors.blue,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(text),
    );
  }
}
""",
        explanation: "Custom widget oluşturma örneği.",
      ),
    ],
    resources: ["https://flutter.dev/docs/development/ui/widgets/custom"],
    quiz: Quiz(
      moduleId: 10,
      questions: [
        Question(
          question: "Custom widget oluşturmanın avantajı nedir?",
          options: [
            "Hız artışı",
            "Kod tekrarını azaltma",
            "Daha az memory",
            "Daha az CPU",
          ],
          correctAnswer: 1,
          explanation:
              "Custom widget kod tekrarını azaltır ve yeniden kullanılabilirlik sağlar.",
        ),
      ],
    ),
  ),

  // Hafta 11: Test ve Yayınlama
  Module(
    id: 11,
    weekNumber: 11,
    title: "Test ve Yayınlama",
    description: "Unit testing, widget testing, uygulama yayınlama süreci.",
    goals: [
      "Unit test yazma",
      "Widget test",
      "Integration test",
      "Test coverage",
      "APK oluşturma",
      "Play Store yayınlama",
    ],
    topics: [
      Topic(
        title: "Testing",
        content: "Flutter'da test yazma teknikleri.",
        keyPoints: [
          "Unit test",
          "Widget test",
          "Integration test",
          "Mock kullanımı",
          "Test coverage",
        ],
      ),
    ],
    codeExamples: [
      CodeExample(
        title: "Unit Test",
        code: """
import 'package:flutter_test/flutter_test.dart';

int add(int a, int b) {
  return a + b;
}

void main() {
  group('Calculator tests', () {
    test('Addition test', () {
      expect(add(2, 3), 5);
      expect(add(-1, 1), 0);
      expect(add(0, 0), 0);
    });
  });
}
""",
        explanation: "Unit test örneği.",
      ),
    ],
    resources: ["https://flutter.dev/docs/testing"],
    quiz: Quiz(
      moduleId: 11,
      questions: [
        Question(
          question: "Unit test neyi test eder?",
          options: [
            "Tüm uygulamayı",
            "Tek bir fonksiyonu",
            "UI elemanlarını",
            "Veritabanını",
          ],
          correctAnswer: 1,
          explanation: "Unit test tek bir fonksiyon veya metodu test eder.",
        ),
      ],
    ),
  ),
];
