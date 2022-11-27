import 'package:firebase_auth/firebase_auth.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:lunchpedia/result.dart';
import 'main.dart' as main;

import 'package:url_launcher/url_launcher.dart';

//final firebase = FirebaseFirestore.instance;
final auth = FirebaseAuth.instance;
var loginState;
var flag = false; // 개인정보동의 flag

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  initState() {
    //로그인 여부 확인
    if (auth.currentUser?.uid == null) {
      //  //print('로그인 안된 상태');
      loginState = false;
    } else {
      ////print('로그인 중, ${auth.currentUser?.uid}');
      loginState = true;
    }
  }

  var userEmail = TextEditingController();
  var userPw = TextEditingController();

  var popupTitle; //팝업타이틀 (회원가입성공, 회원가입실패, 로그인성공, 로그인실패)
  var message; // 팝업메세지

  var tab = 0; // tab => 회원가입, 로그인시 작업처리중 상태를 표기해주기 위한 구분자

  // 회원가입 함수
  createUser(email, password) async {
    // //print('(회원가입) email=${email}, password=${password}');입
    var contentFiltering = filterContents(email);
    print('contentFiltering=${contentFiltering}');
    if (contentFiltering == false) {
      //불건전한 컨텐츠 필터과정
      popupTitle = '부적절한 단어사용';
      message =
          '아이디에 부적적한 단어가 포함되어 있습니다. 해당 단어를 포함하지 않은 아이디로 회원가입 절차를 진행 부탁드립니다.';
      showDialog(
          context: context,
          builder: (context) =>
              PopupPage(popupTitle: popupTitle, message: message));
    } else if (email == '') {
      popupTitle = '회원가입 실패';
      message = '아이디를 입력해 주세요.';
      showDialog(
          context: context,
          builder: (context) =>
              PopupPage(popupTitle: popupTitle, message: message));
    } else if (password == '') {
      popupTitle = '회원가입 실패';
      message = '비밀번호를 입력해 주세요.';
      showDialog(
          context: context,
          builder: (context) =>
              PopupPage(popupTitle: popupTitle, message: message));
    } else if (flag == false) {
      popupTitle = '회원가입 실패';
      message = '개인정보정책을 읽어보시고, 동의에 체크해주시기 바랍니다.';
      showDialog(
          context: context,
          builder: (context) =>
              PopupPage(popupTitle: popupTitle, message: message));
    } else {
      //  //print('회원가입 시작');
      setState(() {
        tab = 1;
      });
      try {
        var result = await auth.createUserWithEmailAndPassword(
          email: email + "@lunchpedia.com",
          password: password,
        );
        // //print(result.user);
        popupTitle = '회원가입 성공';
        result.user?.updateDisplayName(email);
        message = "'${email}'님, 회원가입이 완료되었습니다. 점심백과사전을 이용해주셔서 감사합니다.";
        setState(() {
          tab = 0;
        });

        //회원가입 성공시, userCollection에 doc도 함께 생성한다.
        createUserCollection(auth.currentUser?.uid);

        await showDialog(
            context: context,
            builder: (context) =>
                PopupPage(popupTitle: popupTitle, message: message));
        setState(() {
          login(email, password);
        });
      } catch (e) {
        ////print(e);
        popupTitle = '회원가입 실패';
        message = controlErrorMsg(e.toString());
        setState(() {
          tab = 0;
        });
        showDialog(
            context: context,
            builder: (context) =>
                PopupPage(popupTitle: popupTitle, message: message));
      }
    }
  }

  //회원정보 생성 함수
  createUserCollection(uid) async {
    //  //print('createUserCollection, uid=${uid}');
    await firestore
        .collection('userCollection')
        .doc(uid)
        .set({"likeList": [], "followerList": []});
  }

  //로그인 함수
  login(email, password) async {
    // //print('(로그인) email=${email}, password=${password}');
    if (email == '') {
      popupTitle = '로그인 실패';
      message = '아이디를 입력해 주세요.';
      showDialog(
          context: context,
          builder: (context) =>
              PopupPage(popupTitle: popupTitle, message: message));
    } else if (password == '') {
      popupTitle = '로그인 실패';
      message = '비밀번호를 입력해 주세요.';
      showDialog(
          context: context,
          builder: (context) =>
              PopupPage(popupTitle: popupTitle, message: message));
    } else {
      // //print('email=${email}');
      setState(() {
        tab = 1;
      });
      try {
        await auth.signInWithEmailAndPassword(
          email: email + '@lunchpedia.com',
          password: password,
        );
        popupTitle = '로그인 성공';
        message = "'${email}'님 반갑습니다. 점심백과사전을 이용해주셔서 감사합니다.";
        setState(() {
          tab = 0;
        });

        await showDialog(
            context: context,
            builder: (context) =>
                PopupPage(popupTitle: popupTitle, message: message));
        setState(() {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => main.MyApp()));
        });
      } catch (e) {
        //print(e);
        popupTitle = '로그인 실패';
        message = controlErrorMsg(e.toString());
        setState(() {
          tab = 0;
        });

        showDialog(
            context: context,
            builder: (context) =>
                PopupPage(popupTitle: popupTitle, message: message));
      }
    }
  }

  //로그아웃 함수
  logout() async {
    await auth.signOut();
    popupTitle = '로그아웃';
    message = '다음에 또 방문해 주세요.';
    setState(() {
      tab = 1;
    });
    await showDialog(
        context: context,
        builder: (context) =>
            PopupPage(popupTitle: popupTitle, message: message));
    setState(() {
      loginState = false;
    });
  }

  //에러메세지 처리함수
  controlErrorMsg(msg) {
    //  //print('error controll');
    if (msg ==
        '[firebase_auth/weak-password] Password should be at least 6 characters') {
      msg = '비밀번호는 최소 6글자 이상이어야 합니다.';
    } else if (msg ==
        '[firebase_auth/email-already-in-use] The email address is already in use by another account.') {
      msg = '이미 가입된 아이디입니다. 다른 아이디를 사용해 가입하시거나, 로그인 해주세요.';
    } else if (msg ==
        '[firebase_auth/user-not-found] There is no user record corresponding to this identifier. The user may have been deleted.') {
      msg = '해당 아이디로는 회원가입을 하지 않았습니다. 회원가입부터 진행 부탁드립니다.';
    } else if (msg.toString().contains('[firebase_auth/wrong-password]')) {
      msg = '비밀번호가 틀렸습니다. 비밀번호 확인을 부탁드립니다.';
    } else {}
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            '점심백과사전(강남역)',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
                onPressed: () {
                  loginState == true
                      ? logout()
                      : Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => main.MyApp()));
                },
                child: loginState == true
                    ? Text('로그아웃', style: TextStyle(color: Colors.black))
                    : Icon(
                        Icons.home,
                        color: Colors.black,
                      ))
          ],
        ),
        body: [
          Container(
            color: Color(0xfffef9a7),
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('점심백과사전 함께하기',
                      style: TextStyle(fontSize: 30, color: Color(0xffd61c4e))),
                  SizedBox(
                    height: 30,
                  ),
                  TextField(
                    controller: userEmail,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '아이디를 입력하세요',
                      hintStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xfff77e21)),
                      labelText: 'ID',
                      prefixIcon: Icon(
                        Icons.perm_identity,
                        color: Color(0xfff77e21),
                      ),
                      filled: true,
                      fillColor: Colors.amberAccent,
                      labelStyle: TextStyle(color: Color(0xfff77e21)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        borderSide:
                            BorderSide(width: 1, color: Color(0xfff77e21)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        borderSide:
                            BorderSide(width: 1, color: Color(0xfff77e21)),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: userPw,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '비밀번호를 입력하세요',
                      hintStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xfff77e21)),
                      labelText: 'Password',
                      prefixIcon: Icon(
                        Icons.lock,
                        color: Color(0xfff77e21),
                      ),
                      filled: true,
                      fillColor: Colors.amberAccent,
                      labelStyle: TextStyle(color: Color(0xfff77e21)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        borderSide:
                            BorderSide(width: 1, color: Color(0xfff77e21)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                        borderSide:
                            BorderSide(width: 1, color: Color(0xfff77e21)),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        flex: 10,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                minimumSize: Size(200, 40),
                                primary: Color(0xfff77e21)),
                            child: Text(
                              '회원가입',
                              style: TextStyle(
                                  color: Color(0xffd61c4e),
                                  fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              createUser(userEmail.text, userPw.text);
                            }),
                      ),
                      Flexible(flex: 1, child: Container()),
                      Flexible(
                        flex: 10,
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                minimumSize: Size(180, 40),
                                primary: Color(0xffd61c4e)),
                            child: Text(
                              '로그인',
                              style: TextStyle(
                                  color: Color(0xfffef9a7),
                                  fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              login(userEmail.text, userPw.text);
                            }),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                          onPressed: () async {
                            final Uri url = Uri.parse(
                                'https://lunchpediaprivacypolicy.netlify.app/'); //네이버지도앱으로 연결
                            await launchUrl(url);
                          },
                          child: Text(
                            '개인정보정책 동의',
                            style: TextStyle(color: Color(0xffd61c4e)),
                          )),
                      IconButton(
                          onPressed: () {
                            setState(() {
                              flag == true ? flag = false : flag = true;
                            });
                          },
                          icon: flag == true
                              ? Icon(
                                  Icons.check_box,
                                  color: Color(0xffd61c4e),
                                )
                              : Icon(Icons.check_box_outline_blank,
                                  color: Color(0xffd61c4e)))
                    ],
                  ),
                ],
              ),
            ),
          ),
          Loading()
        ][tab]);
  }
}

class PopupPage extends StatefulWidget {
  const PopupPage({Key? key, this.popupTitle, this.message}) : super(key: key);
  final popupTitle;
  final message;

  @override
  State<PopupPage> createState() => _PopupPageState();
}

class _PopupPageState extends State<PopupPage> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xfffef9a7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      title: Center(
          child: Text(
        '${widget.popupTitle}',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xffd61c4e)),
      )),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 30,
          ),
          Text('${widget.message}'),
          SizedBox(
            height: 50,
          ),
          SizedBox(
              height: 150,
              child: widget.popupTitle == '회원가입 성공'
                  ? Image.asset('assets/premium-icon-celebrating-2454281.png')
                  : widget.popupTitle == '회원가입 실패' ||
                          widget.popupTitle == '매장추천 실패' ||
                          widget.popupTitle == '매장정보 수정실패'
                      ? Image.asset('assets/free-icon-cry-1497120.png')
                      : widget.popupTitle == '로그인 성공'
                          ? Image.asset('assets/app-icon.png')
                          : widget.popupTitle == '로그인 실패'
                              ? Image.asset(
                                  'assets/free-icon-confusion-3362383.png')
                              : widget.popupTitle == '로그아웃'
                                  ? Image.asset('assets/see-you.png')
                                  : widget.popupTitle == '매장 추천하기' ||
                                          widget.popupTitle == '여기 좋아요' ||
                                          widget.popupTitle == '꼭 주문하기 추가'
                                      ? Image.asset(
                                          'assets/free-icon-login-2038964.png')
                                      : widget.popupTitle == '매장등록 성공' ||
                                              widget.popupTitle == '매장정보 수정완료'
                                          ? Image.asset(
                                              'assets/premium-icon-grocery-store-1892627.png')
                                          : widget.popupTitle == '부적절한 단어사용'
                                              ? Image.asset('assets/ban.png')
                                              : Image.asset(
                                                  'assets/service.png'))
        ],
      ),
    );
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
