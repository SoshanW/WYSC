import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../session_type_screen/session_type_screen.dart';

class OptionsScreen extends StatefulWidget {
  final String sessionId;
  final List<Map<String, dynamic>> options;
  final String craving;
  final int regenerationsRemaining;

  const OptionsScreen({
    Key? key,
    required this.sessionId,
    required this.options,
    required this.craving,
    this.regenerationsRemaining = 3,
  }) : super(key: key);

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  int? _selectedIndex;
  bool _isLoading = false;
  bool _isRegenerating = false;
  late List<Map<String, dynamic>> _options;
  late int _regenerationsRemaining;

  @override
  void initState() {
    super.initState();
    _options = List.from(widget.options);
    _regenerationsRemaining = widget.regenerationsRemaining;
  }

  Future<void> _regenerateOptions() async {
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
      final data = await ApiService().regenerateCraveOptions(widget.sessionId);

      if (!mounted) return;

      final newOptions = (data['options'] as List?)
              ?.map((o) => o is Map<String, dynamic>
                  ? o
                  : Map<String, dynamic>.from(o as Map))
              .toList() ??
          [];

      setState(() {
        _options = newOptions;
        _regenerationsRemaining = data['regenerations_remaining'] as int? ?? 0;
        _selectedIndex = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New options loaded! 🍕'),
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
          content: Text('Failed to get new options'),
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

  Future<void> _onOptionSelected(int index) async {
    setState(() {
      _selectedIndex = index;
      _isLoading = true;
    });

    try {
      // Step 1: Select the option
      final optionName = _options[index]['option'] as String? ?? '';
      final selectData = await ApiService().selectOption(
        widget.sessionId,
        optionName,
      );

      final estimatedCalories = selectData['estimated_calories'] as int? ?? 0;

      if (!mounted) return;

      // Step 2: Navigate to session type selection screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionTypeScreen(
            sessionId: widget.sessionId,
            craving: widget.craving,
            selectedOption: optionName,
            estimatedCalories: estimatedCalories,
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
              // Title & Regenerate button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Your Options',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 24 : 28,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1B5E20),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    // Regenerate button
                    GestureDetector(
                      onTap: _isRegenerating || _regenerationsRemaining <= 0
                          ? null
                          : _regenerateOptions,
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
              // Options list
              Expanded(
                child: _options.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off_rounded,
                                  size: 64,
                                  color: const Color(0xFF66BB6A).withOpacity(0.4)),
                              const SizedBox(height: 16),
                              Text(
                                'No options found. Try a different craving!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: const Color(0xFF1B5E20).withOpacity(0.6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: _options.length,
                        itemBuilder: (context, index) {
                          return _buildOptionCard(
                            _options[index],
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

  Widget _buildOptionCard(
      Map<String, dynamic> optionData, int index, bool isSmallScreen) {
    final isSelected = _selectedIndex == index;
    final isProcessing = _isLoading && isSelected;

    final optionName = optionData['option'] as String? ?? 'Option ${index + 1}';
    final storeName = optionData['store'] as String? ?? '';
    final description = optionData['description'] as String? ?? '';

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      optionName,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 15 : 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B5E20),
                        height: 1.3,
                      ),
                    ),
                    if (storeName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.store_rounded,
                              size: 14,
                              color: const Color(0xFF66BB6A).withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              storeName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF66BB6A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF1B5E20).withOpacity(0.6),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
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
