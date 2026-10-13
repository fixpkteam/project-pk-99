import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/widgets/components.dart';
import '../../care/data/care_repository.dart';
import 'location_fields.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key, this.createAccount = false, this.redirectTo});
  final bool createAccount;
  final String? redirectTo;

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _country = TextEditingController(text: 'Pakistan');
  final _city = TextEditingController();
  bool _busy = false;
  bool _showPassword = false;

  String get _destination {
    final route = widget.redirectTo;
    return route != null && route.startsWith('/') && !route.startsWith('//')
        ? route
        : '/home';
  }

  String get _redirectQuery => widget.redirectTo == null
      ? ''
      : '?redirect=${Uri.encodeComponent(_destination)}';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _country.dispose();
    _city.dispose();
    super.dispose();
  }

  String? _required(String? value, String label) =>
      value == null || value.trim().isEmpty ? 'Enter your $label.' : null;

  Future<void> _submit() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    final config = ref.read(configProvider);
    if (config.preview) {
      _message('Connect the Supabase environment to use customer accounts.');
      return;
    }
    setState(() => _busy = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      if (widget.createAccount) {
        final response = await repository.signUp(
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          password: _password.text,
          country: _country.text,
          city: _city.text,
        );
        await _rememberOnboarding();
        if (!mounted) return;
        if (response.session == null) {
          _message('Check your email to confirm your FixPK account.');
          context.go('/sign-in$_redirectQuery');
        } else {
          ref.invalidate(authUserProvider);
          context.go(_destination);
        }
      } else {
        await repository.signIn(email: _email.text, password: _password.text);
        await _rememberOnboarding();
        if (!mounted) return;
        ref.invalidate(authUserProvider);
        context.go(_destination);
      }
    } on AuthException catch (error) {
      _message(error.message);
    } catch (_) {
      _message(
        'We could not complete that request. Check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rememberOnboarding() async {
    if (!mounted) return;
    try {
      await ref
          .read(preferencesProvider)
          .setOnboardingCompleted(completed: true);
    } on Object {
      // A successful sign-in must not be reported as failed because a local
      // preference write failed. The restored session also skips onboarding.
    }
  }

  Future<void> _resetPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _message('Enter your email address first.');
      return;
    }
    if (ref.read(configProvider).preview) {
      _message('Connect the Supabase environment to reset a password.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
      _message(
        'If an account exists for that email, a reset link is on its way.',
      );
    } on Object {
      _message('We could not send the reset link. Try again shortly.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final creating = widget.createAccount;
    return Scaffold(
      appBar: AppBar(title: Text(creating ? 'Create account' : 'Sign in')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/brand/fixpk-app-icon.png',
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    semanticLabel: 'FixPK',
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  creating ? 'Join FixPK' : 'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  creating
                      ? 'Tell us a little about yourself to get started with FixPK.'
                      : 'Sign in to view and manage your FixPK service requests.',
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (creating) ...[
                        TextFormField(
                          key: const ValueKey('auth-name'),
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                          ),
                          validator: (value) => _required(value, 'name'),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const ValueKey('auth-phone'),
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                          ),
                          validator: (value) =>
                              _required(value, 'phone number'),
                        ),
                        const SizedBox(height: 14),
                        LocationFields(
                          country: _country,
                          city: _city,
                          enabled: !_busy,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        key: const ValueKey('auth-email'),
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                        ),
                        validator: (value) {
                          if (value == null || !value.trim().contains('@')) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        key: const ValueKey('auth-password'),
                        controller: _password,
                        obscureText: !_showPassword,
                        autofillHints: [
                          creating
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          suffixIcon: IconButton(
                            tooltip: _showPassword
                                ? 'Hide password'
                                : 'Show password',
                            onPressed: () =>
                                setState(() => _showPassword = !_showPassword),
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return 'Use at least 8 characters.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: creating ? 'Create account' : 'Sign in',
                  busy: _busy,
                  onPressed: _busy ? null : _submit,
                ),
                if (!creating)
                  TextButton(
                    onPressed: _busy ? null : _resetPassword,
                    child: const Text('Forgot password?'),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => context.go(
                          '${creating ? '/sign-in' : '/sign-up'}$_redirectQuery',
                        ),
                  child: Text(
                    creating
                        ? 'Already have an account? Sign in'
                        : 'New to FixPK? Create an account',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountLinks extends StatelessWidget {
  const _AccountLinks();
  @override
  Widget build(BuildContext context) => ContentCard(
    child: Column(
      children: [
        _AccountLink(
          icon: Icons.assignment_outlined,
          label: 'My requests',
          onTap: () => context.go('/requests'),
        ),
        _AccountLink(
          icon: Icons.request_quote_outlined,
          label: 'Quotations',
          onTap: () => context.go('/requests'),
        ),
        _AccountLink(
          icon: Icons.location_on_outlined,
          label: 'Saved addresses',
          onTap: () => context.push('/account/addresses'),
        ),
        _AccountLink(
          icon: Icons.star_outline,
          label: 'My reviews',
          onTap: () => context.push('/account/reviews'),
        ),
        _AccountLink(
          icon: Icons.notifications_none,
          label: 'Notifications',
          onTap: () => context.push('/account/notifications'),
        ),
        _AccountLink(
          icon: Icons.support_agent_outlined,
          label: 'Help & support',
          onTap: () => context.push('/account/support'),
        ),
        _AccountLink(
          icon: Icons.policy_outlined,
          label: 'Legal and privacy',
          onTap: () => context.push('/account/legal'),
        ),
      ],
    ),
  );
}

class _AccountLink extends StatelessWidget {
  const _AccountLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: const Color(0xFF006BC7)),
    title: Text(label),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(configProvider).preview) {
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
            children: [
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 38,
                      backgroundColor: Color(0xFFEFF8FF),
                      child: Icon(
                        Icons.person_outline,
                        size: 38,
                        color: Color(0xFF006BC7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Welcome to FixPK',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text('Sign in to manage your services'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Sign in',
                onPressed: () => context.push('/sign-in'),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Create account',
                kind: ActionKind.outline,
                onPressed: () => context.push('/sign-up'),
              ),
              const SizedBox(height: 20),
              const _AccountLinks(),
            ],
          ),
        ),
      );
    }
    final userState = ref.watch(authUserProvider);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            Text(
              'Your FixPK account',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            userState.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) =>
                  const Text('Account status could not be loaded.'),
              data: (user) {
                if (user == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Sign in to manage your profile and follow service requests. You can browse services as a guest.',
                      ),
                      const SizedBox(height: 20),
                      AppButton(
                        label: 'Sign in',
                        onPressed: () => context.push('/sign-in'),
                      ),
                      const SizedBox(height: 8),
                      AppButton(
                        label: 'Create account',
                        kind: ActionKind.outline,
                        onPressed: () => context.push('/sign-up'),
                      ),
                      const SizedBox(height: 24),
                      const ContentCard(
                        child: Text(
                          'Engineering, maintenance, installation, product and project solutions.',
                        ),
                      ),
                    ],
                  );
                }
                final metadata = user.userMetadata ?? const <String, dynamic>{};
                final staffRoles = ref.watch(staffRoleListProvider(user.id));
                final name =
                    '${metadata['full_name'] ?? metadata['name'] ?? 'FixPK customer'}';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ContentCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(user.email ?? ''),
                          if (metadata['phone'] != null) ...[
                            const SizedBox(height: 4),
                            Text('${metadata['phone']}'),
                          ],
                          if ('${metadata['city'] ?? ''}'.isNotEmpty ||
                              '${metadata['country'] ?? ''}'.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              [metadata['city'], metadata['country']]
                                  .whereType<String>()
                                  .where((value) => value.trim().isNotEmpty)
                                  .join(', '),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Edit profile',
                      kind: ActionKind.outline,
                      onPressed: () => _editProfile(context, ref, user),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Saved addresses',
                      kind: ActionKind.outline,
                      onPressed: () => context.push('/account/addresses'),
                    ),
                    const SizedBox(height: 8),
                    ContentCard(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.notifications_outlined),
                            title: const Text('Notifications'),
                            onTap: () => context.push('/account/notifications'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.support_agent_outlined),
                            title: const Text('Support'),
                            onTap: () => context.push('/account/support'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.help_outline),
                            title: const Text('FAQs'),
                            onTap: () => context.push('/account/faq'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.tune_outlined),
                            title: const Text('Preferences'),
                            onTap: () => context.push('/account/preferences'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.star_outline),
                            title: const Text('My reviews'),
                            onTap: () => context.push('/account/reviews'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.policy_outlined),
                            title: const Text('Legal and privacy'),
                            onTap: () => context.push('/account/legal'),
                          ),
                          if (staffRoles.value?.any(
                                (role) => role.role == 'admin',
                              ) ==
                              true)
                            ListTile(
                              leading: const Icon(
                                Icons.dashboard_customize_outlined,
                              ),
                              title: const Text('Admin panel'),
                              subtitle: const Text(
                                'Manage FixPK content and users',
                              ),
                              onTap: () => context.push('/admin'),
                            ),
                          if (staffRoles.value?.isNotEmpty == true)
                            ListTile(
                              leading: const Icon(
                                Icons.admin_panel_settings_outlined,
                              ),
                              title: const Text('Staff operations'),
                              onTap: () => context.push('/staff'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Sign out',
                      kind: ActionKind.text,
                      onPressed: () async {
                        try {
                          await ref.read(authRepositoryProvider).signOut();
                          ref.invalidate(authUserProvider);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Could not sign out. Try again.'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    User user,
  ) async {
    final nameController = TextEditingController(
      text:
          '${user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? ''}',
    );
    final phoneController = TextEditingController(
      text: '${user.userMetadata?['phone'] ?? ''}',
    );
    final countryController = TextEditingController(
      text: '${user.userMetadata?['country'] ?? 'Pakistan'}',
    );
    final cityController = TextEditingController(
      text: '${user.userMetadata?['city'] ?? ''}',
    );
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your phone number.'
                      : null,
                ),
                const SizedBox(height: 14),
                LocationFields(
                  country: countryController,
                  city: cityController,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save == true) {
      try {
        await ref
            .read(authRepositoryProvider)
            .updateProfile(
              name: nameController.text,
              phone: phoneController.text,
              country: countryController.text,
              city: cityController.text,
            );
        ref.invalidate(authUserProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Profile updated.')));
        }
      } on Object {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not update profile. Check your connection and try again.',
              ),
            ),
          );
        }
      }
    }
    nameController.dispose();
    phoneController.dispose();
    countryController.dispose();
    cityController.dispose();
  }
}
