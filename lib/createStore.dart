import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'login.dart' as login;
import 'main.dart' as main;
import 'style.dart' as style;
import 'result.dart' as result;
import 'myfavorite.dart' as mypage;


//storeList 등록 함수 (다른 페이지에서 호출할 수 있도록 전역함수로 정의.)
addStore(type, category, exit, distance, name, favorite, remarks, likes,
    storeCd, register, likepeople, createDate) async {
  await result.firestore.collection('storeCollection').doc(storeCd).set({
    "type": type,
    "category": category,
    "exit": exit,
    "distance": distance,
    "name": name,
    "favorite": favorite,
    "remarks": remarks,
    "likes": likes,
    "storeCd": storeCd,
    "register": register,
    "likepeople": likepeople,
    "createDate": int.parse(createDate),
    "display": "Y",
    "reason":"",
    "keyword": []
  });
}


//입력값을 담을 변수선언
var type;
var category;
var exit;
var storeCd;

var distance = TextEditingController();
var storeName = TextEditingController();
var favorite = TextEditingController();
var remarks = TextEditingController();

class CreateStore extends StatefulWidget {
  const CreateStore({Key? key}) : super(key: key);

  @override
  State<CreateStore> createState() => _CreateStoreState();
}

class _CreateStoreState extends State<CreateStore> {
  //로그아웃 함수
  logout() async {
    await login.auth.signOut();
    await showDialog(
        context: context,
        builder: (context) =>
            login.PopupPage(popupTitle: '로그아웃', message: '다음에 또 방문해 주세요.'));
    setState(() {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => login.Login()));
    });
  }

  //신규 storeCode 생성함수
  var storeCodeList = []; //storeCd 리스트
  var storeNameList = []; //storeName 리스트 => 등록시 중복체크하기 위해

  getCreateStoreCd() async {
    var results = await result.firestore.collection('storeCollection').get();
    for (var doc in results.docs) {
      storeCodeList
          .add(int.parse(doc['storeCd'].toString().replaceAll('ST', '')));
      storeNameList.add(doc['name']);
    }
    storeCodeList..sort();
    storeCd = 'ST' + (storeCodeList[storeCodeList.length - 1] + 1).toString();
  }

  @override
  void initState() {
    // TODO: implement initState
    //컨텐츠 유해성 경고 팝업칭
    SchedulerBinding.instance.addPostFrameCallback((_) => showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) {
          return WarningPopup();
        }));


    getCreateStoreCd();

    type;
    category;
    exit;
    storeName.text = ''; //textfeild의 default 값과, input값을 수정하였을 때 변화를 처리하기 위한 변수
    distance.text = ''.toString();
    favorite.text ='';
    remarks.text = '';
    //print('storeCd = ${storeCd}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: style.myPageTheme,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            '매장 추천하기',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  logout();
                },
                child: Text('로그아웃', style: TextStyle(color: Colors.white)))
          ],
          leading: IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => main.MyApp()));
              }),
        ),
        body: Container(
          color: Color(0xfffef9a7),
          child: Center(
            child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Column(
                  //mainAxisAlignment: MainAxisAlignment.center,
                  //crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectBoxes(),
                    Row(
                      children: [
                        SizedBox(
                          width: 230,
                          height: 40,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: '상호명',
                              labelStyle: TextStyle(color: Color(0xffd61c4e)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                                borderSide:
                                    BorderSide(width: 1, color: Color(0xffd61c4e)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                                borderSide:
                                    BorderSide(width: 1, color: Color(0xffd61c4e)),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                              ),
                            ),
                            keyboardType: TextInputType.text,
                            controller: storeName,
                            /*onChanged: (text){
                              setState((){
                                storeName..text = text;
                                storeName..selection = TextSelection.fromPosition(TextPosition(offset: text.length));
                              });
                            },*/
                          ),
                        ),
                        SizedBox(
                          width: 7,
                        ),
                        Text('(을)를 추천합니다.',
                            style: TextStyle(
                                color: Color(0xffd61c4e),
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Row(
                      children: [
                        Text('가까운 출구는 강남역',
                            style: TextStyle(
                                color: Color(0xffd61c4e),
                                fontWeight: FontWeight.bold)),
                        Container(width: 100, child: ExitDropdown()),
                        Text('번 출구입니다.',
                            style: TextStyle(
                                color: Color(0xffd61c4e),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        Text('출구에서 걸어서',
                            style: TextStyle(
                                color: Color(0xffd61c4e),
                                fontWeight: FontWeight.bold)),
                        Icon(
                          Icons.directions_walk,
                          color: Colors.green,
                        ),
                        SizedBox(
                          width: 60,
                          height: 40,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: '(분)',
                              labelStyle: TextStyle(color: Color(0xffd61c4e)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                                borderSide:
                                    BorderSide(width: 1, color: Color(0xffd61c4e)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                                borderSide:
                                    BorderSide(width: 1, color: Color(0xffd61c4e)),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                              ),
                            ),
                            keyboardType: TextInputType.text,
                            controller: distance,
                           /* onChanged: (text){
                              setState((){
                                distance..text = text;
                                distance..selection = TextSelection.fromPosition(TextPosition(offset: text.length));
                              });
                            },*/
                          ),
                        ),
                        SizedBox(
                          width: 7,
                        ),
                        Text('분 정도 걸려요.',
                            style: TextStyle(
                                color: Color(0xffd61c4e),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),

                    SizedBox(
                      height: 30,
                    ),
                    TextFormField(
                      minLines: 3, // any number you need (It works as the rows for the textarea)
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                        labelText: '꼭 주문하기!',
                        labelStyle: TextStyle(color: Color(0xffd61c4e)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(10.0)),
                          borderSide:
                          BorderSide(width: 1, color: Color(0xffd61c4e)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(10.0)),
                          borderSide:
                          BorderSide(width: 1, color: Color(0xffd61c4e)),
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(10.0)),
                        ),
                      ),
                      //keyboardType: TextInputType.text,
                      controller: favorite,
                      /*onChanged: (text){
                        setState((){
                          favorite..text = text;
                          favorite..selection = TextSelection.fromPosition(TextPosition(offset: text.length));
                        });
                      },*/
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    TextFormField(
                      minLines: 3, // any number you need (It works as the rows for the textarea)
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      decoration: InputDecoration(
                        labelText: '특이사항',
                        labelStyle: TextStyle(color: Color(0xffd61c4e)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(10.0)),
                          borderSide:
                          BorderSide(width: 1, color: Color(0xffd61c4e)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(10.0)),
                          borderSide:
                          BorderSide(width: 1, color: Color(0xffd61c4e)),
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(10.0)),
                        ),
                      ),
                      //keyboardType: TextInputType.text,
                      controller: remarks,
                      /*onChanged: (text){
                        setState((){
                          remarks..text = text;
                          remarks..selection = TextSelection.fromPosition(TextPosition(offset: text.length));
                        });
                      },*/
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Center(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              minimumSize: Size(200, 40), primary: Color(0xffd61c4e)),
                          child: Text(
                            '등록하기',
                            style: TextStyle(
                                color: Color(0xfffef9a7),
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            //print('type=${type}, category=${category}, 상호명=${storeName.text}, 출구=${exit}, 거리=${distance.text}, 추천메뉴=${favorite.text}, 특이사항=${remarks.text}, storeCd=${storeCd}');
                            //입력값 체크
                            //부적절한 언어 사용체크
                            var contentsFlagStoreName = result.filterContents(storeName.text.trim());
                            var contentsFlagFavorite = result.filterContents(favorite.text.trim());
                            var contentsFlagRemarks = result.filterContents(remarks.text.trim());
                            if(contentsFlagStoreName==false){
                              var popupTitle = '부적절한 단어사용';
                              var message =
                                  '상호명에 부적적한 단어가 포함되어 있습니다. 해당 단어를 포함하지 않은 용어를 사용바랍니다.';
                              showDialog(
                                  context: context,
                                  builder: (context) =>
                                      login.PopupPage(popupTitle: popupTitle, message: message));
                            }
                            else if(contentsFlagFavorite==false){
                              var popupTitle = '부적절한 단어사용';
                              var message =
                                  '"꼭 주문하기"에 부적적한 단어가 포함되어 있습니다. 해당 단어를 포함하지 않은 용어를 사용바랍니다.';
                              showDialog(
                                  context: context,
                                  builder: (context) =>
                                      login.PopupPage(popupTitle: popupTitle, message: message));
                            }
                            else if(contentsFlagRemarks==false){
                              var popupTitle = '부적절한 단어사용';
                              var message =
                                  '"특이사항"에 부적적한 단어가 포함되어 있습니다. 해당 단어를 포함하지 않은 용어를 사용바랍니다.';
                              showDialog(
                                  context: context,
                                  builder: (context) =>
                                      login.PopupPage(popupTitle: popupTitle, message: message));
                            }

                            //1. type, category null
                            else if (type == null || category == null) {
                              showDialog(
                                  context: context,
                                  builder: (context) => login.PopupPage(
                                      popupTitle: '매장추천 실패',
                                      message: '음식유형을 선택해주세요'));
                            }
                            //2. 상호명 null
                            else if (storeName.text.trim() == '') {
                              showDialog(
                                  context: context,
                                  builder: (context) => login.PopupPage(
                                      popupTitle: '매장추천 실패', message: '상호명을 입력해주세요'));
                            }
                            //3. 상호명 길이체크
                            else if (storeName.text.trim().length > 20) {
                              showDialog(
                                  context: context,
                                  builder: (context) => login.PopupPage(
                                      popupTitle: '매장추천 실패',
                                      message: '상호명이 너무 깁니다. 20자 이내로 작성 부탁드립니다.'));
                            }
                            //3-2. 상호명 중복체크
                            else if(storeNameList.contains(storeName.text.trim())){
                              showDialog(
                                  context: context,
                                  builder: (context) => login.PopupPage(
                                      popupTitle: '매장추천 실패',
                                      message: '이미 다른 사용자에 의해 등록된 매장입니다. 상호명 검색을 통해 확인해 주세요.'));
                            }
                            //4. 거리 null
                            else if (distance.text.trim() == '') {
                              showDialog(
                                  context: context,
                                  builder: (context) => login.PopupPage(
                                      popupTitle: '매장추천 실패',
                                      message: '도보시간을 입력해주세요'));
                            }
                            //5. 출구 null
                            else if (exit == null) {
                              showDialog(
                                  context: context,
                                  builder: (context) => login.PopupPage(
                                      popupTitle: '매장추천 실패',
                                      message: '가까운 출구를 선택해주세요'));
                            }
                            //6. 추천메뉴 null
                            else if(favorite.text.trim() == ''){
                              showDialog(
                                  context: context,
                                  builder: (context) => login.PopupPage(
                                      popupTitle: '매장추천 실패',
                                      message: '꼭 주문하기를 입력해주세요'));
                            }
                            else {
                              //6. 거리 숫자체크
                              try {
                                //print(int.parse(distance.text));
                                ////print('추천매장 등록수행');
                                DateTime now = DateTime.now();
                                addStore(
                                    type,
                                    category,
                                    int.parse(exit),
                                    int.parse(distance.text.trim()),
                                    storeName.text.trim(),
                                    favorite.text.trim(),
                                    remarks.text.trim(),
                                    1,
                                    storeCd,
                                    login.auth.currentUser?.uid,
                                    [login.auth.currentUser?.uid],
                                    now.month < 10
                                        ? '${now.year}0${now.month}${now.day}'
                                        : '${now.year}${now.month}${now.day}');
                                await showDialog(
                                    context: context,
                                    builder: (context) => login.PopupPage(
                                        popupTitle: '매장등록 성공',
                                        message:
                                            '추천매장이 성공적으로 등록되었습니다. 내가 좋아요한 스토어 리스트에서 확인하세요'));
                                setState(() {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => mypage.Result()));
                                });
                              } catch (e) {
                                showDialog(
                                    context: context,
                                    builder: (context) => login.PopupPage(
                                        popupTitle: '매장추천 실패',
                                        message: '도보시간은 숫자로만 입력해주세요'));
                              }
                            }
                          }),
                    ),
                  ],
                )),
          ),
        ),
      ),
    );
  }
}

//유형별 Dropdown
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
                  items: main.timeList.map((item) {
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
                  items: main.categoryList.map((item) {
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

//출구별 Dropdown
class ExitDropdown extends StatefulWidget {
  const ExitDropdown({Key? key}) : super(key: key);

  @override
  State<ExitDropdown> createState() => _ExitDropdownState();
}

class _ExitDropdownState extends State<ExitDropdown> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      isExpanded: true,
      value: exit,
      items: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12']
          .map((item) {
        return DropdownMenuItem(
          child: Center(child: Text(item)),
          value: item,
        );
      }).toList(),
      onChanged: (item) {
        setState(() {
          exit = item.toString();
        });
        exit = item.toString();
      },
    );
  }
}

class WarningPopup extends StatelessWidget {
  const WarningPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xfffef9a7),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0)),
      title: Center(
          child: Text(
            '매장등록시 유의사항',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xffd61c4e)),
          )),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 10,
            ),
            Text('사용자 생성 콘텐츠(UGC) 정책에 따라 상대에게 불쾌감을 줄 수 있는 내용을 작성시에는 해당 글은 사용자들에 의해 신고가 가능하며, 관리자 검토 후 삭제가 가능함을 사전에 알려드립니다. 작성자는 이러한 사항을 인지하고 동의함을 확인합니다.'),
            SizedBox(height: 20,),
            Container( height: 150, margin: EdgeInsets.fromLTRB(0, 10, 0, 30), child: Image.asset('assets/ban.png')),
            Row(
              mainAxisAlignment:
              MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('확인'),
                  style: ElevatedButton.styleFrom(
                      primary: Color(0xffd61c4e)),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
