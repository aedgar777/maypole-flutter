import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maypole/core/app_theme.dart';
import 'package:maypole/core/widgets/error_dialog.dart';
import 'package:maypole/features/identity/domain/domain_user.dart';
import 'package:maypole/features/maypolechat/domain/user_mention.dart';
import 'package:maypole/features/maypolechat/presentation/viewmodels/mention_controller.dart';
import 'package:maypole/l10n/generated/app_localizations.dart';

/// A text field that supports @mentions with autocomplete
class MentionTextField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String threadId;
  final VoidCallback? onSubmitted;
  final FocusNode? focusNode;

  const MentionTextField({
    super.key,
    required this.controller,
    required this.threadId,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  ConsumerState<MentionTextField> createState() => _MentionTextFieldState();
}

class _MentionTextFieldState extends ConsumerState<MentionTextField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  String _currentMentionQuery = '';
  int _mentionStartIndex = -1;
  int _selectedUserIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;

    if (cursorPosition < 0) return;

    // Find if we're in the middle of typing a mention
    final mentionMatch = _findMentionAtCursor(text, cursorPosition);

    if (mentionMatch != null) {
      final query = mentionMatch['query'] as String;
      final startIndex = mentionMatch['startIndex'] as int;

      if (query != _currentMentionQuery || startIndex != _mentionStartIndex) {
        setState(() {
          _currentMentionQuery = query;
          _mentionStartIndex = startIndex;
          _selectedUserIndex = 0;
        });
        _showUserSuggestions(query);
      }
    } else {
      _removeOverlay();
      setState(() {
        _currentMentionQuery = '';
        _mentionStartIndex = -1;
        _selectedUserIndex = 0;
      });
    }
  }

  Map<String, dynamic>? _findMentionAtCursor(String text, int cursorPosition) {
    // Look backwards from cursor to find the last '@' symbol
    int atIndex = -1;
    for (int i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] == '@') {
        atIndex = i;
        break;
      }
      // Stop if we hit a space or newline (not in a mention)
      if (text[i] == ' ' || text[i] == '\n') {
        break;
      }
    }

    if (atIndex == -1) return null;

    // Check if there's a space or start of text before the @
    if (atIndex > 0 && text[atIndex - 1] != ' ' && text[atIndex - 1] != '\n') {
      return null; // @ must be at start or after whitespace
    }

    // Extract the query after @
    final query = text.substring(atIndex + 1, cursorPosition);

    // Query should not contain spaces
    if (query.contains(' ') || query.contains('\n')) {
      return null;
    }

    return {
      'query': query,
      'startIndex': atIndex,
    };
  }

  void _showUserSuggestions(String query) {
    _removeOverlay();

    _overlayEntry = _createOverlayEntry(query);
    Overlay.of(context).insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry(String query) {
    return OverlayEntry(
      builder: (context) =>
          Positioned(
            width: 300,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 8),
              targetAnchor: Alignment.topLeft,
              followerAnchor: Alignment.bottomLeft,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(8),
                child: Consumer(
                  builder: (context, ref, child) {
                    final users = ref.watch(
                      userSearchProvider(
                        UserSearchParams(
                          threadId: widget.threadId,
                          query: query,
                        ),
                      ),
                    );

                    if (users.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          AppLocalizations.of(context)!.noUsersFound,
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodyMedium,
                        ),
                      );
                    }

                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final isSelected = index == _selectedUserIndex;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Theme
                                .of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            leading: CircleAvatar(
                              backgroundImage: user.profilePictureUrl
                                  .isNotEmpty
                                  ? NetworkImage(user.profilePictureUrl)
                                  : null,
                              child: user.profilePictureUrl.isEmpty
                                  ? Text(user.username[0].toUpperCase())
                                  : null,
                            ),
                            title: Text(user.username),
                            onTap: () => _selectUser(user),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
    );
  }

  void _selectUser(DomainUser user) {
    final text = widget.controller.text;
    final beforeMention = text.substring(0, _mentionStartIndex);
    final afterMention = text.substring(widget.controller.selection.baseOffset);

    // Create the mention text with a special marker
    final mentionText = '@${user.username}';

    // Update the text
    final newText = beforeMention + mentionText + afterMention;
    widget.controller.text = newText;

    // Store the mention in the controller
    ref.read(mentionControllerProvider.notifier).addMention(
      UserMention(
        userId: user.firebaseID,
        username: user.username,
        startIndex: _mentionStartIndex,
        endIndex: _mentionStartIndex + mentionText.length,
      ),
    );

    // Move cursor after the mention
    final newCursorPosition = _mentionStartIndex + mentionText.length;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursorPosition),
    );

    _removeOverlay();
    setState(() {
      _currentMentionQuery = '';
      _mentionStartIndex = -1;
      _selectedUserIndex = 0;
    });

    // Return focus to the text field
    widget.focusNode?.requestFocus();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        decoration: InputDecoration(
          hintText: l10n.enterMessage,
          hintStyle: TextStyle(
            color: Theme
                .of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3),
          ),
          filled: true,
          fillColor: lightPurple,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        maxLines: null,
        textInputAction: TextInputAction.newline,
        onSubmitted: (_) => widget.onSubmitted?.call(),
      ),
    );
  }
}
