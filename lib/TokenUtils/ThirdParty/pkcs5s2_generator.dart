import 'dart:typed_data';

import 'package:pointycastle/api.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/pointycastle.dart';

class Pkcs5S2ParametersGenerator {
  final HMac hMac;
  final Uint8List state;

  Pkcs5S2ParametersGenerator(Digest digest)
      : hMac = HMac(digest, 64),
        state = Uint8List((digest).digestSize);

  void F(Uint8List S, int c, Uint8List iBuf, Uint8List outBytes, int outOff) {
    if (c <= 0) {
      throw ArgumentError('Iteration count must be at least 1.');
    }

    hMac.update(S, 0, S.length);

    hMac.update(iBuf, 0, iBuf.length);
    hMac.doFinal(state, 0);

    for (int i = 0; i < state.length; i++) {
      outBytes[outOff + i] = state[i];
    }

    for (int count = 1; count < c; count++) {
      hMac.update(state, 0, state.length);
      hMac.doFinal(state, 0);

      for (int j = 0; j < state.length; j++) {
        outBytes[outOff + j] ^= state[j];
      }
    }
  }

  Uint8List generateDerivedKey(
      Uint8List password, Uint8List salt, int iterationCount, int dkLen) {
    int hLen = hMac.macSize;
    int l = (dkLen + hLen - 1) ~/ hLen;
    Uint8List iBuf = Uint8List(4);
    Uint8List outBytes = Uint8List(l * hLen);
    int outPos = 0;

    hMac.init(KeyParameter(password));

    for (int i = 1; i <= l; i++) {
      // Increment the value in 'iBuf'
      int pos = 3;
      while (++iBuf[pos] == 0) {
        --pos;
      }

      F(salt, iterationCount, iBuf, outBytes, outPos);
      outPos += hLen;
    }

    return outBytes;
  }

  KeyParameter generateDerivedParameters(
      Uint8List password, Uint8List salt, int iterationCount, int keySize) {
    keySize ~/= 8;

    Uint8List dKey =
        generateDerivedKey(password, salt, iterationCount, keySize);
    return KeyParameter(dKey);
  }

  ParametersWithIV generateDerivedParametersWithIV(Uint8List password,
      Uint8List salt, int iterationCount, int keySize, int ivSize) {
    keySize ~/= 8;
    ivSize ~/= 8;

    Uint8List dKey =
        generateDerivedKey(password, salt, iterationCount, keySize + ivSize);
    KeyParameter key = KeyParameter(dKey.sublist(0, keySize));

    return ParametersWithIV(key, dKey.sublist(keySize, keySize + ivSize));
  }

  KeyParameter generateDerivedMacParameters(
      Uint8List password, Uint8List salt, int iterationCount, int keySize) {
    keySize ~/= 8;

    Uint8List dKey =
        generateDerivedKey(password, salt, iterationCount, keySize);
    return KeyParameter(dKey);
  }
}
