import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../services/api_service.dart';
import '../widgets/profile_ui_helpers.dart';
import '../widgets/skeleton_loading.dart';
import 'ticket_detail_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  static const Color _black = Color(0xFF050505);
  static const Color _surface = Color(0xFF101010);
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

  void _openTicketDetail(Map<String, dynamic> ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(ticket: ticket),
      ),
    );
  }

  String _getIconForContentType(String? type) {
    switch (type) {
      case 'event':
        return 'assets/icons/events.svg';
      case 'course':
        return 'assets/icons/graduation.svg';
      case 'publication':
        return 'assets/icons/books.svg';
      case 'news':
        return 'assets/icons/newspaper.svg';
      case 'article':
        return 'assets/icons/book.pages.svg';
      default:
        return 'assets/icons/wallet.svg';
    }
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final title = ticket['event_title'] as String? ?? 'Eveniment PULSE';
    final dateStr = ticket['start_date'] as String?;
    final ticketCode = ticket['ticket_code'] as String?;
    final type =
        ticket['content_type'] as String? ??
        ticket['content_item_type'] as String? ??
        'event';
    final iconPath = _getIconForContentType(type);

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
      onTap: () => _openTicketDetail(ticket),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: SvgPicture.asset(
                        iconPath,
                        width: 24,
                        height: 24,
                        colorFilter: const ColorFilter.mode(
                          _orange,
                          BlendMode.srcIn,
                        ),
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
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/calendar.svg',
                              width: 14,
                              height: 14,
                              colorFilter: ColorFilter.mode(
                                Colors.white.withValues(alpha: 0.5),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(dateStr),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/location.svg',
                              width: 14,
                              height: 14,
                              colorFilter: ColorFilter.mode(
                                Colors.white.withValues(alpha: 0.5),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
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
                  const SizedBox(width: 12),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _openTicketDetail(ticket),
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/arrow.right.svg',
                            width: 16,
                            height: 16,
                            colorFilter: ColorFilter.mode(
                              Colors.white.withValues(alpha: 0.76),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (ticketCode != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF4FA3).withValues(alpha: 0.14),
                        _orange.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFF4FA3).withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/ticket.svg',
                        width: 16,
                        height: 16,
                        colorFilter: ColorFilter.mode(
                          Colors.white.withValues(alpha: 0.72),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Cod bilet: $ticketCode',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
