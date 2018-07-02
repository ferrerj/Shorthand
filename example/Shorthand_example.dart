import 'package:Shorthand/Shorthand.dart';

import 'dart:io';

/*
Everything here works as intended, I have tried to comment as much as I can to
avoid writing up documentation on all of it. So far only InputFormat.AndData has
been fully tested as a URL param organization method. The code in the functions
is admittedly lazy but that's not what I wanted to show here. I do plan on doing
reworks in the future to fix earlier work done with less direction, specifically
the code around the functions below which do not exist in a class to define 404s
and home page, etc. Further, the flutter code generators could use work and only
output to the command line at the moment, something that will be one of my more
immediate focuses after getting SQL queries from strings to work.
 */

testPage() {
  return "Good Job!";
}

pageNotFound() {
  return "Find a better page.";
}

home(List cookies, String getData, String postData) {
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
  final String id;
}

@DataSources(const LookUp())
@HostName("http://192.168.1.19")
@GetData(InputFormat.AndData) // made up the name AndData, basically its /?param=val&param2=val2 format
@DataBaseOptions("example/connection.options")
class TestClass {
  // should be skipped
  var test;

  @Output(const ["name"], const ["id"]) // tells internetlist what to expect, will be depricated soon
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
  @Output(const ["title"], const ["id"])
  @InternetList("Songs")
  @EndPoint()
  // FromGet here will override whatever source is declared in the DataSources
  // object, doing so is ill advised if you have sources set up already
  // I will admit the code in this function is pretty lazy, I just wanted to prove it works
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

  @DynamicString()
  String testString = "ID no is {id}";

  @DynamicSQL()
  String testSQL = "SELECT * "
      "             FROM users "
      "             WHERE id = {id};";
}

main() async {
  TestClass tc = new TestClass();

  Shorthand sh = new Shorthand(object: tc);

  print(sh.generatedMap);

  var server = new MapServer(
      siteMap: sh.generatedMap, homePage: testPage, notFound: pageNotFound);
}
