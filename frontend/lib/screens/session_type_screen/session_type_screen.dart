import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/challenge_models.dart';
import '../solo_challenge_suggestions_screen/solo_challenge_suggestions_screen.dart';
import '../healthy_substitutes_screen/healthy_substitutes_screen.dart';

class SessionTypeScreen extends StatefulWidget {
  final String sessionId;
  final String craving;
  final String selectedOption;
  final int estimatedCalories;

  const SessionTypeScreen({
    Key? key,
    required this.sessionId,
    required this.craving,
    required this.selectedOption,
    required this.estimatedCalories,
  }) : super(key: key);

  @override
  State<SessionTypeScreen> createState() => _SessionTypeScreenState();
}

class _SessionTypeScreenState extends State<SessionTypeScreen> {
  bool _isLoading = false;
  String? _loadingType;

  Future<void> _selectSessionType(String type) async {
    setState(() {
      _isLoading = true;
      _loadingType = type;
    });

    try {
      final data = await ApiService().chooseType(widget.sessionId, type);

      if (!mounted) return;

      if (type == 'solo_challenge') {
        final challengesList = (data['challenges'] as List?) ?? [];
        final challenges = challengesList
            .asMap()
            .entries
            .map((e) => ChallengeData.fromApiChallenge(
                  e.value as Map<String, dynamic>,
                  e.key,
                ))
            .toList();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SoloChallengeSuggestionsScreen(
              craving: widget.craving,
              estimatedCalories: widget.estimatedCalories,
              sessionId: widget.sessionId,
              challenges: challenges,
            ),
          ),
        );
      } else if (type == 'healthy_route') {
        final suggestionsList = (data['suggestions'] as List?) ?? [];
        final suggestions = suggestionsList
            .map((s) => s is Map<String, dynamic>
                ? s
                : Map<String, dynamic>.from(s as Map))
            .toList();
        final regenerationsRemaining = data['regenerations_remaining'] as int? ?? 3;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HealthySubstitutesScreen(
              sessionId: widget.sessionId,
              craving: widget.craving,
              selectedOption: widget.selectedOption,
              estimatedCalories: widget.estimatedCalories,
              suggestions: suggestions,
              regenerationsRemaining: regenerationsRemaining,
            ),
          ),
        );
      } else {
        // For invite_friend and challenge_random - coming soon
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This feature is coming soon! 🚀'),
            backgroundColor: Color(0xFF66BB6A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingType = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8F9FA),
              const Color(0xFFE8F5E9).withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selectedOption,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B5E20),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '~${widget.estimatedCalories} calories',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF66BB6A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What would you like to do?',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 26 : 30,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B5E20),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how you want to balance your craving',
                      style: TextStyle(
                        fontSize: 15,
                        color: const Color(0xFF1B5E20).withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Session type buttons
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildSessionTypeCard(
                      icon: Icons.fitness_center_rounded,
                      title: 'Solo Challenge',
                      description: 'Burn off those calories with a personalized workout challenge',
                      type: 'solo_challenge',
                      color: const Color(0xFF66BB6A),
                      isEnabled: true,
                    ),
                    const SizedBox(height: 16),
                    _buildSessionTypeCard(
                      icon: Icons.eco_rounded,
                      title: 'Healthier Substitution',
                      description: 'Get suggestions for healthier alternatives to satisfy your craving',
                      type: 'healthy_route',
                      color: const Color(0xFF4CAF50),
                      isEnabled: true,
                    ),
                    const SizedBox(height: 16),
                    _buildSessionTypeCard(
                      icon: Icons.people_rounded,
                      title: 'Invite Friend for Challenge',
                      description: 'Challenge a friend to work out together',
                      type: 'invite_friend',
                      color: const Color(0xFF42A5F5),
                      isEnabled: false,
                      comingSoon: true,
                    ),
                    const SizedBox(height: 16),
                    _buildSessionTypeCard(
                      icon: Icons.casino_rounded,
                      title: 'Random Challenge',
                      description: 'Get matched with a random user for a fun challenge',
                      type: 'challenge_random',
                      color: const Color(0xFFAB47BC),
                      isEnabled: false,
                      comingSoon: true,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionTypeCard({
    required IconData icon,
    required String title,
    required String description,
    required String type,
    required Color color,
    required bool isEnabled,
    bool comingSoon = false,
  }) {
    final isLoadingThis = _loadingType == type;

    return GestureDetector(
      onTap: _isLoading || !isEnabled ? null : () => _selectSessionType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEnabled
                ? color.withOpacity(0.2)
                : Colors.grey.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isEnabled
                  ? color.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isEnabled
                    ? color.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isEnabled ? color : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: isEnabled
                                ? const Color(0xFF1B5E20)
                                : Colors.grey,
                          ),
                        ),
                      ),
                      if (comingSoon)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Soon',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isEnabled
                          ? const Color(0xFF1B5E20).withOpacity(0.6)
                          : Colors.grey.withOpacity(0.6),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isLoadingThis)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: color,
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: isEnabled ? color.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }
}
