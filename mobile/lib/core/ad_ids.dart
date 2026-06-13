import 'dart:io';

const _bannerAndroid      = 'ca-app-pub-8684604729751875/9140705023';
const _interstitialAndroid = 'ca-app-pub-8684604729751875/6458701367';
const _bannerIos           = 'ca-app-pub-8684604729751875/9424905356';
const _interstitialIos     = 'ca-app-pub-8684604729751875/1386674795';

String get kAdBannerId       => Platform.isIOS ? _bannerIos       : _bannerAndroid;
String get kAdInterstitialId => Platform.isIOS ? _interstitialIos : _interstitialAndroid;
