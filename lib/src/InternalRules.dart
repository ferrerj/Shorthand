part of Shorthand_base;

// the rule to rule all (map/internal) rules
abstract class MapRule extends RuleBase {
  final List<String> allowedTypes =
      null; // we we can type check the data coming in, stored as strings
  Map transformData(
      var name, var dataAdded); // here we transform the data, return a map
  // dataToBeAdded is whatever the variable/function being analyzed is
  Map executeRule(var name, var dataToBeAdded) {
    return transformData(name, dataToBeAdded);
    /*
    if(allowedTypes.contains(structureName(dataToBeAdded))||allowedTypes.contains("Any")){
      // Using the word any will allow any structure to pass through the rule
      print(executeRule(dataToBeAdded));
      return transformData(dataToBeAdded);
    } else {
      return {};
    }*/
  }

  const MapRule();

  // gets the name of the structure for structure checks
  // made it static just in case its needed outside of this
  String structureName(var struct) {
    if (struct is Function) {
      return "Function";
    } else {
      InstanceMirror im = reflect(struct);
      String ret = im.type.simpleName.toString();
      print(ret);
      return ret.substring(8, ret.length - 2);
    }
  }

  String funcName(var struct) {
    InstanceMirror im = reflect(struct);

    print(im.type.qualifiedName);
    return im.toString();
  }
}

// defines a new route
// used to mark an object which is to be read into the route
// name used will be the name of the structure, choose carefully
class Route extends MapRule {
  final List<String> allowedTypes = const ["Any"];

  const Route();

  Map transformData(var name, var obj) {
    if (obj is! Function) {
      // this would defeat the purpose
      Shorthand sh = new Shorthand(object: obj, currentRoute: "/$name");
      return {name: sh.generatedMap};
    } else {
      return {};
    }
  }
}

// used to mark a function which will serve as a point to hand a web page
// number of variable inputs, types, and names can be grabbed from function
class EndPoint extends MapRule implements RuleBase {
  final List<String> allowedTypes = const ["Function"];

  const EndPoint();

  // obj is really a map of the params, the instance mirror,
  // and the symbol in the instance mirror
  Map transformData(var name, var obj) {
    EndPointHelperObject input = obj;
    bool hasCookie = false;
    bool hasGet = false;
    bool hasPost = false;
    DataSources ds = null;
    // map the post/cookie/get data to the inputs of the function
    for(ParameterMirror parameter in input.parameters){
      if(parameter.metadata.length>0){
        // there is metadata defining where to find the data, there should only be one
        if(parameter.metadata[0] is CookieData){
          hasCookie=true;
        } else if(parameter.metadata[0] is GetData){
          hasGet=true;
        } else if(parameter.metadata[0] is PostData){
          hasPost=true;
        }
      } else {
        // there is no metadata defining where to find the data
        // use the data sources object
        if(ds==null){
          for(dynamic data in input.da.aggregate.values){
            if(data is DataSources){
              ds = data;
            }
          }
        }
        if(ds == null){
          print("parameter ${parameter.simpleName} in ${input.symbol} lacks a data input source. Please define in line or create a global DataSources variable");
          exit(0);
        }
        //
      }
    }
    // build the function
    return {name: obj};
  }
}
// used in place of a map for the method to be passed
class EndPointHelperObject{
  List<ParameterMirror> parameters;
  InstanceMirror im;
  Symbol symbol;
  DataAggregate da;
  EndPointHelperObject(this.parameters, this.im, this.symbol, this.da);
}

// helper class for endpoint
// takes in all functions to process data and run function
class HttpRequestHandler{
  // cookie, get, and post handling functions, transforms them into maps
  // each has params function(List args, List cookies, List post)
  List<Function> httpInputHandlers = new List();
  // takes maps from above list and gets parts of data necessary for function
  // each has params function(Map args, Map cookies, Map post)
  List<Function> inputHandlers = new List();
  Symbol symbol; // symbol of object to be invoked from instance mirror
  Function handledFunction; // invoke function from instance mirror

  HttpRequestHandler(this.symbol, this.handledFunction);

  addHandlers(Function httpInputHandler, Function inputHandler){
    httpInputHandlers.add(httpInputHandler);
    inputHandlers.add(inputHandler);
  }

  executeRequest(List args, List cookies){
    // get the processed cookies, get, and post data
    List<Map> maps = new List();
    for(Function httpInputHandler in httpInputHandlers){
      maps.add(httpInputHandler(args, cookies));
    }
    // send processed data, getting data needed for request in order
    List<dynamic> inputs = new List();
    for(Function inputHandler in inputHandlers){
      inputs.add(inputHandler(maps[0], maps[1]));
    }
    // return function
    return handledFunction(symbol, inputs);
  }
}

// used for static content, mainly strings to be served
// essentially an end point with some black magic in the background to make it work
class StaticContent extends MapRule {
  final List<String> allowedTypes = const ["String"];

  const StaticContent();

  Map transformData(var name, var obj) {
    // need to write code to get the getString code from string returner
    if (obj is String) {
      StringReturner sr = new StringReturner(obj);
      return {name: sr.getString};
    } else if (obj is File) {
      StringReturner sr = new StringReturner(obj.readAsStringSync());
      return {name: sr.getString};
    }
    return {};
  }
}

class StringReturner {
  String input;

  StringReturner(String this.input);

  String getString(List args, List cookies) {
    return this.input;
  }
}

// to be implemented later, runs a legacy script through the terminal
class LegacyScript extends MapRule {
  final dynamic executable;

  const LegacyScript(var this.executable);

  Map transformData(var name, var obj) {
    return {"": ""};
  }
}

// The ones below will be left out of the generator rules for now

// used to indicate the expected output value
// really for use in future work on this
class EndPointOutput {
  final String output;
  final String outputType;

  EndPointOutput([this.output, this.outputType]);
}

// method of HTTP handling to be used (GET, PUT, POST, DELETE, OPTIONS)
// to be implemented later
class Method {
  final String method;

  Method([this.method]);
}

// dynamically generated file to be generated and served
// for integration with legacy scripts not in Dart that you don't want to port over
class DynamicFile {
  final String file;
  final String program;

  DynamicFile([this.file, this.program]);
}
