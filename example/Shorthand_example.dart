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
// class for using dataSouces annotation
// list all params used in functions, then just call the class in a param for
// the class being built, declaring where the data comes from
class LookUp{
  const LookUp();
  // delcares that all parameters with name id which do not specify whether it
  // is from a cookie, get or post will be from a get.
  @FromGet()
  final dynamic id;
}

@DataSources(const LookUp())
@HostName("http://192.168.1.19")
@GetData(InputFormat.AndData)
class TestClass {
  // should be skipped
  var test;

  @Input(const []) // tells internetlist what params it needs
  @Output(const ["name"], const ["id"]) // tells internetlist what to expect
  @FlowTo("Songs") // where the internetlist will lead next
  @InternetList("Artists") // generates flutter code titled artist which will pull data from this url
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
  // manually declaring data source (cookie, get, post)
  @Input(const ["id"])
  @Output(const ["title"], const ["id"])
  @InternetList("Songs")
  @EndPoint()
  // FromGet here will override whatever source is declared in the DataSources
  // object, doing so is ill advised if you have sources set up already
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
  // implying data souce from DataSources object
  @Input(const ["id"])
  @Output(const ["title"], const ["id"])
  @InternetList("Songs")
  @EndPoint()
  songsAgain(dynamic id) {
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
