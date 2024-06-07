import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mysql_client/mysql_client.dart';


import 'dart:io';
import 'dart:convert';

import 'Home_page.dart';
import 'Login_page.dart';

void main() {
  KakaoSdk.init(nativeAppKey: 'e74597e83efd8e297b02fbb902c9d93f');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);
  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".


  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage(); //flutter_secure_storage 사용을 위한 초기화 작업
  Future<bool> _asyncMethod() async {
    //read 함수를 통하여 key값에 맞는 정보를 불러오게 됩니다. 이때 불러오는 결과의 타입은 String 타입임을 기억해야 합니다.
    //(데이터가 없을때는 null을 반환을 합니다.)
    var login = await storage.read(key: 'login');
    var id = await storage.read(key: 'clientId');
    var platform = await storage.read(key: 'platform');
    if(Platform.isIOS){
      await storage.write(key: 'OS', value: 'IOS');
    } else if(Platform.isAndroid){
      await storage.write(key: 'OS', value: 'Android');
    } else{
      await storage.write(key: 'OS', value: 'Unknown');
    }
    print('정보 - id :$id / platform :$platform');
    var result;
    List<Map<String, dynamic>> dataList = [];

    // SNS 로그인을 했었을 경우
    if(login == "true" && id != null && id != ""){

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

      result = await conn.execute("SELECT * FROM ms_member WHERE clientId = :id",
          {"id" : id});

      // select 결과가 있을 경우에만 실행
      if(!result.rows.isEmpty){
        for(var row in result.rows){
          // print('쿼리 결과 : ${row.colAt(0)}');
          dataList.add({
            'ms_email' : row.colByName("ms_email"),
            'ms_tel' : row.colByName("ms_tel"),
            'ms_name' : row.colByName("ms_name"),
          });
        }
        // print('데이터 리스트 :${dataList}');

        await storage.write(key: 'ms_tel', value: dataList[0]['ms_tel']);
        await storage.write(key: 'ms_email', value: dataList[0]['ms_email']);
        await storage.write(key: 'ms_name', value: dataList[0]['ms_name']);
      }

      // 연결 끊기
      await conn.close();
      return true;

    } else {
      return false;
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _asyncMethod(),
        builder: (context,snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: CircularProgressIndicator());
          } else{
            if(snapshot.data == true){
              return const HomePage();
            } else {
              return const LoginPage();
            }
          }
        },
      ),
    );
  }
}
