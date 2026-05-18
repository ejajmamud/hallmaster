import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hallmaster_enterprise/src/app/router.dart';
import 'package:hallmaster_enterprise/src/app/theme.dart';

class HallMasterApp extends ConsumerWidget {
  const HallMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'HallMaster Enterprise',
      theme: buildHallMasterTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
