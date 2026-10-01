import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/default_exercises.dart';
import '../../../core/constants/exercise_category.dart';
import '../../../core/constants/exercise_type.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typo.dart';
import '../../exercise/data/exercise_repository.dart';

final exercisesStreamProvider = StreamProvider<List<Exercise>>((ref) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchAllExercises();
});

Future<String?> _saveExerciseImage(XFile pickedFile) async {
  final appDir = await getApplicationDocumentsDirectory();
  final imagesDir = Directory(p.join(appDir.path, 'exercise_images'));
  if (!imagesDir.existsSync()) {
    imagesDir.createSync(recursive: true);
  }
  final ext = p.extension(pickedFile.path);
  final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
  final savedPath = p.join(imagesDir.path, fileName);
  await File(pickedFile.path).copy(savedPath);
  return savedPath;
}

class ManageExercisesScreen extends ConsumerStatefulWidget {
  const ManageExercisesScreen({super.key});

  @override
  ConsumerState<ManageExercisesScreen> createState() =>
      _ManageExercisesScreenState();
}

class _ManageExercisesScreenState extends ConsumerState<ManageExercisesScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final exercisesAsync = ref.watch(exercisesStreamProvider);
    final categories = ExerciseCategories.get(l10n.isKorean);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageExercises),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExerciseDialog(context, ref, l10n),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _buildCategoryChip(null, l10n.allCategories, l10n.isKorean),
                ...categories.map((cat) =>
                    _buildCategoryChip(cat, cat, l10n.isKorean)),
              ],
            ),
          ),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) =>
                  _buildExerciseGrid(context, ref, l10n, exercises, theme),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.error)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    String? category,
    String label,
    bool isKorean,
  ) {
    final isSelected = _selectedCategory == category;
    Color? chipColor;
    if (category != null) {
      chipColor = ExerciseCategory.fromString(category).color;
    }

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
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
          setState(() => _selectedCategory = category);
        },
      ),
    );
  }

  Widget _buildExerciseGrid(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<Exercise> exercises,
    ThemeData theme,
  ) {
    var filtered = exercises;
    if (_selectedCategory != null) {
      filtered = exercises.where((e) {
        final displayCategory = DefaultExerciseHelper.getDisplayCategory(
          e.id,
          e.category,
          l10n.isKorean,
        );
        return displayCategory == _selectedCategory;
      }).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 56, color: Colors.grey[400]),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.noExercisesFound,
              style: TextStyle(fontSize: AppTypo.bodyLg, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final exercise = filtered[index];
        return _buildExerciseCard(context, ref, l10n, exercise, theme);
      },
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Exercise exercise,
    ThemeData theme,
  ) {
    final displayName = DefaultExerciseHelper.getDisplayName(
      exercise.id,
      exercise.name,
      l10n.isKorean,
    );
    final displayCategory = DefaultExerciseHelper.getDisplayCategory(
      exercise.id,
      exercise.category,
      l10n.isKorean,
    );
    final displayMuscleGroup = DefaultExerciseHelper.getDisplayMuscleGroup(
      exercise.id,
      exercise.muscleGroup,
      l10n.isKorean,
    );
    final categoryColor = AppColors.getCategoryColor(exercise.category);
    final hasImage =
        exercise.imagePath != null && File(exercise.imagePath!).existsSync();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            _showEditExerciseDialog(context, ref, l10n, exercise),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: hasImage
                  ? Image.file(
                      File(exercise.imagePath!),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: categoryColor.withValues(alpha: 0.12),
                      child: Center(
                        child: Text(
                          displayName[0],
                          style: TextStyle(
                            fontSize: AppTypo.displayLg,
                            fontWeight: FontWeight.bold,
                            color: categoryColor,
                          ),
                        ),
                      ),
                    ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.sm, AppSpacing.xs, AppSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: categoryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            displayCategory,
                            style: TextStyle(
                              fontSize: AppTypo.caption,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: AppTypo.bodyMd,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (displayMuscleGroup.isNotEmpty) ...[
                      const SizedBox(height: 1),
                      Text(
                        displayMuscleGroup,
                        style: TextStyle(
                          fontSize: AppTypo.caption,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!exercise.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Text(
                              l10n.customExercise,
                              style: TextStyle(
                                fontSize: AppTypo.overline,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (!exercise.isDefault)
                          InkWell(
                            onTap: () =>
                                _showDeleteDialog(context, ref, l10n, exercise),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExerciseDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final nameController = TextEditingController();
    final muscleGroupController = TextEditingController();
    final categories = l10n.isKorean ? ExerciseCategories.ko : ExerciseCategories.en;
    String selectedCategory = categories.first;
    String? pickedImagePath;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.addExerciseTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImagePicker(context, l10n, pickedImagePath, (path) {
                  setState(() => pickedImagePath = path);
                }),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.exerciseName,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: l10n.categoryLabel,
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: muscleGroupController,
                  decoration: InputDecoration(
                    labelText: l10n.muscleGroupLabel,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.enterExerciseName)),
                  );
                  return;
                }

                String? savedImagePath;
                if (pickedImagePath != null) {
                  savedImagePath = await _saveExerciseImage(XFile(pickedImagePath!));
                }

                final repo = ref.read(exerciseRepositoryProvider);
                final isCardio = ExerciseCategory.fromString(selectedCategory) == ExerciseCategory.cardio;
                await repo.createExercise(
                  name: nameController.text.trim(),
                  category: selectedCategory,
                  muscleGroup: muscleGroupController.text.trim().isNotEmpty
                      ? muscleGroupController.text.trim()
                      : null,
                  imagePath: savedImagePath,
                  exerciseType: isCardio ? ExerciseType.cardio : ExerciseType.strength,
                );

                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.exerciseAdded)),
                  );
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditExerciseDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Exercise exercise,
  ) {
    final displayName = DefaultExerciseHelper.getDisplayName(
      exercise.id, exercise.name, l10n.isKorean,
    );
    final displayMuscleGroup = DefaultExerciseHelper.getDisplayMuscleGroup(
      exercise.id, exercise.muscleGroup, l10n.isKorean,
    );
    final nameController = TextEditingController(text: displayName);
    final muscleGroupController = TextEditingController(text: displayMuscleGroup ?? '');
    final categories = l10n.isKorean ? ExerciseCategories.ko : ExerciseCategories.en;
    String selectedCategory = categories.contains(exercise.category)
        ? exercise.category
        : ExerciseCategories.translate(exercise.category, l10n.isKorean);

    if (!categories.contains(selectedCategory)) {
      selectedCategory = categories.first;
    }

    String? currentImagePath = exercise.imagePath;
    bool imageRemoved = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.editExerciseTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImagePicker(context, l10n, currentImagePath, (path) {
                  setState(() {
                    currentImagePath = path;
                    imageRemoved = path == null;
                  });
                }, showRemove: currentImagePath != null),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.exerciseName,
                  ),
                  enabled: !exercise.isDefault,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: l10n.categoryLabel,
                  ),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: exercise.isDefault
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => selectedCategory = value);
                          }
                        },
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: muscleGroupController,
                  decoration: InputDecoration(
                    labelText: l10n.muscleGroupLabel,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.enterExerciseName)),
                  );
                  return;
                }

                Value<String?> imagePathValue = const Value.absent();
                if (imageRemoved) {
                  if (exercise.imagePath != null) {
                    final oldFile = File(exercise.imagePath!);
                    if (oldFile.existsSync()) oldFile.deleteSync();
                  }
                  imagePathValue = const Value(null);
                } else if (currentImagePath != null && currentImagePath != exercise.imagePath) {
                  final savedPath = await _saveExerciseImage(XFile(currentImagePath!));
                  if (exercise.imagePath != null) {
                    final oldFile = File(exercise.imagePath!);
                    if (oldFile.existsSync()) oldFile.deleteSync();
                  }
                  imagePathValue = Value(savedPath);
                }

                final repo = ref.read(exerciseRepositoryProvider);
                await repo.updateExercise(
                  exercise.id,
                  name: exercise.isDefault ? null : nameController.text.trim(),
                  category: exercise.isDefault ? null : selectedCategory,
                  muscleGroup: muscleGroupController.text.trim().isNotEmpty
                      ? muscleGroupController.text.trim()
                      : null,
                  imagePath: imagePathValue,
                );

                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.exerciseUpdated)),
                  );
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(
    BuildContext context,
    AppLocalizations l10n,
    String? currentImagePath,
    ValueChanged<String?> onImageChanged, {
    bool showRemove = false,
  }) {
    final hasImage = currentImagePath != null && File(currentImagePath).existsSync();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (sheetContext) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(l10n.takePhoto),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.camera,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      onImageChanged(picked.path);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text(l10n.chooseFromGallery),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 800,
                      maxHeight: 800,
                      imageQuality: 85,
                    );
                    if (picked != null) {
                      onImageChanged(picked.path);
                    }
                  },
                ),
                if (showRemove)
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: Text(l10n.removePhoto, style: const TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onImageChanged(null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: AppRadius.lgAll,
          image: hasImage
              ? DecorationImage(
                  image: FileImage(File(currentImagePath)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasImage
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 36, color: Colors.grey[500]),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.exercisePhoto,
                    style: TextStyle(fontSize: AppTypo.bodySm, color: Colors.grey[500]),
                  ),
                ],
              ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Exercise exercise,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteExerciseTitle),
        content: Text(l10n.deleteExerciseMessage(exercise.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final repo = ref.read(exerciseRepositoryProvider);
              await repo.deleteExercise(exercise.id);

              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.exerciseDeleted)),
                );
              }
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
