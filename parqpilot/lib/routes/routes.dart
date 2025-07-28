import 'package:go_router/go_router.dart';
import 'package:parqpilot/screens/FirstPage.dart';


// GoRouter configuration
final router = GoRouter(
  routes: [
    GoRoute(
      name:'fristScreen',
      path: '/',
      builder: (context, state) => FirstPage(),
    ),
  ],
);