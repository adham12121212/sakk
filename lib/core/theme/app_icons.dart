import 'package:flutter/widgets.dart';

/// Every icon in the app, from the Phosphor set (phosphor_flutter's fonts).
///
/// Defined here instead of using PhosphorIcons* directly because the package
/// marks every icon to mirror in right-to-left layouts; in Arabic that would
/// flip icons like the camera or "@". Only the directional ones below mirror.
/// Regular weight by default; Fill for selected tabs and solid status marks.
abstract final class AppIcons {
  // Navigation and direction. These flip in Arabic so they point the right way.
  static const back = IconData(
    0xe058,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
    matchTextDirection: true,
  ); // arrowLeft
  static const forward = IconData(
    0xe06c,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
    matchTextDirection: true,
  ); // arrowRight
  static const chevronForward = IconData(
    0xe13a,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
    matchTextDirection: true,
  ); // caretRight
  static const fillSuggestion = IconData(
    0xe090,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
    matchTextDirection: true,
  ); // arrowUpLeft
  static const send = IconData(
    0xe396,
    fontFamily: 'PhosphorFill',
    fontPackage: 'phosphor_flutter',
    matchTextDirection: true,
  ); // paperPlaneRight (fill)
  static const logOut = IconData(
    0xe42a,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
    matchTextDirection: true,
  ); // signOut
  static const returnItem = IconData(
    0xe08a,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
    matchTextDirection: true,
  ); // arrowUUpLeft

  // Everything else keeps its shape in Arabic.
  static const sendUp = IconData(
    0xe08e,
    fontFamily: 'PhosphorBold',
    fontPackage: 'phosphor_flutter',
  ); // arrowUp (bold)
  static const warranty = IconData(
    0xe40c,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // shieldCheck
  static const shield = IconData(
    0xe40a,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // shield
  static const delete = IconData(
    0xe4a6,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // trash
  static const deleteAccount = IconData(
    0xe4ce,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // userMinus
  static const products = IconData(
    0xe390,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // package
  static const error = IconData(
    0xe4e2,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // warningCircle
  static const errorFilled = IconData(
    0xe4e2,
    fontFamily: 'PhosphorFill',
    fontPackage: 'phosphor_flutter',
  ); // warningCircle (fill)
  static const warning = IconData(
    0xe4e0,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // warning
  static const info = IconData(
    0xe2ce,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // info
  static const aiFilled = IconData(
    0xe6a2,
    fontFamily: 'PhosphorFill',
    fontPackage: 'phosphor_flutter',
  ); // sparkle (fill)
  static const ai = IconData(
    0xe6a2,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // sparkle
  static const search = IconData(
    0xe30c,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // magnifyingGlass
  static const searchEmpty = IconData(
    0xe30c,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // magnifyingGlass
  static const recentSearch = IconData(
    0xe1a0,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // clockCounterClockwise
  static const expiring = IconData(
    0xe2b8,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // hourglassMedium
  static const share = IconData(
    0xeaf0,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // export
  static const download = IconData(
    0xe20c,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // downloadSimple
  static const fingerprint = IconData(
    0xe23e,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // fingerprint
  static const edit = IconData(
    0xe3b4,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // pencilSimple
  static const scan = IconData(
    0xebb6,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // scan
  static const close = IconData(
    0xe4f6,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // x
  static const check = IconData(
    0xe182,
    fontFamily: 'PhosphorBold',
    fontPackage: 'phosphor_flutter',
  ); // check (bold)
  static const successFilled = IconData(
    0xe184,
    fontFamily: 'PhosphorFill',
    fontPackage: 'phosphor_flutter',
  ); // checkCircle (fill)
  static const success = IconData(
    0xe184,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // checkCircle
  static const online = IconData(
    0xe4ea,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // wifiHigh
  static const offline = IconData(
    0xe4f2,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // wifiSlash
  static const cloudOff = IconData(
    0xe1b6,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // cloudSlash
  static const show = IconData(
    0xe220,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // eye
  static const hide = IconData(
    0xe224,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // eyeSlash
  static const receipt = IconData(
    0xe3ec,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // receipt
  static const notifications = IconData(
    0xe0ce,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // bell
  static const reminder = IconData(
    0xe5e8,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // bellRinging
  static const add = IconData(
    0xe3d4,
    fontFamily: 'PhosphorBold',
    fontPackage: 'phosphor_flutter',
  ); // plus (bold)
  static const retry = IconData(
    0xe036,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // arrowClockwise
  static const pdf = IconData(
    0xe702,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // filePdf
  static const gallery = IconData(
    0xe836,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // images
  static const camera = IconData(
    0xe10e,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // camera
  static const brokenImage = IconData(
    0xe7a8,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // imageBroken
  static const person = IconData(
    0xe4c2,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // user
  static const email = IconData(
    0xe0ac,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // at
  static const store = IconData(
    0xe470,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // storefront
  static const category = IconData(
    0xe464,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // squaresFour
  static const price = IconData(
    0xe1d2,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // creditCard
  static const calendar = IconData(
    0xe10a,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // calendarBlank
  static const wallet = IconData(
    0xe68a,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // wallet
  static const language = IconData(
    0xe288,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // globe
  static const theme = IconData(
    0xe18c,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // circleHalf
  static const chat = IconData(
    0xe168,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // chatCircle
  static const filter = IconData(
    0xe268,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // funnelSimple
  static const filterEmpty = IconData(
    0xe26a,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // funnelSimpleX
  static const home = IconData(
    0xe2c2,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // house
  static const homeFilled = IconData(
    0xe2c2,
    fontFamily: 'PhosphorFill',
    fontPackage: 'phosphor_flutter',
  ); // house (fill)
  static const productsTab = IconData(
    0xe464,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // squaresFour
  static const productsTabFilled = IconData(
    0xe464,
    fontFamily: 'PhosphorFill',
    fontPackage: 'phosphor_flutter',
  ); // squaresFour (fill)
  static const analytics = IconData(
    0xe150,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // chartBar
  static const analyticsFilled = IconData(
    0xe150,
    fontFamily: 'PhosphorFill',
    fontPackage: 'phosphor_flutter',
  ); // chartBar (fill)
  static const electronics = IconData(
    0xe1e0,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // deviceMobile
  static const appliances = IconData(
    0xede8,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // washingMachine
  static const furniture = IconData(
    0xe012,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // armchair
  static const vehicles = IconData(
    0xe112,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // car
  static const accessories = IconData(
    0xe4e6,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // watch
  static const otherCategory = IconData(
    0xe200,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // dotsThreeCircle
  static const productPlaceholder = IconData(
    0xe390,
    fontFamily: 'PhosphorRegular',
    fontPackage: 'phosphor_flutter',
  ); // package
}
