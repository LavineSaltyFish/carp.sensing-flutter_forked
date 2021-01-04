import 'package:flutter/material.dart';
import 'package:carp_webservices/carp_service/carp_service.dart';
import 'package:carp_webservices/carp_auth/carp_auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CARP Backend Demo',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void initState() {
    super.initState();
    bloc.init();
  }

  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('CARP Authentication Example'),
      // ),
      body: Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            height: 80,
            width: 200,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: TextButton.icon(
              onPressed: () => bloc.authenticate(
                    context,
                    username: 'sys1admin1DK@cachet.dk',
                  ),
              icon: Icon(Icons.login),
              label: Text(
                'LOGIN',
                style: TextStyle(fontSize: 35),
              ),
            ),
          ),
          Container(
            height: 80,
            width: 400,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: TextButton.icon(
              onPressed: () => bloc.getStudyId(context),
              icon: Icon(Icons.mail),
              label: Text(
                'GET STUDY',
                style: TextStyle(fontSize: 35),
              ),
            ),
          ),
          StreamBuilder(
            stream: CarpService().authStateChanges,
            builder: (BuildContext context, AsyncSnapshot<AuthEvent> event) =>
                Padding(
                    padding: EdgeInsets.fromLTRB(10, 30, 10, 0),
                    child: Text(
                        'Authentication status: ${(CarpService().authenticated) ? 'Authenticated' : 'Not authenticated'}')),
          )
        ],
      )),
    );
  }
}

class AppBLoC {
  final String uri = "https://cans.cachet.dk:443"; // CANS PROD
  String _studyId;
  String get studyId => _studyId;

  CarpApp _app;
  CarpApp get app => _app;

  Future init() async {
    _app = CarpApp(
      name: 'carp_backend_example_app',
      uri: Uri.parse(uri),
      oauth: OAuthEndPoint(clientID: 'carp', clientSecret: 'carp'),
    );

    CarpService().configure(app);
  }

  void dispose() async {}

  Future authenticate(BuildContext context, {String username}) async =>
      await CarpService().authenticateWithDialog(
        context,
        username: username,
      );

  Future<String> getStudyId(BuildContext context) async {
    _studyId = await CarpService().getStudyIdByInvitation(context);
    print('CARP Study Deployment ID: $_studyId');
    return _studyId;
  }
}

final bloc = AppBLoC();