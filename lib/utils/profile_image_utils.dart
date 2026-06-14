import 'dart:convert';

import 'package:flutter/material.dart';

ImageProvider? profileImageProvider({String? photoUrl, String? photoDataUrl}) {
  final dataUrl = photoDataUrl?.trim() ?? '';
  if (dataUrl.isNotEmpty) {
    try {
      final encoded = dataUrl.contains(',') ? dataUrl.split(',').last : dataUrl;
      return MemoryImage(base64Decode(encoded));
    } catch (_) {
      return null;
    }
  }

  final url = photoUrl?.trim() ?? '';
  return url.isEmpty ? null : NetworkImage(url);
}
