import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hallmaster_enterprise/src/app/theme.dart';
import 'package:hallmaster_enterprise/src/core/app_state.dart';
import 'package:hallmaster_enterprise/src/core/models.dart';
import 'package:hallmaster_enterprise/src/core/security.dart';
import 'package:hallmaster_enterprise/src/core/widgets/async_state_views.dart';
import 'package:hallmaster_enterprise/src/core/widgets/app_shell_scaffold.dart';
import 'package:uuid/uuid.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _showPassword = false;
  String? _feedback;
  bool _isErrorFeedback = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final normalizedEmail =
        SecurityService.normalizeEmail(_emailController.text);
    if (!LoginRateLimiter.canAttempt(normalizedEmail)) {
      final seconds = LoginRateLimiter.remainingSeconds(normalizedEmail);
      setState(() {
        _feedback = 'Too many failed attempts. Try again in ${seconds}s.';
        _isErrorFeedback = true;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.authenticate(
          normalizedEmail, _passwordController.text);

      if (user != null) {
        LoginRateLimiter.recordSuccess(normalizedEmail);
        ref.read(currentUserProvider.notifier).state = user;
        if (mounted) {
          context.go(user.role == UserRole.admin ? '/admin' : '/user');
        }
      } else {
        LoginRateLimiter.recordFailed(normalizedEmail);
        setState(() {
          _feedback = 'Invalid email or password';
          _isErrorFeedback = true;
        });
      }
    } catch (e) {
      setState(() {
        _feedback = e.toString();
        _isErrorFeedback = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    final nameError = ValidationService.validateName(_nameController.text);
    final emailError = ValidationService.validateEmail(_emailController.text);
    final passwordError =
        ValidationService.validatePassword(_passwordController.text);

    if (_formKey.currentState?.validate() != true ||
        nameError != null ||
        emailError != null ||
        passwordError != null) {
      setState(() {
        _feedback = nameError ?? emailError ?? passwordError;
        _isErrorFeedback = true;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);
      final normalizedEmail =
          SecurityService.normalizeEmail(_emailController.text);
      final exists = await userRepo.emailExists(normalizedEmail);

      if (exists) {
        setState(() {
          _feedback = 'Email already registered';
          _isErrorFeedback = true;
        });
        return;
      }

      const uuid = Uuid();
      await userRepo.createUser(
        id: uuid.v4(),
        name: SecurityService.normalizeName(_nameController.text),
        email: normalizedEmail,
        password: _passwordController.text,
        role: UserRole.user,
      );

      setState(() {
        _isLogin = true;
        _nameController.clear();
        _feedback = 'Registration successful. Please sign in.';
        _isErrorFeedback = false;
      });
    } catch (e) {
      setState(() {
        _feedback = e.toString();
        _isErrorFeedback = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _demoLogin(UserRole role) async {
    setState(() => _isLoading = true);
    try {
      final userRepo = ref.read(userRepositoryProvider);

      late AppUser user;
      if (role == UserRole.admin) {
        user =
            await userRepo.authenticate('admin@hallmaster.app', 'Admin@123') ??
                const AppUser(
                    id: 'a1',
                    name: 'Admin User',
                    email: 'admin@hallmaster.app',
                    role: UserRole.admin);
      } else {
        user = await userRepo.authenticate('user@hallmaster.app', 'User@123') ??
            const AppUser(
                id: 'u1',
                name: 'Standard User',
                email: 'user@hallmaster.app',
                role: UserRole.user);
      }

      ref.read(currentUserProvider.notifier).state = user;
      if (mounted) {
        context.go(role == UserRole.admin ? '/admin' : '/user');
      }
    } catch (e) {
      setState(() {
        _feedback = e.toString();
        _isErrorFeedback = true;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShellScaffold(
      title: _isLogin ? 'Sign In' : 'Register',
      currentPath: '/login',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          final formPanel = _buildAuthFormPanel(context);

          if (!isWide) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s4,
                0,
                AppTokens.s4,
                AppTokens.s4,
              ),
              children: [
                _LoginValuePanel(isLogin: _isLogin),
                const SizedBox(height: 14),
                formPanel,
              ],
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s4,
              0,
              AppTokens.s4,
              AppTokens.s4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 6, child: _LoginValuePanel(isLogin: _isLogin)),
                const SizedBox(width: 18),
                Expanded(flex: 5, child: formPanel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthFormPanel(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppTokens.cardPadding,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isLogin ? 'Secure Sign In' : 'Create Enterprise Account',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                _isLogin
                    ? 'Access bookings, approvals, and operational controls.'
                    : 'Register once to submit and monitor hall requests.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              if (!_isLogin)
                TextFormField(
                  controller: _nameController,
                  maxLength: 80,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                      _isLogin ? null : ValidationService.validateName(value),
                  textInputAction: TextInputAction.next,
                ),
              if (!_isLogin) const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                maxLength: 120,
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.email
                ],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'name@company.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => ValidationService.validateEmail(value),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                maxLength: 128,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(_showPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    tooltip: _showPassword ? 'Hide password' : 'Show password',
                  ),
                ),
                obscureText: !_showPassword,
                validator: (value) => ValidationService.validatePassword(value),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) =>
                    _isLogin ? _handleLogin() : _handleRegister(),
              ),
              const SizedBox(height: 12),
              if (_feedback != null)
                _isErrorFeedback
                    ? AppInlineMessage.error(message: _feedback!)
                    : AppInlineMessage.success(message: _feedback!),
              const SizedBox(height: 16),
              Tooltip(
                message: _isLogin
                    ? 'Sign in to your account'
                    : 'Register a new account',
                child: FilledButton(
                  onPressed: _isLoading
                      ? null
                      : (_isLogin ? _handleLogin : _handleRegister),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isLogin ? 'Sign In' : 'Register'),
                ),
              ),
              const SizedBox(height: 8),
              Tooltip(
                message: _isLogin
                    ? 'Switch to registration form'
                    : 'Switch to sign in form',
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _isLogin = !_isLogin;
                            _feedback = null;
                          }),
                  child: Text(_isLogin
                      ? "Don't have an account? Register"
                      : 'Already have an account? Sign In'),
                ),
              ),
              const SizedBox(height: AppTokens.s4),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppTokens.s3),
                    child: Text(
                      'Or explore with a demo account',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppTokens.textTertiary),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: AppTokens.s3),
              Tooltip(
                message: 'Explore with a standard user account',
                child: OutlinedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _demoLogin(UserRole.user),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Continue as Demo User'),
                ),
              ),
              const SizedBox(height: AppTokens.s2),
              Tooltip(
                message: 'Explore with an administrator account',
                child: OutlinedButton.icon(
                  onPressed:
                      _isLoading ? null : () => _demoLogin(UserRole.admin),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Continue as Demo Admin'),
                ),
              ),
              const SizedBox(height: AppTokens.s2),
              Tooltip(
                message: 'Browse public halls without an account',
                child: TextButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          ref.read(currentUserProvider.notifier).state =
                              const AppUser(
                                  id: 'guest',
                                  name: 'Guest',
                                  email: '-',
                                  role: UserRole.guest);
                          context.go('/guest');
                        },
                  icon: const Icon(Icons.public_outlined, size: 18),
                  label: const Text('Continue as guest'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginValuePanel extends StatelessWidget {
  const _LoginValuePanel({required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: const Color(0x330A57C7)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565D8), Color(0xFF0B4DB5), Color(0xFF083A80)],
          stops: [0.0, 0.56, 1.0],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0B3F9A),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -52,
            right: -44,
            child: Container(
              width: 156,
              height: 156,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -44,
            left: -24,
            child: Container(
              width: 128,
              height: 128,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s2,
                vertical: AppTokens.s1,
              ),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                border: Border.all(color: const Color(0x26FFFFFF)),
              ),
              child: Text(
                'Premium access',
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: AppTokens.wBold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTokens.s2),
                Text('HallMaster Enterprise',
                    style:
                        textTheme.labelLarge?.copyWith(color: Colors.white70)),
                const SizedBox(height: AppTokens.s2),
                Text(
                  isLogin
                      ? 'Run operations with confidence'
                      : 'Start secure booking operations',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: AppTokens.wExtraBold,
                    letterSpacing: -0.25,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppTokens.s2),
                Text(
                  isLogin
                      ? 'Keep approvals, bookings, and audit trails in one place.'
                      : 'Register once to manage bookings and request halls cleanly.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppTokens.s3),
                const Row(
                  children: [
                    Expanded(
                      child: _StatBadge(
                        icon: Icons.verified_user_outlined,
                        label: 'Role-aware access',
                      ),
                    ),
                    SizedBox(width: AppTokens.s2),
                    Expanded(
                      child: _StatBadge(
                        icon: Icons.fact_check_outlined,
                        label: 'Audit logging',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.s3),
                const _FeatureRow(
                    icon: Icons.verified_user_outlined,
                    text: 'Secure role-based routing'),
                const SizedBox(height: AppTokens.s2),
                const _FeatureRow(
                    icon: Icons.event_available_outlined,
                    text: 'End-to-end booking approval lifecycle'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s3,
        vertical: AppTokens.s2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        color: const Color(0x14FFFFFF),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white, fontWeight: AppTokens.wSemibold),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
