import 'package:Shorthand/Shorthand.dart';
import 'package:Shorthand/MapServer.dart';

import 'dart:io';

/*
Everything here works as intended, I have tried to comment as much as I can to
avoid writing up documentation on all of it. So far only InputFormat.AndData has
been fully tested as a URL param organization method. The code in the functions
is admittedly lazy but that's not what I wanted to show here. I do plan on doing
reworks in the future to fix earlier work done with less direction, specifically
the code around the functions below which do not exist in a class to define 404s
and home page, etc. Further, the flutter code generators could use work and only
output to the command line at the moment. Further in the near future I have plans
for socket code using similar styling as below. Two important features currently
needed are cookie/header annotations and HTTPS signing.
 */

//temporary homepage example
testPage() {
  return "Good Job!";
}

// class for using dataSouces annotation
// list all params used in functions, then just call the class in a param for
// the class being built, declaring where the data comes from

// Warning will say final variables need to be initialized, but that's now how
// we plan to use the object, so just ignore.
class LookUp{
  const LookUp();
  // delcares that all parameters with name id which do not specify whether it
  // is from a cookie, get or post will be from a get.
  @FromGet()
  final int id;

  @FromPost()
  final String name;
}

@DataSources(const LookUp())
@HostName("http://192.168.1.19") // for flutter code generation
@GetData(InputFormat.AndData) // made up the name AndData, basically its /?param=val&param2=val2 format
@PostData(InputFormat.JSON)
@DataBaseOptions("example/connection.options") // for database connections
class TestClass {
  // should be skipped
  var test;

  // no arg function
  @Output(const ["name"], const ["id"]) // tells internetlist what to expect, will be depricated soon
  @FlowTo("Songs") // where the internetlist will lead next (external rules only)
  @InternetList("Artists") // generates flutter code titled artist which will pull data from this url
  @EndPoint() // tells the map server to build closure for request handling around this
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
  // FromGet here will override whatever source is declared in the DataSources (LookUp)
  // object, doing so is ill advised if you have sources set up already
  songs(@FromGet() int id) {
    List songLib = [
      {1: "Little Talks", 2: "Mountain Sound", 3: "Dirty Paws"},
      {4: "Ho Hey", 5: "Ophelia", 6: "Flowers In Your Hair"},
      {7: "Buddy Holly", 8: "Beverly Hills", 9: "Hash Pipe"}
    ];
    String returnVal = "[";
    for (int i = 0; i < songLib[id].length; i++) {
      returnVal = "$returnVal {\"id\" : \"${songLib[id].keys
          .toList()[i]}\", \"title\" : \"${songLib[id].values
          .toList()[i]}\"}${(i < songLib[id].length - 1) ? "," : "]"}";
    }
    return returnVal;
  }
  // implying data souce from DataSources object
  @Output(const ["title"], const ["id"])
  @InternetList("Songs")
  @EndPoint()
  songsAgain(int id) {
    List<Map> songLib = [
      {1: "Little Talks", 2: "Mountain Sound", 3: "Dirty Paws"},
      {4: "Ho Hey", 5: "Ophelia", 6: "Flowers In Your Hair"},
      {7: "Buddy Holly", 8: "Beverly Hills", 9: "Hash Pipe"}
    ];
    print(songLib);
    print(id);
    print(id.runtimeType);
    String returnVal = "[";
    for (int i = 0; i < songLib[id].length; i++) {
      returnVal = "$returnVal {\"id\" : \"${songLib[id].keys
          .toList()[i]}\", \"title\" : \"${songLib[id].values
          .toList()[i]}\"}${(i < songLib[id].length - 1) ? "," : "]"}";
    }
    return returnVal;
  }

  // StaticContent returns the content of a string or file which is stored in
  // memory, don't go too crazy with this one
  @StaticContent()
  String temp = "You got StringReturner to work";

  @StaticContent()
  File testFile = new File("${Directory.current.path}\\example\\testfile.txt");

  // Similar to StaticContent, only it will use member variables names of the
  // DataSources (LookUp) object to build a closure around the function
  @DynamicString()
  String testString = "ID no is {id}";

  @DynamicString()
  String postTest = "Hello, {name}";

  // Similar to DynamicString, only after building the string below, it will
  // query the database using the connections options provided in file provided
  // to the DataBaseOptions declaration and returns the result as a JSON object

  @DynamicSQL()
  String testSQL = "SELECT * "
      "             FROM users "
      "             WHERE id = {id};";

}

main() async {
  TestClass tc = new TestClass();

  Shorthand sh = new Shorthand(object: tc);

  print(sh.generatedMap);

  MapServer server = new MapServer(
      siteMap: sh.generatedMap, homePage: testPage);
}
