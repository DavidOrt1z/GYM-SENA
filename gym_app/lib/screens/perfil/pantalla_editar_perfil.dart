import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:gym_app/models/user_model.dart';
import 'package:gym_app/screens/perfil/pantalla_perfil_guardado.dart';
import 'package:gym_app/l10n/app_localizations.dart';
import '../../utils/constants.dart';
import '../../utils/error_messages.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  final ImagePicker _imagePicker = ImagePicker();
  late String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _lastNameController = TextEditingController(
      text: widget.user.lastName ?? '',
    );
    _ageController = TextEditingController(
      text: widget.user.age?.toString() ?? '',
    );
    _currentAvatarUrl = widget.user.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadPhoto() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingPhoto = true);

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        setState(() => _isUploadingPhoto = false);
        return;
      }

      final userId = currentUser.id;
      final fileName = 'avatar_$userId.jpg';

      // Leer archivo como bytes usando XFile
      final Uint8List bytes = await pickedFile.readAsBytes();

      debugPrint('DEBUG: Subiendo foto, userId: $userId, fileName: $fileName');

      // Subir a Supabase Storage usando uploadBinary con upsert
      await Supabase.instance.client.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Obtener URL pública
      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(fileName);

      debugPrint('DEBUG: URL generada: $publicUrl');

      if (mounted) {
        setState(() {
          _currentAvatarUrl = publicUrl;
          _isUploadingPhoto = false;
        });
      }
    } catch (e) {
      debugPrint('Error uploading photo: $e');
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessages.map(
                e,
                fallback: isEnglish
                    ? 'Could not upload the photo. Please try again.'
                    : 'No se pudo subir la foto. Intenta nuevamente',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEnglish ? 'Name is required' : 'El nombre es requerido',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authUserId = Supabase.instance.client.auth.currentUser?.id;
      if (authUserId == null) {
        throw Exception(
          isEnglish ? 'User not authenticated' : 'Usuario no autenticado',
        );
      }

      final userRow = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('id_autenticacion', authUserId)
          .maybeSingle();

      final userId = userRow?['id']?.toString() ?? authUserId;

      int? age;
      if (_ageController.text.isNotEmpty) {
        age = int.tryParse(_ageController.text);
      }

      // Construir mapa de actualización con solo los campos disponibles
      final updateData = {
        'nombre_completo': _nameController.text,
        if (_lastNameController.text.isNotEmpty)
          'apellido': _lastNameController.text,
        if (age != null) 'edad': age,
        if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty)
          'url_avatar': _currentAvatarUrl,
      };

      debugPrint('DEBUG: Guardando datos: $updateData');

      await Supabase.instance.client
          .from('users')
          .update(updateData)
          .eq('id', userId);

      debugPrint('DEBUG: Datos guardados exitosamente');

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProfileSavedScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppErrorMessages.map(
                e,
                fallback: isEnglish
                    ? 'Could not save profile. Please try again.'
                    : 'No se pudo guardar el perfil. Intenta nuevamente',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    final createdAt = widget.user.createdAt;
    final year = createdAt?.year ?? DateTime.now().year;

    return Scaffold(
      backgroundColor: DARKER_BG,
      appBar: AppBar(
        backgroundColor: DARKER_BG,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: WHITE),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context, 'editar_perfil'),
          style: TextStyle(
            color: WHITE,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Avatar con botón de cámara
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: const Color(0xFFE8D4B8),
                    child: ClipOval(
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child:
                            _currentAvatarUrl != null &&
                                _currentAvatarUrl!.isNotEmpty
                            ? Image.network(
                                '$_currentAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      widget.user.fullName[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 48,
                                        color: Color(0xFF6B5D4F),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  widget.user.fullName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    color: Color(0xFF6B5D4F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  // Botón flotante para cambiar foto
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: PRIMARY_COLOR,
                          shape: BoxShape.circle,
                          border: Border.all(color: DARKER_BG, width: 3),
                        ),
                        child: _isUploadingPhoto
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    WHITE,
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt,
                                color: WHITE,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nombre
              Text(
                widget.user.fullName,
                style: const TextStyle(
                  color: WHITE,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Miembro desde
              Text(
                isEnglish ? 'Member since $year' : 'Miembro desde $year',
                style: const TextStyle(color: SECONDARY_COLOR, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Nombre
              _buildInputField(
                label: isEnglish ? 'First name' : 'Nombre',
                controller: _nameController,
                hint: isEnglish ? 'Enter your first name' : 'Ingresa tu nombre',
              ),
              const SizedBox(height: 20),

              // Apellido
              _buildInputField(
                label: isEnglish ? 'Last name' : 'Apellido',
                controller: _lastNameController,
                hint: isEnglish
                    ? 'Enter your last name'
                    : 'Ingresa tu apellido',
              ),
              const SizedBox(height: 20),

              // Años
              _buildInputField(
                label: isEnglish ? 'Age' : 'Años',
                controller: _ageController,
                hint: isEnglish ? 'Enter your age' : 'Ingresa tu edad',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 40),

              // Botón Guardar cambios
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PRIMARY_COLOR,
                    disabledBackgroundColor: PRIMARY_COLOR.withValues(
                      alpha: 0.5,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(WHITE),
                          ),
                        )
                      : Text(
                          isEnglish ? 'Save changes' : 'Guardar cambios',
                          style: TextStyle(
                            color: WHITE,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: WHITE,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: WHITE, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: SECONDARY_COLOR),
            filled: true,
            fillColor: DARK_BG,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
