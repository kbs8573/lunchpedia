import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //세로고정 기능을 위한 package

import 'package:lunchpedia/myfavorite.dart' as myfavorite;
import 'package:lunchpedia/result.dart' as result;
import 'package:lunchpedia/style.dart' as style;
import 'package:lunchpedia/login.dart' as login;
import 'package:url_launcher/url_launcher.dart';
import 'createStore.dart';
//import 'data.dart' as data;

import 'firebase_options.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'dart:math';

var toggle = 0; //검색 타입 토글
var tabIdx = 0; //탭 인덱스
var keyword = TextEditingController();
var exit;
var loginState; //로그인 상태

final timeList = ['간식', '식사', '주류']..sort();
final categoryList = [
  '한식',
  '일식',
  '중식',
  '분식',
  '양식',
  '멕시코',
  '베트남/태국',
  '아시아퓨전',
  '퓨전한식',
  '샤브샤브',
  '삼계탕',
  '스페인',
  '카페'
]..sort();
var type;
var category;

var totalStoreCnt;
var randomStore;
var loading;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp(
    theme: style.theme,
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //전체 store갯수 카운팅 함수
  getTotalCntOfStore() async {
    //print('get total count');
    var results = await result.firestore
        .collection('storeCollection')
        .get()
        .then((value) => {totalStoreCnt = value.size});
  }

  //random으로 스토어 1개를 가져오는 함수
  getRandomStore() async {
    setState(() {
      loading = true;
    });
    //print('totalCnt = ${totalStoreCnt}');
    //Display = 'N' 인 스토어카드가 나올 시, 재수행
    var retry = 'Y';
    while (retry == 'Y') {
      var randomNum = Random().nextInt(totalStoreCnt) + 1;
      randomStore = await result.firestore
          .collection('storeCollection')
          .doc('ST${randomNum}')
          .get();

      if (randomStore['display'] == 'Y') {
        retry = 'N';
        setState(() {
          loading = false;
        });
      }
      //print('randomStore = ${randomStore['name']}');
    }
  }

  @override
  initState() {
    //화면 세로고정
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    //로그인 여부 확인
    if (login.auth.currentUser?.uid == null) {
      // //print('로그인 안된 상태');
      loginState = false;
    } else {
      loginState = true;
      //  //print('로그인 중, displayName=${auth.currentUser?.displayName.toString()}');
      //  //print('로그인 중, uid=${auth.currentUser?.uid.toString()}');
    }
    //초기값세팅
    setState(() {
      result.type == '' ? type = '식사' : type = result.type;
      result.category == '' ? category = '한식' : category = result.category;
    });
    //print("init state, type=${type}, category=${category}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xffd61c4e),
        child: Icon(Icons.add_business),
        onPressed: () async {
          //로그인이 되어있지 않을경우, 로그인 페이지로 이동한다.
          if (loginState == false) {
            await showDialog(
                context: context,
                builder: (context) => login.PopupPage(
                    popupTitle: '매장 추천하기',
                    message: '로그인이 필요한 서비스입니다. 로그인 페이지로 이동합니다.'));
            setState(() {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => login.Login()));
            });
          } else {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => CreateStore()));
          }
        },
      ),
      appBar: AppBar(
          //backgroundColor: Color(0xfff77e21),
          actionsIconTheme: IconThemeData(color: Colors.black),
          title: Text(
            '점심백과사전(강남역)',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => loginState == true
                              ? myfavorite.Result()
                              : login.Login()));
                },
                child: loginState == false
                    ? Text(
                        '로그인',
                        style: TextStyle(color: Colors.black),
                      )
                    : Icon(
                        Icons.account_circle,
                        color: Colors.black,
                      ))
          ]),
      body: [
        Search(),
        RandomChioce(
            getTotalCntOfStore: getTotalCntOfStore,
            getRandomStore: getRandomStore)
      ][tabIdx],
      //bottomNavigationBar 으로 tab 전환 시, 불필요한 검색 request 가 많이 발생할 거 같아, 상단 AppBar > leading의 IconButton 으로 처리함.
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          //BottomNavigationBarItem(icon: Icon(Icons.update), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(
            icon: Icon(Icons.casino_outlined),
            label: '랜덤 Pick',
          ),
        ],
        currentIndex: tabIdx,
        onTap: (i) {
          setState(() {
            tabIdx = i;
            if (i == 1) {
              loading = true;
            }
          });
        },
      ),
    );
  }
}

class Search extends StatefulWidget {
  const Search({Key? key}) : super(key: key);

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Color(0xfffef9a7),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(0, 20, 0, 120),
              child: ToggleSwitch(
                minWidth: 80.0,
                minHeight: 30.0,
                initialLabelIndex: toggle,
                cornerRadius: 20.0,
                activeFgColor: Colors.white,
                inactiveBgColor: Colors.grey,
                inactiveFgColor: Colors.white,
                totalSwitches: 3,
                labels: ['출구별', '유형별', '상호명'],
                activeBgColors: [
                  [Color(0xffd61c4e)],
                  [Color(0xffd61c4e)],
                  [Color(0xffd61c4e)]
                ],
                onToggle: (index) {
                  //   //print('switched to: $index');
                  setState(() {
                    toggle = index!;
                  });
                },
              ),
            ),
            [
              Container(
                child: Text(
                  '지하철 출구별 검색',
                  style: TextStyle(
                    fontSize: 30,
                    color: Color(0xffd61c4e),
                  ),
                ),
                margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
              ),
              Container(
                child: Text(
                  '',
                  style: TextStyle(fontSize: 30),
                ),
                margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
              ),
              Container(
                child: Text(
                  '',
                  style: TextStyle(fontSize: 30),
                ),
                margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
              ),
            ][toggle],
            [
              ExitSearch(),
              Container(
                child: SelectBoxes(),
                margin: EdgeInsets.fromLTRB(100, 0, 0, 0),
              ),
              InputBoxes(),
            ][toggle],
            toggle == 0
                ? Text('')
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: Size(193, 40), primary: Color(0xfff77e21)),
                    child: Text(
                      toggle == 1 ? '어디로 가야하지?' : '상호명 검색',
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    })
          ],
        ));
  }
}

//유형별 검색화면
class SelectBoxes extends StatefulWidget {
  const SelectBoxes({Key? key}) : super(key: key);

  @override
  State<SelectBoxes> createState() => _SelectBoxesState();
}

class _SelectBoxesState extends State<SelectBoxes> {
  @override
  Widget build(BuildContext context) {
    return Container(
      //margin: EdgeInsets.fromLTRB(80, 0, 0, 0),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 100,
                child: DropdownButton(
                  isExpanded: true,
                  value: type,
                  items: timeList.map((item) {
                    return DropdownMenuItem(
                      child: Center(child: Text(item)),
                      value: item,
                    );
                  }).toList(),
                  onChanged: (item) {
                    setState(() {
                      type = item.toString();
                    });
                    type = item.toString();
                  },
                ),
              ),
              Text('(으)로',
                  style: TextStyle(
                      color: Color(0xffd61c4e), fontWeight: FontWeight.bold))
            ],
          ),
          Row(
            children: [
              Container(
                width: 120,
                child: DropdownButton(
                  isExpanded: true,
                  value: category,
                  items: categoryList.map((item) {
                    return DropdownMenuItem(
                      child: Center(child: Text(item)),
                      value: item,
                    );
                  }).toList(),
                  onChanged: (item) {
                    setState(() {
                      category = item.toString();
                    });
                    category = item.toString();
                  },
                ),
              ),
              Text(
                '이 먹고싶을 땐,',
                style: TextStyle(
                    color: Color(0xffd61c4e), fontWeight: FontWeight.bold),
              )
            ],
          ),
        ],
      ),
    );
  }
}

//상호명 검색화면
class InputBoxes extends StatefulWidget {
  const InputBoxes({Key? key}) : super(key: key);

  @override
  State<InputBoxes> createState() => _InputBoxesState();
}

class _InputBoxesState extends State<InputBoxes> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(80, 0, 80, 30),
      child: TextField(
        decoration: InputDecoration(
          labelText: '상호명',
          hintText: '상호명을 입력하세요',
          labelStyle: TextStyle(color: Color(0xfff77e21)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(width: 1, color: Color(0xfff77e21)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            borderSide: BorderSide(width: 1, color: Color(0xfff77e21)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
        ),
        keyboardType: TextInputType.text,
        controller: keyword,
      ),
    );
  }
}

//출구검색 화면
class ExitSearch extends StatefulWidget {
  const ExitSearch({Key? key}) : super(key: key);

  @override
  State<ExitSearch> createState() => _ExitSearchState();
}

class _ExitSearchState extends State<ExitSearch> {
  @override
  Widget build(BuildContext context) {
    var circleWidth = 80.0;
    return Container(
      //color: Color(0xfff77e21),
      margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: new BoxDecoration(
          color: Color(0xfff77e21), //new Color.fromRGBO(255, 0, 0, 0.0),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(0, 20, 0, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                    child: Image.asset('assets/1.png', width: circleWidth),
                    onTap: () {
                      //출구번호 세팅
                      setState(() {
                        exit = 1;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    }),
                InkWell(
                    child: Image.asset('assets/2.png', width: circleWidth),
                    onTap: () {
                      //출구번호 세팅
                      setState(() {
                        exit = 2;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    }),
                InkWell(
                    child: Image.asset('assets/3.png', width: circleWidth),
                    onTap: () {
                      //출구번호 세팅
                      setState(() {
                        exit = 3;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    }),
                InkWell(
                    child: Image.asset('assets/4.png', width: circleWidth),
                    onTap: () {
                      //출구번호 세팅
                      setState(() {
                        exit = 4;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    }),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                    child: Image.asset('assets/5.png', width: circleWidth),
                    onTap: () {
                      //출구번호 세팅
                      setState(() {
                        exit = 5;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    }),
                InkWell(
                    child: Image.asset('assets/6.png', width: circleWidth),
                    onTap: () {
                      //출구번호 세팅
                      setState(() {
                        exit = 6;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    }),
                InkWell(
                    child: Image.asset('assets/7.png', width: circleWidth),
                    onTap: () {
                      //출구번호 세팅
                      setState(() {
                        exit = 7;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    }),
                InkWell(
                    child: Image.asset('assets/8.png', width: circleWidth),
                    onTap: () {
                      //출구번호 세팅
                      setState(() {
                        exit = 8;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    }),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(0, 10, 0, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                    child: Image.asset('assets/9.png', width: circleWidth),
                    onTap: () {
                      //출구번호 세팅
                      setState(() {
                        exit = 9;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    }),
                InkWell(
                    child: Image.asset('assets/10.png', width: circleWidth),
                    onTap: () {
                      //출구번호 세팅
                      setState(() {
                        exit = 10;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    }),
                InkWell(
                    child: Image.asset('assets/11.png', width: circleWidth),
                    onTap: () {
                      //출구번호 세팅
                      setState(() {
                        exit = 11;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    }),
                InkWell(
                    child: Image.asset('assets/12.png', width: circleWidth),
                    onTap: () {
                      //출구번호 세팅
                      setState(() {
                        exit = 12;
                      });
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => result.Result()));
                    }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Today extends StatelessWidget {
  const Today({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text("Today");
  }
}

class RandomChioce extends StatefulWidget {
  const RandomChioce({Key? key, this.getTotalCntOfStore, this.getRandomStore})
      : super(key: key);
  final getTotalCntOfStore;
  final getRandomStore;

  @override
  State<RandomChioce> createState() => _RandomChioceState();
}

class _RandomChioceState extends State<RandomChioce> {
  var fontSize = 17.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xfffef9a7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          loading == true
              ? Image.asset(
                  'assets/animation-500-l4uvsbmd-unscreen.gif') //룰렛 이미지 gif
              : SingleChildScrollView(
                child: Container(
                    margin: EdgeInsets.fromLTRB(45, 0, 45, 10),
                    padding: EdgeInsets.fromLTRB(0, 30, 0, 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30), //모서리를 둥글게
                        border:
                            Border.all(color: Colors.black12, width: 3)), //테두리
                    child: Column(
                      children: [
                        Text(
                          randomStore['name'],
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          height: 100,
                          child:
                              result.FlagImage(category: randomStore['category']),
                        ),
                        Container(
                          margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
                          child: Container(
                            width: 200,
                            //margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '・ ${randomStore['category']}',
                                  style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '・ 가까운 출구 : ${randomStore["exit"]}번',
                                  style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  '・ 출구에서 도보 ${randomStore['distance']}분',
                                  style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 5),
                                favorite == ''
                                    ? randomStore['remarks'] == ''
                                        ? Text('')
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '・ 특이사항 :',
                                                style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              Container(
                                                margin: EdgeInsets.fromLTRB(
                                                    10, 0, 0, 0),
                                                child: Text(
                                                    '${randomStore['remarks']}',
                                                    style: TextStyle(
                                                        fontSize: fontSize)),
                                              )
                                            ],
                                          )
                                    : randomStore['remarks'] == ''
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '・ 꼭 주문하기 :',
                                                style: TextStyle(
                                                    color: Color(0xffd61c4e),
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              Container(
                                                margin: EdgeInsets.fromLTRB(
                                                    10, 0, 0, 10),
                                                child: Text(
                                                    randomStore['favorite'],
                                                    style: TextStyle(
                                                        fontSize: fontSize)),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '・ 꼭 주문하기 :',
                                                style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold),
                                              ),
                                              Container(
                                                margin: EdgeInsets.fromLTRB(
                                                    10, 0, 0, 10),
                                                child: Text(
                                                    '${randomStore['favorite']}',
                                                    style: TextStyle(
                                                        fontSize: fontSize)),
                                              ),
                                              Text('・ 특이사항 :',
                                                  style: TextStyle(
                                                      fontSize: fontSize,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              Container(
                                                margin: EdgeInsets.fromLTRB(
                                                    10, 0, 0, 0),
                                                child: Text(
                                                    '${randomStore['remarks']}',
                                                    style: TextStyle(
                                                        fontSize: fontSize)),
                                              )
                                            ],
                                          )
                              ],
                            ),
                          ),
                        ),
                        Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('좋아요 ${randomStore['likes']}개'),
                              IconButton(
                                onPressed: () async {
                                  final Uri url = Uri.parse(
                                      'nmap://search?query=${randomStore['name']}&appname=com.kbs.lunchpedia'); //네이버지도앱으로 연결
                                  try {
                                    await launchUrl(url);
                                  } catch (e) {
                                    await launchUrl(Uri.parse(
                                        'market://details?id=com.nhn.android.nmap')); //네이버지도앱 검색하여 마켓으로 연결
                                  }
                                },
                                icon: Icon(Icons.room),
                                color: Colors.green,
                              )
                            ],
                          ),
                        ),

                      ],
                    ),
                  ),
              ),
          SizedBox(height: 20,),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                //print('loading=${loading}');
                if (loading == true) {
                  await widget.getTotalCntOfStore();
                }
                widget.getRandomStore();
              },
              child: Text('랜덤 Pick'),
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(193, 40), primary: Color(0xfff77e21)),
            ),
          )
        ],
      ),
    );
  }
}
