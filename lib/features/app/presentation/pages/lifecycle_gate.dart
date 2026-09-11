import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/session_cubit.dart';

class LifecycleGate extends StatefulWidget {
  const LifecycleGate({required this.child, super.key});

  final Widget child;

  @override
  State<LifecycleGate> createState() => _LifecycleGateState();
}

class _LifecycleGateState extends State<LifecycleGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<SessionCubit>().lockIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
