import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import '../widgets/skeleton_loading.dart';
import 'profile_screen.dart';
import 'ticket_detail_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  static const Color _black = Color(0xFF050505);
  static const Color _surface = Color(0xFF101010);
  static const Color _surfaceSoft = Color(0xFF181818);
  static const Color _orange = Color(0xFFF97316);

  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getMyTickets();
      if (!mounted) return;
      setState(() {
        _tickets = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Dată necunoscută';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final months = [
        'Ian',
        'Feb',
        'Mar',
        'Apr',
        'Mai',
        'Iun',
        'Iul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final month = months[dt.month - 1];
      final day = dt.day.toString().padLeft(2, '0');
      final year = dt.year;
      return '$day $month $year';
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildStatusBadge(String? status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'paid':
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
        textColor = const Color(0xFF10B981);
        label = 'Confirmat';
        break;
      case 'registered':
        bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.15);
        textColor = const Color(0xFF3B82F6);
        label = 'Înscris';
        break;
      case 'cancelled':
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
        textColor = const Color(0xFFEF4444);
        label = 'Anulat';
        break;
      default:
        bgColor = Colors.white.withValues(alpha: 0.1);
        textColor = Colors.white70;
        label = status ?? 'Necunoscut';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final title = ticket['event_title'] as String? ?? 'Eveniment PULSE';
    final dateStr = ticket['start_date'] as String?;
    final status = ticket['registration_status'] as String?;
    final ticketCode = ticket['ticket_code'] as String?;

    final venueName = ticket['venue_name'] as String?;
    final cityName = ticket['city_name'] as String?;

    String location = '';
    if (venueName != null && venueName.isNotEmpty) {
      location = venueName;
      if (cityName != null && cityName.isNotEmpty) {
        location += ', $cityName';
      }
    } else if (cityName != null && cityName.isNotEmpty) {
      location = cityName;
    } else {
      location = 'Online / Fără locație';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailScreen(ticket: ticket),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _surfaceSoft,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/events.svg',
                            width: 20,
                            height: 20,
                            colorFilter: const ColorFilter.mode(
                              _orange,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(dateStr),
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildStatusBadge(status),
                ],
              ),
              if (ticketCode != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cod bilet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ticketCode,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Row(
                children: [
                  ProfileBackButton(onPressed: () => Navigator.pop(context)),
                  SizedBox(width: 16),
                  Expanded(child: ProfileGradientHeading('Biletele mele')),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          child: SkeletonBlock(height: 140, radius: 20),
                        );
                      },
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'A apărut o eroare',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: _loadTickets,
                              style: TextButton.styleFrom(
                                foregroundColor: _orange,
                              ),
                              child: const Text('Încearcă din nou'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: _surface,
                              shape: BoxShape.circle,
                            ),
                            child: SvgPicture.asset(
                              'assets/icons/events.svg',
                              width: 48,
                              height: 48,
                              colorFilter: ColorFilter.mode(
                                Colors.white.withValues(alpha: 0.1),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Nu ai bilete încă.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Aici vor apărea biletele tale\\nla evenimentele PULSE.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 32),
                      itemCount: _tickets.length,
                      itemBuilder: (context, index) {
                        return _buildTicketCard(_tickets[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
