import 'package:flutter/material.dart';

class AuthScreenManager extends StatefulWidget {
  const AuthScreenManager({super.key});

  @override
  State<AuthScreenManager> createState() => _AuthScreenManagerState();
}

class _AuthScreenManagerState extends State<AuthScreenManager> {
  int _currentScreen = 0;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  void _showLoginScreen() {
    setState(() {
      _currentScreen = 0;
      _errorMessage = '';
    });
  }

  void _showSignUpScreen() {
    setState(() {
      _currentScreen = 1;
      _errorMessage = '';
    });
  }

  void _showForgotPasswordScreen() {
    setState(() {
      _currentScreen = 2;
      _errorMessage = '';
    });
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Simulate login process
      await Future.delayed(const Duration(seconds: 2));

      // Direct navigation without Firebase
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Simulate signup process
      await Future.delayed(const Duration(seconds: 2));

      // Direct navigation without Firebase
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Simulate password reset process
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset link sent to your email'),
          backgroundColor: Colors.green,
        ),
      );

      _showLoginScreen();
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget currentAuthWidget;
    switch (_currentScreen) {
      case 1:
        currentAuthWidget = SignUpScreen(
          onLoginPressed: _showLoginScreen,
          emailController: _emailController,
          passwordController: _passwordController,
          usernameController: _usernameController,
          confirmPasswordController: _confirmPasswordController,
          onSignUp: _signUp,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
        );
        break;
      case 2:
        currentAuthWidget = ForgotPasswordScreen(
          onLoginPressed: _showLoginScreen,
          emailController: _emailController,
          onResetPassword: _resetPassword,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
        );
        break;
      default:
        currentAuthWidget = LoginScreen(
          onSignUpPressed: _showSignUpScreen,
          onForgotPasswordPressed: _showForgotPasswordScreen,
          emailController: _emailController,
          passwordController: _passwordController,
          onLogin: _login,
          isLoading: _isLoading,
          errorMessage: _errorMessage,
        );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            height: MediaQuery.of(context).size.height,
            child: currentAuthWidget,
          ),
        ),
      ),
    );
  }
}

// LoginScreen (same as your existing code, but ensure it's complete)
class LoginScreen extends StatelessWidget {
  final VoidCallback onSignUpPressed;
  final VoidCallback onForgotPasswordPressed;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final bool isLoading;
  final String errorMessage;

  const LoginScreen({
    super.key,
    required this.onSignUpPressed,
    required this.onForgotPasswordPressed,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Your existing LoginScreen UI code here
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.apartment,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'CraneIQ Pro',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Industrial Crane Monitoring',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // Login Form Container
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              if (errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (errorMessage.isNotEmpty) const SizedBox(height: 16),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF1E3A5F),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF1E3A5F),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onForgotPasswordPressed,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: Color(0xFF1E3A5F)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: isLoading
                    ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF1E3A5F,
                          ).withOpacity(0.6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A5F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: onSignUpPressed,
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF1E3A5F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Add missing SignUpScreen and ForgotPasswordScreen classes
class SignUpScreen extends StatelessWidget {
  final VoidCallback onLoginPressed;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController usernameController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSignUp;
  final bool isLoading;
  final String errorMessage;

  const SignUpScreen({
    super.key,
    required this.onLoginPressed,
    required this.emailController,
    required this.passwordController,
    required this.usernameController,
    required this.confirmPasswordController,
    required this.onSignUp,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.apartment,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Join CraneIQ Pro',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your professional account',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign up to get started',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              if (errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (errorMessage.isNotEmpty) const SizedBox(height: 16),

              TextField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                    color: Color(0xFF1E3A5F),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF1E3A5F),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF1E3A5F),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF1E3A5F),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: isLoading
                    ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF1E3A5F,
                          ).withOpacity(0.6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: onSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A5F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(color: Colors.black54),
                  ),
                  GestureDetector(
                    onTap: onLoginPressed,
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Color(0xFF1E3A5F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ForgotPasswordScreen extends StatelessWidget {
  final VoidCallback onLoginPressed;
  final TextEditingController emailController;
  final VoidCallback onResetPassword;
  final bool isLoading;
  final String errorMessage;

  const ForgotPasswordScreen({
    super.key,
    required this.onLoginPressed,
    required this.emailController,
    required this.onResetPassword,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.lock_reset,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'ll send you a reset link',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email to receive a reset link',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              if (errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (errorMessage.isNotEmpty) const SizedBox(height: 16),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF1E3A5F),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: isLoading
                    ? ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF1E3A5F,
                          ).withOpacity(0.6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: onResetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A5F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Send Reset Link',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: onLoginPressed,
                child: const Text(
                  'Back to Sign In',
                  style: TextStyle(color: Color(0xFF1E3A5F)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
