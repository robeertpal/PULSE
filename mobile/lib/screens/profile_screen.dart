import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/pulse_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _value(String key, {String fallback = 'Necompletat'}) {
    final value = _profile?[key];
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PulseTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: PulseTheme.textPrimary,
        title: const Text('Profilul meu'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Nu am putut încărca profilul: $_errorMessage',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: PulseTheme.textSecondary),
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: PulseTheme.borderLight),
                          boxShadow: PulseTheme.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: PulseTheme.avatarRingGradient,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: PulseTheme.textSecondary,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _value('display_name', fallback: 'Medic'),
                                    style: const TextStyle(
                                      color: PulseTheme.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _value('email', fallback: 'Email necunoscut'),
                                    style: const TextStyle(
                                      color: PulseTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _profileCard(
                        title: 'Date de bază',
                        rows: {
                          'Telefon': _value('phone'),
                          'Județ': _value('county_name'),
                          'Oraș': _value('city_name'),
                        },
                      ),
                      const SizedBox(height: 14),
                      _profileCard(
                        title: 'Date profesionale',
                        rows: {
                          'Ocupație': _value('occupation_name'),
                          'Specializare': _value('specialization_name'),
                          'Titlu universitar': _value('professional_grade_name'),
                        },
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _profileCard({
    required String title,
    required Map<String, String> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PulseTheme.borderLight),
        boxShadow: PulseTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: PulseTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...rows.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        color: PulseTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: PulseTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
