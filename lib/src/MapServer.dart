library MapServer;

import 'dart:io';

class MapServer {
  // url route : (map with further routes or function to generate page)
  String baseURL;
  Map site;
  int portNo;

  // these should be functions, really special cases compared to the rest of the site map
  var nf; // not found
  var hp; // home page

  // need base url for routing purposes
  // rest can be set later, but server will have lame homepage/not found page
  // will only start on own with a siteMap provided
  MapServer(
      {Map siteMap,
      Function notFound,
      Function homePage,
      int portNo: 80,
      bool start: true}) {
    if (siteMap != null) {
      this.site = siteMap;
    }
    if (notFound != null) {
      this.nf = notFound;
    }
    if (homePage != null) {
      this.hp = homePage;
    }
    this.portNo = portNo;
    if (start) {
      startServer();
    }
  }

  startServer() async {
    var requestServer =
        await HttpServer.bind(InternetAddress.anyIPv4, portNo);
    print('listening on localhost, port ${requestServer.port}');
    await for (HttpRequest request in requestServer) {
      print(request.uri.toString());
      request.response
        ..write(this.findPage(request.uri.toString(), request.cookies))
        ..close();
    }
  }

  // level 0: base page
  // level 1: routing or a page
  // level 2+: routing found in a sub-site map
  findPage(var route, var cookies, {int level, Map subMap}) {
    if (site == null && hp == null) {
      return "Please set me up!";
    } else if (site == null && hp is Function) {
      return hp();
    }
    if (route is String) {
      // break it up and start routing
      if (route == "/") {
        if (hp is Function) {
          return hp();
        } else {
          return "homepage";
        }
      } else {
        return findPage(route.split("/"), cookies, level: 1);
      }
    } else if (route is List) {
      // route is already broken up and routing
      var useThisMap = null;
      if (level < 2) {
        //  no need to check for sub-map, run the function at that level, providing the data at the end of the route info
        useThisMap = site;
      } else {
        // level 2 or greater, need to check sub-map
        // TODO: Test sub maps
        print("I'm using the sub map");
        useThisMap = subMap;
      }
      if (useThisMap[route[level]] == null) {
        // 404 not found
        if (nf is Function) {
          return nf();
        } else {
          return "notfound";
        }
      } else if (useThisMap[route[level]] is Map) {
        // map found requires further routing
        // TODO: test sub maps more...
        return findPage(route, cookies,
            level: level++, subMap: useThisMap[route[level]]);
      } else {
        // found a page to generate
        // route.sublist(level) gets all params after the routing and passes them as a list
        // cookies, passes the cookies
        // still need to find way to get post data.
        String get = "";
        for(String data in route.sublist(level+1)){
          if(get==""){
            get=data;
          } else {
            get="$get/$data";
          }
        }
        return useThisMap[route[level]](cookies, get, "");
      }
    }
  }

  // these set variables which can be set later,
  // depending on how you really want to structure the program
  setNotFound(Function notFoundFunc) {
    nf = notFoundFunc;
  }

  setHomePage(Function homePageFunc) {
    hp = homePageFunc;
  }

  setPortNo(int portNumber) {
    portNo = portNumber;
  }

  setMap(var m) {
    // need the map
    if (m is Map) {
      this.site = m;
    } else {
      print("no map provided");
      exit(0);
    }
  }
}
