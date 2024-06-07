import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:http/http.dart' as http;
import 'package:mysql_client/mysql_client.dart';

import 'dart:convert';
import 'dart:io';

import 'package:moblie_storage/Home_page.dart';

import 'Regist_page.dart';

class LoginPage extends StatefulWidget{
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  // 회원인지 확인
  bool isMember = false;

  // 로딩중인지 판별
  bool isLoading = false;
  // 구글 로그인
  void signWithGoogle() async{
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if(googleUser != null){
      await storage.write(key: 'platform', value: 'google');
      await storage.write(key: 'clientId', value: googleUser.id);
      await storage.write(key: 'ms_email', value: googleUser.email);
      isMemberUser();
    }
  }

  // 카카오 로그인
  void signWithKakao() async{
    setState(() {
      isLoading = true;
    });
    try {
      bool isInstalled = await isKakaoTalkInstalled();

      OAuthToken token = isInstalled
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();

      var url = Uri.https('kapi.kakao.com', '/v2/user/me');

      var response = await http.get(
        url,
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer ${token.accessToken}'
        },
      );

      Map<String, dynamic> parsedData = json.decode(response.body);
      // print(parsedData['id']);
      // print(parsedData['kakao_account']['email']);
      // print(parsedData);
      await storage.write(key: 'platform', value: 'kakao');
      await storage.write(key: 'clientId', value: parsedData['id'].toString());
      await storage.write(key: 'ms_email', value: parsedData['kakao_account']['email'].toString());
      isMemberUser();
    } catch (error) {
      print('카카오톡으로 로그인 실패 ${error}');
      setState(() {
        isLoading = false;
      });
    }
  }

  // 페이스북 로그인
  void signInWithFacebook() async {
    setState(() {
      isLoading = true;
    });
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      var url = Uri.https('graph.facebook.com', '/v2.12/me', {
        'fields': 'id, email, name',
        'access_token': result.accessToken!.token
      });

      var response = await http.get(url);

      var profileInfo = json.decode(response.body);
      print('facebook : ${profileInfo.toString()}');
      await storage.write(key: 'platform', value: 'facebook');
      await storage.write(key: 'clientId', value: response.body);
      // navigateToHomePage();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 애플 로그인
  void signInWithApple() async {
    setState(() {
      isLoading = true;
    });
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      var url = Uri.https('graph.facebook.com', '/v2.12/me', {
        'fields': 'id, email, name',
        'access_token': result.accessToken!.token
      });

      var response = await http.get(url);

      var profileInfo = json.decode(response.body);
      print('facebook : ${profileInfo.toString()}');
      await storage.write(key: 'platform', value: 'apple');
      await storage.write(key: 'clientId', value: response.body);
      // navigateToHomePage();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 로그인 후 회원이면 메인, 비회원이면 회원가입 페이지로
  void navigateToHomePage(){
    if(isMember){
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage())
      );
    } else {
      setState(() {
        isLoading = true;
      });
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const RegistPage())).then((_) {
        // RegisterPage에서 돌아왔을 때 isLoading을 false로 설정
        setState(() {
          isLoading = false;
        });
      });
    }
  }

  Future<void> isMemberUser() async{
    var clientId = await storage.read(key: 'clientId');
    var result;
    List<Map<String, dynamic>> dataList = [];
    print("DB연결 중");

    // MySQL 접속 설정
    final conn = await MySQLConnection.createConnection(
      host: 'database-itsam.ca55knps7ctg.ap-northeast-2.rds.amazonaws.com',
      port: 3306,
      userName: 'ms1472',
      password: "dlftkcjsfl12#\$",
      databaseName: 'mobilestorage',
    );

    // 연결 하기
    await conn.connect();

    result = await conn.execute("SELECT * FROM ms_member WHERE clientId = :id",{"id": clientId});

    if(!result.rows.isEmpty){
      for(var row in result.rows){
        dataList.add({
          'ms_email' : row.colByName("ms_email"),
          'ms_tel' : row.colByName("ms_tel"),
          'ms_name' : row.colByName("ms_name"),
        });
      }
      await storage.write(key: 'ms_tel', value: dataList[0]['ms_tel']);
      await storage.write(key: 'ms_email', value: dataList[0]['ms_email']);
      await storage.write(key: 'ms_name', value: dataList[0]['ms_name']);
      setState(() {
        isMember = true;
      });
    }

    // 연결 끊기
    await conn.close();
    navigateToHomePage();
  }

  @override
  Widget build(BuildContext context) {
    String os;
    if (Platform.isIOS) {
      os = 'iOS';
    } else if (Platform.isAndroid) {
      os = 'Android';
    } else {
      os = 'Unknown';
    }
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text('로그인 페이지'),
      ),
      body: Stack(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.


          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          children: [
            isLoading ?
            Align(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
            :
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 200.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '모바일\n스토리지',
                      style: TextStyle(fontSize: 65, fontWeight: FontWeight.bold,),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      '로그인 버튼을 눌러주세요',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 90.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LoginButton(imagePath: 'asset/images/google_login.png', onPressed: signWithGoogle, buttonColor: Colors.white),
                    const SizedBox(height: 5,),
                    LoginButton(imagePath: 'asset/images/kakao_login.png', onPressed: signWithKakao, buttonColor: Colors.yellow),
                    const SizedBox(height: 5,),
                    os == 'ios' ?
                      LoginButton(imagePath: 'asset/images/apple_login.png',
                          onPressed: signInWithApple,
                          buttonColor: Colors.black)
                      :
                    const SizedBox(height: 5,),
                  ],
                ),
              ),
            ),
          ],
      ),
    );
  }
}

class LoginButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onPressed;
  final Color buttonColor;

  const LoginButton({
    Key? key,
    required this.imagePath,
    required this.onPressed,
    required this.buttonColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: EdgeInsets.zero,
        minimumSize: const Size(250, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Container(
          width: 250,
          height: 40,
          alignment: Alignment.center,
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
      ),
    );
  }
}