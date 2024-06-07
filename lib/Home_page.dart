import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:moblie_storage/Login_page.dart';

void main(){
  FlutterSecureStorage storage = new FlutterSecureStorage();
}

class HomePage extends StatefulWidget {

  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage(); //flutter_secure_storage 사용을 위한 초기화 작업
  dynamic name;
  dynamic platform ;

  Future<bool> _asyncMethod() async {
    //read 함수를 통하여 key값에 맞는 정보를 불러오게 됩니다. 이때 불러오는 결과의 타입은 String 타입임을 기억해야 합니다.
    //(데이터가 없을때는 null을 반환을 합니다.)
    // storage에 저장된 id, platform 정보 가져오기
    await storage.write(key: 'login', value: 'true');
    name = await storage.read(key: 'ms_name');
    platform = await storage.read(key: 'platform');

    return true;
  }

  Future<void> signOut() async{

    String? platform = await storage.read(key: 'platform');
    await storage.delete(key: 'login');
    await storage.delete(key: 'clientId');
    await storage.delete(key: 'platform');
    await storage.delete(key: 'ms_email');
    await storage.delete(key: 'ms_name');
    await storage.delete(key: 'ms_tel');

    switch(platform){
      case 'facebook':
        await FacebookAuth.instance.logOut();
        break;
      case 'google':
        await GoogleSignIn().signOut();
        break;
      case 'kakao':
        await UserApi.instance.logout();
        break;
      case 'none':
        break;
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('메인 페이지'),
      ),
      body:
      FutureBuilder<bool>(
        future: _asyncMethod(),
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: CircularProgressIndicator());
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Welcome! ${name}',
                    style: TextStyle(fontSize: 24),
                  ),
                  ElevatedButton(
                    onPressed: (){
                      signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                      );
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        const Color(0xff0165E1),
                      ),
                    ),
                    child: const Text('로그아웃'),
                  ),
                ],
              ),
            );
          }
        },
      )
    );
  }
}