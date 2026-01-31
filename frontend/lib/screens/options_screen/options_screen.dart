import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/challenge_models.dart';
import '../solo_challenge_suggestions_screen/solo_challenge_suggestions_screen.dart';

class OptionsScreen extends StatefulWidget {
  final String sessionId;
  final List<String> options;
  final String craving;

  const OptionsScreen({
    Key? key,
    required this.sessionId,
    required this.options,
    required this.craving,
  }) : super(key: key);

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  int? _selectedIndex;
  bool _isLoading = false;

  Future<void> _onOptionSelected(int index) async {
    setState(() {
      _selectedIndex = index;
      _isLoading = true;
    });

    try {
      // Step 1: Select the option
      final selectData = await ApiService().selectOption(
        widget.sessionId,
        widget.options[index],
      );

      final estimatedCalories = selectData['estimated_calories'] as int? ?? 0;

      // Step 2: Auto-choose solo_challenge type
      final typeData = await ApiService().chooseType(
        widget.sessionId,
        'solo_challenge',
      );

      if (!mounted) return;

      final challengesList = (typeData['challenges'] as List?) ?? [];
      final challenges = challengesList
          .asMap()
          .entries
          .map((e) => ChallengeData.fromApiChallenge(
                e.value as Map<String, dynamic>,
                e.key,
              ))
          .toList();

      // Navigate to challenge suggestions
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SoloChallengeSuggestionsScreen(
            craving: widget.craving,
            estimatedCalories: estimatedCalories,
            sessionId: widget.sessionId,
            challenges: challenges,
          ),
        ),
      );
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
      if (mounted) setState(() => _isLoading = false);
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
                            'Craving: ${widget.craving}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 18 : 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1B5E20),
                            ),
                          ),
                          Text(
                            'Pick your preferred option',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF1B5E20).withOpacity(0.6),
                              fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Options',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 26 : 30,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1B5E20),
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              // Options list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: widget.options.length,
                  itemBuilder: (context, index) {
                    return _buildOptionCard(
                      widget.options[index],
                      index,
                      isSmallScreen,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(String option, int index, bool isSmallScreen) {
    final isSelected = _selectedIndex == index;
    final isProcessing = _isLoading && isSelected;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: _isLoading ? null : () => _onOptionSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF66BB6A)
                  : const Color(0xFF66BB6A).withOpacity(0.1),
              width: isSelected ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF66BB6A).withOpacity(0.2)
                    : const Color(0xFF66BB6A).withOpacity(0.05),
                blurRadius: isSelected ? 20 : 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isSmallScreen ? 44 : 50,
                height: isSmallScreen ? 44 : 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF66BB6A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1B5E20),
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (isProcessing)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Color(0xFF66BB6A),
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: const Color(0xFF66BB6A).withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
