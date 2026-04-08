import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_event.dart';
import 'package:manga_recommendation_app/bloc/register/register_bloc.dart';
import 'package:manga_recommendation_app/bloc/register/register_event.dart';
import 'package:manga_recommendation_app/bloc/register/register_state.dart';

// Email verification code input with auto-login on success
class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleVerify() {
    if (!_formKey.currentState!.validate()) return;
    context.read<RegisterBloc>().add(VerificationCodeSubmitted(_codeController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: BlocListener<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state is RegisterVerified) {
            context.read<AuthBloc>().add(LoginEvent(
                  username: state.username,
                  password: state.password,
                ));
          }
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: BlocBuilder<RegisterBloc, RegisterState>(
                  builder: (context, state) {
                    final email = state is RegisterCodeSent ? state.email : '';
                    return Column(
                      children: [
                        Icon(Icons.mark_email_read, size: 80, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 24),
                        const Text(
                          'Verification Code Sent',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          email.isNotEmpty
                              ? 'A 6-digit code has been sent to $email'
                              : 'A 6-digit code has been sent to your email',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Verification Code',
                            hintText: '000000',
                            counterText: '',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            helperText: ' ',
                          ),
                          style: const TextStyle(fontSize: 24, letterSpacing: 8),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Code is required';
                            if (value.trim().length != 6) return 'Enter a 6-digit code';
                            return null;
                          },
                          onFieldSubmitted: (_) => _handleVerify(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: state is RegisterLoading ? null : _handleVerify,
                            child: state is RegisterLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Verify', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(
                            state is RegisterError && state.isVerificationStep ? state.message : '',
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
