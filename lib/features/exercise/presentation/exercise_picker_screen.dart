import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/default_exercises.dart';
import '../../../core/constants/exercise_category.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typo.dart';
import '../data/exercise_repository.dart';

final exercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchAllExercises();
});

final favoriteExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchFavoriteExercises();
});

final recentExerciseIdsProvider = StreamProvider<List<String>>((ref) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchRecentExerciseIds(limit: 10);
});

class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategoryIndex;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  void _selectExercise(Exercise exercise, bool isKorean) {
    final name = _getExerciseName(exercise, isKorean);
    Navigator.pop(context, {
      'id': exercise.id,
      'name': name,
      'exerciseType': exercise.exerciseType,
    });
  }

  void _toggleFavorite(String exerciseId) {
    ref.read(exerciseRepositoryProvider).toggleFavorite(exerciseId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKorean = l10n.isKorean;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectExercise),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: l10n.recentExercises),
            Tab(text: l10n.favoriteExercises),
            Tab(text: l10n.allExercises),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRecentTab(isKorean, l10n, theme),
          _buildFavoritesTab(isKorean, l10n, theme),
          _buildAllTab(isKorean, l10n, theme),
        ],
      ),
    );
  }

  Widget _buildRecentTab(bool isKorean, AppLocalizations l10n, ThemeData theme) {
    final recentIdsAsync = ref.watch(recentExerciseIdsProvider);
    final exercisesAsync = ref.watch(exercisesProvider);

    return recentIdsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${l10n.error}: $e')),
      data: (recentIds) {
        if (recentIds.isEmpty) {
          return _buildEmptyState(
            icon: Icons.history,
            message: l10n.noRecentExercises,
          );
        }
        return exercisesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('${l10n.error}: $e')),
          data: (allExercises) {
            final exerciseMap = {for (final e in allExercises) e.id: e};
            final recentExercises = recentIds
                .map((id) => exerciseMap[id])
                .whereType<Exercise>()
                .toList();
            if (recentExercises.isEmpty) {
              return _buildEmptyState(
                icon: Icons.history,
                message: l10n.noRecentExercises,
              );
            }
            return _buildExerciseList(recentExercises, isKorean, l10n, theme);
          },
        );
      },
    );
  }

  Widget _buildFavoritesTab(bool isKorean, AppLocalizations l10n, ThemeData theme) {
    final favoritesAsync = ref.watch(favoriteExercisesProvider);

    return favoritesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('${l10n.error}: $e')),
      data: (favorites) {
        if (favorites.isEmpty) {
          return _buildEmptyState(
            icon: Icons.star_border,
            message: l10n.noFavoriteExercises,
            hint: l10n.addFavoriteHint,
          );
        }
        return _buildExerciseList(favorites, isKorean, l10n, theme);
      },
    );
  }

  Widget _buildAllTab(bool isKorean, AppLocalizations l10n, ThemeData theme) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final categories = ExerciseCategories.get(isKorean);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, 0,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchExercise,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _buildCategoryChip(null, l10n.allCategories, isKorean),
              ...categories.asMap().entries.map((entry) =>
                  _buildCategoryChip(
                    entry.key.toString(), entry.value, isKorean,
                  )),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: exercisesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('${l10n.error}: $e')),
            data: (exercises) {
              final filtered = _filterExercises(exercises, isKorean);
              if (filtered.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.search_off,
                  message: l10n.noExercisesFound,
                );
              }
              return _buildExerciseList(filtered, isKorean, l10n, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseList(
    List<Exercise> exercises,
    bool isKorean,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise, isKorean, theme);
      },
    );
  }

  Widget _buildExerciseCard(Exercise exercise, bool isKorean, ThemeData theme) {
    final name = _getExerciseName(exercise, isKorean);
    final category = _getExerciseCategory(exercise, isKorean);
    final muscleGroup = _getExerciseMuscleGroup(exercise, isKorean);
    final categoryColor = AppColors.getCategoryColor(exercise.category);

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => _selectExercise(exercise, isKorean),
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              _buildExerciseAvatar(exercise, name, categoryColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: AppTypo.bodyLg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            '$category${muscleGroup != null && muscleGroup.isNotEmpty ? ' · $muscleGroup' : ''}',
                            style: TextStyle(
                              fontSize: AppTypo.bodySm,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  exercise.isFavorite ? Icons.star : Icons.star_border,
                  color: exercise.isFavorite
                      ? Colors.amber
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _toggleFavorite(exercise.id),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseAvatar(
    Exercise exercise,
    String name,
    Color categoryColor,
  ) {
    if (exercise.imagePath != null &&
        File(exercise.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: AppRadius.smAll,
        child: Image.file(
          File(exercise.imagePath!),
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.15),
        borderRadius: AppRadius.smAll,
      ),
      child: Center(
        child: Text(
          name[0],
          style: TextStyle(
            fontSize: AppTypo.titleMd,
            fontWeight: FontWeight.bold,
            color: categoryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String? categoryIndex,
    String label,
    bool isKorean,
  ) {
    final isSelected = _selectedCategoryIndex == categoryIndex;
    Color? chipColor;
    if (categoryIndex != null) {
      final categories = ExerciseCategories.get(isKorean);
      final catLabel = categories[int.parse(categoryIndex)];
      chipColor = ExerciseCategory.fromString(catLabel).color;
    }

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        selected: isSelected,
        selectedColor: chipColor ?? AppColors.primary,
        checkmarkColor: Colors.white,
        avatar: chipColor != null && !isSelected
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: chipColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onSelected: (_) {
          setState(() {
            _selectedCategoryIndex = categoryIndex;
          });
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? hint,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            style: TextStyle(
              fontSize: AppTypo.bodyLg,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              hint,
              style: TextStyle(
                fontSize: AppTypo.bodySm,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
