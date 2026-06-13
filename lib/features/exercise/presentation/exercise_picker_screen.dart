import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/default_exercises.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../data/exercise_repository.dart';

final exercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchAllExercises();
});

class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  String? _selectedCategoryIndex;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DefaultExercise? _findDefaultExercise(String id) {
    try {
      return defaultExercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  String _getExerciseName(Exercise exercise, bool isKorean) {
    final defaultEx = _findDefaultExercise(exercise.id);
    if (defaultEx != null) {
      return defaultEx.getName(isKorean);
    }
    return exercise.name;
  }

  String _getExerciseCategory(Exercise exercise, bool isKorean) {
    return DefaultExerciseHelper.getDisplayCategory(
      exercise.id,
      exercise.category,
      isKorean,
    );
  }

  String? _getExerciseMuscleGroup(Exercise exercise, bool isKorean) {
    final defaultEx = _findDefaultExercise(exercise.id);
    if (defaultEx != null) {
      return defaultEx.getMuscleGroup(isKorean);
    }
    return exercise.muscleGroup;
  }

  List<Exercise> _filterExercises(List<Exercise> exercises, bool isKorean) {
    var filtered = exercises;

    if (_selectedCategoryIndex != null) {
      final categories = ExerciseCategories.get(isKorean);
      final selectedCategory = categories[int.parse(_selectedCategoryIndex!)];
      filtered = filtered
          .where((e) {
            final displayCategory = DefaultExerciseHelper.getDisplayCategory(
              e.id,
              e.category,
              isKorean,
            );
            return displayCategory == selectedCategory;
          })
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((e) {
            final name = _getExerciseName(e, isKorean);
            return name.toLowerCase().contains(_searchQuery.toLowerCase());
          })
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKorean = l10n.isKorean;
    final exercisesAsync = ref.watch(exercisesProvider);
    final categories = ExerciseCategories.get(isKorean);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.selectExercise,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchExercise,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(null, isKorean ? '전체' : 'All'),
                        ...categories.asMap().entries.map((entry) =>
                            _buildCategoryChip(entry.key.toString(), entry.value)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: exercisesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('${l10n.error}: $e')),
                data: (exercises) {
                  final filtered = _filterExercises(exercises, isKorean);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(l10n.noExercisesFound, style: const TextStyle(color: Colors.grey)),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final exercise = filtered[index];
                      final name = _getExerciseName(exercise, isKorean);
                      final category = _getExerciseCategory(exercise, isKorean);
                      final muscleGroup = _getExerciseMuscleGroup(exercise, isKorean);

                      return ListTile(
                        leading: exercise.imagePath != null && File(exercise.imagePath!).existsSync()
                            ? CircleAvatar(
                                backgroundImage: FileImage(File(exercise.imagePath!)),
                              )
                            : CircleAvatar(
                                backgroundColor: AppColors.getCategoryColor(exercise.category),
                                child: Text(
                                  name[0],
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                        title: Text(name),
                        subtitle: Text('$category${muscleGroup != null ? ' • $muscleGroup' : ''}'),
                        onTap: () {
                          Navigator.pop(context, {
                            'id': exercise.id,
                            'name': name,
                            'exerciseType': exercise.exerciseType,
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip(String? categoryIndex, String label) {
    final isSelected = _selectedCategoryIndex == categoryIndex;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedCategoryIndex = categoryIndex;
          });
        },
      ),
    );
  }
}
