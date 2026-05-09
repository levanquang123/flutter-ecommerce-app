import 'package:e_commerce_flutter/utility/extensions.dart';

import '../../utility/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import '../home_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      loginAfterSignUp: false,
      logo: const AssetImage('assets/images/logo.png'),
      onLogin: (loginData) async {
        return await context.userProvider.login(loginData);
      },
      onSignup: (SignupData data) async {
        final error = await context.userProvider.register(data);
        if (error == null && context.mounted) {
          final pendingEmail = context.userProvider.pendingVerificationEmail;
          if (pendingEmail != null && pendingEmail.isNotEmpty) {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) {
                return VerifyEmailScreen(email: pendingEmail);
              },
            ));
          }
        }
        return error;
      },
      onSubmitAnimationCompleted: () {
        final pendingEmail = context.userProvider.pendingVerificationEmail;
        final user = context.userProvider.getLoginUsr();
        if (pendingEmail != null && pendingEmail.isNotEmpty) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) {
              return VerifyEmailScreen(email: pendingEmail);
            },
          ));
          return;
        }

        if (user?.emailVerified == false && (user?.email ?? '').isNotEmpty) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) {
              return VerifyEmailScreen(email: user!.email!);
            },
          ));
          return;
        }

        if (context.userProvider.getLoginUsr()?.sId != null) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) {
              return const HomeScreen();
            },
          ));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) {
              return const LoginScreen();
            },
          ));
        }
      },
      onRecoverPassword: (_) => null,
      hideForgotPasswordButton: true,
      theme: LoginTheme(
          primaryColor: AppColor.darkGrey,
          accentColor: AppColor.darkOrange,
          buttonTheme: const LoginButtonTheme(
            backgroundColor: AppColor.darkOrange,
          ),
          cardTheme: const CardTheme(
              color: Colors.white, surfaceTintColor: Colors.white),
          titleStyle: const TextStyle(color: Colors.black)),
    );
  }
}
