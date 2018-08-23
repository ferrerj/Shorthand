part of Shorthand_base;

// the rule to rule all (map/internal) rules
abstract class MapRule extends RuleBase {
  static Map<String,DataRule> dataRules = new Map();
  Map transformData(
      var name, var dataAdded, [DataAggregate da]); // here we transform the data, return a map
  // dataToBeAdded is whatever the variable/function being analyzed is
  // override this to get more complex request handling (write cookies and stuff).
  Map executeRule(var name, var dataToBeAdded, [DataAggregate da]) {
    Map retMap = transformData(name, dataToBeAdded, da);
    SimpleMapHelper smh = new SimpleMapHelper(retMap[name]);
    retMap[name] = smh.transformRequest;
    return retMap;
  }
  clearDataRules(){
    dataRules = new Map();
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
      return ret.substring(8, ret.length - 2);
    }
  }

  String funcName(var struct) {
    InstanceMirror im = reflect(struct);

    return im.toString();
  }
  static List<Function> httpInputHandlerBuilder(bool hasCookie, bool hasGet, bool hasPost, DataAggregate da){
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

  static Function getParser(TypeMirror tm){
    if(tm.reflectedType == int){
      return (String input){
        Match m = (new RegExp("(-)*[0-9]+")).firstMatch(input);
        if(m.groupCount==0){
          return null;
        }
        return int.parse(input.substring(m.start, m.end));
      };
    } else if(tm.reflectedType == double){
      return (String input){
        Match m = (new RegExp("(-)*[0-9]*(.)[0-9]*([eE][+-][0-9]+)*")).firstMatch(input);
        if(m.groupCount==0){
          return null;
        }
        return double.parse(input.substring(m.start, m.end));
      };
    } else if(tm.reflectedType == String) {
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
    }else if(tm.reflectedType == bool){
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

// used as an simple write response, no cookie, rule
class SimpleMapHelper{
    Function f;
    SimpleMapHelper(this.f);

    transformRequest(HttpRequest request, String get) async {
              String post = await request.transform(utf8.decoder).join();
              request.response
                ..write(await f(request.cookies, get, post))
                ..close();
    }
}

// defines a new route
// used to mark an object which is to be read into the route
// name used will be the name of the structure, choose carefully
class Route extends MapRule {
  const Route();

  Map transformData(var name, var obj, [DataAggregate da]) {
    if (obj is! Function && obj is! String && obj is! num) {
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
      inputParsers.add(MapRule.getParser(parameter.type));
      if (paramSource is FromCookie) {
        hasCookie = true;
      } else if (paramSource is FromGet) {
        hasGet = true;
      } else if (paramSource is FromPost) {
        hasPost = true;
      }
    }
    MapRule.dataRules.addAll({"Input":(new Input(inputNames))});
    httpInputHandlers = MapRule.httpInputHandlerBuilder(hasCookie, hasGet, hasPost, input.da);
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

class BaseClosure {
  // cookie, get, and post handling functions, transforms them into maps
  // each has params function(List args, List cookies, List post)
  List<Function> httpInputHandlers = new List();
  // takes maps from above list and gets parts of data necessary for function
  // each has params function(Map args, Map cookies, Map post)
  List<Function> inputHandlers = new List();
  // takes each input and parses int, double, or bool
  // also makes strings SQL safe so you don't have to.
  List<Function> inputParsers = new List();

  BaseClosure(this.httpInputHandlers, this.inputHandlers, this.inputParsers);

  List getInputs(List cookies, String get, String post){
    // get the processed cookies, get, and post data
    List<Map> maps = new List();
    for(Function httpInputHandler in httpInputHandlers){
      maps.add(httpInputHandler(cookies, get, post));
    }
    // send processed data, getting data needed for request in order
    List<dynamic> inputs = new List();
    for(int x = 0; x<inputHandlers.length; x++){
      inputs.add(inputParsers[x](inputHandlers[x](maps[0], maps[1], maps[2])));
    }
    return inputs;
  }

}

// helper class for endpoint
// takes in all functions to process data and run function
class HttpRequestHandler extends BaseClosure{
  Symbol symbol; // symbol of object to be invoked from instance mirror
  InstanceMirror im; // invoke function from instance mirror
  HttpRequestHandler(this.symbol, this.im, List httpInputHandlers, List inputHandlers, List inputParsers) :
    super(httpInputHandlers, inputHandlers, inputParsers);

  executeRequest(List cookies, String get, String post){
    if(inputHandlers==[]){ // no arg funtion
      return im.invoke(symbol, []);
    }
    List inputs = getInputs(cookies, get, post);
    if(inputs.length!=inputParsers.length){
      return "";
    } else{
      return im.invoke(symbol, inputs).reflectee;
    }
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

class DynamicStringHelper{
    String string;
    bool hasCookie = false;
    bool hasGet = false;
    bool hasPost = false;
    List<Function> httpInputHandlers = new List();
    List<Function> inputHandlers = new List();
    List<String> names = new List();
    List<Function> inputParsers = new List();
    var pool;

    DynamicStringHelper(this.string, DataAggregate da){
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
                inputParsers.add(MapRule.getParser(dr.findParamTypeByName(source)));
              }
            }
            httpInputHandlers = MapRule.httpInputHandlerBuilder(hasCookie, hasGet, hasPost, da);
          } else if(dr is DataBaseOptions){
            pool = dr.getDB();
          }
        }
    }

}

class DynamicString extends MapRule{
  const DynamicString();

  // obj is a string, name is the name of the string
  Map transformData(var name, var obj, [DataAggregate da]) {
    DynamicStringHelper dsh = new DynamicStringHelper(obj, da);
    return {name: (new StringModifier(dsh.string, dsh.names, dsh.httpInputHandlers, dsh.inputHandlers, dsh.inputParsers)).executeRequest};
  }
}

class StringModifier extends BaseClosure{
  List<String> names;
  String string; // symbol of object to be invoked from instance mirror
  StringModifier(this.string, this.names, List httpInputHandlers, List inputHandlers, List inputParsers) :
    super(httpInputHandlers, inputHandlers, inputParsers);

  executeRequest(List cookies, String get, String post){
    if(inputHandlers==[]){
      return string;
    }
    String tempString = string;
    List inputs = getInputs(cookies, get, post);
    if(inputs.length!=names.length){
      return "";
    } else{
      for(int i = 0; i<names.length; i++){
        tempString = tempString.replaceAll("{${names[i]}}", inputs[i].toString());
      }
      return tempString;
    }
  }
}

class DynamicSQL extends MapRule{
  const DynamicSQL();
  @override
  Map transformData(var name, var obj, [DataAggregate da]) {
    DynamicStringHelper dhs = new DynamicStringHelper(obj, da);
    return {name: (new SQLCaller(dhs.string, dhs.names, dhs.httpInputHandlers, dhs.inputHandlers, dhs.pool, dhs.inputParsers)).runSQL};
  }
}
// need to implement input parsers into string modifier
class SQLCaller extends StringModifier{
  var pool;
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
