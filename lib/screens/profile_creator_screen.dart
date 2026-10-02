import 'package:flutter/material.dart';

import '../models/player_profile.dart';
import '../services/profile_api.dart';

/// A small account screen backed by the Node server.
///
/// The server stores only a salted password hash, never the original password.
class ProfileCreatorScreen extends StatefulWidget {
  const ProfileCreatorScreen({super.key, this.api});

  final ProfileApi? api;

  @override
  State<ProfileCreatorScreen> createState() => _ProfileCreatorScreenState();
}

class _ProfileCreatorScreenState extends State<ProfileCreatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late final ProfileApi _api = widget.api ?? ProfileApi();

  bool _creatingAccount = true;
  bool _saving = false;
  bool _hidePassword = true;
  PlayerProfile? _signedInAccount;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final account = _creatingAccount
          ? await _api.register(username: username, password: password)
          : await _api.login(username: username, password: password);
      if (!mounted) return;
      _passwordController.clear();
      setState(() => _signedInAccount = account);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _creatingAccount
                ? 'Account created. Welcome, ${account.displayName}!'
                : 'Signed in as ${account.displayName}.',
          ),
        ),
      );
    } on ProfileApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not reach the account server at ${ProfileApi.baseUrl}. '
            'Start the server and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.account_circle, size: 92),
                  const SizedBox(height: 20),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.person_add),
                        label: Text('Create Account'),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.login),
                        label: Text('Sign In'),
                      ),
                    ],
                    selected: {_creatingAccount},
                    onSelectionChanged: _saving
                        ? null
                        : (selection) => setState(() {
                            _creatingAccount = selection.first;
                            _signedInAccount = null;
                            _formKey.currentState?.reset();
                          }),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const ValueKey('username-field'),
                    controller: _usernameController,
                    maxLength: 20,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'animal_player',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final username = value?.trim() ?? '';
                      if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username)) {
                        return 'Use 3-20 letters, numbers, or underscores.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('password-field'),
                    controller: _passwordController,
                    obscureText: _hidePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _hidePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) => (value?.length ?? 0) < 6
                        ? 'Password must be at least 6 characters.'
                        : null,
                    onFieldSubmitted: (_) {
                      if (!_saving) _submit();
                    },
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    key: const ValueKey('account-submit'),
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _creatingAccount ? Icons.person_add : Icons.login,
                          ),
                    label: Text(
                      _saving
                          ? 'Checking…'
                          : _creatingAccount
                          ? 'Create Account'
                          : 'Sign In',
                    ),
                  ),
                  if (_signedInAccount != null) ...[
                    const SizedBox(height: 20),
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.verified_user),
                        title: Text(
                          'Welcome, ${_signedInAccount!.displayName}!',
                        ),
                        subtitle: const Text(
                          'Your account was verified by the server.',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
