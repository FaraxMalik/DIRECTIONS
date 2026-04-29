import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/personality_results.dart';
import '../services/personality_service.dart';

class ManualPersonalityEntryScreen extends StatefulWidget {
  final PersonalityResults? existingResults;

  const ManualPersonalityEntryScreen({
    super.key,
    this.existingResults,
  });

  @override
  State<ManualPersonalityEntryScreen> createState() => _ManualPersonalityEntryScreenState();
}

class _ManualPersonalityEntryScreenState extends State<ManualPersonalityEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final PersonalityService _personalityService = PersonalityService();
  
  // MBTI Type
  String _selectedEI = 'E';
  String _selectedSN = 'S';
  String _selectedTF = 'T';
  String _selectedJP = 'J';
  
  // Big Five scores
  final _opennessController = TextEditingController();
  final _conscientiousnessController = TextEditingController();
  final _extraversionController = TextEditingController();
  final _agreeablenessController = TextEditingController();
  final _neuroticismController = TextEditingController();
  
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingResults != null) {
      _loadExistingResults();
    }
  }

  void _loadExistingResults() {
    final results = widget.existingResults!;
    
    // Parse MBTI type
    if (results.mbtiLikeType.length == 4) {
      _selectedEI = results.mbtiLikeType[0];
      _selectedSN = results.mbtiLikeType[1];
      _selectedTF = results.mbtiLikeType[2];
      _selectedJP = results.mbtiLikeType[3];
    }
    
    // Set Big Five scores
    _opennessController.text = results.bigFive.openness.toInt().toString();
    _conscientiousnessController.text = results.bigFive.conscientiousness.toInt().toString();
    _extraversionController.text = results.bigFive.extraversion.toInt().toString();
    _agreeablenessController.text = results.bigFive.agreeableness.toInt().toString();
    _neuroticismController.text = results.bigFive.neuroticism.toInt().toString();
  }

  String get _mbtiType => '$_selectedEI$_selectedSN$_selectedTF$_selectedJP';

  Future<void> _saveResults() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final results = PersonalityResults(
        mbtiLikeType: _mbtiType,
        bigFive: BigFiveScores(
          openness: double.parse(_opennessController.text),
          conscientiousness: double.parse(_conscientiousnessController.text),
          extraversion: double.parse(_extraversionController.text),
          agreeableness: double.parse(_agreeablenessController.text),
          neuroticism: double.parse(_neuroticismController.text),
        ),
        timestamp: DateTime.now(),
      );

      await _personalityService.savePersonalityResults(results);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personality results saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving results: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEF0),
      appBar: AppBar(
        title: const Text('Enter Personality Results'),
        backgroundColor: const Color(0xFFB20000),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Already know your personality type? Enter it manually here.',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // MBTI Type Selection
              const Text(
                'Jungian 16-Type (MBTI-like)',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB20000),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select one from each pair:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              
              _buildDichotomySelector(
                'Extraversion (E) vs Introversion (I)',
                ['E', 'I'],
                _selectedEI,
                (value) => setState(() => _selectedEI = value),
              ),
              const SizedBox(height: 12),
              _buildDichotomySelector(
                'Sensing (S) vs Intuition (N)',
                ['S', 'N'],
                _selectedSN,
                (value) => setState(() => _selectedSN = value),
              ),
              const SizedBox(height: 12),
              _buildDichotomySelector(
                'Thinking (T) vs Feeling (F)',
                ['T', 'F'],
                _selectedTF,
                (value) => setState(() => _selectedTF = value),
              ),
              const SizedBox(height: 12),
              _buildDichotomySelector(
                'Judging (J) vs Perceiving (P)',
                ['J', 'P'],
                _selectedJP,
                (value) => setState(() => _selectedJP = value),
              ),
              const SizedBox(height: 16),
              
              // Show selected type
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB20000), Color(0xFF8B0000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Your Type: ',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _mbtiType,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Big Five Scores
              const Text(
                'Big Five Personality Traits',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB20000),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter scores from 0-100:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              
              _buildScoreInput('Openness', _opennessController, 
                'Creativity, curiosity, imagination'),
              const SizedBox(height: 12),
              _buildScoreInput('Conscientiousness', _conscientiousnessController,
                'Organization, discipline, goal-oriented'),
              const SizedBox(height: 12),
              _buildScoreInput('Extraversion', _extraversionController,
                'Sociability, assertiveness, energy'),
              const SizedBox(height: 12),
              _buildScoreInput('Agreeableness', _agreeablenessController,
                'Compassion, cooperation, trust'),
              const SizedBox(height: 12),
              _buildScoreInput('Neuroticism', _neuroticismController,
                'Emotional stability, anxiety, stress'),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveResults,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB20000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              'Save Results',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDichotomySelector(
    String title,
    List<String> options,
    String selected,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB20000).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: options.map((option) {
              final isSelected = option == selected;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => onChanged(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFFB20000) 
                            : Colors.white,
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFFB20000) 
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        option,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreInput(
    String label,
    TextEditingController controller,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFB20000).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              hintText: 'Enter 0-100',
              suffixText: '%',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFB20000), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a score';
              }
              final score = int.tryParse(value);
              if (score == null || score < 0 || score > 100) {
                return 'Score must be between 0-100';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _opennessController.dispose();
    _conscientiousnessController.dispose();
    _extraversionController.dispose();
    _agreeablenessController.dispose();
    _neuroticismController.dispose();
    super.dispose();
  }
}





