library MapServer;

import 'dart:io';

class MapServer {
  // url route : (map with further routes or function to generate page)
  String baseURL;
  Map siteMap;
  int portNo;

  // these should be functions, really special cases compared to the rest of the site map
  var homePage; // home page

  // need base url for routing purposes
  // rest can be set later, but server will have lame homepage/not found page
  // will only start on own with a siteMap provided
  MapServer(
      {Map this.siteMap,
      Function this.homePage,
      int this.portNo: 80,
      bool start: true}) {
    if (start) {
      startServer();
    }
  }

  startServer({SecurityContext securityContext = null}) async {
    var requestServer;
    if(securityContext==null){
        requestServer = await HttpServer.bind(InternetAddress.anyIPv4, portNo);
    } else {
      requestServer = await HttpServer.bindSecure(InternetAddress.anyIPv4, portNo, securityContext);
    }
    print('listening on localhost, port ${requestServer.port}');
    await for (HttpRequest request in requestServer) {
      print(request.uri.toString());
      await findPage(request);
    }
  }

  // level 0: base page
  // level 1: routing or a page
  // level 2+: routing found in a sub-site map
  findPage(HttpRequest request, {var route : null, int level, Map subMap}) async {
    if(route == null){
      route = request.uri.toString();
    }
    if (siteMap == null && homePage == null) {
      return "Please set me up!";
    } else if (siteMap == null && homePage is Function) {
      return homePage();
    }
    if (route is String) {
      // break it up and start routing
      if (route == "/") {
        if (homePage is Function) {
          return homePage();
        } else {
          return "homepage";
        }
      } else {
        return findPage(request, route: route.split("/"), level: 1);
      }
    } else if (route is List) {
      // route is already broken up and routing
      var useThisMap = null;
      if (level < 2) {
        //  no need to check for sub-map, run the function at that level, providing the data at the end of the route info
        useThisMap = siteMap;
      } else {
        // level 2 or greater, need to check sub-map
        // TODO: Test sub maps
        print("I'm using the sub map");
        useThisMap = subMap;
      }
      if (useThisMap[route[level]] == null) {
        // 404 not found
        request.response.statusCode = HttpStatus.notFound;
        request.response
          ..write("")
          ..close();
      } else if (useThisMap[route[level]] is Map) {
        // map found requires further routing
        // TODO: test sub maps more...
        //print(findPage(route, cookies, post,
        //    level: level++, subMap: useThisMap[route[level]]));
        return findPage(request, route: route,
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
        print("get is $get");
        return await useThisMap[route[level]](request, get);
      }
    }
  }

  // these set variables which can be set later,
  // depending on how you really want to structure the program
  setHomePage(Function homePageFunc) {
    homePage = homePageFunc;
  }

  setPortNo(int portNumber) {
    portNo = portNumber;
  }

  setMap(var m) {
    // need the map
    if (m is Map) {
      this.siteMap = m;
    } else {
      print("no map provided");
      exit(0);
    }
  }
}
