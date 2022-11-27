import 'package:flutter/material.dart';
import 'package:lunchpedia/editStore.dart';

//import 'package:lunchpedia/result.dart';
import 'package:toggle_switch/toggle_switch.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'main.dart' as main;
import 'style.dart' as style;
import 'login.dart';
import 'result.dart' as result;
import 'createStore.dart';

// widget 구조
// Result() > [Loading(), NoResult(), StoreList()] > StoreList() 하위에 storeDetailPopup()

//final firestore = FirebaseFirestore.instance;

var loginState;
var likeListOfUsr; //로그인한 user의 좋아요리스트 => 좋아요 리스트가 수정되면, storeCollection의 likepeeple 뿐만아니라, userCollection의 likeList도 수정해줘야 한다.
// likeListOfUsr의 Scope이 최상단인 이유는 storeDetailPopup 에서도 해당 변수를 사용하기 위해서 임. setState 로 관리하지 않기위해서
var storeForEdit; // editStore.dart에서 사용할 겂
var switchIndex; // 좋아요 리스트 정렬 토글
var switchIndexForRegister; //내가 등록한 매장 정렬 토글

//user의 likeList의 값을 업데이트 한다.
updateUserCollection(likeList) async {
  await result.firestore
      .collection('userCollection')
      .doc(auth.currentUser?.uid)
      .update({'likeList': likeList});
}

//updateUSer => 추후, store별 keyword로 검색케하는 기능에 사용
updateUserData() async {
  ////print("test");
  await result.firestore
      .collection('storeCollection')
      .doc('ST1')
      .update({"keyword": "매운맛"});
}

class Result extends StatefulWidget {
  const Result({Key? key}) : super(key: key);

  @override
  State<Result> createState() => _ResultState();
}

class _ResultState extends State<Result> {
  var tab =
      1; // tab => body 부분 인덱스 => 0 ~ 4 : 로딩중, 좋아요한매장 없음, 좋아요한 매장리스트, 등록매장 없음, 등록 매장리스트
  var stores = []; // 조회결과 리스트
  var myResterList = []; //내가 등록한 store리스트
  var likepeople = []; // store별 좋아요한 유저리스트
  var favorite = ''; // store별 추천메뉴
  var tabIdx = 0; // tab의 인덱스
  var issueStores = []; //이슈상태인 store

  //로그아웃 함수
  logout() async {
    await auth.signOut();
    await showDialog(
        context: context,
        builder: (context) =>
            PopupPage(popupTitle: '로그아웃', message: '다음에 또 방문해 주세요.'));
    setState(() {
      Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
    });
  }

  //내가 좋아요한 스토어리스트 조회 함수(좋아요순)
  getMyFavoriteOrderbyLike() async {
    ////print('uid=${auth.currentUser?.uid}');
    var results = await result.firestore
        .collection('storeCollection')
        .where('likepeople', arrayContains: auth.currentUser?.uid)
        .where('display', isEqualTo: 'Y')
        .orderBy('likes', descending: true)
        .get();
    setState(() {
      stores = results.docs;
      if (stores.length == 0) {
        tab = 2;
      } else {
        tab = 3;
      }
      switchIndex = 1;
    });
    //print('조회결과(좋아요순) = ${stores.length}');
  }

  //내가 좋아요한 스토어리스트 조회 함수(음식유형순)
  getMyFavoriteOrderbyFood() async {
    ////print('uid=${auth.currentUser?.uid}');
    var results = await result.firestore
        .collection('storeCollection')
        .where('likepeople', arrayContains: auth.currentUser?.uid)
        .where('display', isEqualTo: 'Y')
        .orderBy('category')
        .get();
    setState(() {
      stores = results.docs;
      if (stores.length == 0) {
        tab = 2;
      } else {
        tab = 3;
      }
      switchIndex = 0;

    });
    //print('조회결과(음식유형순) = ${stores.length}');
  }

  //내가 좋아요한 스토어리스트 조회 함수(거리순)
  getMyFavoriteOrderbyDistance() async {
    ////print('uid=${auth.currentUser?.uid}');
    var results = await result.firestore
        .collection('storeCollection')
        .where('likepeople', arrayContains: auth.currentUser?.uid)
        .where('display', isEqualTo: 'Y')
        .orderBy('distance')
        .get();
    setState(() {
      stores = results.docs;
      if (stores.length == 0) {
        tab = 2;
      } else {
        tab = 3;
      }
      switchIndex = 2;
    });
    //print('조회결과(거리순) = ${stores.length}');
  }

  //내가 등록한 스토어리스트 조회 함수(등록일 최신순)
  getMyResterList(uid) async {
    ////print('uid=${auth.currentUser?.uid}');
    //관리자 계정의 경우 전체 리스트를 조회해준다.
    var results;
    if (auth.currentUser?.displayName == 'admin') {
      results = await result.firestore
          .collection('storeCollection')
          .orderBy('createDate', descending: true)
          .get();
    } else {
      results = await result.firestore
          .collection('storeCollection')
          .where('register', isEqualTo: uid)
          .where('display', isEqualTo: 'Y')
          .orderBy('createDate', descending: true)
          .get();
    }
    setState(() {
      myResterList = results.docs;
      switchIndexForRegister = 0;
    });
    //print('조회결과(내가 등록한 매장, 등록일순) = ${myResterList.length}');
  }

  //내가 등록한 스토어리스트 조회 함수(등록일 이름순)
  getMyResterListOrderByName(uid) async {
    ////print('uid=${auth.currentUser?.uid}');
    var results;
    if (auth.currentUser?.displayName == 'admin') {
      results = await result.firestore
          .collection('storeCollection')
          .orderBy('name')
          .get();
    } else {
      results = await result.firestore
          .collection('storeCollection')
          .where('register', isEqualTo: uid)
          .where('display', isEqualTo: 'Y')
          .orderBy('name')
          .get();
    }
    setState(() {
      myResterList = results.docs;
      switchIndexForRegister = 1;
    });
    //print('조회결과(내가 등록한 매장, 이름순) = ${myResterList.length}');
  }

  // 이슈있는 매장리스트 조회 (관리자만)
  getIssueStoreList() async {
    var results = await result.firestore
        .collection('storeCollection')
        .where('display', isEqualTo: 'N')
        .orderBy('updateDate', descending: true)
        .get();
    setState(() {
      issueStores = results.docs;
    });
  }

//user의 likeList 조회함수
  retreiveListListOfUser() async {
    var user = await result.firestore
        .collection('userCollection')
        .doc(auth.currentUser?.uid)
        .get();
    likeListOfUsr = user['likeList'];
  }

  //likes와 likepeople를 선택한 store의 값으로 세팅하는 함수
  setStoreCollection(likeList, favoritefood) {
    setState(() {
      likepeople = likeList;
      favorite = favoritefood;
    });
    //print('set likes = ${likepeople.length}, likepeople=${likepeople}, favorite=${favorite}');
  }

  //userCollection 업데이트를 위해 user의 likeList를 세팅하는 함수
  setUserCollection(likeStore) {
    setState(() {
      likeListOfUsr = likeStore;
    });
  }

  @override
  initState() {
    //login check
    if (auth.currentUser?.uid == null) {
      loginState = false;
    } else {
      loginState = true;
    }
    //로그인유저의 좋아요리스트 조회
    retreiveListListOfUser();
    //내가 좋아요한 storeList 조회
    getMyFavoriteOrderbyLike();
    //내가 등록한 매장 조회 (관리자의 경우 전체리스트를 보여준다)
    getMyResterList(auth.currentUser?.uid);

    if (auth.currentUser?.displayName == 'admin') {
      getIssueStoreList();
    }
  }

  //Result widget 세팅
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: style.theme,
        home: Scaffold(
          appBar: AppBar(
            title: Text(
              '마이 페이지',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    logout();
                  },
                  child: Text('로그아웃', style: TextStyle(color: Colors.black)))
            ],
            leading: IconButton(
                icon: Icon(Icons.home),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => main.MyApp()));
                }),
          ),
          body: [
            UserInfo(myResterList: myResterList, issueStores: issueStores),
            //회원정보페이지
            Loading(),
            //로딩중페이지
            NoResult(),
            //좋아요한 매장없음 페이지
            StoreList(
                stores: stores,
                likepeople: likepeople,
                favorite: favorite,
                getMyFavoriteOrderbyFood: getMyFavoriteOrderbyFood,
                getMyFavoriteOrderbyLike: getMyFavoriteOrderbyLike,
                getMyFavoriteOrderbyDistance: getMyFavoriteOrderbyDistance,
                setUserCollection: setUserCollection,
                setStoreCollection: setStoreCollection),
            NoRegisterList(),
            RegisterList(
                myResterList: myResterList,
                getMyResterList: getMyResterList,
                getMyResterListOrderByName: getMyResterListOrderByName),
          ][tab],
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.favorite), label: '좋아요'),
              BottomNavigationBarItem(
                icon: Icon(Icons.store),
                label: '내가 등록한 매장',
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.account_circle), label: '회원정보'),
            ],
            currentIndex: tabIdx,
            onTap: (i) {
              setState(() {
                if (i == 0) {
                  stores.length == 0 ? tab = 2 : tab = 3;
                } else if (i == 1) {
                  myResterList.length == 0 ? tab = 4 : tab = 5;
                } else {
                  tab = 0;
                }
                tabIdx = i;
              });
            },
          ),
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
        color: Colors.indigo,
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
              '좋아요한 스토어가 없습니다.',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "내가 좋아하는 스토어의",
              style: TextStyle(fontSize: 20),
            ),
            Text(
              "❤️ 버튼을 눌러보아요",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(
              height: 50,
            ),
            SizedBox(
                width: 150,
                child: Image.asset('assets/free-icon-love-1029132.png'))
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
      this.getMyFavoriteOrderbyFood,
      this.getMyFavoriteOrderbyLike,
      this.getMyFavoriteOrderbyDistance,
      this.likepeople, //state에 변경이 있을 때만, firebase업데이트를 수행하기 위해
      this.favorite, //state에 변경이 있을 때만, firebase업데이트를 수행하기 위해
      this.setUserCollection,
      this.setStoreCollection})
      : super(key: key);
  final stores;
  final getMyFavoriteOrderbyFood;
  final getMyFavoriteOrderbyLike;
  final getMyFavoriteOrderbyDistance;

  final likepeople; //좋아요한 사람 리스트
  final favorite; //추천메뉴
  final setStoreCollection; //store의 likes, likepeople 세팅함수
  final setUserCollection; //user의 likeList 세팅함수

  @override
  State<StoreList> createState() => _StoreListState();
}

class _StoreListState extends State<StoreList> {
  var storeName = main.keyword;


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
                      '총 ${widget.stores.length}개',
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
                        totalSwitches: 3,
                        customIcons: [
                          Icon(
                            Icons.fastfood,
                            color: Colors.white,
                          ),
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
                          [Color(0xfff77e21)],
                          [Color(0xffd61c4e)],
                          [Colors.green]
                        ],
                        onToggle: (index) {
                          //print('switched to: $index');
                          index == 0
                              ? widget.getMyFavoriteOrderbyFood()
                              : index == 1
                                  ? widget.getMyFavoriteOrderbyLike()
                                  : widget.getMyFavoriteOrderbyDistance();

                          /*setState(() {
                            switchIndex = index!;
                          });*/
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
                    radius: 20,
                    child: result.FlagImage(
                        category: widget.stores[i]['category']),
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
                        widget.stores[i][
                            'favorite']); // 선택한 store의 값으로 likes, likepeople 세팅
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
                          widget.favorite != widget.stores[i]['favorite']) {
                        result.updateStoreCollection(
                            widget.stores[i]['storeCd'],
                            widget.likepeople,
                            widget.favorite,
                            "Y",
                            "");
                        updateUserCollection(likeListOfUsr);

                        //재조회 로직
                        widget.getMyFavoriteOrderbyLike();
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

  var inputFavorite = TextEditingController(); //추가한 추천메뉴

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    likeCnt = widget.store['likes']; //storeDetailPopup 에서 보여지는 좋아요 갯수
    people = widget.store['likepeople']; //store의 like를 누른 사람 리스트
    favorite = widget.store['favorite']; //store의 추천메뉴 (favorite)
  }

  @override
  Widget build(BuildContext context) {
    // List<Dynamic>타입은 contains 메소드를 갖고있지 않아, 특정요소가 포함되어있는지 확인하려면 형변환을 해야 한다.
    List<String> strPeopleList = people.cast<String>();
    if (strPeopleList.contains(auth.currentUser?.uid)) {
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
              Container(
                  height: 100,
                  child: result.FlagImage(category: widget.store['category'])),
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
                                          color: Color(0xffd61c4e),
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
                                ),
                      auth.currentUser?.displayName =='admin'?
                      Column(
                        children: [
                          Text(
                            '・ 신고사유 :',
                            style: TextStyle(
                                color: Color(0xffd61c4e),
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold),
                          ),
                          Container(
                            margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                            child: Text('${widget.store['reason']}',
                                style: TextStyle(fontSize: fontSize)),
                          )
                        ],
                      )
                      :SizedBox(height: 1,)
                    ],
                  ),
                ),
              ),
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      onPressed: () {
                        //로그인 체크 : 로그인이 안되있을 경우, 좋아요를 클릭할 시 로그인 페이지로 이동하게 한다.
                        if (loginState == false) {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) => Login()));
                        } else {
                          //좋아요를 누르면 likeState가 바뀌고, 그에 따라 storeCollection과 userCollection의 state도 변경해준다.
                          setState(() {
                            likeState == false
                                ? likeState = true
                                : likeState = false;
                          });
                          if (likeState == true) {
                            people.add(auth.currentUser?.uid);
                            likeListOfUsr.add(widget.store['storeCd']);
                            likeCnt++;
                            //  //print('좋아요, strPeopleList=${strPeopleList}');
                          } else {
                            //like를 취소했을 때 처릴
                            //print('people=${people}, likeListOfUsr=${likeListOfUsr}');
                            people.remove(auth.currentUser?.uid);
                            likeListOfUsr.remove(widget.store['storeCd']);
                            likeCnt--;
                            // //print('좋아요 취소, strPeopleList=${strPeopleList}');
                          }
                          widget.setStoreCollection(people, favorite);
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
                          await showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: Color(0xfffef9a7),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0)),
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
                                                var contentsFlag = result
                                                    .filterContents(inputFavorite);
                                                // print('inputFavorite=${inputFavorite}, contentsFlag=${contentsFlag}');
                                                if (contentsFlag == false) {
                                                  var popupTitle = '부적절한 단어사용';
                                                  var message =
                                                      '추천메뉴에 부적적한 단어가 포함되어 있습니다. 해당 단어를 포함하지 않은 용어를 사용바랍니다.';
                                                  showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          PopupPage(
                                                              popupTitle:
                                                                  popupTitle,
                                                              message: message));
                                                } else {
                                                  setFavorite();
                                                  widget.setStoreCollection(
                                                      people, favorite);
                                                  widget.setUserCollection(
                                                      likeListOfUsr);
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterList extends StatefulWidget {
  const RegisterList(
      {Key? key,
      this.myResterList,
      this.getMyResterList,
      this.getMyResterListOrderByName})
      : super(key: key);
  final myResterList;
  final getMyResterList;
  final getMyResterListOrderByName;

  @override
  State<RegisterList> createState() => _RegisterListState();
}

class _RegisterListState extends State<RegisterList> {

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
                    child: auth.currentUser?.displayName == 'admin'
                        ? Text(
                            '전체 매장리스트, ${widget.myResterList.length}개',
                            style: TextStyle(fontSize: 15, color: Colors.black),
                          )
                        : Text(
                            '내가 등록한 매장리스트, ${widget.myResterList.length}개',
                            style: TextStyle(fontSize: 15, color: Colors.black),
                          ),
                  ),
                  Container(
                      padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: ToggleSwitch(
                        minWidth: 60.0,
                        minHeight: 30.0,
                        initialLabelIndex: switchIndexForRegister,
                        cornerRadius: 20.0,
                        activeFgColor: Colors.white,
                        inactiveBgColor: Colors.grey,
                        inactiveFgColor: Colors.white,
                        totalSwitches: 2,
                        customIcons: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.white,
                          ),
                          Icon(
                            Icons.sort_by_alpha,
                            color: Colors.white,
                          )
                        ],
                        activeBgColors: [
                          [Color(0xffd61c4e)],
                          [Colors.green]
                        ],
                        onToggle: (index) {
                          //print('switched to: $index');
                          index == 0
                              ? widget.getMyResterList(auth.currentUser?.uid)
                              : widget.getMyResterListOrderByName(
                                  auth.currentUser?.uid);

                          /*setState(() {
                            switchIndexForRegister = index!;
                          });*/
                        },
                      ))
                ],
              )),
          Expanded(
              child: Container(
            child: ListView.builder(
              itemCount: widget.myResterList.length,
              itemBuilder: (c, i) {
                return ListTile(
                  tileColor: Color(0xfffef9a7),
                  leading: CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: 20,
                    child: result.FlagImage(
                        category: widget.myResterList[i]['category']),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      widget.myResterList[i]['name'].length <= 10
                          ? Text('${widget.myResterList[i]['name']}')
                          : Text(
                              '${widget.myResterList[i]['name'].toString().substring(0, 10)}..'),
                      Container(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.edit,
                              // color: Colors.red,
                            ),
                            Text(
                              '수정하기',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => EditStore()));
                    setState(() {
                      storeForEdit = widget.myResterList[i];
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

// 등록한 매장 없음 화면
class NoRegisterList extends StatelessWidget {
  const NoRegisterList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xfffef9a7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '내가 등록한 스토어가 없습니다.',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "내가 좋아하는 스토어를 공유해보아요",
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(
              height: 50,
            ),
            SizedBox(
                width: 150,
                child: Image.asset(
                    'assets/premium-icon-grocery-store-1892627.png')),
            SizedBox(
              height: 20,
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(120, 40), primary: Color(0xffd61c4e)),
                child: Text(
                  '스토어 등록하러 가기',
                  style: TextStyle(
                      color: Color(0xfffef9a7), fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => CreateStore()));
                })
          ],
        ),
      ),
    );
  }
}

//user정보 페이지
class UserInfo extends StatefulWidget {
  const UserInfo(
      {Key? key,
      this.myResterList,
      this.issueStores,
      this.setStoreCollection,
      this.setUserCollection})
      : super(key: key);
  final myResterList;
  final issueStores;
  final setStoreCollection;
  final setUserCollection;

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xfffef9a7),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
            color: Color(0xfffef9a7),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                        margin: EdgeInsets.fromLTRB(30, 0, 30, 0),
                        width: 100,
                        height: 100,
                        child: auth.currentUser?.displayName == 'admin'
                            ? Image.asset('assets/free-icon-manager-7775465.png')
                            : widget.myResterList.length >= 20
                                ? Image.asset(
                                    'assets/free-icon-professor-2038443.png')
                                : widget.myResterList.length >= 10
                                    ? Image.asset(
                                        'assets/free-icon-teacher-6928042.png')
                                    : Image.asset('assets/starter.png')),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '아이디 : ${auth.currentUser?.displayName}',
                          style: TextStyle(fontSize: 18),
                        ),
                        auth.currentUser?.displayName == 'admin'
                            ? Text(
                                '회원등급 : 관리자',
                                style: TextStyle(fontSize: 18),
                              )
                            : widget.myResterList.length >= 20
                                ? Text(
                                    '회원등급 : 쩝쩝박사',
                                    style: TextStyle(fontSize: 18),
                                  )
                                : widget.myResterList.length >= 10
                                    ? Text(
                                        '회원등급 : 맛선생',
                                        style: TextStyle(fontSize: 18),
                                      )
                                    : Text(
                                        '회원등급 : 일반',
                                        style: TextStyle(fontSize: 18),
                                      )
                      ],
                    ),
                  ],
                ),
                auth.currentUser?.displayName == 'admin'
                    ? Container(
                        color: Colors.red,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('***신고 접수된 매장 리스트***', style: TextStyle(fontSize: 20),),
                          ],
                        ))
                    : Container(
                    //color: Colors.red,
                    padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: Text('[회원등급 기준] 등록한 매장수 10개, 20개를 기점으로 회원등급이 변경됩니다.', style: TextStyle(fontSize: 15),))
              ],
            ),
          ),
          auth.currentUser?.displayName == 'admin'
              ? Expanded(
                  child: Container(
                  child: ListView.builder(
                    itemCount: widget.issueStores.length,
                    itemBuilder: (c, i) {
                      return ListTile(
                        tileColor: Colors.grey,
                        leading: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          radius: 20,
                          child: result.FlagImage(
                              category: widget.issueStores[i]['category']),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            widget.issueStores[i]['name'].length <= 10
                                ? Text('${widget.issueStores[i]['name']}')
                                : Text(
                                    '${widget.issueStores[i]['name'].toString().substring(0, 10)}..'),
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
                                    '${widget.issueStores[i]['likes']}',
                                  ),
                                  Icon(
                                    Icons.directions_walk,
                                    color: Colors.green,
                                  ),
                                  Text('${widget.issueStores[i]['distance']}분'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          /*widget.setStoreCollection(
                              widget.stores[i]['likepeople'],
                              widget.stores[i][
                              'favorite']);*/ // 선택한 store의 값으로 likes, likepeople 세팅
                          await showDialog(
                              context: context,
                              builder: (context) {
                                return storeDetailPopup(
                                    store: widget.issueStores[i],
                                    setStoreCollection: widget.setStoreCollection,
                                    setUserCollection: widget.setUserCollection);
                              });
                          setState(() {
                            // 선택한 store를 '좋아요' 상태가 변했을 때, storeCollection과 userCollection을 업데이트하고 재조회한다.
                            /*  if (!ListEquality().equals(widget.likepeople,
                                widget.stores[i]['likepeople']) ||
                                widget.favorite != widget.stores[i]['favorite']) {
                              result.updateStoreCollection(
                                  widget.stores[i]['storeCd'],
                                  widget.likepeople,
                                  widget.favorite,
                                  "Y",
                                  "");
                              updateUserCollection(likeListOfUsr);

                              //재조회 로직
                              widget.getMyFavoriteOrderbyLike();
                            }*/
                          });
                        },
                      );
                    },
                  ),
                ))
              : Text('')
        ],
      ),
    );
  }
}
