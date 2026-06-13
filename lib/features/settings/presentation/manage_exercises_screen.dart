import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/default_exercises.dart';
import '../../../core/constants/exercise_type.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
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

class ManageExercisesScreen extends ConsumerWidget {
  const ManageExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final exercisesAsync = ref.watch(exercisesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageExercises),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExerciseDialog(context, ref, l10n),
        child: const Icon(Icons.add),
      ),
      body: exercisesAsync.when(
        data: (exercises) => _buildExerciseList(context, ref, l10n, exercises),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.error)),
      ),
    );
  }

  Widget _buildExerciseList(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    List<Exercise> exercises,
  ) {
    final categories = l10n.isKorean ? ExerciseCategories.ko : ExerciseCategories.en;
    final groupedExercises = <String, List<Exercise>>{};

    for (final category in categories) {
      groupedExercises[category] = exercises
          .where((e) {
            final displayCategory = DefaultExerciseHelper.getDisplayCategory(
              e.id,
              e.category,
              l10n.isKorean,
            );
            return displayCategory == category;
          })
          .toList();
    }

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryExercises = groupedExercises[category] ?? [];

        if (categoryExercises.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.getCategoryColor(
                        l10n.isKorean ? category : ExerciseCategories.translate(category, true),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${categoryExercises.length})',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ...categoryExercises.map((exercise) => _buildExerciseTile(
                  context,
                  ref,
                  l10n,
                  exercise,
                )),
          ],
        );
      },
    );
  }

  Widget _buildExerciseTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Exercise exercise,
  ) {
    final displayName = DefaultExerciseHelper.getDisplayName(
      exercise.id,
      exercise.name,
      l10n.isKorean,
    );
    final displayMuscleGroup = DefaultExerciseHelper.getDisplayMuscleGroup(
      exercise.id,
      exercise.muscleGroup,
      l10n.isKorean,
    );

    return ListTile(
      leading: exercise.imagePath != null && File(exercise.imagePath!).existsSync()
          ? CircleAvatar(
              backgroundImage: FileImage(File(exercise.imagePath!)),
            )
          : CircleAvatar(
              backgroundColor: AppColors.getCategoryColor(exercise.category),
              child: Text(
                displayName[0],
                style: const TextStyle(color: Colors.white),
              ),
            ),
      title: Text(displayName),
      subtitle: displayMuscleGroup.isNotEmpty
          ? Text(
              displayMuscleGroup,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!exercise.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.customExercise,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                ),
              ),
            ),
          if (!exercise.isDefault) const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => _showEditExerciseDialog(context, ref, l10n, exercise),
          ),
          if (!exercise.isDefault)
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _showDeleteDialog(context, ref, l10n, exercise),
            ),
        ],
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
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.exerciseName,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
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
                final isCardio = selectedCategory == '유산소' || selectedCategory == 'Cardio';
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
    final nameController = TextEditingController(text: exercise.name);
    final muscleGroupController = TextEditingController(text: exercise.muscleGroup ?? '');
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
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.exerciseName,
                  ),
                  enabled: !exercise.isDefault,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
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
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
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
                  Icon(Icons.add_a_photo, size: 32, color: Colors.grey[500]),
                  const SizedBox(height: 4),
                  Text(
                    l10n.exercisePhoto,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
