import 'package:flutter/material.dart';
 
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
 
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}
 
class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
 
  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C1A0E),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Section (dark brown background) ──
            _buildTopSection(),
 
            // ── Bottom Section (white card) ──
            _buildBottomCard(),
          ],
        ),
      ),
    );
  }
 
  Widget _buildTopSection() {
    return Container(
      color: const Color(0xFF2C1A0E),
      padding: const EdgeInsets.only(top: 60, bottom: 32, left: 24, right: 24),
      child: Column(
        children: [
          // Logo
          Container(
            width: 110,
            height: 110,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFD4B483),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.coffee,
                    color: Color(0xFF2C1A0E),
                    size: 36,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CāfeKu',
                    style: TextStyle(
                      color: const Color(0xFF2C1A0E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'COFFEE SHOP',
                    style: TextStyle(
                      color: const Color(0xFF2C1A0E),
                      fontSize: 7,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
 
          const SizedBox(height: 24),
 
          // Title
          const Text(
            'Buat Akunmu Sekarang !',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
 
          const SizedBox(height: 10),
 
          // Subtitle
          const Text(
            'Satu langkah lagi untuk menikmati kopi favoritmu\ntanpa antri.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
 
          const SizedBox(height: 32),
        ],
      ),
    );
  }
 
  Widget _buildBottomCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama Field
          _buildLabel('Nama'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _namaController,
            hint: 'Masukkan Nama Kamu',
            icon: Icons.person_outline,
          ),
 
          const SizedBox(height: 20),
 
          // Email Field
          _buildLabel('Email'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hint: 'Masukkan Email Kamu',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
 
          const SizedBox(height: 20),
 
          // Password Field
          _buildLabel('Password'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            hint: 'Masukkan Password Kamu',
            icon: Icons.lock_outline,
            isPassword: true,
          ),

          const SizedBox(height: 20),

          // Confirm Password Field
          _buildLabel('Konfirmasi Password'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: 'Konfirmasi Password Kamu',
            icon: Icons.lock_outline,
            isPassword: true,
            isConfirmPassword: true,
          ),

          const SizedBox(height: 8),

          // Error Message Display
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(
                    color: Color(0xFFCC8A1A),
                    width: 4,
                  ),
                ),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Color(0xFFC62828),
                  fontSize: 13,
                ),
              ),
            ),

          const SizedBox(height: 28),

          // Tombol Daftar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC8A1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Daftar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
 
          const SizedBox(height: 24),
 
          // Divider "atau Daftar dengan"
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFFDDDDDD))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'atau Daftar dengan',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFDDDDDD))),
            ],
          ),
 
          const SizedBox(height: 20),
 
          // Tombol Google
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDDDDDD)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo sederhana
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Google',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
 
          const SizedBox(height: 24),
 
          // Link ke Login
          Center(
            child: RichText(
              text: TextSpan(
                text: 'Sudah punya akun? ',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
                children: [
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to login page
                        // context.go('/login');
                      },
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          color: Color(0xFFCC8A1A),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' sekarang'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
 
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final obscureText = isConfirmPassword ? _obscureConfirmPassword : _obscurePassword;
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.black38,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.black38, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black38,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    if (isConfirmPassword) {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    } else {
                      _obscurePassword = !_obscurePassword;
                    }
                  });
                },
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCC8A1A), width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  void _handleRegister() {
    // UI validation - show errors but don't actually register yet
    setState(() {
      _errorMessage = null;
    });

    // Validation logic
    if (_namaController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Nama tidak boleh kosong';
      });
      return;
    }

    if (_emailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Email tidak boleh kosong';
      });
      return;
    }

    if (!_isValidEmail(_emailController.text)) {
      setState(() {
        _errorMessage = 'Format email tidak valid';
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Password tidak boleh kosong';
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMessage = 'Password minimal 6 karakter';
      });
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Konfirmasi password tidak boleh kosong';
      });
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Password tidak cocok';
      });
      return;
    }

    // TODO: Integrate backend registration API here
    // For now, just show loading state then reset
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
        // TODO: Navigate to login page or success screen after backend integration
      }
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}