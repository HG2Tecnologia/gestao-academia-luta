import 'package:flutter/material.dart';

final adminShellKey = GlobalKey<ScaffoldState>();
final alunoShellKey = GlobalKey<ScaffoldState>();
final profShellKey = GlobalKey<ScaffoldState>();

void openAppDrawer() {
  if (adminShellKey.currentState != null) {
    adminShellKey.currentState!.openEndDrawer();
  } else if (alunoShellKey.currentState != null) {
    alunoShellKey.currentState!.openEndDrawer();
  } else {
    profShellKey.currentState?.openEndDrawer();
  }
}
