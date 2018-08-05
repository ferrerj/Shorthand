part of Shorthand_base;

abstract class InternalRule extends RuleBase{
  const InternalRule();

  static Map<String,DataRule> dataRules = new Map();

  Map transformData(var name, var dataAdded, [DataAggregate da]);
  Map executeRule(var name, var dataToBeAdded, [DataAggregate da]);
  clearDataRules(){
    dataRules = new Map();
  }
  // gets the name of the structure for structure checks
  String structureName(var struct) {
    if (struct is Function) {
      return "Function";
    } else {
      InstanceMirror im = reflect(struct);
      String ret = im.type.simpleName.toString();
      return ret.substring(8, ret.length - 2);
    }
  }

  String funcName(var struct) {
    InstanceMirror im = reflect(struct);

    return im.toString();
  }

  Function getParser(TypeMirror tm){
    if(tm.reflectedType is int){
      return (String input){
        Match m = (new RegExp("(-)*[0-9]+")).firstMatch(input);
        if(m.groupCount==0){
          return null;
        }
        return int.parse(input.substring(m.start, m.end));
      };
    } else if(tm.reflectedType is double){
      return (String input){
        Match m = (new RegExp("(-)*[0-9]*(.)[0-9]*([eE][+-][0-9]+)*")).firstMatch(input);
        if(m.groupCount==0){
          return null;
        }
        return double.parse(input.substring(m.start, m.end));
      };
    } else if(tm.reflectedType is String) {
      return (String input){
        if(input.contains(";")){
          input = input.split(";")[0];
        }
        if(input.contains("'")){
          input = input.split("'")[0];
        }
        if(input.contains('"')){
          input = input.split('"')[0];
        }
        if(input.contains("=")){
          input = input.split("=")[0];
        }
        if(input.contains("(")){
          // stops function injection
          input = input.split("(")[0];
        }
        if(input.indexOf("@")==0){
          // stops variables from being used
          input = input.substring(1, input.length);
        }
        return input;
      };
    }else if(tm.reflectedType is bool){
      return (String input){
        Match m = (new RegExp("((true)|(false)|(t)|(f)|0|1)")).firstMatch(input.toLowerCase());
        if(m.groupCount==0){
          return null;
        } else {
          String result = input.substring(m.start, m.end);
          if(result=="true"||result=="t"||result=="1"){
            return true;
          }
          return false;
        }
      };
    } else {
      return (String input){
        return input;
      };
    }
  }
}

// the rule to rule all (map/internal) rules
abstract class MapRule extends InternalRule {

  Map transformData(
      var name, var dataAdded, [DataAggregate da]); // here we transform the data, return a map
  // dataToBeAdded is whatever the variable/function being analyzed is
  Map executeRule(var name, var dataToBeAdded, [DataAggregate da]) {
    return transformData(name, dataToBeAdded, da);
  }

  const MapRule();


  // made it static just in case its needed outside of this
  List<Function> httpInputHandlerBuilder(bool hasCookie, bool hasGet, bool hasPost, DataAggregate da){
    List<Function> httpInputHandlers = new List();
    if(hasCookie){
      // special cookie allows for custom made CookieData types
      // if it doesn't exist and the programmer doesn't want anything fancy
      // just use a regular old CookieData, doesn't have anything special in it
      CookieData specialCookie = null;
      for(dynamic data in da.aggregate.values){
        if(data is CookieData){
          specialCookie = data;
        }
      }
      if(specialCookie==null){
        httpInputHandlers.add((new CookieData()).returnMap);
      } else {
        httpInputHandlers.add(specialCookie.returnMap);
      }
    } else {
      httpInputHandlers.add((a, b, c)=> {});
    }
    if(hasGet){
      for(dynamic data in da.aggregate.values){
        if(data is GetData){
          httpInputHandlers.add(data.returnMap);
          break;
        }
      }
    } else {
      httpInputHandlers.add((a, b, c)=> {});
    }
    if(hasPost){
      for(dynamic data in da.aggregate.values){
        if(data is PostData){
          httpInputHandlers.add(data.returnMap);
          break;
        }
      }
    } else {
      httpInputHandlers.add((a, b, c)=> {});
    }
    return httpInputHandlers;
  }
}

// defines a new route
// used to mark an object which is to be read into the route
// name used will be the name of the structure, choose carefully
class Route extends MapRule {
  const Route();

  Map transformData(var name, var obj, [DataAggregate da]) {
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
  const EndPoint();

  // obj is really a map of the params, the instance mirror,
  // and the symbol in the instance mirror
  Map transformData(var name, var obj, [DataAggregate da]) {
    EndPointHelperObject input = obj;
    bool hasCookie = false;
    bool hasGet = false;
    bool hasPost = false;
    DataSources ds = null;
    List<Function> httpInputHandlers = new List();
    List<Function> inputHandlers = new List();
    List<Function> inputParsers = new List(); // used to parse inputs to ints, doubles, floats, make SQL safe strings, etc.
    List<String> inputNames = new List();
    // map the post/cookie/get data to the inputs of the function
    for(ParameterMirror parameter in input.parameters) {
      From paramSource = null;
      inputNames.add(nameOfTheSymbol(parameter.simpleName));
      if (parameter.metadata.length > 0) {
        // there is metadata defining where to find the data, there should only be one
        if (parameter.metadata[0].reflectee is From) {
          paramSource = parameter.metadata[0].reflectee;
          inputHandlers.add(
              paramSource.getFunction(nameOfTheSymbol(parameter.simpleName)));
        }
      } else {
        // there is no metadata defining where to find the data
        // use the data sources object to find if there are any defined there
        if (ds == null) {
          for (dynamic data in input.da.aggregate.values) {
            if (data is DataSources) {
              ds = data;
              break;
            }
          }
        }
        // there is no source provided for the parameter and no datasource to draw from
        if (ds == null) {
          print("parameter ${parameter.simpleName} in ${input
              .symbol} lacks a data input source. Please define in line or create a global DataSources variable");
          exit(0);
        }
        paramSource =
            ds.findParamSourceByName(nameOfTheSymbol(parameter.simpleName));
        if (paramSource == null) {
          print("parameter ${parameter.simpleName} in ${input
              .symbol} lacks a data input source. Please define in line or create a global DataSources variable");
          exit(0);
        }
        inputHandlers.add(
            paramSource.getFunction(nameOfTheSymbol(parameter.simpleName)));
        //
      }
      inputParsers.add(getParser(parameter.type));
      if (paramSource is FromCookie) {
        hasCookie = true;
      } else if (paramSource is FromGet) {
        hasGet = true;
      } else if (paramSource is FromPost) {
        hasPost = true;
      }
    }
    InternalRule.dataRules.addAll({"Input":(new Input(inputNames))});
    httpInputHandlers = httpInputHandlerBuilder(hasCookie, hasGet, hasPost, input.da);
    // build the function
    HttpRequestHandler hrh = new HttpRequestHandler(input.symbol, input.im, httpInputHandlers, inputHandlers, inputParsers);
    return {name: hrh.executeRequest};
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
  // takes each input and parses int, double, or bool
  // also makes strings SQL safe so you don't have to.
  List<Function> inputParsers = new List();
  Symbol symbol; // symbol of object to be invoked from instance mirror
  InstanceMirror im; // invoke function from instance mirror
  HttpRequestHandler(this.symbol, this.im, this.httpInputHandlers, this.inputHandlers, this.inputParsers);

  executeRequest(List cookies, String get, String post){
    if(inputHandlers==[]){
      return im.invoke(symbol, []);
    }
    // get the processed cookies, get, and post data
    List<Map> maps = new List();
    for(Function httpInputHandler in httpInputHandlers){
      maps.add(httpInputHandler(cookies, get, post));
    }
    // send processed data, getting data needed for request in order
    List<dynamic> inputs = new List();
    /*
    for(Function inputHandler in inputHandlers){
      inputs.add(inputHandler(maps[0], maps[1], maps[2]));
    }
    */
    for(int x = 0; x<inputHandlers.length; x++){
      inputs.add(inputParsers[x](inputHandlers[x](maps[0], maps[1], maps[2])));
    }
    // return function
    return im.invoke(symbol, inputs).reflectee;
  }
}

// used for static content, mainly strings to be served
// essentially an end point with some black magic in the background to make it work
class StaticContent extends MapRule {
  const StaticContent();

  Map transformData(var name, var obj, [DataAggregate da]) {
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

  String getString(List cookies, String getData, String postData) {
    return this.input;
  }
}

class DynamicString extends MapRule{
  const DynamicString();


  // obj is a string, name is the name of the string
  Map transformData(var name, var obj, [DataAggregate da]) {
    String string = obj;
    bool hasCookie = false;
    bool hasGet = false;
    bool hasPost = false;
    List<Function> httpInputHandlers = new List();
    List<Function> inputHandlers = new List();
    List<String> names = new List();
    List<Function> inputParsers = new List();
    for(DataRule dr in da.aggregate.values){
      if(dr is DataSources){
        Map<String, From> sources = dr.findAllParamSources();
        for(String source in sources.keys){
          if(string.contains("{${source}}")){
            names.add(source);
            inputHandlers.add(sources[source].getFunction(source));
            if (sources[source] is FromCookie) {
              hasCookie = true;
            } else if (sources[source] is FromGet) {
              hasGet = true;
            } else if (sources[source] is FromPost) {
              hasPost = true;
            }
            inputParsers.add(getParser(dr.findParamTypeByName(source)));
          }
        }
        httpInputHandlers = httpInputHandlerBuilder(hasCookie, hasGet, hasPost, da);
        break;
      }
    }
    return {name: (new StringModifier(string, names, httpInputHandlers, inputHandlers, inputParsers)).executeRequest};
  }
}

class StringModifier{
  // cookie, get, and post handling functions, transforms them into maps
  // each has params function(List args, List cookies, List post)
  List<Function> httpInputHandlers;
  // takes maps from above list and gets parts of data necessary for function
  // each has params function(Map args, Map cookies, Map post)
  List<Function> inputHandlers;
  List<String> names;
  String string; // symbol of object to be invoked from instance mirror
  List<Function> inputParsers;
  StringModifier(this.string, this.names, this.httpInputHandlers, this.inputHandlers, this.inputParsers);

  executeRequest(List cookies, String get, String post){
    if(inputHandlers==[]){
      return string;
    }
    String tempString = string;
    // get the processed cookies, get, and post data
    List<Map> maps = new List();
    for(Function httpInputHandler in httpInputHandlers){
      maps.add(httpInputHandler(cookies, get, post));
    }
    // send processed data, getting data needed for request in order
    List<dynamic> inputs = new List();
    for(Function inputHandler in inputHandlers){
      inputs.add(inputHandler(maps[0], maps[1], maps[2]));
    }
    if(inputs.length!=names.length){
      return "";
    }
    for(int i = 0; i<names.length; i++){
      tempString = tempString.replaceAll("{${names[i]}}", inputParsers[i](inputs[i]).toString());
    }
    return tempString;
  }
}

class DynamicSQL extends MapRule{
  const DynamicSQL();
  @override
  Map transformData(var name, var obj, [DataAggregate da]) {
    String string = obj;
    bool hasCookie = false;
    bool hasGet = false;
    bool hasPost = false;
    List<Function> httpInputHandlers = new List();
    List<Function> inputHandlers = new List();
    List<String> names = new List();
    List<Function> inputParsers = new List();
    ConnectionPool pool;
    for(DataRule dr in da.aggregate.values){
      if(dr is DataSources){
        Map<String, From> sources = dr.findAllParamSources();
        for(String source in sources.keys){
          if(string.contains("{${source}}")){
            names.add(source);
            inputHandlers.add(sources[source].getFunction(source));
            if (sources[source] is FromCookie) {
              hasCookie = true;
            } else if (sources[source] is FromGet) {
              hasGet = true;
            } else if (sources[source] is FromPost) {
              hasPost = true;
            }
            inputParsers.add(getParser(dr.findParamTypeByName(source)));
          }
        }
        httpInputHandlers = httpInputHandlerBuilder(hasCookie, hasGet, hasPost, da);
      } else if(dr is DataBaseOptions){
        pool = dr.getDB();
      }
    }
    return {name: (new SQLCaller(string, names, httpInputHandlers, inputHandlers, pool, inputParsers)).runSQL};
  }
}
// need to implement input parsers into string modifier
class SQLCaller extends StringModifier{
  ConnectionPool pool;
  JsonEncoder je = new JsonEncoder();
  SQLCaller(String string, List<String> names, List<Function> httpInputHandlers, List<Function> inputHandlers, this.pool, List<Function> inputParsers)
      : super(string, names, httpInputHandlers, inputHandlers, inputParsers);
  Future runSQL(List cookies, String get, String post) async {
    String query = executeRequest(cookies, get, post);
    try {
      List<Row> list = await pool.query(query).then((results) =>
          results.toList());
      List<String> retVal = new List();
      for (Row r in list) {
        String temp = r.toString().substring(8);
        for (dynamic s in r) {
          temp = temp.replaceAll(" ${s.toString()}", ' "${s.toString()}"');
        }
        // convert output to JSON
        temp = temp.replaceAll(":", '":');
        temp = temp.replaceAll("{", '{"');
        temp = temp.replaceAll(', ', ', "');
        retVal.add(temp);
      }
      return retVal;
    } catch (error){
      print(error.toString());
      return error.toString();
    }
  }
}

// to be implemented later, runs a legacy script through the terminal
class LegacyScript extends MapRule {
  final dynamic executable;

  const LegacyScript(var this.executable);

  Map transformData(var name, var obj, [DataAggregate da]) {
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
