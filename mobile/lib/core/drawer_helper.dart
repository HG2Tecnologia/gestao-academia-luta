import 'package:flutter/material.dart';

final adminShellKey = GlobalKey<ScaffoldState>();
final alunoShellKey = GlobalKey<ScaffoldState>();
final profShellKey = GlobalKey<ScaffoldState>();

void openAppDrawer() {
  if (adminShellKey.currentState != null) {
    adminShellKey.currentState!.openDrawer();
  } else if (alunoShellKey.currentState != null) {
    alunoShellKey.currentState!.openDrawer();
  } else {
    profShellKey.currentState?.openDrawer();
  }
}
