import 'dart:async';
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:livekit_client/livekit_client.dart' hide ChatMessage;
import 'package:permission_handler/permission_handler.dart';
import 'package:frontend/core/theme/appcolors.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_bloc.dart';
import 'package:frontend/features/auth/presentation/bloc/auth_bloc_state.dart';
import 'package:frontend/features/home/domain/entities/chat_message.dart';
import 'package:frontend/features/home/data/services/chat_socket_service.dart';
import 'package:frontend/features/home/presentation/widget/in_call_chat_sheet.dart';

class VideoCallScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String roomName;
  final String? userName;
  final String? userProfileImage;

  const VideoCallScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.roomName,
    this.userName,
    this.userProfileImage,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  bool _isConnecting = false;
  bool _isConnected = false;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  bool _isTogglingMic = false;
  bool _isTogglingCamera = false;
  bool _speakerphoneOn = true;
  bool _isPipSwapped = false;
  String? _errorMessage;

  // In-call real-time chat state (Socket.IO)
  final ChatSocketService _chatService = ChatSocketService();
  final List<ChatMessage> _chatMessages = [];
  bool _isChatOpen = false;
  int _unreadChatCount = 0;
  String? _typingUserName;
  ChatMessage? _latestToastMessage;
  Timer? _toastTimer;

  @override
  void initState() {
    super.initState();
    _connectToRoom();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChatService();
    });
  }

  void _initChatService() {
    _chatService.onMessageReceived = (message) {
      if (!mounted) return;
      setState(() {
        final existingIndex = _chatMessages.indexWhere((m) => m.id == message.id);
        if (existingIndex >= 0) {
          _chatMessages[existingIndex] = message;
        } else {
          _chatMessages.add(message);
        }
        final isMe = message.isFromUser(_currentUserId, _getUserDisplayName());
        if (!isMe && !_isChatOpen) {
          _unreadChatCount++;
          _showInCallToast(message);
        }
      });
    };

    _chatService.onRoomHistory = (messages) {
      if (!mounted) return;
      setState(() {
        final existingIds = _chatMessages.map((m) => m.id).toSet();
        for (final msg in messages) {
          if (!existingIds.contains(msg.id)) {
            _chatMessages.add(msg);
            existingIds.add(msg.id);
          }
        }
        _chatMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });
    };

    _chatService.onUserTyping = (userName, isTyping) {
      if (!mounted) return;
      setState(() {
        _typingUserName = isTyping ? userName : null;
      });
    };

    _chatService.onConnectionStateChanged = (isConnected) {
      if (mounted) setState(() {});
    };

    _chatService.init();
    _chatService.joinRoom(
      roomId: widget.roomName.trim(),
      userId: _currentUserId,
      userName: _getUserDisplayName(),
      profileImage: widget.userProfileImage,
    );
  }

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
      if (_isChatOpen) {
        _unreadChatCount = 0;
        _latestToastMessage = null;
        _toastTimer?.cancel();
      }
    });
  }

  void _showInCallToast(ChatMessage message) {
    _toastTimer?.cancel();
    setState(() {
      _latestToastMessage = message;
    });
    _toastTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _latestToastMessage == message) {
        setState(() {
          _latestToastMessage = null;
        });
      }
    });
  }

  Future<Map<Permission, PermissionStatus>> _requestPermissions() async {
    try {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      debugPrint(
        '[LiveKit Permissions] Camera: ${statuses[Permission.camera]}, '
        'Microphone: ${statuses[Permission.microphone]}',
      );
      return statuses;
    } catch (e) {
      debugPrint('[LiveKit Permissions] Error: $e');
      return {};
    }
  }

  void _showPermissionSettingsDialog({
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF30363D)),
        ),
        title: Row(
          children: [
            const Icon(Icons.settings_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToRoom() async {
    if (_isConnecting || _isConnected) return;

    if (widget.serverUrl.isEmpty || widget.token.isEmpty) {
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _errorMessage = 'Missing LiveKit server URL or participant access token.';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    // 1. Request camera and microphone permissions before connecting
    final statuses = await _requestPermissions();
    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

    _cameraEnabled = cameraGranted;
    _micEnabled = micGranted;

    debugPrint(
      '[LiveKit Client] Connecting to: ${widget.serverUrl} | '
      'Room: ${widget.roomName} | '
      'Token length: ${widget.token.length} | '
      'Camera allowed: $cameraGranted | Mic allowed: $micGranted',
    );

    try {
      if (_room != null) {
        await _cleanupRoom();
      }

      // Configure room options with clean capture settings
      final room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultCameraCaptureOptions: CameraCaptureOptions(
            cameraPosition: CameraPosition.front,
            maxFrameRate: 30,
          ),
          defaultAudioCaptureOptions: AudioCaptureOptions(),
        ),
      );

      _room = room;
      _listener = room.createListener();

      _setupRoomListeners(room);

      // Connect to LiveKit Cloud / Server
      await room.connect(
        widget.serverUrl,
        widget.token,
        connectOptions: const ConnectOptions(
          autoSubscribe: true,
        ),
      );

      // Initialize media tracks safely based on permissions
      if (_cameraEnabled) {
        try {
          await room.localParticipant?.setCameraEnabled(
            true,
            cameraCaptureOptions: const CameraCaptureOptions(
              cameraPosition: CameraPosition.front,
              maxFrameRate: 30,
            ),
          );
        } catch (camError) {
          debugPrint('[LiveKit Track Warning] Camera init notice: $camError');
          _cameraEnabled = false;
        }
      }

      if (_micEnabled) {
        try {
          await room.localParticipant?.setMicrophoneEnabled(true);
        } catch (micError) {
          debugPrint('[LiveKit Track Warning] Media track init notice: $micError');
          _micEnabled = false;
        }
      }

      // Attach listener to local participant for real-time track updates
      room.localParticipant?.addListener(_onParticipantChanged);

      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _errorMessage = null;
        if (room.localParticipant != null) {
          _micEnabled = room.localParticipant!.isMicrophoneEnabled();
          _cameraEnabled = room.localParticipant!.isCameraEnabled();
        }
      });
    } catch (e) {
      debugPrint('[LiveKit Error] Connection failed: $e');

      String friendlyMessage = e.toString();
      if (friendlyMessage.contains('Invalid API key') ||
          friendlyMessage.contains('joinFailure') ||
          friendlyMessage.contains('ConnectException')) {
        friendlyMessage =
            'Unable to connect to LiveKit Cloud (join failure):\n\n'
            'The cloud server rejected the connection.\n\n'
            'Please verify your LiveKit credentials in backend/.env.';
      }

      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _errorMessage = friendlyMessage;
      });
    }
  }

  void _onParticipantChanged() {
    if (!mounted) return;
    setState(() {
      final participant = _room?.localParticipant;
      if (participant != null) {
        _micEnabled = participant.isMicrophoneEnabled();
        _cameraEnabled = participant.isCameraEnabled();
      }
    });
  }

  void _setupRoomListeners(Room room) {
    _listener
      ?..on<RoomDisconnectedEvent>((event) {
        if (!mounted) return;
        if (_isConnected) {
          setState(() {
            _isConnected = false;
            _errorMessage = event.reason != null
                ? 'Disconnected from call: ${event.reason}'
                : 'Call ended.';
          });
        }
      })
      ..on<ParticipantConnectedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<ParticipantDisconnectedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<TrackSubscribedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<TrackUnsubscribedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<TrackMutedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<TrackUnmutedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<LocalTrackPublishedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<LocalTrackUnpublishedEvent>((_) {
        if (mounted) setState(() {});
      })
      ..on<ActiveSpeakersChangedEvent>((_) {
        if (mounted) setState(() {});
      });
  }

  Future<void> _cleanupRoom() async {
    _toastTimer?.cancel();
    _chatService.dispose();
    try {
      _room?.localParticipant?.removeListener(_onParticipantChanged);
      await _listener?.dispose();
      _listener = null;
      if (_room != null) {
        await _room!.disconnect();
        await _room!.dispose();
        _room = null;
      }
    } catch (e) {
      debugPrint('[LiveKit Cleanup Notice] $e');
    }
  }

  Future<void> _toggleMic() async {
    if (_isTogglingMic) return;
    final participant = _room?.localParticipant;
    if (participant == null) return;

    final targetState = !_micEnabled;

    if (targetState) {
      // User is unmuting: verify microphone permission
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }

      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        _showPermissionSettingsDialog(
          title: 'Microphone Permission Needed',
          message:
              'Microphone permission is permanently denied. Please allow microphone access in device settings to speak.',
        );
        return;
      } else if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required to unmute.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isTogglingMic = true);
    try {
      debugPrint('[LiveKit] Toggle microphone: $targetState');
      await participant.setMicrophoneEnabled(targetState);
      if (mounted) {
        setState(() {
          _micEnabled = participant.isMicrophoneEnabled();
        });
      }
    } catch (e) {
      debugPrint('[LiveKit] Error toggling mic: $e');
      if (mounted) {
        setState(() {
          _micEnabled = participant.isMicrophoneEnabled();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingMic = false);
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_isTogglingCamera) return;
    final participant = _room?.localParticipant;
    if (participant == null) return;

    final targetState = !_cameraEnabled;

    if (targetState) {
      // User is enabling camera: verify camera permission first
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
      }

      if (status.isPermanentlyDenied) {
        if (!mounted) return;
        _showPermissionSettingsDialog(
          title: 'Camera Permission Needed',
          message:
              'Camera access has been disabled. Please allow camera permission in device settings to turn on video.',
        );
        return;
      } else if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to turn on video.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isTogglingCamera = true);
    try {
      debugPrint('[LiveKit] Toggle camera to: $targetState');
      await participant.setCameraEnabled(
        targetState,
        cameraCaptureOptions: const CameraCaptureOptions(
          cameraPosition: CameraPosition.front,
          maxFrameRate: 30,
        ),
      );

      if (mounted) {
        setState(() {
          _cameraEnabled = participant.isCameraEnabled();
        });
      }
    } catch (e) {
      debugPrint('[LiveKit] Error toggling camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not turn on camera: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() {
          _cameraEnabled = participant.isCameraEnabled();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingCamera = false);
      }
    }
  }

  Future<void> _switchCamera() async {
    final track = _getVideoTrack(_room?.localParticipant);
    if (track is LocalVideoTrack) {
      try {
        final options = track.currentOptions;
        if (options is CameraCaptureOptions) {
          final currentPosition = options.cameraPosition;
          final newPosition = currentPosition == CameraPosition.front
              ? CameraPosition.back
              : CameraPosition.front;
          await track.setCameraPosition(newPosition);
          if (mounted) setState(() {});
        }
      } catch (e) {
        debugPrint('[LiveKit Switch Camera] $e');
      }
    }
  }

  Future<void> _toggleSpeakerphone() async {
    try {
      final next = !_speakerphoneOn;
      await AudioManager.instance.setSpeakerOutputPreferred(next);
      if (mounted) {
        setState(() => _speakerphoneOn = next);
      }
    } catch (e) {
      debugPrint('[LiveKit Speaker] $e');
    }
  }

  Future<void> _leaveCall() async {
    await _cleanupRoom();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _cleanupRoom();
    super.dispose();
  }

  // Helper Methods for Video and Avatars
  VideoTrack? _getVideoTrack(Participant? participant) {
    if (participant == null) return null;
    final pub = participant.getTrackPublicationBySource(TrackSource.camera);
    if (pub?.track is VideoTrack) {
      return pub!.track as VideoTrack;
    }
    for (final p in participant.videoTrackPublications) {
      if (p.track is VideoTrack) {
        return p.track as VideoTrack;
      }
    }
    return null;
  }

  bool _isVideoActive(Participant? participant) {
    if (participant == null) return false;
    if (participant is LocalParticipant) {
      if (!_cameraEnabled) return false;
      final track = _getVideoTrack(participant);
      return track != null && !track.muted;
    }

    final track = _getVideoTrack(participant);
    if (track == null || track.muted) return false;
    final pub = participant.getTrackPublicationBySource(TrackSource.camera);
    if (pub != null && pub.muted) return false;
    return true;
  }

  bool _isLocalFrontCamera() {
    final track = _getVideoTrack(_room?.localParticipant);
    if (track is LocalVideoTrack) {
      final options = track.currentOptions;
      if (options is CameraCaptureOptions) {
        return options.cameraPosition != CameraPosition.back;
      }
    }
    return true;
  }

  bool _isAudioMuted(Participant? participant) {
    if (participant == null) return true;
    if (participant is LocalParticipant) {
      return !_micEnabled;
    }
    final pub = participant.getTrackPublicationBySource(TrackSource.microphone);
    return pub?.muted ?? !(participant.isMicrophoneEnabled());
  }

  String get _currentUserId {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSuccess && authState.user.id.isNotEmpty) {
        return authState.user.id;
      } else if (authState is AuthAuthenticated && authState.user.id.isNotEmpty) {
        return authState.user.id;
      }
    } catch (_) {}
    final local = _room?.localParticipant;
    if (local?.identity != null && local!.identity.trim().isNotEmpty) {
      return local.identity.trim();
    }
    return 'user_${widget.userName?.trim() ?? "guest"}';
  }

  String _getUserDisplayName() {
    if (widget.userName != null && widget.userName!.trim().isNotEmpty) {
      return widget.userName!.trim();
    }
    final local = _room?.localParticipant;
    if (local?.name != null && local!.name.trim().isNotEmpty) {
      return local.name.trim();
    }
    if (local?.identity != null && local!.identity.trim().isNotEmpty) {
      return local.identity.trim();
    }
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthSuccess && authState.user.name.isNotEmpty) {
        return authState.user.name;
      } else if (authState is AuthAuthenticated && authState.user.name.isNotEmpty) {
        return authState.user.name;
      }
    } catch (_) {}
    return 'You';
  }

  String _getParticipantName(Participant? participant) {
    if (participant == null) return 'Participant';
    if (participant is LocalParticipant) {
      return '${_getUserDisplayName()} (You)';
    }
    if (participant.name.trim().isNotEmpty) {
      return participant.name.trim();
    }
    if (participant.identity.trim().isNotEmpty) {
      return participant.identity.trim();
    }
    return 'Participant';
  }

  String _getInitials(String name) {
    final cleanName = name.replaceAll('(You)', '').trim();
    final parts = cleanName.split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isChatOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isChatOpen) {
          setState(() {
            _isChatOpen = false;
          });
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF070A0F),
        body: SafeArea(
          top: false,
          bottom: false,
          child: _isConnecting
              ? _buildConnectingView()
              : _errorMessage != null
                  ? _buildErrorView()
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        // Video & Avatar Layout (remains active & uninterrupted)
                        _buildCallLayout(),

                        // Top Navigation Header
                        _buildHeaderBar(),

                        // Floating In-Call Message Toast (Google Meet style)
                        if (!_isChatOpen && _latestToastMessage != null)
                          _buildMessageToast(),

                        // Floating Bottom Controls Bar
                        if (!_isChatOpen)
                          _buildControlsBar(),

                        // In-Call Chat Overlay (Google Meet style)
                        if (_isChatOpen) ...[
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _toggleChat,
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: InCallChatSheet(
                              messages: List<ChatMessage>.from(_chatMessages),
                              currentUserId: _currentUserId,
                              currentUserName: _getUserDisplayName(),
                              currentUserProfileImage: widget.userProfileImage,
                              typingUserName: _typingUserName,
                              isConnected: _chatService.isConnected,
                              onSendMessage: (text) {
                                final cleanText = text.trim();
                                if (cleanText.isEmpty) return;

                                final messageId =
                                    'msg_${DateTime.now().millisecondsSinceEpoch}_$_currentUserId';
                                final optimisticMsg = ChatMessage(
                                  id: messageId,
                                  roomId: widget.roomName.trim(),
                                  senderId: _currentUserId,
                                  senderName: _getUserDisplayName(),
                                  senderProfileImage: widget.userProfileImage,
                                  text: cleanText,
                                  timestamp: DateTime.now(),
                                );

                                setState(() {
                                  _chatMessages.add(optimisticMsg);
                                });

                                _chatService.sendMessage(
                                  id: messageId,
                                  roomId: widget.roomName.trim(),
                                  text: cleanText,
                                  senderId: _currentUserId,
                                  senderName: _getUserDisplayName(),
                                  senderProfileImage: widget.userProfileImage,
                                );
                              },
                              onTypingChanged: (isTyping) {
                                _chatService.sendTyping(
                                  roomId: widget.roomName.trim(),
                                  isTyping: isTyping,
                                );
                              },
                              onClose: _toggleChat,
                            ),
                          ),
                        ],
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildConnectingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Connecting to call...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Room: ${widget.roomName}',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to join video call',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _leaveCall,
                  icon: const Icon(Icons.close),
                  label: const Text('Back'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _connectToRoom,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallLayout() {
    final local = _room?.localParticipant;
    final remotes = _room?.remoteParticipants.values.toList() ?? [];

    // Case 1: Alone in the room
    if (remotes.isEmpty) {
      if (local != null) {
        return _buildParticipantTile(
          participant: local,
          isLocal: true,
          isPip: false,
        );
      }
      return const SizedBox();
    }

    // Case 2: Exactly 1 remote participant (Main stage + Floating PiP)
    if (remotes.length == 1 && local != null) {
      final remote = remotes.first;
      final Participant mainParticipant = _isPipSwapped ? local : remote;
      final Participant pipParticipant = _isPipSwapped ? remote : local;
      final isMainLocal = _isPipSwapped;
      final isPipLocal = !_isPipSwapped;

      return Stack(
        fit: StackFit.expand,
        children: [
          // Main Stage
          _buildParticipantTile(
            participant: mainParticipant,
            isLocal: isMainLocal,
            isPip: false,
          ),

          // Floating Picture-in-Picture
          Positioned(
            top: 86,
            right: 16,
            width: 115,
            height: 165,
            child: GestureDetector(
              onTap: () {
                setState(() => _isPipSwapped = !_isPipSwapped);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 18,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildParticipantTile(
                      participant: pipParticipant,
                      isLocal: isPipLocal,
                      isPip: true,
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                        child: const Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Case 3: Multiple remote participants (Responsive Grid)
    final all = <Participant>[];
    if (local != null) all.add(local);
    all.addAll(remotes);

    return Padding(
      padding: const EdgeInsets.only(top: 80, bottom: 100, left: 12, right: 12),
      child: GridView.builder(
        itemCount: all.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final p = all[index];
          final isLoc = p is LocalParticipant;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: _buildParticipantTile(
              participant: p,
              isLocal: isLoc,
              isPip: false,
            ),
          );
        },
      ),
    );
  }

  String? _getParticipantProfileImage(Participant? participant, bool isLocal) {
    if (isLocal) {
      return widget.userProfileImage;
    }
    final metaStr = participant?.metadata;
    if (metaStr != null && metaStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(metaStr);
        if (decoded is Map && decoded['profileImage'] != null) {
          final img = decoded['profileImage'].toString().trim();
          if (img.isNotEmpty) return img;
        }
      } catch (_) {}
    }
    return null;
  }

  Widget _buildParticipantTile({
    required Participant participant,
    required bool isLocal,
    required bool isPip,
  }) {
    final videoTrack = _getVideoTrack(participant);
    final hasActiveVideo = _isVideoActive(participant);
    final isMuted = _isAudioMuted(participant);
    final name = _getParticipantName(participant);
    final profileImageUrl = _getParticipantProfileImage(participant, isLocal);

    return ClipRRect(
      borderRadius: BorderRadius.circular(isPip ? 16 : 0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: Video or Avatar
          if (hasActiveVideo && videoTrack != null)
            VideoTrackRenderer(
              videoTrack,
              fit: VideoViewFit.cover,
              mirrorMode: isLocal && _isLocalFrontCamera()
                  ? VideoViewMirrorMode.mirror
                  : VideoViewMirrorMode.off,
              key: ValueKey('${participant.identity}_${isLocal ? "local" : "remote"}_video'),
            )
          else
            _buildAvatarView(
              name: name,
              profileImageUrl: profileImageUrl,
              isLocal: isLocal,
              isPip: isPip,
              isSpeaking: participant.isSpeaking,
            ),

          // Name and status indicators
          if (!isPip) ...[
            // Top gradient overlay for header contrast
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 110,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom gradient overlay for controls contrast
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 150,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Name Tag Badge
            Positioned(
              bottom: 110,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMuted) ...[
                      const Icon(Icons.mic_off_rounded, color: Colors.redAccent, size: 15),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // PiP mini badge
            Positioned(
              bottom: 6,
              left: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMuted) ...[
                      const Icon(Icons.mic_off_rounded, color: Colors.redAccent, size: 11),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        isLocal ? 'You' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarView({
    required String name,
    String? profileImageUrl,
    required bool isLocal,
    required bool isPip,
    required bool isSpeaking,
  }) {
    final initials = _getInitials(name);
    final hasImage = profileImageUrl != null && profileImageUrl.isNotEmpty;

    if (isPip) {
      return Container(
        color: const Color(0xFF161B22),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasImage
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                image: hasImage
                    ? DecorationImage(
                        image: NetworkImage(profileImageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                border: Border.all(
                  color: isSpeaking ? AppColors.liveGreen : Colors.white24,
                  width: isSpeaking ? 2.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: hasImage
                  ? null
                  : Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            const Icon(
              Icons.videocam_off_rounded,
              color: Colors.redAccent,
              size: 14,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [
            Color(0xFF1B2335),
            Color(0xFF0F1420),
            Color(0xFF070A0F),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar circle with glow
              Container(
                width: 124,
                height: 124,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: hasImage
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                  image: hasImage
                      ? DecorationImage(
                          image: NetworkImage(profileImageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: (isSpeaking ? AppColors.liveGreen : const Color(0xFF6366F1))
                          .withValues(alpha: 0.35),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                  ],
                  border: Border.all(
                    color: isSpeaking ? AppColors.liveGreen : Colors.white38,
                    width: isSpeaking ? 3.5 : 2,
                  ),
                ),
                alignment: Alignment.center,
                child: hasImage
                    ? null
                    : Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 44,
                          letterSpacing: 1.2,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              // Name
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              // Camera Off Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off_rounded, color: Colors.redAccent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Camera is turned off',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Waiting message if alone in room
              if (isLocal && (_room?.remoteParticipants.isEmpty ?? true)) ...[
                const SizedBox(height: 28),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_empty_rounded, color: Colors.amberAccent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Waiting for others to join...',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: widget.roomName));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Room ID copied to clipboard!'),
                              duration: Duration(seconds: 2),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Room: ${widget.roomName}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy_rounded, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    final participantCount = (_room?.remoteParticipants.length ?? 0) + 1;

    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: SafeArea(
        child: Row(
          children: [
            // Back Button
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                    onPressed: _leaveCall,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Room Name Pill
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF22C55E),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF22C55E),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.roomName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Participant Count Pill
            GestureDetector(
              onTap: _showParticipantsSheet,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_rounded, color: Colors.white70, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          '$participantCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipantsSheet() {
    final local = _room?.localParticipant;
    final remotes = _room?.remoteParticipants.values.toList() ?? [];
    final allParticipants = <Map<String, dynamic>>[];

    if (local != null) {
      allParticipants.add({
        'name': '${_getUserDisplayName()} (You)',
        'profileImage': widget.userProfileImage,
        'initials': _getInitials(_getUserDisplayName()),
        'isMuted': !_micEnabled,
        'isVideoOn': _cameraEnabled,
        'isLocal': true,
      });
    }

    for (final remote in remotes) {
      final name = _getParticipantName(remote);
      final profileImg = _getParticipantProfileImage(remote, false);
      allParticipants.add({
        'name': name,
        'profileImage': profileImg,
        'initials': _getInitials(name),
        'isMuted': _isAudioMuted(remote),
        'isVideoOn': _isVideoActive(remote),
        'isLocal': false,
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF131822).withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Participants (${allParticipants.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: allParticipants.length,
                      separatorBuilder: (context, index) =>
                          const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (_, idx) {
                        final p = allParticipants[idx];
                        final hasImage = p['profileImage'] != null &&
                            (p['profileImage'] as String).isNotEmpty;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 0),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: p['isLocal'] == true
                                ? AppColors.primary
                                : const Color(0xFF3B82F6),
                            backgroundImage: hasImage
                                ? NetworkImage(p['profileImage'] as String)
                                : null,
                            child: hasImage
                                ? null
                                : Text(
                                    p['initials'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                          title: Text(
                            p['name'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                p['isVideoOn'] == true
                                    ? Icons.videocam
                                    : Icons.videocam_off,
                                color: p['isVideoOn'] == true
                                    ? Colors.white70
                                    : Colors.redAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                p['isMuted'] == true
                                    ? Icons.mic_off
                                    : Icons.mic,
                                color: p['isMuted'] == true
                                    ? Colors.redAccent
                                    : Colors.white70,
                                size: 18,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlsBar() {
    return Positioned(
      bottom: 28,
      left: 16,
      right: 16,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF141A23).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Microphone Button
                    _buildControlButton(
                      icon: _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                      isActive: _micEnabled,
                      isLoading: _isTogglingMic,
                      activeColor: Colors.white.withValues(alpha: 0.18),
                      inactiveColor: Colors.redAccent.shade700,
                      tooltip: _micEnabled ? 'Mute' : 'Unmute',
                      onTap: _toggleMic,
                    ),
                    const SizedBox(width: 10),

                    // Camera Button
                    _buildControlButton(
                      icon: _cameraEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                      isActive: _cameraEnabled,
                      isLoading: _isTogglingCamera,
                      activeColor: Colors.white.withValues(alpha: 0.18),
                      inactiveColor: Colors.redAccent.shade700,
                      tooltip: _cameraEnabled ? 'Turn Off Video' : 'Turn On Video',
                      onTap: _toggleCamera,
                    ),
                    const SizedBox(width: 10),

                    // Flip Camera Button (shown when camera is ON)
                    if (_cameraEnabled) ...[
                      _buildControlButton(
                        icon: Icons.flip_camera_ios_rounded,
                        isActive: true,
                        activeColor: Colors.white.withValues(alpha: 0.18),
                        inactiveColor: Colors.white12,
                        tooltip: 'Flip Camera',
                        onTap: _switchCamera,
                      ),
                      const SizedBox(width: 10),
                    ],

                    // In-Call Chat Button (Google Meet style with badge)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _buildControlButton(
                          icon: _isChatOpen
                              ? Icons.chat_bubble_rounded
                              : Icons.chat_bubble_outline_rounded,
                          isActive: _isChatOpen,
                          activeColor: AppColors.primary,
                          inactiveColor: Colors.white.withValues(alpha: 0.18),
                          tooltip: 'In-call messages',
                          onTap: _toggleChat,
                        ),
                        if (_unreadChatCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF141A23),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Center(
                                child: Text(
                                  _unreadChatCount > 99 ? '99+' : '$_unreadChatCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),

                    // Speakerphone Button
                    _buildControlButton(
                      icon: _speakerphoneOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                      isActive: _speakerphoneOn,
                      activeColor: Colors.white.withValues(alpha: 0.18),
                      inactiveColor: Colors.white12,
                      tooltip: _speakerphoneOn ? 'Speaker On' : 'Speaker Off',
                      onTap: _toggleSpeakerphone,
                    ),
                    const SizedBox(width: 14),

                    // End Call Button
                    InkWell(
                      onTap: _leaveCall,
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE11D48),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE11D48).withValues(alpha: 0.5),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.call_end_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageToast() {
    final msg = _latestToastMessage;
    if (msg == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 96,
      left: 20,
      right: 20,
      child: Center(
        child: GestureDetector(
          onTap: _toggleChat,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary,
                      ),
                      child: Center(
                        child: Text(
                          msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: RichText(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${msg.senderName}: ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: msg.text,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Reply',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required Color inactiveColor,
    required VoidCallback onTap,
    bool isLoading = false,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(26),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : inactiveColor,
            border: Border.all(
              color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    icon,
                    color: Colors.white,
                    size: 21,
                  ),
          ),
        ),
      ),
    );
  }
}
