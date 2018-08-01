import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gankio/data/article.dart';
import 'package:gankio/display/webview.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;

class TodayPage extends StatefulWidget {
  @override
  _TodayPageState createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x99D9DAE4),
      child: FutureBuilder<Article>(
        future: _fetchHomePage(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _generateContent(snapshot.data, context);
          } else if (snapshot.hasError) {
            return new Center(
              child: Text("${snapshot.error}"),
            );
          }
          return new Container(
            width: MediaQuery.of(context).size.width * 0.15,
            height: MediaQuery.of(context).size.width * 0.15,
            child: Center(
              child: CircularProgressIndicator(), // By default, show a loading spinner
            ),
          );
        },
      ),
    );
  }
}

Widget _generateContent(Article article, BuildContext context) {
  List<Widget> items = new List();
  // ==============> Title
  items.add(FutureBuilder<dom.Document>(
    future: _fetchHtml(),
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        for (var node in snapshot.data.head.nodes) {
          if (node != null && node.toString() == '<html title>') {
            return _generateTitle(node.text);
          }
        }
      }
      return _generateTitle("Gank IO~");
    },
  ));
  // ==============> RequestTime
  items.add(
    new Container(
        padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Text(
          "请求时间：${ DateTime.now().toString()}",
          textAlign: TextAlign.left,
          style: TextStyle(fontSize: 10.0, color: const Color(0xFF747474)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )),
  );

  // =================> App Content
  var appArticles = article.result['App'];
  if (appArticles != null && appArticles.length != 0) {
    items.add(_buildArticlesBlock(title: 'App', icon: 'images/android_icon.png', articles: appArticles, context: context));
    items.add(_buildSectionSpace());
  }
  // =================> Android Content
  var androidArticles = article.result['Android'];
  if (androidArticles != null && androidArticles.length != 0) {
    items
        .add(_buildArticlesBlock(title: 'Android', icon: 'images/android_icon.png', articles: androidArticles, context: context));
    items.add(_buildSectionSpace());
  }
  // =================> iOS Content
  var iOSArticles = article.result['iOS'];
  if (iOSArticles != null && iOSArticles.length != 0) {
    items.add(_buildArticlesBlock(title: 'iOS', icon: 'images/android_icon.png', articles: iOSArticles, context: context));
    items.add(_buildSectionSpace());
  }
  // =================> QianDuan Content
  var frontArticles = article.result['前端'];
  if (frontArticles != null && frontArticles.length != 0) {
    items.add(_buildArticlesBlock(title: '前端', icon: 'images/android_icon.png', articles: frontArticles, context: context));
    items.add(_buildSectionSpace());
  }
  // =================> TuoZhan Content
  var extendArticles = article.result['拓展资源'];
  if (extendArticles != null && extendArticles.length != 0) {
    items.add(_buildArticlesBlock(title: '拓展资源', icon: 'images/android_icon.png', articles: extendArticles, context: context));
    items.add(_buildSectionSpace());
  }
  // =================> XiuXi Content
  var relaxArticles = article.result['休息视频'];
  if (relaxArticles != null && relaxArticles.length != 0) {
    items.add(_buildArticlesBlock(title: '休息视频', icon: 'images/android_icon.png', articles: relaxArticles, context: context));
    items.add(_buildSectionSpace());
  }
  // ==============> FuLi Image
  items.add(_generateSectionTitle('福利'));
  items.add(_generateHorizontalLine());
  String fuLiUrl = (article.result['福利'] != null && article.result['福利'].length > 0) ? article.result['福利'][0].url : null;
  if (fuLiUrl != null) {
    Image image = new Image.network(article.result['福利'][0].url);
    Completer<ui.Image> completer = new Completer<ui.Image>();
    image.image.resolve(new ImageConfiguration()).addListener((ImageInfo info, bool _) => completer.complete(info.image));
    items.add(new FutureBuilder<ui.Image>(
      future: completer.future,
      builder: (BuildContext context, AsyncSnapshot<ui.Image> snapshot) {
        if (snapshot.hasData) {
          double imageWidthDefine = MediaQuery.of(context).size.width * 0.5;
          return new Container(
            margin: EdgeInsets.only(top: 3.0, bottom: 10.0),
            width: imageWidthDefine,
            height: imageWidthDefine / snapshot.data.width * snapshot.data.height,
            child: image,
          );
        } else {
          return new Text('Loading...');
        }
      },
    ));
  } else {
    items.add(new Container(
      margin: EdgeInsets.only(top: 15.0, bottom: 15.0),
      child: Text(
        '今天没有福利~QAQ~',
        style: TextStyle(fontSize: 15.0),
      ),
    ));
  }

  return ListView(
    padding: new EdgeInsets.only(left: 15.0, right: 15.0),
    children: items,
  );
}

Widget _buildSectionSpace() {
  return Container(
    height: 10.0,
  );
}

Widget _generateTitle(String text) {
  return new Container(
    padding: EdgeInsets.only(top: 15.0, bottom: 2.0),
    child: new Text(
      text,
      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF747474)),
    ),
  );
}

Widget _buildArticlesBlock({String title, String icon, List<ArticleSector> articles, BuildContext context}) {
  var articleItems = List<Widget>();
  articleItems.add(_buildArticlesBlockTitle(title: title, icon: icon));
  for (var sector in articles) {
    articleItems.add(_buildArticleItem(sector, context));
  }
  Color color = Colors.black26;
  switch (title) {
    case 'App':
      color = Colors.blueAccent;
      break;
    case 'iOS':
      color = Colors.deepPurpleAccent;
      break;
    case 'Android':
      color = Colors.lightGreen;
      break;
    case '前端':
      color = Colors.brown;
      break;
    case '拓展资源':
      color = Colors.blueGrey;
      break;
    case '休息视频':
      color = Colors.teal;
      break;
  }
  return Card(
    child: Container(
      color: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 5.0,
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.only(top: 10.0, left: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: articleItems,
              ),
            ),
          )
        ],
      ),
    ),
  );
}

Widget _buildArticlesBlockTitle({String title, String icon}) {
  return Row(
    children: <Widget>[
      Container(
        padding: EdgeInsets.all(0.0),
        width: 22.0,
        height: 22.0,
        child: Image.asset(icon),
      ),
      Text(
        '  $title',
        style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500, color: const Color(0xFF515151)),
      ),
    ],
  );
}

Widget _buildArticleItem(ArticleSector article, BuildContext context) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => WebViewer(
                    url: article.url,
                    title: article.desc,
                  )));
    },
    child: Container(
      padding: EdgeInsets.only(left: 8.0, top: 8.0, right: 3.0, bottom: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(top: 3.0, right: 6.0),
            child: Image.asset('images/article_icon.png'),
            width: 15.0,
            height: 15.0,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                    margin: EdgeInsets.only(right: 5.0),
                    child: Text(
                      '${article.desc.trim()}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.0, color: Color(0xFF555555)),
                    )),
                Container(
                  child: Text(
                    '${article.who} 发布于 ${article.publishedAt.substring(0, 10)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 9.0, color: Colors.black45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _generateSectionTitle(String text) {
  return new Container(
    margin: EdgeInsets.only(top: 8.0),
    child: Text(
      text,
      style: TextStyle(fontSize: 18.5, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    ),
  );
}

_generateArticleDesc(List<Widget> items, ArticleSector sector, BuildContext context) {
  items.add(new GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => WebViewer(
                      url: sector.url,
                      title: sector.desc,
                    )));
      },
      child: new Container(
        margin: EdgeInsets.only(top: 3.0, bottom: 3.0),
        padding: EdgeInsets.only(left: 10.0, right: 2.0, top: 12.0, bottom: 12.0),
        color: Colors.black12,
        child: new RichText(
            text: new TextSpan(style: new TextStyle(fontSize: 13.0), children: <TextSpan>[
          new TextSpan(text: sector.desc, style: new TextStyle(color: Colors.black)),
          new TextSpan(
              text: "\nby ${sector.who}", style: new TextStyle(color: Colors.grey, fontSize: 10.0, fontStyle: FontStyle.italic))
        ])),
      )));
}

Widget _generateHorizontalLine() {
  return new Container(
    height: 1.0,
    color: Colors.blueGrey,
  );
}

Future<Article> _fetchHomePage() async {
  final response = await http.get('https://gank.io/api/today');
  if (response.statusCode == 200) {
    return Article.fromJson(response.body);
  } else {
    throw Exception('Failed to HomePage');
  }
}

Future<dom.Document> _fetchHtml() async {
  final response = await http.get('https://gank.io');
  if (response.statusCode == 200) {
    return parse(response.body);
  } else {
    throw Exception('Failed to HomeHtml');
  }
}