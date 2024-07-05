import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart' as ffi;

import 'webrtc_agc_bindings_generated.dart';

const String _libName = 'webrtc_agc';

/// The dynamic library in which the symbols for [WebrtcAgcBindings] can be found.
final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final WebrtcAgcBindings _bindings = WebrtcAgcBindings(_dylib);

enum AGCMode {
  NONE,
  // Adaptive mode intended for use if an analog volume control is available
  // on the capture device. It will require the user to provide coupling
  // between the OS mixer controls and AGC through the |stream_analog_level()|
  // functions.
  //
  // It consists of an analog gain prescription for the audio device and a
  // digital compression stage.
  AdaptiveAnalog,

  // Adaptive mode intended for situations in which an analog volume control
  // is unavailable. It operates in a similar fashion to the adaptive analog
  // mode, but with scaling instead applied in the digital domain. As with
  // the analog mode, it additionally uses a digital compression stage.
  AdaptiveDigital,

  // Fixed mode which enables only the digital compression stage also used by
  // the two adaptive modes.
  //
  // It is distinguished from the adaptive modes by considering only a
  // short time-window of the input signal. It applies a fixed gain through
  // most of the input level range, and compresses (gradually reduces gain
  // with increasing level) the input signal at higher levels. This mode is
  // preferred on embedded devices where the capture signal level is
  // predictable, so that a known gain can be applied.
  FixedDigital,
}

class WebrtcAgc {
  final Pointer<Void> _nullptr = Pointer.fromAddress(0);

  Pointer<Void>? _handle;

  bool get _hasInit => _handle != null && _handle != _nullptr;

  ///初始化
  ///[sampleRate]音频数据采样率
  ///[mode]AGC模式,默认为AdaptiveDigital
  ///[minLevel] 最小麦克风音量 默认0
  ///[maxLevel] 最大麦克风音量 默认255
  void init(int sampleRate,
      {int minLevel = 0,
      int maxLevel = 255,
      AGCMode mode = AGCMode.AdaptiveDigital}) {
    release();
    _handle =
        _bindings.webrtc_agc_init(minLevel, maxLevel, sampleRate, mode.index);
  }

  ///销毁
  void release() {
    if (_hasInit) {
      _bindings.webrtc_agc_destroy(_handle!);
      _handle = null;
    }
  }

  ///设置AGC配置
  ///[targetLevelDBFS]default 3 (-3 dBOv), dbfs表示相对于full scale的下降值，0表示full scale，越小声音越大
  ///[compressionGainDB] default 9 dB,在Fixed模式下，越大声音越大
  void setConfig(
      {int targetLevelDBFS = 3,
      int compressionGainDB = 9,
      bool limiterEnable = true}) {
    if (_hasInit) {
      _bindings.webrtc_agc_set_config(
          _handle!, targetLevelDBFS, compressionGainDB, limiterEnable ? 1 : 0);
    }
  }

  ///处理byte数组,如果没有初始化,或者处理失败返回原始数据
  ///如果处理成功 返回处理后的数据
  ///数据长度最好为160byte的倍数
  Uint8List process(Uint8List bytes) {
    if (_hasInit) {
      return ffi.using((arena) {
        Int16List shorts = _bytesToShort(bytes);
        int length = shorts.length;
        final ptr = arena<Int16>(length);
        ptr.asTypedList(length).setAll(0, shorts);
        int ret = _bindings.webrtc_agc_process(_handle!, ptr, length);
        if (ret == 0) {
          return _shortToBytes(ptr.asTypedList(length));
        } else {
          return bytes;
        }
      });
    }
    return bytes;
  }

  static Int16List _bytesToShort(Uint8List bytes) {
    Int16List shorts = Int16List(bytes.length ~/ 2);
    for (int i = 0; i < shorts.length; i++) {
      shorts[i] = (bytes[i * 2] & 0xff | ((bytes[i * 2 + 1] & 0xff) << 8));
    }
    return shorts;
  }

  static Uint8List _shortToBytes(Int16List shorts) {
    Uint8List bytes = Uint8List(shorts.length * 2);
    for (int i = 0; i < shorts.length; i++) {
      bytes[i * 2] = (shorts[i] & 0xff);
      bytes[i * 2 + 1] = (shorts[i] >> 8 & 0xff);
    }
    return bytes;
  }
}
