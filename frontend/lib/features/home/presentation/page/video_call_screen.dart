import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class VideoCallScreen extends StatefulWidget {
  final String serverUrl;
  final String token;
  final String roomName;

  const VideoCallScreen({
    super.key,
    required this.serverUrl,
    required this.token,
    required this.roomName,
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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _connectToRoom();
  }

  Future<void> _connectToRoom() async {
    // Prevent duplicate concurrent connection attempts
    if (_isConnecting || _isConnected) return;

    // Validate inputs before attempting connection
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

    // Safe diagnostic logging (never prints full token)
    debugPrint(
      '[LiveKit Client] Connecting to: ${widget.serverUrl} | '
      'Room: ${widget.roomName} | '
      'Token length: ${widget.token.length}',
    );

    try {
      // Disconnect and clean up any previous instance before reconnecting
      if (_room != null) {
        await _cleanupRoom();
      }

      final room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultCameraCaptureOptions: CameraCaptureOptions(
            maxFrameRate: 30,
          ),
        ),
      );

      _room = room;
      _listener = room.createListener();

      _setupRoomListeners(room);

      // Connect to LiveKit Cloud / Server with the participant JWT
      await room.connect(
        widget.serverUrl,
        widget.token,
        connectOptions: const ConnectOptions(
          autoSubscribe: true,
        ),
      );

      // Enable default media tracks safely
      try {
        await room.localParticipant?.setCameraEnabled(_cameraEnabled);
        await room.localParticipant?.setMicrophoneEnabled(_micEnabled);
      } catch (trackError) {
        debugPrint('[LiveKit Track Warning] Media track init notice: $trackError');
      }

      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('[LiveKit Error] Connection failed: $e');

      String friendlyMessage = e.toString();
      if (friendlyMessage.contains('Invalid API key') ||
          friendlyMessage.contains('joinFailure') ||
          friendlyMessage.contains('ConnectException')) {
        friendlyMessage =
            'Unable to connect to LiveKit Cloud (join failure):\n\n'
            'The cloud server (wss://live-loop-wdcidnza.livekit.cloud) rejected the connection.\n\n'
            'Please update backend/.env with your real LiveKit Cloud credentials:\n'
            '1. Go to https://cloud.livekit.io\n'
            '2. Open project: live-loop-wdcidnza\n'
            '3. Go to Settings -> Keys and copy your API Key and Secret\n'
            '4. Replace devkey and devsecret in backend/.env with your Cloud keys';
      }

      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _isConnected = false;
        _errorMessage = friendlyMessage;
      });
    }
  }

  void _setupRoomListeners(Room room) {
    _listener
      ?..on<RoomDisconnectedEvent>((event) {
        if (!mounted) return;
        // Only trigger disconnect state if we were already connected to an active room
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
      });
  }

  Future<void> _cleanupRoom() async {
    try {
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
    final participant = _room?.localParticipant;
    if (participant == null) return;
    final nextState = !_micEnabled;
    try {
      await participant.setMicrophoneEnabled(nextState);
      if (mounted) setState(() => _micEnabled = nextState);
    } catch (e) {
      debugPrint('Error toggling mic: $e');
    }
  }

  Future<void> _toggleCamera() async {
    final participant = _room?.localParticipant;
    if (participant == null) return;
    final nextState = !_cameraEnabled;
    try {
      await participant.setCameraEnabled(nextState);
      if (mounted) setState(() => _cameraEnabled = nextState);
    } catch (e) {
      debugPrint('Error toggling camera: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101418),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101418),
        foregroundColor: Colors.white,
        title: Text(widget.roomName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _leaveCall,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: _isConnecting
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16),
                    Text(
                      'Connecting to room...',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                )
              : _errorMessage != null
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
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
                                  backgroundColor: Colors.green,
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
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam,
                          color: Colors.green,
                          size: 72,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Connected to meeting',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Room: ${widget.roomName}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (_room != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Participants: ${(_room?.remoteParticipants.length ?? 0) + 1}',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 36),
                        Wrap(
                          spacing: 20,
                          children: [
                            IconButton.filled(
                              onPressed: _toggleMic,
                              style: IconButton.styleFrom(
                                backgroundColor: _micEnabled
                                    ? Colors.white24
                                    : Colors.redAccent,
                              ),
                              icon: Icon(
                                _micEnabled ? Icons.mic : Icons.mic_off,
                              ),
                            ),
                            IconButton.filled(
                              onPressed: _toggleCamera,
                              style: IconButton.styleFrom(
                                backgroundColor: _cameraEnabled
                                    ? Colors.white24
                                    : Colors.redAccent,
                              ),
                              icon: Icon(
                                _cameraEnabled
                                    ? Icons.videocam
                                    : Icons.videocam_off,
                              ),
                            ),
                            IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: _leaveCall,
                              icon: const Icon(Icons.call_end),
                            ),
                          ],
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
