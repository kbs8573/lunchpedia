import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lunchpedia/myfavorite.dart' as myfavorite;
import 'package:toggle_switch/toggle_switch.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart' as main;
import 'style.dart' as style;
import 'login.dart' as login;

import 'fword_list.dart' as fword; //비속어 리스트

// widget 구조
// Result() > [Loading(), NoResult(), StoreList()] > StoreList() 하위에 storeDetailPopup()

final firestore = FirebaseFirestore.instance;

var type = '';
var category = '';
var loginState;
var likeListOfUsr; //로그인한 user의 좋아요리스트

//불건전 컨텐츠 필터함수
filterContents(word) {
  var forbidden_word_list = fword.fword;

  for (var fword in forbidden_word_list) {
    if (word
        .toString()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .trim()
        .contains(fword)) {
      return false;
      break;
    }
  }
  return true;
}

// store의 likes, liekpeople 의 값을 업데이트 한다
updateStoreCollection(storeCd, likepeople, favorite, display, reason) async {
  //print("updateStoreCollection for update : storeCd=${storeCd}, likepeople=${likepeople}, favorite=${favorite}, display=${display}, reason=${reason}");
  var contentsFlag = filterContents(favorite);
  //print('favorite=${favorite}, contentsFlag=${contentsFlag}');
  if (contentsFlag == false) {
    var popupTitle = '부적절한 단어사용';
    var message = '추천메뉴에 부적적한 단어가 포함되어 있습니다. 해당 단어를 포함하지 않은 용어를 사용바랍니다.';
    var context;
    showDialog(
        context: context,
        builder: (context) =>
            login.PopupPage(popupTitle: popupTitle, message: message));
  } else {
    DateTime now = DateTime.now();
    await firestore.collection('storeCollection').doc(storeCd).update({
      'likes': likepeople.length,
      'likepeople': likepeople,
      'favorite': favorite,
      'display': display,
      'reason': reason,
      'updateDate': now.month < 10
          ? int.parse('${now.year}0${now.month}${now.day}')
          : int.parse('${now.year}${now.month}${now.day}')
    });
  }
}

//user의 likeList의 값을 업데이트 한다.
updateUserCollection(likeList) async {
  await firestore
      .collection('userCollection')
      .doc(login.auth.currentUser?.uid)
      .update({'likeList': likeList});
}

//user의 likeList 조회함수
retreiveListListOfUser() async {
  var user = await firestore
      .collection('userCollection')
      .doc(login.auth.currentUser?.uid)
      .get();
  likeListOfUsr = user['likeList'];
}

class Result extends StatefulWidget {
  const Result({Key? key}) : super(key: key);

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  var tab = 0; // tab
  var stores = []; // 조회결과 리스트
  var likepeople = []; // store별 좋아요한 유저리스트
  var favorite = ''; // store별 추천메뉴
  var display; //store별 display 여부
  var warningReason; //스토어별 신고사유

  //likes와 likepeople를 선택한 store의 값으로 세팅하는 함수
  setStoreCollection(likeList, favoritefood, displayYN, reasonInput) {
    setState(() {
      likepeople = likeList;
      favorite = favoritefood;
      display = displayYN;
      warningReason = reasonInput;
    });
    //print('set likes = ${likepeople.length}, likepeople=${likepeople}, favorite=${favoritefood}, display=${displayYN}, reason=${warningReason}');
  }

  //userCollection 업데이트를 위해 user의 likeList를 세팅하는 함수
  setUserCollection(likeStore) {
    setState(() {
      likeListOfUsr = likeStore;
    });
  }

  //storeList 유형별 조회함수 (좋아요순)
  getDataOderbyLikes(type, category) async {
    var results = await firestore
        .collection('storeCollection')
        .where('type', isEqualTo: type)
        .where('category', isEqualTo: category)
        .where('display', isEqualTo: 'Y')
        .orderBy('likes', descending: true)
        .orderBy('distance')
        .orderBy('name')
        .get();
    setState(() {
      stores = results.docs;
      if (stores.length == 0) {
        tab = 1;
      } else {
        tab = 2;
      }
    });
    //print('조회결과(좋아요순) = ${stores.length}');
  }

  //storeList 유형별 조회함수 (거리순)
  getDataOderbyDistance(type, category) async {
    var results = await firestore
        .collection('storeCollection')
        .where('type', isEqualTo: type)
        .where('category', isEqualTo: category)
        .where('display', isEqualTo: 'Y')
        .orderBy('distance')
        .orderBy('likes', descending: true)
        .orderBy('name')
        .get();
    setState(() {
      stores = results.docs;
      if (stores.length == 0) {
        tab = 1;
      } else {
        tab = 2;
      }
    });
    //print('조회결과(거리순) = ${stores.length}');
  }

  //상호명 검색 쿼리
  getDataByStoreName(keyword) async {
    var results = await firestore
        .collection('storeCollection')
        .where('name', isEqualTo: keyword)
        .where('display', isEqualTo: 'Y')
        .orderBy('likes', descending: true)
        .orderBy('distance')
        .get();
    setState(() {
      stores = results.docs;
      if (stores.length == 0) {
        tab = 1;
      } else {
        tab = 2;
      }
    });
    //print('상호명 검색 : ${keyword}, ${stores.length}개');
  }

  //가까운 출구 검색 쿼리 (좋아요순)
  getDataByExitNumberOrderbyLikes(exit) async {
    var results = await firestore
        .collection('storeCollection')
        .where('exit', isEqualTo: exit)
        .where('display', isEqualTo: 'Y')
        .orderBy('likes', descending: true)
        .orderBy('distance')
        .orderBy('name')
        .get();
    setState(() {
      stores = results.docs;
      if (stores.length == 0) {
        tab = 1;
      } else {
        tab = 2;
      }
    });
    //print('출구 검색(좋아요순) : ${exit}번출구, ${stores.length}개');
  }

  //가까운 출구 검색 쿼리 (거리순)
  getDataByExitNumberOrderbyDistance(exit) async {
    var results = await firestore
        .collection('storeCollection')
        .where('exit', isEqualTo: exit)
        .where('display', isEqualTo: 'Y')
        .orderBy('distance')
        .orderBy('likes', descending: true)
        .orderBy('name')
        .get();
    setState(() {
      stores = results.docs;
      if (stores.length == 0) {
        tab = 1;
      } else {
        tab = 2;
      }
    });
    //print('출구 검색(거리순) : ${exit}, ${stores.length}개');
  }

  @override
  initState() {
    //login check
    if (login.auth.currentUser?.uid == null) {
      loginState = false;
    } else {
      loginState = true;
    }

    setState(() {
      type = main.type;
      category = main.category;
    });

    // toggle 값에따라, 출구별조회, 유형별조회, 상호명조회를 수행한다.
    if (main.toggle == 0) {
      getDataByExitNumberOrderbyLikes(main.exit);
    } else if (main.toggle == 1) {
      getDataOderbyLikes(type, category);
    } else {
      getDataByStoreName(main.keyword.text);
    }

    //로그인유저의 좋아요리스트 조회
    retreiveListListOfUser();
  }

  //Result widget 세팅
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: style.theme,
        home: Scaffold(
          appBar: AppBar(
              title: Text('검색결과',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
              leading: IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => main.MyApp()));
                  }),
              actions: [
                TextButton(
                  child: loginState == true
                      ? Icon(
                          Icons.account_circle,
                          color: Colors.black,
                        )
                      : Text('로그인', style: TextStyle(color: Colors.black)),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => loginState == true
                                ? myfavorite.Result()
                                : login.Login()));
                  },
                )
              ]),
          body: [
            Loading(),
            NoResult(),
            StoreList(
                stores: stores,
                getDataOderbyLikes: getDataOderbyLikes,
                getDataOderbyDistance: getDataOderbyDistance,
                getDataByExitNumberOrderbyLikes:
                    getDataByExitNumberOrderbyLikes,
                getDataByExitNumberOrderbyDistance:
                    getDataByExitNumberOrderbyDistance,
                getDataByStoreName: getDataByStoreName,
                likepeople: likepeople,
                favorite: favorite,
                display: display,
                warningReason: warningReason,
                setUserCollection: setUserCollection,
                setStoreCollection: setStoreCollection)
          ][tab],
        ));
  }
}

// 로딩중 화면
class Loading extends StatelessWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xfffef9a7),
      child: Center(
          child: CircularProgressIndicator(
        color: Color(0xfff77e21),
      )),
    );
  }
}

// 조회결과 없음 화면
class NoResult extends StatelessWidget {
  const NoResult({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xfffef9a7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '조회결과가 없습니다.',
              style: TextStyle(fontSize: 20),
            ),
            main.toggle == 0
                ? Text('(조회조건 : ${main.exit}번 출구)')
                : main.toggle == 1
                    ? Text('(조회조건 : ${main.type}, ${main.category})')
                    : Text('(조회조건 : 상호명 "${main.keyword.text}")'),
            SizedBox(
              height: 50,
            ),
            SizedBox(width: 150, child: Image.asset('assets/no-content.png'))
          ],
        ),
      ),
    );
  }
}

//storeList 조회화면
class StoreList extends StatefulWidget {
  const StoreList(
      {Key? key,
      this.stores,
      this.getDataOderbyLikes,
      this.getDataOderbyDistance,
      this.getDataByStoreName,
      this.getDataByExitNumberOrderbyLikes,
      this.getDataByExitNumberOrderbyDistance,
      this.likepeople, //state에 변경이 있을 때만, firebase업데이트를 수행하기 위해
      this.favorite, //state에 변경이 있을 때만, firebase업데이트를 수행하기 위해      this.likepeople, //state에 변경이 있을 때만, firebase업데이트를 수행하기 위해
      this.display, //state에 변경이 있을 때만, firebase업데이트를 수행하기 위해      this.likepeople, //state에 변경이 있을 때만, firebase업데이트를 수행하기 위해
      this.warningReason, //state에 변경이 있을 때만, firebase업데이트를 수행하기 위해
      this.setUserCollection,
      this.setStoreCollection})
      : super(key: key);
  final stores;
  final getDataOderbyLikes;
  final getDataOderbyDistance;
  final getDataByExitNumberOrderbyLikes;
  final getDataByExitNumberOrderbyDistance;
  final getDataByStoreName;

  final likepeople; //좋아요한 사람 리스트
  final favorite; //추천메뉴
  final display;
  final warningReason; //신고사유
  final setStoreCollection; //store의 likes, likepeople, favorite 세팅함수
  final setUserCollection; //user의 likeList 세팅함수

  @override
  State<StoreList> createState() => _StoreListState();
}

class _StoreListState extends State<StoreList> {
  var toggle = main.toggle;
  var storeName = main.keyword;
  var switchIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xfffef9a7),
      child: Column(
        children: [
          Container(
              height: 50,
              color: Color(0xfffac213),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                    child: Text(
                      toggle == 0
                          ? '${main.exit}번출구 근처, ${widget.stores.length}개'
                          : toggle == 1
                              ? '${type}, ${category} ${widget.stores.length}개'
                              : '"${storeName.text}" 검색결과',
                      style: TextStyle(fontSize: 15, color: Colors.black),
                    ),
                  ),
                  Container(
                      padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: ToggleSwitch(
                        minWidth: 60.0,
                        minHeight: 30.0,
                        initialLabelIndex: switchIndex,
                        cornerRadius: 20.0,
                        activeFgColor: Colors.white,
                        inactiveBgColor: Colors.grey,
                        inactiveFgColor: Colors.white,
                        totalSwitches: 2,
                        customIcons: [
                          Icon(
                            Icons.favorite,
                            color: Colors.white,
                          ),
                          Icon(
                            Icons.directions_walk,
                            color: Colors.white,
                          )
                        ],
                        activeBgColors: [
                          [Color(0xffd61c4e)],
                          [Colors.green]
                        ],
                        onToggle: (index) {
                          //  //print('switched to: $index');
                          setState(() {
                            if (toggle == 0) {
                              if (index == 0) {
                                widget
                                    .getDataByExitNumberOrderbyLikes(main.exit);
                              } else {
                                widget.getDataByExitNumberOrderbyDistance(
                                    main.exit);
                              }
                            } else if (toggle == 1) {
                              if (index == 0) {
                                widget.getDataOderbyLikes(type, category);
                              } else {
                                widget.getDataOderbyDistance(type, category);
                              }
                            } else {
                              if (index == 0) {
                              } else {}
                            }
                            switchIndex = index!;
                          });
                        },
                      ))
                ],
              )),
          Expanded(
              child: Container(
            child: ListView.builder(
              itemCount: widget.stores.length,
              itemBuilder: (c, i) {
                return ListTile(
                  tileColor: Color(0xfffef9a7),
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: toggle == 1 ? 30 : 20,
                    child: toggle == 1
                        ? Image.asset('assets/${widget.stores[i]['exit']}.png')
                        : FlagImage(category: widget.stores[i]['category']),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      widget.stores[i]['name'].length <= 10
                          ? Text('${widget.stores[i]['name']}')
                          : Text(
                              '${widget.stores[i]['name'].toString().substring(0, 10)}..'),
                      Container(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.red,
                            ),
                            Text(
                              '${widget.stores[i]['likes']}',
                            ),
                            Icon(
                              Icons.directions_walk,
                              color: Colors.green,
                            ),
                            Text('${widget.stores[i]['distance']}분'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    widget.setStoreCollection(
                        widget.stores[i]['likepeople'],
                        widget.stores[i]['favorite'],
                        widget.stores[i]['display'],
                        widget.stores[i][
                            'reason']); // 선택한 store의 값으로 likes, likepeople, favorite 세팅
                    await showDialog(
                        context: context,
                        builder: (context) {
                          return storeDetailPopup(
                              store: widget.stores[i],
                              setStoreCollection: widget.setStoreCollection,
                              setUserCollection: widget.setUserCollection);
                        });
                    setState(() {
                      // 선택한 store를 '좋아요' 상태가 변했을 때, storeCollection과 userCollection을 업데이트하고 재조회한다.
                      if (!ListEquality().equals(widget.likepeople,
                              widget.stores[i]['likepeople']) ||
                          widget.favorite != widget.stores[i]['favorite'] ||
                          widget.display != widget.stores[i]['display']) {
                        updateStoreCollection(
                            widget.stores[i]['storeCd'],
                            widget.likepeople,
                            widget.favorite,
                            widget.display,
                            widget.warningReason);
                        updateUserCollection(likeListOfUsr);

                        //재조회 로직
                        if (toggle == 0) {
                          widget.getDataByExitNumberOrderbyLikes(main.exit);
                        } else if (toggle == 1) {
                          widget.getDataOderbyLikes(widget.stores[i]['type'],
                              widget.stores[i]['category']);
                        } else {
                          widget.getDataByStoreName(widget.stores[i]['name']);
                        }
                      }
                    });
                  },
                );
              },
            ),
          ))
        ],
      ),
    );
  }
}

class storeDetailPopup extends StatefulWidget {
  const storeDetailPopup(
      {Key? key, this.store, this.setStoreCollection, this.setUserCollection})
      : super(key: key);
  final store;
  final setStoreCollection;
  final setUserCollection;

  @override
  State<storeDetailPopup> createState() => _storeDetailPopupState();
}

class _storeDetailPopupState extends State<storeDetailPopup> {
  var likeState = false;
  var likeCnt;
  var people;
  var favorite;
  var inputFavorite = TextEditingController(); //추가한 추천메뉴
  var displayInDetailPopup;
  var warningReason;
  var warningReasonInput = TextEditingController(); //신고사유

  setFavorite() {
    setState(() {
      inputFavorite.text.trim().length > 0
          ? favorite == ''
              ? favorite = '${inputFavorite.text.trim()}'
              : favorite = '${favorite}, ${inputFavorite.text.trim()}' //추가했을 때
          : favorite = '${favorite}'; //추가하지 않았을 때
    });
    ////print('favorite=${favorite}, inputFavorite=${inputFavorite.text}');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    likeCnt = widget.store['likes']; //storeDetailPopup 에서 보여지는 좋아요 갯수
    people = widget.store['likepeople']; //store의 like를 누른 사람 리스트
    favorite = widget.store['favorite']; //store의 추천메뉴 (favorite)
    displayInDetailPopup = widget.store['likepeople']; //store의 display yn
    warningReason = widget.store['reason']; //store의 신고사유
  }

  @override
  Widget build(BuildContext context) {
    // List<Dynamic>타입은 contains 메소드를 갖고있지 않아, 특정요소가 포함되어있는지 확인하려면 형변환을 해야 한다.
    List<String> strPeopleList = people.cast<String>();
    if (strPeopleList.contains(login.auth.currentUser?.uid)) {
      setState(() {
        likeState = true;
      });
    }

    var fontSize = 17.0;
    return Container(
      child: AlertDialog(
        backgroundColor: Color(0xfffef9a7),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        title: Center(
          child: Text(widget.store['name'],
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Color(0xfffef9a7),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0)),
                              title: Center(
                                  child: Text(
                                '부적절한 컨텐츠 신고하기',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xffd61c4e)),
                              )),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: '사유',
                                        labelStyle:
                                            TextStyle(color: Color(0xffd61c4e)),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10.0)),
                                          borderSide: BorderSide(
                                              width: 1,
                                              color: Color(0xffd61c4e)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10.0)),
                                          borderSide: BorderSide(
                                              width: 1,
                                              color: Color(0xffd61c4e)),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10.0)),
                                        ),
                                      ),
                                      keyboardType: TextInputType.text,
                                      controller: warningReasonInput,
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            setFavorite();
                                            widget.setStoreCollection(
                                                people,
                                                favorite,
                                                "N",
                                                warningReasonInput.text);
                                            //widget.setUserCollection(likeListOfUsr);
                                            Navigator.pop(context);
                                          },
                                          child: Text('저장'),
                                          style: ElevatedButton.styleFrom(
                                              primary: Color(0xffd61c4e)),
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: Text('취소'),
                                          style: ElevatedButton.styleFrom(
                                              primary: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Text(
                                        '상대방에게 불쾌감을 줄 수 있는 컨텐츠는 사유를 적으신 후, 저장버튼을 누르고 매장상세정보 카드를 닫으면 전체 매장리스트에서 즉시 사라집니다. 사유를 적으실 때, 이메일연락처를 기입해 주시면 처리과정에 대해서 조속히 피드백 드리도록 하겠습니다. ')
                                  ],
                                ),
                              ),
                            );
                          });
                    },
                    icon: Icon(Icons.warning_amber_rounded, color: Colors.red),
                  )
                ],
              ),
              Container(
                  height: 100,
                  child: FlagImage(category: widget.store['category'])),
              Container(
                margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
                child: Container(
                  width: 200,
                  //margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '・ ${widget.store['category']}',
                        style: TextStyle(
                            fontSize: fontSize, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '・ 가까운 출구 : ${widget.store["exit"]}번',
                        style: TextStyle(
                            fontSize: fontSize, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text(
                        '・ 출구에서 도보 ${widget.store['distance']}분',
                        style: TextStyle(
                            fontSize: fontSize, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      favorite == ''
                          ? widget.store['remarks'] == ''
                              ? Text('')
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '・ 특이사항 :',
                                      style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                      child: Text('${widget.store['remarks']}',
                                          style: TextStyle(fontSize: fontSize)),
                                    )
                                  ],
                                )
                          : widget.store['remarks'] == ''
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '・ 꼭 주문하기 :',
                                      style: TextStyle(
                                          color: Color(0xffd61c4e),
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      margin: EdgeInsets.fromLTRB(10, 0, 0, 10),
                                      child: Text(favorite,
                                          style: TextStyle(fontSize: fontSize)),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '・ 꼭 주문하기 :',
                                      style: TextStyle(
                                          fontSize: fontSize,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Container(
                                      margin: EdgeInsets.fromLTRB(10, 0, 0, 10),
                                      child: Text(favorite,
                                          style: TextStyle(fontSize: fontSize)),
                                    ),
                                    Text('・ 특이사항 :',
                                        style: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold)),
                                    Container(
                                      margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                      child: Text('${widget.store['remarks']}',
                                          style: TextStyle(fontSize: fontSize)),
                                    )
                                  ],
                                )
                    ],
                  ),
                ),
              ),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () async {
                        //로그인 체크 : 로그인이 안되있을 경우, 좋아요를 클릭할 시 로그인 페이지로 이동하게 한다.
                        if (loginState == false) {
                          await showDialog(
                              context: context,
                              builder: (context) => login.PopupPage(
                                  popupTitle: '여기 좋아요',
                                  message: '로그인이 필요한 서비스입니다. 로그인 페이지로 이동합니다.'));
                          setState(() {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => login.Login()));
                          });

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => login.Login()));
                        } else {
                          //좋아요를 누르면 likeState가 바뀌고, 그에 따라 storeCollection과 userCollection의 state도 변경해준다.
                          setState(() {
                            likeState == false
                                ? likeState = true
                                : likeState = false;
                          });
                          if (likeState == true) {
                            people.add(login.auth.currentUser?.uid);
                            likeListOfUsr.add(widget.store['storeCd']);
                            likeCnt++;
                            //  //print('좋아요, strPeopleList=${strPeopleList}');
                          } else {
                            //like를 취소했을 때 처릴
                            people.remove(login.auth.currentUser?.uid);
                            likeListOfUsr.remove(widget.store['storeCd']);
                            likeCnt--;
                            // //print('좋아요 취소, strPeopleList=${strPeopleList}');
                          }
                          widget.setStoreCollection(people, favorite, "Y", "");
                          widget.setUserCollection(likeListOfUsr);
                        }
                      },
                      icon: likeState == false
                          ? Icon(
                              Icons.favorite_border,
                              color: Colors.black,
                            )
                          : Icon(Icons.favorite),
                      color: Colors.red,
                    ),
                    IconButton(
                        onPressed: () async {
                          //로그인 체크 : 로그인이 안되있을 경우, 좋아요를 클릭할 시 로그인 페이지로 이동하게 한다.
                          if (loginState == false) {
                            await showDialog(
                                context: context,
                                builder: (context) => login.PopupPage(
                                    popupTitle: '꼭 주문하기 추가',
                                    message:
                                        '로그인이 필요한 서비스입니다. 로그인 페이지로 이동합니다.'));
                            setState(() {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => login.Login()));
                            });

                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => login.Login()));
                          } else {
                            //좋아요를 누르면 likeState가 바뀌고, 그에 따라 storeCollection과 userCollection의 state도 변경해준다.
                            await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: Color(0xfffef9a7),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0)),
                                    title: Center(
                                        child: Text(
                                      '꼭 주문하기 추가',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xffd61c4e)),
                                    )),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextField(
                                            decoration: InputDecoration(
                                              labelText: '추천메뉴',
                                              labelStyle: TextStyle(
                                                  color: Color(0xffd61c4e)),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10.0)),
                                                borderSide: BorderSide(
                                                    width: 1,
                                                    color: Color(0xffd61c4e)),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10.0)),
                                                borderSide: BorderSide(
                                                    width: 1,
                                                    color: Color(0xffd61c4e)),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(10.0)),
                                              ),
                                            ),
                                            keyboardType: TextInputType.text,
                                            controller: inputFavorite,
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  var contentsFlag =
                                                      filterContents(
                                                          inputFavorite);
                                                 // print('inputFavorite=${inputFavorite}, contentsFlag=${contentsFlag}');
                                                  if (contentsFlag == false) {
                                                    var popupTitle = '부적절한 단어사용';
                                                    var message =
                                                        '추천메뉴에 부적적한 단어가 포함되어 있습니다. 해당 단어를 포함하지 않은 용어를 사용바랍니다.';
                                                    showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            login.PopupPage(
                                                                popupTitle:
                                                                    popupTitle,
                                                                message:
                                                                    message));
                                                  } else {
                                                    setFavorite();
                                                    widget.setStoreCollection(
                                                        people,
                                                        favorite,
                                                        "Y",
                                                        "");
                                                    //widget.setUserCollection(likeListOfUsr);
                                                    Navigator.pop(context);
                                                  }
                                                },
                                                child: Text('저장'),
                                                style: ElevatedButton.styleFrom(
                                                    primary: Color(0xffd61c4e)),
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: Text('취소'),
                                                style: ElevatedButton.styleFrom(
                                                    primary: Colors.grey),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10,),
                                          Text('사용자 생성 콘텐츠(UGC) 정책에 따라 상대에게 불쾌감을 줄 수 있는 내용을 작성시에는 해당 글은 사용자들에 의해 신고가 가능하며, 관리자 검토후 삭제될 수 있음을 사전에 알려드립니다. 작성자는 이러한 사항을 인지하고 작성부탁드립니다.'),
                                        ],
                                      ),
                                    ),
                                  );
                                });
                          }
                        },
                        icon: Icon(
                          Icons.restaurant_menu_outlined,
                          color: Color(0xfff77e21),
                        )),
                    IconButton(
                      onPressed: () async {
                        final Uri url = Uri.parse(
                            'nmap://search?query=${widget.store['name']}&appname=com.kbs.lunchpedia'); //네이버지도앱으로 연결
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
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('좋아요 ${likeCnt}개'),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class FlagImage extends StatelessWidget {
  const FlagImage({Key? key, this.category}) : super(key: key);
  final category;

  @override
  Widget build(BuildContext context) {
    var flag;
    if (category == '한식') {
      flag = 'korea';
    } else if (category == '중식') {
      flag = 'china';
    } else if (category == '일식') {
      flag = 'japan';
    } else if (category == '멕시코') {
      flag = 'mexico';
    } else if (category == '스페인') {
      flag = 'spain';
    } else if (category == '양식') {
      flag = 'usa';
    } else if (category == '분식') {
      flag = 'snack';
    } else if (category == '카페') {
      flag = 'caffe';
    } else if (category == '베트남/태국') {
      flag = 'vietnam';
    } else if (category == '삼계탕') {
      flag = 'chickensoup';
    } else if (category == '샤브샤브') {
      flag = 'free-icon-shabu-shabu';
    } else {
      flag = 'fusion';
    }
    return Image.asset('assets/${flag}.png', width: 80);
  }
}
