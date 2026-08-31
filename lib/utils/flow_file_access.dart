import 'dart:io';

import 'package:flutter/services.dart';

abstract final class FlowFileAccess {
  static const _channel = MethodChannel(
    'com.aran.personalfinance/exported_files',
  );

  static Future<void> open(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const FileSystemException('Exported file no longer exists');
    }

    if (Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('openFile', {'path': file.path});
      } on PlatformException catch (error) {
        throw FileSystemException(
          error.message ?? 'No installed app can open this file',
          file.path,
        );
      }
      return;
    }
    if (Platform.isWindows) {
      await Process.run('cmd.exe', ['/c', 'start', '', file.path]);
      return;
    }
    if (Platform.isMacOS) {
      await Process.run('open', [file.path]);
      return;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', [file.path]);
      return;
    }
    throw UnsupportedError('Opening exported files is not supported here.');
  }

  static Future<String?> chooseLocation(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw const FileSystemException('Exported file no longer exists');
    }

    if (Platform.isAndroid) {
      try {
        return await _channel.invokeMethod<String>('saveFile', {
          'path': file.path,
        });
      } on PlatformException catch (error) {
        throw FileSystemException(
          error.message ?? 'Could not open the file location picker',
          file.path,
        );
      }
    }
    if (Platform.isWindows) {
      await Process.run('explorer.exe', ['/select,${file.absolute.path}']);
      return file.absolute.path;
    }
    if (Platform.isMacOS) {
      await Process.run('open', ['-R', file.absolute.path]);
      return file.absolute.path;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', [file.parent.path]);
      return file.absolute.path;
    }
    throw UnsupportedError('Locating exported files is not supported here.');
  }
}
