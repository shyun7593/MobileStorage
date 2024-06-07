import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'Home_page.dart';

class RegistPage extends StatefulWidget {

  const RegistPage({Key? key}) : super(key: key);

  @override
  _RegistPageState createState() => _RegistPageState();
}

class _RegistPageState extends State<RegistPage> {
  final FlutterSecureStorage storage = const FlutterSecureStorage(); //flutter_secure_storage 사용을 위한 초기화 작업
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  final _nameController = TextEditingController();
  final _telController = TextEditingController();
  // clientId
  dynamic id;
  // platform
  dynamic platform;

  Future<void> _setInformation() async{
    String? user_email = await storage.read(key: 'ms_email');
    _emailController = TextEditingController(text: user_email ?? '');
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      id = await storage.read(key: 'clientId');
      platform = await storage.read(key: 'platform');
      // MySQL 연결 설정
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

      // 회원 정보 저장
      try{
        await conn.execute(
          'INSERT INTO ms_member (ms_email, ms_name, ms_tel, clientId, ms_type) VALUES (:email, :name, :tel, :id, :platform)',
          {
            "email" : _emailController.text,
            "name" : _nameController.text,
            "tel" : _telController.text,
            "id" : id,
            "platform" : platform,
          },
        );

        // 회원가입 후 메인화면으로
        await storage.write(key: 'ms_email', value: _emailController.text);
        await storage.write(key: 'ms_name', value: _nameController.text);
        await storage.write(key: 'ms_tel', value: _telController.text);

        // 회원가입 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('회원가입이 완료되었습니다.')),
        );

        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (Route<dynamic> route) => false,
        );
      }catch(error){
        print('Insert falsed: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$error')),
        );
      } finally{
        await conn.close();
      }



    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _telController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입'),
      ),
      body: FutureBuilder(
        future: _setInformation(),
        builder: (context, snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center(child: CircularProgressIndicator());
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: <Widget>[
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: '이메일'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이메일을 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: '이름'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이름을 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _telController,
                      decoration: InputDecoration(labelText: '전화번호'),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '전화번호를 입력해주세요.';
                        }
                        if (!RegExp(r'^\d{10,11}$').hasMatch(value)) {
                          return '유효한 전화번호를 입력해주세요.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _signup,
                      child: Text('회원가입'),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      )
    );
  }
}