import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_storage.dart';
import '../../core/appearance_controls.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';
import '../../core/drawer_helper.dart';
import '../../core/firestore_service.dart';
import '../../core/perfil_switch.dart';
import '../notificacoes_screen.dart';

class ProfPerfilScreen extends StatefulWidget {
  const ProfPerfilScreen({super.key});

  @override
  State<ProfPerfilScreen> createState() => _ProfPerfilScreenState();
}

class _ProfPerfilScreenState extends State<ProfPerfilScreen> {
  AppLocalizations get _l => context.l10n;
  final _nomeCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _academiaId;
  String? _userId;
  bool _isFuncionario = false;
  List<Map<String, dynamic>> _perfis = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await AuthStorage.getUser();
      if (user != null) {
        _academiaId = user.academiaId;
        _userId = user.id;
        _perfis = user.perfis;
        // Professores, secretaria e admin ficam em 'funcionarios'; alunos em 'usuarios'
        _isFuncionario =
            user.perfil == 'Professor' ||
            user.perfil == 'Admin' ||
            user.perfil == 'Secretaria';
        _nomeCtrl.text = user.nome;
        if (user.academiaId != null) {
          try {
            final Map<String, dynamic>? dados;
            if (_isFuncionario) {
              dados = await firestoreService.getFuncionario(
                user.academiaId!,
                user.id,
              );
            } else {
              dados = await firestoreService.getUsuario(
                user.academiaId!,
                user.id,
              );
            }
            if (dados != null) {
              _nomeCtrl.text = dados['nome'] as String? ?? user.nome;
              _telCtrl.text = dados['telefone'] as String? ?? '';
              _emailCtrl.text = dados['email'] as String? ?? '';
            }
          } catch (_) {}
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      if (_academiaId != null && _userId != null) {
        final data = {
          'nome': _nomeCtrl.text.trim(),
          'telefone': _telCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
        };
        if (_isFuncionario) {
          await firestoreService.updateFuncionario(
            _academiaId!,
            _userId!,
            data,
          );
        } else {
          await firestoreService.updateUsuario(_academiaId!, _userId!, data);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l.profUpdated)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l.commonSaveError)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sair() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.cfgLogout,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          _l.cfgLogoutConfirm,
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(
              _l.cfgLogout,
              style: TextStyle(
                color: context.sem.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await AuthStorage.clear();
    if (mounted) context.go('/boas-vindas');
  }

  Future<void> _excluirConta() async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: context.c.surfaceContainer,
        title: Text(
          _l.cfgDeleteAccountTitle,
          style: TextStyle(
            color: context.c.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          _l.cfgDeleteAccountBody,
          style: TextStyle(color: context.c.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: Text(
              _l.commonCancel,
              style: TextStyle(color: context.c.onSurfaceVariant),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(
              _l.commonDelete,
              style: TextStyle(
                color: context.sem.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirma != true || !mounted) return;
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (_) {}
    await AuthStorage.clear();
    if (mounted) context.go('/boas-vindas');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator(color: context.c.primary))
            : RefreshIndicator(
                onRefresh: _load,
                color: context.c.primary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: openAppDrawer,
                          child: Icon(
                            Icons.menu_rounded,
                            color: context.c.onSurface,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            _l.profMyProfile,
                            style: TextStyle(
                              color: context.c.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (_perfis.length > 1)
                          PerfilSwitchButton(
                            onPressed: () async {
                              await mostrarTrocarPerfil(context);
                              _load();
                            },
                          ),
                        const SizedBox(width: 8),
                        const SinoNotificacoes(),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── Dados ────────────────────────────────
                    _label(_l.sdName),
                    _input(_nomeCtrl, _l.profYourNameHint),
                    const SizedBox(height: 16),
                    _label(_l.sdPhone),
                    _input(
                      _telCtrl,
                      '(00) 00000-0000',
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _label(_l.sdEmail),
                    _input(
                      _emailCtrl,
                      'seu@email.com',
                      keyboard: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _salvar,
                      style: FilledButton.styleFrom(
                        backgroundColor: context.c.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : Text(
                              _l.commonSave,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),

                    const SizedBox(height: 32),

                    const AppearanceSettingsCard(),

                    const SizedBox(height: 32),

                    // ── Conta ────────────────────────────────
                    _secao(_l.cfgAccountSection),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/alterar-senha'),
                      icon: Icon(Icons.lock_reset_rounded, size: 18),
                      label: Text(
                        _l.profChangePassword,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.c.onSurface,
                        side: BorderSide(color: context.c.outline),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: const Size.fromHeight(0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _sair,
                        icon: Icon(
                          Icons.logout_rounded,
                          color: context.sem.danger,
                          size: 18,
                        ),
                        label: Text(
                          _l.cfgLogoutBtn,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.sem.danger,
                          side: BorderSide(
                            color: context.sem.danger.withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Zona de Perigo ───────────────────────
                    _secao(_l.cfgDangerSection),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _excluirConta,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.sem.danger,
                          side: BorderSide(
                            color: context.sem.danger.withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _l.cfgDeleteAccountBtn,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _secao(String t) => Text(
    t,
    style: TextStyle(
      color: context.c.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
    ),
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      t,
      style: TextStyle(
        color: context.c.onSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _input(
    TextEditingController c,
    String hint, {
    TextInputType keyboard = TextInputType.text,
  }) => TextField(
    controller: c,
    keyboardType: keyboard,
    style: TextStyle(color: context.c.onSurface, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.c.onSurfaceVariant),
      filled: true,
      fillColor: context.c.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.c.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.c.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.c.primary),
      ),
    ),
  );
}
