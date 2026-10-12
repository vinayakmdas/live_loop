import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/appcolors.dart';
import '../../data/datasources/meeting_remote_datasource.dart';
import '../../data/repositories/meeting_repository_impl.dart';
import '../../domain/usecases/create_meeting.dart';
import '../bloc/meeting_bloc.dart';
import '../bloc/meeting_event.dart';
import '../bloc/meeting_state.dart';
import '../widgets/meeting_access_option.dart';
import '../widgets/meeting_form_field.dart';

class CreateMeetingPage extends StatelessWidget {
  const CreateMeetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataSource = MeetingRemoteDataSourceImpl();
    final repository = MeetingRepositoryImpl(dataSource);
    final useCase = CreateMeeting(repository);

    return BlocProvider(
      create: (_) => MeetingBloc(createMeeting: useCase),
      child: const _CreateMeetingView(),
    );
  }
}

class _CreateMeetingView extends StatefulWidget {
  const _CreateMeetingView();

  @override
  State<_CreateMeetingView> createState() => _CreateMeetingViewState();
}

class _CreateMeetingViewState extends State<_CreateMeetingView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const _categories = ['Project', 'Friends', 'Community', 'Team', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, MeetingState state) {
    FocusScope.of(context).unfocus();
    context.read<MeetingBloc>().add(MeetingSubmitted(
      name: _nameController.text,
      description: _descriptionController.text,
      category: state.category,
      accessType: state.accessType,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('My meetings', style: TextStyle(color: AppColors.inactiveText, fontSize: 14, fontWeight: FontWeight.w500)),
      ),
      body: SafeArea(
        child: BlocConsumer<MeetingBloc, MeetingState>(
          listener: (context, state) {
            if (state.status == MeetingStatus.success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.success),
              );
              Navigator.maybePop(context, true);
            } else if (state.status == MeetingStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.navigationBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.navigationBorder),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Create a meeting space', style: TextStyle(color: AppColors.textPrimary, fontSize: 21, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                                const SizedBox(height: 26),
                                MeetingFormField(
                                  label: 'Meeting name',
                                  hint: 'e.g. Kerala Community',
                                  controller: _nameController,
                                ),
                                const SizedBox(height: 20),
                                MeetingFormField(
                                  label: 'Description',
                                  hint: 'What brings this group together?',
                                  controller: _descriptionController,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 20),
                                const Text('Category', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 9),
                                DropdownButtonFormField<String>(
                                  value: state.category.isEmpty ? null : state.category,
                                  hint: const Text(
                                    'Choose a category',
                                    style: TextStyle(color: AppColors.hintText, fontSize: 13),
                                  ),
                                  dropdownColor: AppColors.navigationBackground,
                                  iconEnabledColor: AppColors.inactiveText,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppColors.background,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.navigationBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: AppColors.primary),
                                    ),
                                  ),
                                  items: _categories.map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  )).toList(),
                                  onChanged: (value) {
                                    if (value != null) context.read<MeetingBloc>().add(MeetingCategoryChanged(value));
                                  },
                                ),
                                const SizedBox(height: 22),
                                const Text('Who can access this space?', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                MeetingAccessOption(
                                  title: 'Invite only',
                                  value: 'invite_only',
                                  groupValue: state.accessType,
                                  onChanged: (value) => context.read<MeetingBloc>().add(MeetingAccessChanged(value)),
                                ),
                                const SizedBox(height: 10),
                                MeetingAccessOption(
                                  title: 'Anyone with the link',
                                  value: 'anyone_with_link',
                                  groupValue: state.accessType,
                                  onChanged: (value) => context.read<MeetingBloc>().add(MeetingAccessChanged(value)),
                                ),
                                const SizedBox(height: 20),
                                const Divider(color: AppColors.navigationBorder, height: 1),
                                const SizedBox(height: 16),
                                if (state.status == MeetingStatus.failure && state.message.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(state.message, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                                  ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: state.status == MeetingStatus.submitting
                                          ? null
                                          : () => Navigator.maybePop(context),
                                      child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                    ),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: state.status == MeetingStatus.submitting
                                          ? null
                                          : () => _submit(context, state),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        disabledBackgroundColor: AppColors.primaryDisabled,
                                        foregroundColor: AppColors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                      child: state.status == MeetingStatus.submitting
                                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                                          : const Text('Create meeting', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _MeetingBottomNavigation(
                  onHome: () => Navigator.maybePop(context),
                  onMeetings: () {},
                  onNotifications: () {},
                  onProfile: () {},
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MeetingBottomNavigation extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onMeetings;
  final VoidCallback onNotifications;
  final VoidCallback onProfile;

  const _MeetingBottomNavigation({
    required this.onHome,
    required this.onMeetings,
    required this.onNotifications,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navigationBackground,
        border: Border.all(color: AppColors.navigationBorder),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          _NavItem(label: 'Home', selected: false, onTap: onHome),
          _NavItem(label: 'Meetings', selected: true, onTap: onMeetings),
          _NavItem(label: 'Notifications', selected: false, onTap: onNotifications),
          _NavItem(label: 'Profile', selected: false, onTap: onProfile),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? AppColors.selectedBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AppColors.selectedText : AppColors.inactiveText,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
