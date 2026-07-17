import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// Результат записи: путь к файлу и длительность в секундах
class RecordingResult {
  final String path;
  final int duration;
  const RecordingResult({required this.path, required this.duration});
}

/// Хелпер для записи аудиосообщений
class AudioRecorderHelper {
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _startTime;
  String? _currentPath;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  /// Запрашивает разрешение и начинает запись
  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception('Нет разрешения на использование микрофона');
    }

    final dir = await getTemporaryDirectory();
    _currentPath =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _startTime = DateTime.now();

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: _currentPath!,
    );
    _isRecording = true;
  }

  /// Останавливает запись и возвращает результат
  Future<RecordingResult?> stopRecording() async {
    _isRecording = false;
    final recording = await _recorder.isRecording();
    if (!recording) return null;

    await _recorder.stop();

    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    final path = _currentPath;
    _currentPath = null;
    _startTime = null;

    if (path == null) return null;
    return RecordingResult(path: path, duration: duration);
  }

  /// Отменяет запись без сохранения
  Future<void> cancelRecording() async {
    _isRecording = false;
    try {
      final recording = await _recorder.isRecording();
      if (recording) {
        await _recorder.cancel();
      }
    } catch (_) {}
    _currentPath = null;
    _startTime = null;
  }

  void dispose() {
    _recorder.dispose();
  }
}
