import 'package:commuter/pb.dart';
import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  final _formKey = GlobalKey<FormState>();

  bool register = false;
  String username = "";
  String email = "";
  String password = "";

  String? usernameError;
  String? emailError;
  String? passwordError;

  bool loading = false;

  void auth() async {
    setState(() {
      loading = true;
      usernameError = null;
      passwordError = null;
    });
    _formKey.currentState!.save();

    if (register) {
      final body = <String, dynamic>{
        "username": username,
        "email": email,
        "emailVisibility": true,
        "password": password,
        "passwordConfirm": password,
        "following": []
      };
      bool error = false;
      try {
        await Pb.pb.collection('users').create(body: body);
      } on ClientException catch (e) {
        error = true;
        final data = e.response["data"];
        if (data.containsKey("email")) {
          emailError = data["email"]["message"];
        }
        if (data.containsKey("password")) {
          passwordError = data["password"]["message"];
        }
        if (data.containsKey("username")) {
          usernameError = data["username"]["message"];
        }
      }
      if (!error) {
        await Pb.pb.collection('users').authWithPassword(username, password);
        Navigator.popAndPushNamed(context, "/");
      }
    } else {
      bool error = false;
      try {
        await Pb.pb.collection('users').authWithPassword(username, password);
      } on ClientException catch (e) {
        final data = e.response["data"];
        if (data.containsKey("identity")) {
          usernameError = data["identity"]["message"];
        }
        if (data.containsKey("password")) {
          passwordError = data["password"]["message"];
        }
        if (e.response.containsKey("message")) {
          usernameError = e.response["message"];
        }
        error = true;
      }
      if (!error) {
        Navigator.popAndPushNamed(context, "/");
      }
    }

    setState(() {
      loading = false;
      _formKey.currentState!.validate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  register ? "Register" : "Login",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.person),
                    labelText: "Username",
                  ),
                  onSaved: (v) => {
                    setState(() {
                      username = v!;
                    })
                  },
                  validator: (v) => usernameError,
                ),
                const SizedBox(height: 20),
                register
                    ? TextFormField(
                        decoration: const InputDecoration(
                          icon: Icon(Icons.email),
                          labelText: "Email",
                        ),
                        onSaved: (v) => {
                          setState(() {
                            email = v!;
                          })
                        },
                        validator: (v) => emailError,
                      )
                    : const SizedBox.shrink(),
                SizedBox(height: register ? 20 : 0),
                TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.password),
                    labelText: "Password",
                  ),
                  onSaved: (v) => {
                    setState(() {
                      password = v!;
                    })
                  },
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  validator: (v) => passwordError,
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: loading ? null : auth,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text("Submit"),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      register = !register;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: Text(register
                      ? "Already have an account? Login"
                      : "Don't have an account? Register"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
