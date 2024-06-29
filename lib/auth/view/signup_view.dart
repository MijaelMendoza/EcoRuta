import 'package:flutter/material.dart';
import 'package:flutter_gmaps/auth/controller/auth_controller.dart';
import 'package:flutter_gmaps/auth/widgets/auth_field.dart';
import 'package:flutter_gmaps/common/loading_page.dart';
import 'package:flutter_gmaps/constants/ui_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';


class SignUpView extends ConsumerStatefulWidget {
  static route() => MaterialPageRoute(builder: (context) => const SignUpView());
  const SignUpView({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView> {
  final appbar = UIConstants.appBar();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  int currentStep = 1;

  final List<String> latinAmericanCountries = [
    'AR',
    'BO',
    'BR',
    'CL',
    'CO',
    'CR',
    'CU',
    'DO',
    'EC',
    'SV',
    'GT',
    'HN',
    'MX',
    'NI',
    'PA',
    'PY',
    'PE',
    'PR',
    'UY',
    'VE'
  ];

  bool isPasswordVisible = false;

  String fullPhoneNumber = '';

  String? validatePassword(String value) {
    if (value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Al menos una letra mayúscula
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    // Al menos una letra minúscula
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    // Al menos un dígito
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one digit';
    }

    // Al menos un carácter especial
    /*if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }*/

    return null; // La contraseña es válida
  }

  void nextStep() {
    if (currentStep == 1) {
      if (passwordController.text != confirmPasswordController.text) {
        // Las contraseñas no coinciden, muestra un mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Passwords do not match"),
            backgroundColor: Colors.white,
          ),
        );
        return;
      }
    }

    setState(() {
      currentStep++;
    });
  }

  void previousStep() {
    setState(() {
      currentStep--;
    });
  }

  void onSignUp() {
    String phoneNumber = fullPhoneNumber;

    String username = '${firstNameController.text} ${lastNameController.text}';


    ref.read(authControllerProvider.notifier).signUp(
          email: emailController.text,
          password: passwordController.text,
          phoneNumber: phoneNumber,
          name: username,
          context: context,
        );
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneNumberController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: appbar,
      body: isLoading
          ? const Loader()
          : Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // textfield 1
                      if (currentStep == 1)
                        const Text(
                          'Create an Account with Email',
                          style: TextStyle(
                            fontSize: 50,
                          ),
                          textAlign: TextAlign.right,
                        ),

                      if (currentStep == 1) const SizedBox(height: 5),

                      if (currentStep == 1)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Your Email:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      if (currentStep == 1) const SizedBox(height: 5),

                      if (currentStep == 1)
                        AuthField(
                          controller: emailController,
                          hintText: 'Email',
                        ),

                      if (currentStep == 1) const SizedBox(height: 15),

                      if (currentStep == 1)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      if (currentStep == 1) const SizedBox(height: 5),

                      if (currentStep == 1)
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: passwordController,
                                obscureText: !isPasswordVisible,
                                decoration: const InputDecoration(
                                  hintText: 'Password',
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (currentStep == 1) const SizedBox(height: 5),

                      // Confirm Password
                      if (currentStep == 1)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Confirm Password:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      if (currentStep == 1) const SizedBox(height: 5),

                      if (currentStep == 1)
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: confirmPasswordController,
                                obscureText: !isPasswordVisible,
                                decoration: const InputDecoration(
                                  hintText: 'Confirm Password',
                                ),
                              ),
                            ),
                          ],
                        ),
                      if (currentStep == 1)
                        IconButton(
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      if (currentStep == 2)
                        Column(
                          children: [
                            // Nuevo título y subtítulo para el paso 2
                            const SizedBox(height: 15),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Contact Information',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Please complete your emergency information profile',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // Campos de entrada para el paso 2
                            const SizedBox(height: 15),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'First Name:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            AuthField(
                              controller: firstNameController,
                              hintText: 'First Name',
                            ),
                            const SizedBox(height: 15),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Last Name:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            AuthField(
                              controller: lastNameController,
                              hintText: 'Last Name',
                            ),

                            const SizedBox(height: 5),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Phone Number:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            InternationalPhoneNumberInput(
                              onInputChanged: (PhoneNumber number) {
                                fullPhoneNumber = '${number.phoneNumber}';
                              },
                              selectorConfig: const SelectorConfig(
                                selectorType:
                                    PhoneInputSelectorType.BOTTOM_SHEET,
                                setSelectorButtonAsPrefixIcon: true,
                                leadingPadding: 20,
                                showFlags: true,
                              ),
                              onInputValidated: (bool value) {},
                              inputDecoration: const InputDecoration(
                                hintText: 'Phone Number',
                              ),
                              textStyle: const TextStyle(fontSize: 16),
                              keyboardType: TextInputType.phone,
                              selectorTextStyle: const TextStyle(fontSize: 16),
                              textFieldController: phoneNumberController,
                              initialValue: PhoneNumber(isoCode: 'BO'),
                              countries: latinAmericanCountries,
                            ),
                          ],
                        ),

                      if (currentStep == 2)
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceBetween, // Alineación horizontal de los botones
                          children: [
                            ElevatedButton(
                              onPressed: previousStep,
                              child: const Text('Back'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 198, 12, 12),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: currentStep < 2 ? nextStep : onSignUp,
                              child: Text(
                                currentStep < 2 ? 'Next' : 'Done',
                                /*style: TextStyle(
                                  color: Color.fromARGB(255, 198, 12, 12),
                                ),*/
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 198, 12, 12),
                              ),
                            ),
                          ],
                        ),
                      if (currentStep == 1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .end, // Alineación horizontal de los botones
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // Validar la contraseña antes de pasar al siguiente paso
                                String? passwordError =
                                    validatePassword(passwordController.text);
                                if (passwordError != null) {
                                  // Muestra un mensaje de error si la contraseña no es válida
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(passwordError),
                                      backgroundColor: Colors.white,
                                    ),
                                  );
                                } else {
                                  // Si la contraseña es válida, avanza al siguiente paso
                                  nextStep();
                                }
                              },
                              child: const Text('Next'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 198, 12, 12),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
