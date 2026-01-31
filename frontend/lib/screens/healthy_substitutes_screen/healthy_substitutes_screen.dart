import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class HealthySubstitutesScreen extends StatefulWidget {
  final String sessionId;
  final String craving;
  final String selectedOption;
  final int estimatedCalories;
  final List<Map<String, dynamic>> suggestions;
  final int regenerationsRemaining;

  const HealthySubstitutesScreen({
    Key? key,
    required this.sessionId,
    required this.craving,
    required this.selectedOption,
    required this.estimatedCalories,
    required this.suggestions,
    required this.regenerationsRemaining,
  }) : super(key: key);

  @override
  State<HealthySubstitutesScreen> createState() =>
      _HealthySubstitutesScreenState();
}

class _HealthySubstitutesScreenState extends State<HealthySubstitutesScreen> {
  late List<Map<String, dynamic>> _suggestions;
  late int _regenerationsRemaining;
  int? _selectedIndex;
  bool _isLoading = false;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _suggestions = List.from(widget.suggestions);
    _regenerationsRemaining = widget.regenerationsRemaining;
  }

  Future<void> _regenerateSuggestions() async {
    if (_regenerationsRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No more re-prompts available!'),
          backgroundColor: Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isRegenerating = true;
    });

    try {
      final data = await ApiService().regenerateHealthy(widget.sessionId);

      if (!mounted) return;

      final newSuggestions = (data['suggestions'] as List?)
              ?.map((s) => s is Map<String, dynamic>
                  ? s
                  : Map<String, dynamic>.from(s as Map))
              .toList() ??
          [];

      setState(() {
        _suggestions = newSuggestions;
        _regenerationsRemaining = data['regenerations_remaining'] as int? ?? 0;
        _selectedIndex = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New suggestions loaded! 🌱'),
          backgroundColor: Color(0xFF66BB6A),
          behavior: SnackBarBehavior.floating,
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
          content: Text('Failed to get new suggestions'),
          backgroundColor: Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });
      }
    }
  }

  Future<void> _acceptSuggestion(int index) async {
    setState(() {
      _selectedIndex = index;
      _isLoading = true;
    });

    try {
      final suggestion = _suggestions[index]['suggestion'] as String? ?? '';
      final data = await ApiService().acceptHealthy(widget.sessionId, suggestion);

      if (!mounted) return;

      final pointsEarned = data['points_earned'] as int? ?? 0;
      final totalPoints = data['total_points'] as int? ?? 0;
      final rank = data['rank'] as String? ?? '';

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(Icons.eco_rounded, color: Color(0xFF66BB6A), size: 28),
              SizedBox(width: 12),
              Text(
                'Great Choice! 🌱',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You chose a healthier option!',
                style: TextStyle(
                  fontSize: 15,
                  color: const Color(0xFF1B5E20).withOpacity(0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '+$pointsEarned',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF66BB6A),
                          ),
                        ),
                        const Text(
                          'Points',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFF66BB6A).withOpacity(0.3),
                    ),
                    Column(
                      children: [
                        Text(
                          '$totalPoints',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                      ],
                    ),
                    if (rank.isNotEmpty) ...[
                      Container(
                        width: 1,
                        height: 40,
                        color: const Color(0xFF66BB6A).withOpacity(0.3),
                      ),
                      Column(
                        children: [
                          const Icon(
                            Icons.military_tech_rounded,
                            color: Color(0xFFFFB300),
                            size: 24,
                          ),
                          Text(
                            rank,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Navigate to home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF66BB6A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
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
          content: Text('Something went wrong'),
          backgroundColor: Color(0xFFEF5350),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
                            'Instead of: ${widget.selectedOption}',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1B5E20),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '~${widget.estimatedCalories} cal → Save calories!',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF66BB6A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Title & Regenerate
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Healthier Options 🌱',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1B5E20),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pick a healthier alternative',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF1B5E20).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    // Regenerate button
                    GestureDetector(
                      onTap: _isRegenerating || _regenerationsRemaining <= 0
                          ? null
                          : _regenerateSuggestions,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _regenerationsRemaining > 0
                              ? const Color(0xFF66BB6A).withOpacity(0.15)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _regenerationsRemaining > 0
                                ? const Color(0xFF66BB6A).withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_isRegenerating)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF66BB6A),
                                ),
                              )
                            else
                              Icon(
                                Icons.refresh_rounded,
                                size: 18,
                                color: _regenerationsRemaining > 0
                                    ? const Color(0xFF66BB6A)
                                    : Colors.grey,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              '$_regenerationsRemaining left',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _regenerationsRemaining > 0
                                    ? const Color(0xFF66BB6A)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Suggestions list
              Expanded(
                child: _suggestions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.eco_outlined,
                                size: 64,
                                color: const Color(0xFF66BB6A).withOpacity(0.4),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No suggestions available',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color:
                                      const Color(0xFF1B5E20).withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          return _buildSuggestionCard(index);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(int index) {
    final suggestion = _suggestions[index];
    final isSelected = _selectedIndex == index;
    final isProcessing = _isLoading && isSelected;

    final name = suggestion['suggestion'] as String? ?? 'Healthy Option';
    // Backend returns 'estimated_calories', fallback to 'calories' for compatibility
    final calories = (suggestion['estimated_calories'] as int?) ?? 
                     (suggestion['calories'] as int?) ?? 0;
    final description = suggestion['description'] as String? ?? '';
    final why = suggestion['why'] as String? ?? '';
    final savedCalories = widget.estimatedCalories - calories;

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
        onTap: _isLoading ? null : () => _acceptSuggestion(index),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Color(0xFF66BB6A),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF66BB6A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$calories cal',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF66BB6A),
                                ),
                              ),
                            ),
                            if (savedCalories > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Save $savedCalories cal',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
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
                      Icons.check_circle_outline_rounded,
                      size: 24,
                      color: const Color(0xFF66BB6A).withOpacity(0.5),
                    ),
                ],
              ),
              if (description.isNotEmpty || why.isNotEmpty) ...[
                const SizedBox(height: 12),
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF1B5E20).withOpacity(0.7),
                      height: 1.4,
                    ),
                  ),
                if (why.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 14,
                        color: const Color(0xFF66BB6A).withOpacity(0.8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          why,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF66BB6A).withOpacity(0.9),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
