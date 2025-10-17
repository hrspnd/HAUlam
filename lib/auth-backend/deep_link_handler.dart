/*
  File: deep_link_handler.dart
  Purpose: Listens for and processes deep links used for Supabase authentication flows 
           (e.g., sign-up, magic link, recovery, and invite). Handles both cold and warm 
           app launches and routes users accordingly.
  Developers: Pineda, Mary Alexa Ysabelle V. [hrspnd]
*/

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  const DeepLinkHandler({super.key, required this.child});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    // Handle cold start (app opened from a link)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _onUri(uri);
    });

    // Handle warm links (app already running)
    _sub = _appLinks.uriLinkStream.listen(_onUri, onError: (_) {});
  }

  Future<void> _onUri(Uri uri) async {
    final type = uri.queryParameters['type'];
    final code = uri.queryParameters['code'];

    if (code == null || code.isEmpty) {
      _snack('Missing auth code in link.');
      return;
    }

    try {
      await Supabase.instance.client.auth.exchangeCodeForSession(code);

      if (!mounted) return;

      if (type == 'recovery') {
        Navigator.pushNamed(context, '/reset-password');
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Could not complete sign-in.'); // fallback
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
