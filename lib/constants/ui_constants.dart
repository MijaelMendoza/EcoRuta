import 'package:flutter/material.dart';
import 'package:flutter_gmaps/constants/assets_constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UIConstants {
  static AppBar appBar() {
    return AppBar(
      title: SvgPicture.asset(

        AssetsConstants.alertoLogo,
        color: Color.fromARGB(255, 169, 8, 8),
        height: 30,
      ),
      centerTitle: true,
    );
  }

}
