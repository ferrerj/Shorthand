import 'package:Shorthand/Shorthand.dart';

import 'dart:io';

testPage() {
  return "Good Job!";
}

pageNotFound() {
  return "Find a better page.";
}

home(List args, List cookies) {
  return "you are home";
}

@HostName("http://192.168.1.19")
@GetData(InputFormat.AndData)
class TestClass {
  // should be skipped
  var test;

  @InternetList("Artists")
  @Input(const [])
  @Output(const ["name"], const ["id"])
  @FlowTo("Songs")
  @EndPoint()
  artists() {
    Map<int, String> artistList = {
      1: "Of Monsters and Men",
      2: "The Lumineers",
      3: "Weezer"
    }; // to be replaced with sql value later
    String returnVal = "[";
    for (int i = 0; i < artistList.length; i++) {
      returnVal = "$returnVal {\"id\" : \"${artistList.keys
          .toList()[i]}\", \"name\" : \"${artistList.values
          .toList()[i]}\"}${(i < artistList.length - 1) ? "," : "]"}";
    }
    return returnVal;
  }

  @InternetList("Songs")
  @Input(const ["id"])
  @Output(const ["title"], const ["id"])
  @EndPoint()
  songs(@FromGet() dynamic id) {
    int idNo = int.parse(id);
    List songLib = [
      {1: "Little Talks", 2: "Mountain Sound", 3: "Dirty Paws"},
      {4: "Ho Hey", 5: "Ophelia", 6: "Flowers In Your Hair"},
      {7: "Buddy Holly", 8: "Beverly Hills", 9: "Hash Pipe"}
    ];
    String returnVal = "[";
    for (int i = 0; i < songLib[idNo].length; i++) {
      returnVal = "$returnVal {\"id\" : \"${songLib[idNo].keys
          .toList()[i]}\", \"title\" : \"${songLib[idNo].values
          .toList()[i]}\"}${(i < songLib[idNo].length - 1) ? "," : "]"}";
    }
    return returnVal;
  }

  @StaticContent()
  String temp = "You got StringReturner to work";

  @StaticContent()
  File testFile = new File("${Directory.current.path}\\example\\testfile.txt");
}

main() async {
  TestClass tc = new TestClass();

  Shorthand sh = new Shorthand(object: tc);

  var server = new MapServer(
      siteMap: sh.generatedMap, homePage: testPage, notFound: pageNotFound);
}
