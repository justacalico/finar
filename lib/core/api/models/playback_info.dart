/// Playback info response from Jellyfin
class PlaybackInfo {
  final List<MediaSourceData> mediaSources;
  final String? playSessionId;

  const PlaybackInfo({
    required this.mediaSources,
    this.playSessionId,
  });

  factory PlaybackInfo.fromJson(Map<String, dynamic> json) {
    return PlaybackInfo(
      mediaSources: (json['MediaSources'] as List<dynamic>?)
              ?.map((e) => MediaSourceData.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      playSessionId: json['PlaySessionId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MediaSources': mediaSources.map((e) => e.toJson()).toList(),
      'PlaySessionId': playSessionId,
    };
  }

  /// Get the best media source for direct play
  MediaSourceData? get directPlaySource {
    return mediaSources.firstWhere(
      (s) => s.supportsDirectPlay == true,
      orElse: () => mediaSources.firstWhere(
        (s) => s.supportsDirectStream == true,
        orElse: () => mediaSources.first,
      ),
    );
  }
}

class MediaSourceData {
  final String id;
  final String? name;
  final String? path;
  final String? container;
  final int? size;
  final int? bitrate;
  final int? runTimeTicks;
  final bool? supportsDirectPlay;
  final bool? supportsDirectStream;
  final bool? supportsTranscoding;
  final bool? isRemote;
  final String? eTag;
  final String? directStreamUrl;
  final String? transcodingUrl;
  final String? transcodingSubProtocol;
  final String? transcodingContainer;
  final List<MediaStreamData>? mediaStreams;
  final int? defaultAudioStreamIndex;
  final int? defaultSubtitleStreamIndex;

  const MediaSourceData({
    required this.id,
    this.name,
    this.path,
    this.container,
    this.size,
    this.bitrate,
    this.runTimeTicks,
    this.supportsDirectPlay,
    this.supportsDirectStream,
    this.supportsTranscoding,
    this.isRemote,
    this.eTag,
    this.directStreamUrl,
    this.transcodingUrl,
    this.transcodingSubProtocol,
    this.transcodingContainer,
    this.mediaStreams,
    this.defaultAudioStreamIndex,
    this.defaultSubtitleStreamIndex,
  });

  factory MediaSourceData.fromJson(Map<String, dynamic> json) {
    return MediaSourceData(
      id: json['Id'] as String,
      name: json['Name'] as String?,
      path: json['Path'] as String?,
      container: json['Container'] as String?,
      size: json['Size'] as int?,
      bitrate: json['Bitrate'] as int?,
      runTimeTicks: json['RunTimeTicks'] as int?,
      supportsDirectPlay: json['SupportsDirectPlay'] as bool?,
      supportsDirectStream: json['SupportsDirectStream'] as bool?,
      supportsTranscoding: json['SupportsTranscoding'] as bool?,
      isRemote: json['IsRemote'] as bool?,
      eTag: json['ETag'] as String?,
      directStreamUrl: json['DirectStreamUrl'] as String?,
      transcodingUrl: json['TranscodingUrl'] as String?,
      transcodingSubProtocol: json['TranscodingSubProtocol'] as String?,
      transcodingContainer: json['TranscodingContainer'] as String?,
      mediaStreams: (json['MediaStreams'] as List<dynamic>?)
          ?.map((e) => MediaStreamData.fromJson(e as Map<String, dynamic>))
          .toList(),
      defaultAudioStreamIndex: json['DefaultAudioStreamIndex'] as int?,
      defaultSubtitleStreamIndex: json['DefaultSubtitleStreamIndex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'Name': name,
      'Path': path,
      'Container': container,
      'Size': size,
      'Bitrate': bitrate,
      'RunTimeTicks': runTimeTicks,
      'SupportsDirectPlay': supportsDirectPlay,
      'SupportsDirectStream': supportsDirectStream,
      'SupportsTranscoding': supportsTranscoding,
      'IsRemote': isRemote,
      'ETag': eTag,
      'DirectStreamUrl': directStreamUrl,
      'TranscodingUrl': transcodingUrl,
      'TranscodingSubProtocol': transcodingSubProtocol,
      'TranscodingContainer': transcodingContainer,
      'MediaStreams': mediaStreams?.map((e) => e.toJson()).toList(),
      'DefaultAudioStreamIndex': defaultAudioStreamIndex,
      'DefaultSubtitleStreamIndex': defaultSubtitleStreamIndex,
    };
  }

  /// Get video streams
  List<MediaStreamData> get videoStreams =>
      mediaStreams?.where((s) => s.type == 'Video').toList() ?? [];

  /// Get audio streams
  List<MediaStreamData> get audioStreams =>
      mediaStreams?.where((s) => s.type == 'Audio').toList() ?? [];

  /// Get subtitle streams
  List<MediaStreamData> get subtitleStreams =>
      mediaStreams?.where((s) => s.type == 'Subtitle').toList() ?? [];

  /// Get the best quality label
  String get qualityLabel {
    final video = videoStreams.firstOrNull;
    if (video == null) return '';
    
    final height = video.height ?? 0;
    if (height >= 2160) return '4K';
    if (height >= 1440) return '1440p';
    if (height >= 1080) return '1080p';
    if (height >= 720) return '720p';
    if (height >= 480) return '480p';
    return 'SD';
  }
}

class MediaStreamData {
  final String? codec;
  final String? codecTag;
  final String? language;
  final String? displayTitle;
  final String? title;
  final String type;
  final int index;
  final bool? isDefault;
  final bool? isForced;
  final bool? isExternal;
  final int? width;
  final int? height;
  final double? averageFrameRate;
  final double? realFrameRate;
  final String? profile;
  final int? level;
  final int? bitRate;
  final int? bitDepth;
  final int? channels;
  final String? channelLayout;
  final int? sampleRate;
  final String? deliveryMethod;
  final String? deliveryUrl;
  final String? path;
  final bool? isTextSubtitleStream;
  final bool? supportsExternalStream;

  const MediaStreamData({
    this.codec,
    this.codecTag,
    this.language,
    this.displayTitle,
    this.title,
    required this.type,
    required this.index,
    this.isDefault,
    this.isForced,
    this.isExternal,
    this.width,
    this.height,
    this.averageFrameRate,
    this.realFrameRate,
    this.profile,
    this.level,
    this.bitRate,
    this.bitDepth,
    this.channels,
    this.channelLayout,
    this.sampleRate,
    this.deliveryMethod,
    this.deliveryUrl,
    this.path,
    this.isTextSubtitleStream,
    this.supportsExternalStream,
  });

  factory MediaStreamData.fromJson(Map<String, dynamic> json) {
    return MediaStreamData(
      codec: json['Codec'] as String?,
      codecTag: json['CodecTag'] as String?,
      language: json['Language'] as String?,
      displayTitle: json['DisplayTitle'] as String?,
      title: json['Title'] as String?,
      type: json['Type'] as String? ?? 'Unknown',
      index: json['Index'] as int? ?? 0,
      isDefault: json['IsDefault'] as bool?,
      isForced: json['IsForced'] as bool?,
      isExternal: json['IsExternal'] as bool?,
      width: json['Width'] as int?,
      height: json['Height'] as int?,
      averageFrameRate: (json['AverageFrameRate'] as num?)?.toDouble(),
      realFrameRate: (json['RealFrameRate'] as num?)?.toDouble(),
      profile: json['Profile'] as String?,
      level: json['Level'] as int?,
      bitRate: json['BitRate'] as int?,
      bitDepth: json['BitDepth'] as int?,
      channels: json['Channels'] as int?,
      channelLayout: json['ChannelLayout'] as String?,
      sampleRate: json['SampleRate'] as int?,
      deliveryMethod: json['DeliveryMethod'] as String?,
      deliveryUrl: json['DeliveryUrl'] as String?,
      path: json['Path'] as String?,
      isTextSubtitleStream: json['IsTextSubtitleStream'] as bool?,
      supportsExternalStream: json['SupportsExternalStream'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Codec': codec,
      'CodecTag': codecTag,
      'Language': language,
      'DisplayTitle': displayTitle,
      'Title': title,
      'Type': type,
      'Index': index,
      'IsDefault': isDefault,
      'IsForced': isForced,
      'IsExternal': isExternal,
      'Width': width,
      'Height': height,
      'AverageFrameRate': averageFrameRate,
      'RealFrameRate': realFrameRate,
      'Profile': profile,
      'Level': level,
      'BitRate': bitRate,
      'BitDepth': bitDepth,
      'Channels': channels,
      'ChannelLayout': channelLayout,
      'SampleRate': sampleRate,
      'DeliveryMethod': deliveryMethod,
      'DeliveryUrl': deliveryUrl,
      'Path': path,
      'IsTextSubtitleStream': isTextSubtitleStream,
      'SupportsExternalStream': supportsExternalStream,
    };
  }

  /// Get a friendly display name for this stream
  String get displayName {
    if (displayTitle != null && displayTitle!.isNotEmpty) {
      return displayTitle!;
    }
    
    final parts = <String>[];
    
    if (language != null && language!.isNotEmpty) {
      parts.add(_languageToName(language!));
    }
    
    if (codec != null && codec!.isNotEmpty) {
      parts.add(codec!.toUpperCase());
    }
    
    if (type == 'Video' && width != null && height != null) {
      parts.add('${width}x$height');
    }
    
    if (type == 'Audio' && channels != null) {
      parts.add(_channelsToName(channels!));
    }
    
    if (parts.isEmpty) {
      parts.add('Stream $index');
    }
    
    return parts.join(' - ');
  }

  String _languageToName(String code) {
    const languages = {
      'eng': 'English',
      'spa': 'Spanish',
      'fra': 'French',
      'deu': 'German',
      'ita': 'Italian',
      'jpn': 'Japanese',
      'kor': 'Korean',
      'zho': 'Chinese',
      'por': 'Portuguese',
      'rus': 'Russian',
      'ara': 'Arabic',
      'hin': 'Hindi',
      'und': 'Unknown',
    };
    return languages[code.toLowerCase()] ?? code.toUpperCase();
  }

  String _channelsToName(int channels) {
    switch (channels) {
      case 1:
        return 'Mono';
      case 2:
        return 'Stereo';
      case 6:
        return '5.1';
      case 8:
        return '7.1';
      default:
        return '$channels ch';
    }
  }
}

/// Progress report sent to Jellyfin
class PlaybackProgressInfo {
  final String itemId;
  final String? mediaSourceId;
  final int positionTicks;
  final bool isPaused;
  final bool isMuted;
  final int? volumeLevel;
  final int? audioStreamIndex;
  final int? subtitleStreamIndex;
  final String? playMethod;
  final String? playSessionId;
  final String? liveStreamId;
  final bool? canSeek;

  const PlaybackProgressInfo({
    required this.itemId,
    this.mediaSourceId,
    required this.positionTicks,
    this.isPaused = false,
    this.isMuted = false,
    this.volumeLevel,
    this.audioStreamIndex,
    this.subtitleStreamIndex,
    this.playMethod,
    this.playSessionId,
    this.liveStreamId,
    this.canSeek,
  });

  Map<String, dynamic> toJson() {
    return {
      'ItemId': itemId,
      'MediaSourceId': mediaSourceId,
      'PositionTicks': positionTicks,
      'IsPaused': isPaused,
      'IsMuted': isMuted,
      'VolumeLevel': volumeLevel,
      'AudioStreamIndex': audioStreamIndex,
      'SubtitleStreamIndex': subtitleStreamIndex,
      'PlayMethod': playMethod,
      'PlaySessionId': playSessionId,
      'LiveStreamId': liveStreamId,
      'CanSeek': canSeek,
    };
  }
}

/// Playback start info sent to Jellyfin
class PlaybackStartInfo {
  final String itemId;
  final String? mediaSourceId;
  final int? audioStreamIndex;
  final int? subtitleStreamIndex;
  final String? playMethod;
  final String? playSessionId;
  final int? positionTicks;
  final bool? canSeek;

  const PlaybackStartInfo({
    required this.itemId,
    this.mediaSourceId,
    this.audioStreamIndex,
    this.subtitleStreamIndex,
    this.playMethod,
    this.playSessionId,
    this.positionTicks,
    this.canSeek,
  });

  Map<String, dynamic> toJson() {
    return {
      'ItemId': itemId,
      'MediaSourceId': mediaSourceId,
      'AudioStreamIndex': audioStreamIndex,
      'SubtitleStreamIndex': subtitleStreamIndex,
      'PlayMethod': playMethod,
      'PlaySessionId': playSessionId,
      'PositionTicks': positionTicks,
      'CanSeek': canSeek,
    };
  }
}

/// Playback stop info sent to Jellyfin
class PlaybackStopInfo {
  final String itemId;
  final String? mediaSourceId;
  final int positionTicks;
  final String? playSessionId;
  final String? liveStreamId;

  const PlaybackStopInfo({
    required this.itemId,
    this.mediaSourceId,
    required this.positionTicks,
    this.playSessionId,
    this.liveStreamId,
  });

  Map<String, dynamic> toJson() {
    return {
      'ItemId': itemId,
      'MediaSourceId': mediaSourceId,
      'PositionTicks': positionTicks,
      'PlaySessionId': playSessionId,
      'LiveStreamId': liveStreamId,
    };
  }
}

/// Transcoding profile for requesting specific formats
class TranscodingProfile {
  final String container;
  final String? audioCodec;
  final String? videoCodec;
  final int? maxVideoBitrate;
  final int? maxAudioBitrate;
  final int? maxWidth;
  final int? maxHeight;

  const TranscodingProfile({
    required this.container,
    this.audioCodec,
    this.videoCodec,
    this.maxVideoBitrate,
    this.maxAudioBitrate,
    this.maxWidth,
    this.maxHeight,
  });

  /// Default HLS profile for most devices
  static const hlsDefault = TranscodingProfile(
    container: 'ts',
    audioCodec: 'aac,mp3',
    videoCodec: 'h264',
    maxVideoBitrate: 10000000, // 10 Mbps
    maxAudioBitrate: 320000, // 320 kbps
    maxWidth: 1920,
    maxHeight: 1080,
  );

  /// High quality profile for capable devices
  static const hlsHighQuality = TranscodingProfile(
    container: 'ts',
    audioCodec: 'aac,flac',
    videoCodec: 'h264,hevc',
    maxVideoBitrate: 40000000, // 40 Mbps
    maxAudioBitrate: 640000, // 640 kbps
    maxWidth: 3840,
    maxHeight: 2160,
  );
}
