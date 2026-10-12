
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
  late final Room _room;
  bool _connecting = true;
  bool _micEnabled = true;
  bool _cameraEnabled = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _room = Room();
    _connectToRoom();
  }

  Future<void> _connectToRoom() async {
    try {
      await _room.connect(widget.serverUrl, widget.token);

      await _room.localParticipant?.setCameraEnabled(true);
      await _room.localParticipant?.setMicrophoneEnabled(true);

      if (!mounted) return;
      setState(() => _connecting = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connecting = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _toggleMic() async {
    final enabled = !_micEnabled;
    await _room.localParticipant?.setMicrophoneEnabled(enabled);
    if (mounted) setState(() => _micEnabled = enabled);
  }

  Future<void> _toggleCamera() async {
    final enabled = !_cameraEnabled;
    await _room.localParticipant?.setCameraEnabled(enabled);
    if (mounted) setState(() => _cameraEnabled = enabled);
  }

  Future<void> _leaveCall() async {
    await _room.disconnect();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _room.disconnect();
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
      ),
      body: Center(
        child: _connecting
            ? const CircularProgressIndicator(color: Colors.green)
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to join call:\n$_error',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
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
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Room: ${widget.roomName}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 20,
                        children: [
                          IconButton.filled(
                            onPressed: _toggleMic,
                            icon: Icon(
                              _micEnabled ? Icons.mic : Icons.mic_off,
                            ),
                          ),
                          IconButton.filled(
                            onPressed: _toggleCamera,
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
    );
  }
}
