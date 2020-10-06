import 'dart:convert';

import 'package:book/common/ReadSetting.dart';
import 'package:book/common/Screen.dart';
import 'package:book/common/common.dart';
import 'package:book/common/net.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/event/event.dart';
import 'package:book/model/ColorModel.dart';
import 'package:book/model/ReadModel.dart';
import 'package:book/route/Routes.dart';
import 'package:book/store/Store.dart';
import 'package:book/view/system/MyBottomSheet.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class Menu extends StatefulWidget {
  @override
  _MenuState createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  ReadModel _readModel;
  ColorModel _colorModel;
  List<String> bgimg = [
    "QR_bg_1.jpg",
    "QR_bg_2.jpg",
    "QR_bg_3.jpg",
    // "QR_bg_4.jpg",
    "QR_bg_5.jpg",
    "QR_bg_7.png",
    "QR_bg_8.png",
  ];

  @override
  void initState() {
    super.initState();
    _readModel = Store.value<ReadModel>(context);
    _colorModel = Store.value<ColorModel>(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        child: Column(
          children: <Widget>[
            Container(
              color: _colorModel.dark ? Colors.black : Colors.white,
              height: Screen.topSafeHeight,
            ),
            Container(
              color: _colorModel.dark ? Colors.black : Colors.white,
              child: Row(
                children: [
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    '${_readModel?.bookTag?.bookName ?? ""}',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 22),
                  ),
                  Expanded(
                    child: Container(),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh),
                    onPressed: () {
                      _readModel.reloadCurrentPage();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () async {
                      String url = Common.detail + '/${_readModel.book.Id}';
                      Response future = await Util(context).http().get(url);
                      var d = future.data['data'];
                      BookInfo bookInfo = BookInfo.fromJson(d);
                      Routes.navigateTo(context, Routes.detail,
                          params: {"detail": jsonEncode(bookInfo)});
                    },
                  )
                ],
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: 0.0,
                  child: Container(
                    width: double.infinity,
                  ),
                ),
                onTap: () {
                  _readModel.toggleShowMenu();
                  if (_readModel.font) {
                    _readModel.reCalcPages();
                  }
                },
              ),
            ),
            Container(
              color: _colorModel.dark ? Colors.black : Colors.white,
              height: 120,
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      GestureDetector(
                        child: Container(
                          child: Icon(
                            Icons.arrow_back_ios,
                            // color: Colors.white,
                          ),
                          width: 70,
                        ),
                        onTap: () {
                          _readModel.bookTag.cur -= 1;
                          BotToast.showText(
                              text: _readModel.curPage.chapterName);
                          _readModel.intiPageContent(
                              _readModel.bookTag.cur, true);
                        },
                      ),
                      Expanded(
                        child: Container(
                          child: Slider(
                            // activeColor: Colors.white,
                            // inactiveColor: Colors.white70,
                            value: _readModel.value,
                            max: (_readModel.chapters.length - 1).toDouble(),
                            min: 0.0,
                            onChanged: (newValue) {
                              int temp = newValue.round();
                              _readModel.bookTag.cur = temp;
                              _readModel.value = temp.toDouble();
                              _readModel.intiPageContent(
                                  _readModel.bookTag.cur, true);
                            },
                            label:
                                '${_readModel.chapters[_readModel.bookTag.cur].name} ',
                            semanticFormatterCallback: (newValue) {
                              return '${newValue.round()} dollars';
                            },
                          ),
                        ),
                      ),
                      GestureDetector(
                        child: Container(
                          child: Icon(
                            Icons.arrow_forward_ios,
                            // color: Colors.white,
                          ),
                          width: 70,
                        ),
                        onTap: () {
                          _readModel.bookTag.cur += 1;
                          _readModel.intiPageContent(
                              _readModel.bookTag.cur, true);
                          BotToast.showText(
                              text: _readModel.curPage.chapterName);
                        },
                      ),
                    ],
                  ),
                  buildBottomMenus()
                ],
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        _readModel.toggleShowMenu();
      },
    );
  }

  buildBottomMenus() {
    return Theme(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          buildBottomItem('目录', Icons.menu),
          GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: ScreenUtil.getScreenW(context) / 4,
                padding: EdgeInsets.symmetric(vertical: 7),
                child: Column(
                  children: <Widget>[
                    ImageIcon(
                      _colorModel.dark
                          ? AssetImage("images/sun.png")
                          : AssetImage("images/moon.png"),
                      // color: Colors.white,
                    ),
                    SizedBox(height: 5),
                    Text(_colorModel.dark ? '日间' : '夜间',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              onTap: () {
                Store.value<ColorModel>(context).switchModel();

                _readModel.toggleShowMenu();
              }),
          buildBottomItem('缓存', Icons.cloud_download),
          buildBottomItem('设置', Icons.settings),
        ],
      ),
      data: _colorModel.theme,
    );
  }

  buildBottomItem(String title, IconData iconData) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: ScreenUtil.getScreenW(context) / 4,
        padding: EdgeInsets.symmetric(vertical: 7),
        child: Column(
          children: <Widget>[
            Icon(
              iconData,
              // color: Colors.white,
            ),
            SizedBox(height: 5),
            Text(title, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      onTap: () {
        print(title.toString());
        switch (title) {
          case '目录':
            {
              eventBus.fire(OpenChapters("dd"));
              // _globalKey.currentState.openDrawer();
              _readModel.toggleShowMenu();
            }
            break;
          case '缓存':
            {
              BotToast.showText(text: '开始下载...');
              _readModel.downloadAll();
            }
            break;
          case '设置':
            {
              myshowModalBottomSheet(
                  context: context,
                  builder: (BuildContext bc) {
                    return StatefulBuilder(
                        builder: (context, state) => buildSetting(state));
                  });
            }
            break;
        }
      },
    );
  }

  buildSetting(state) {
    return Container(
      color: _colorModel.dark ? Colors.black : Colors.white,
      height: 120,
      child: Padding(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Container(
                    child: FlatButton(
                      // color: Colors.white,
                      onPressed: () {
                        // _readModel.fontSize -= 1.0;
                        ReadSetting.calcFontSize(-1.0);
                        _readModel.modifyFont();
                      },
                      child: ImageIcon(
                        AssetImage("images/fontsmall.png"),
                        // color: Colors.black,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(20.0))),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Container(
                    child: FlatButton(
                      // color: Colors.white,
                      onPressed: () {
                        // _readModel.fontSize += 1.0;
                        ReadSetting.calcFontSize(1.0);
                        _readModel.modifyFont();
                      },
                      child: ImageIcon(
                        AssetImage("images/fontbig.png"),
                        // color: Colors.black,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(20.0))),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Container(
                    child: FlatButton(
                      onPressed: () {
                        Routes.navigateTo(
                          context,
                          Routes.fontSet,
                        );
                      },
                      child: Text(
                        '字体',
                        style: TextStyle(
                            color:
                                _colorModel.dark ? Colors.white : Colors.black),
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.all(Radius.circular(20.0))),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: readThemes(state),
            ),
          ],
        ),
        padding: EdgeInsets.only(left: 10, right: 10),
      ),
    );
  }

  List<Widget> readThemes(state) {
    List<Widget> wds = [];
    for (var i = 0; i < bgimg.length; i++) {
      var f = "images/${bgimg[i]}";
      wds.add(RawMaterialButton(
        onPressed: () {
          _readModel.switchBgColor(i);
//          __readModel.saveData();
          state(() {});
        },
        constraints: BoxConstraints(minWidth: 60.0, minHeight: 50.0),
        child: Container(
            margin: EdgeInsets.only(top: 5.0, bottom: 5.0),
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(25.0)),
              image: DecorationImage(
                image: AssetImage(f),
                fit: BoxFit.cover,
              ),
            )
            // decoration: BoxDecoration(
            //     color: Color.fromRGBO(f[0], f[1], f[2], 0.8),
            //     borderRadius: BorderRadius.all(Radius.circular(25.0)),
            //     border: __readModel.bgIdx == i
            //         ? Border.all(color: Theme.of(context).primaryColor, width: 2)
            //         : Border.all(color: Colors.white30)),
            ),
      ));
    }
    wds.add(SizedBox(
      height: 8,
    ));
    return wds;
  }
}
