part of Shorthand_base;

// Placeholder for data to be collected and analyzed
// If you're using this, don't add two of the same descriptor, just no reason to
abstract class DataRule extends RuleBase {
  final String descriptor;
  final dynamic payload;

  const DataRule(this.descriptor, this.payload);

  Map asMap() {
    return {this.descriptor: this};
  }
}

// used for data rules which can be used in forms which may offer multiple inputs/outputs
abstract class MobileDataRule extends DataRule {
  final List<String> fields;

  const MobileDataRule(String descriptor, dynamic payload, this.fields)
      : super(descriptor, payload);

  Map<String, String> mobileSwap(); // map of special things to swap out for mobile forms
// make a static function called generator that returns a new instance of that object,
// just so the External rules can clean up optional data points
}

// used for top level objects, should not be used on any object members
abstract class GlobalDataRule extends DataRule {
  const GlobalDataRule(String descriptor, dynamic payload)
      : super(descriptor, payload);

  Map<String, String> mobileSwap() {
    return {descriptor: payload};
  }
}

/* Regular Data Rules */

// describes the function to be called
class Description extends DataRule {
  const Description(String desc) : super("Description", desc);
}

/* Mobile Data Rules */

// try to use terms consistent with the previous view output for the input vars so they can be matched up later
// provide the inputs and outputs of functions to any aggregate
// Input of the REST API, fields that need to be populated
class Input extends MobileDataRule {
  const Input(List payload)
      : super("Input", payload, const ["KeyInputs", "KeyInputsURL"]);

  Map<String, String> mobileSwap() {
    List<String> things = payload;
    if (things.isEmpty) {
      return {"KeyInputs": "", "KeyInputsURL": ""};
    }
    String keyInputs =
        things.fold("", (prev, element) => prev + "var ${element};\n");
    String keyInputsURL = things.fold(
        "", (prev, element) => prev + "\${widget." + "${element}}//");
    return {
      "KeyInputs": keyInputs,
      /* inputs from previous object which are used to look up current one */
      "KeyInputsURL": keyInputsURL
    }; /* URL format of previous object keys to generate current object */
  }

  static generator() {
    return new Input([]);
  }
}

// try to use terms consistent with the previous view output for the input vars so they can be matched up later
// data to be had from the REST API
// need to implement a key function, used to build next object...like a primary or foreign key
// so when you click on something the next view has something to build from, should you choose
// to use a REST call on that next view
class Output extends MobileDataRule {
  final List<String> key;

  const Output(List payload, this.key)
      : super("Output", payload,
            const ["ObjectFields", "ObjectBuilder", "KeyFields"]);

  Map<String, String> mobileSwap() {
    List<String> things = new List<String>();
    things.addAll(payload);
    things.addAll(key);
    String objectMembers =
        things.fold("", (prev, element) => prev + "var ${element};\n");
    String objectDeclaration =
        things.fold("", (prev, element) => prev + "this.${element},");
    String keyFields = key.fold(
        "",
        (prev, elem) =>
            prev +
            "this.${elem},"); // key fields are used to pass data to the next object to get info from the server
    return {
      "ObjectFields": objectMembers,
      "ObjectBuilder":
          objectDeclaration.substring(0, objectDeclaration.length - 1),
      "KeyFields":
          (keyFields == "") ? "" : keyFields.substring(0, keyFields.length - 1)
    };
  }

  static generator() {
    return new Output([], []);
  }
}

// this one is kinda cheaty seeing as it will be called by the generator
// no one should really be declaring this in their code.
class RoutingInfo extends MobileDataRule {
  const RoutingInfo(String payload)
      : super("RoutingInfo", payload, const ["RoutingInfo"]);

  Map<String, String> mobileSwap() {
    String things = payload;
    return {"RoutingInfo": things};
  }
}

// not sold on this name, basically the view you click to
class FlowTo extends MobileDataRule {
  const FlowTo(String view) : super("FlowTo", view, const ["TapAction"]);

  Map<String, String> mobileSwap() {
    return {
      "TapAction":
          "onTap:(){Navigator.push(context, new MaterialPageRoute( builder: (BuildContext context)=> new {ViewName}List({KeyFields}),"
    };
  }

  static generator() {
    return new FlowTo("");
  }
}

// to be implemented later
// I think I'll need to aggregate External rules with the various parts pre-constructed
class RowNumber extends MobileDataRule {
  // idk how to implement yet
  const RowNumber(int number) : super("RowNumber", number, const []);

  Map<String, String> mobileSwap() {
    return null;
  }

  static generator() {
    return new RowNumber(0);
  }
}

/* Global Data Rules */
// include http, https, etc in the definition
class HostName extends GlobalDataRule {
  const HostName(String payload) : super("HostName", payload);
}

enum InputFormat {JSON, CSV, Slashes, AndData, PositionalData}
// class for GET/POST/COOKIE Data
abstract class InputStorageMethod extends GlobalDataRule {
  final dynamic inputFormat;
  const InputStorageMethod (this.inputFormat) : super("InputStorageMethod", "");
  // to be implemented later
  _mapFromJSON(String input){}
  // to be implemented later
  _mapFromCSV(String input){}
  // getting data like /name1/data1/.../namex/datax
  _mapFromSlashes(String input){
    Map ret = new Map();
    int i = 0;
    String name;
    input.split("/").forEach((stringPart){
      if(i++%2==0){
        name = stringPart;
      } else {
        ret[name] = stringPart;
      }
    });
    return ret;
  }
  // getting data like /?name1=data1&...&namex=datax
  // the leading /? is optional
  _mapFromAndData(String input){
    if(input[0]=="?"){
      input = input.substring(1);
    }
    Map ret = new Map();
    input.split("&").forEach((stringPart){
      List parts = stringPart.split("=");
      ret[parts[0]] = parts[1];
    });
    return ret;
  }
  // getting data like /[1]/[2]/.../[x]
  // returns map <number, value>
  _mapFromPositionalData(String input){
    Map ret = new Map();
    int i = 0;
    input.split("/").forEach((stringPart){
      ret[(i++).toString()] = stringPart;
    });
    return ret;
  }
  returnMap(List cookies, dynamic getData, String postData);
  getProcessingFunction(){
    if(this.inputFormat == InputFormat.JSON){
      return _mapFromJSON;
    } else if(this.inputFormat == InputFormat.CSV){
      return _mapFromCSV;
    } else if(this.inputFormat == InputFormat.AndData){
      return _mapFromAndData;
    } else if(this.inputFormat == InputFormat.PositionalData){
      return _mapFromPositionalData;
    } else if(this.inputFormat == InputFormat.Slashes){
      return _mapFromSlashes;
    }
  }
}

class GetData extends InputStorageMethod {
  const GetData (dynamic inputFormat) : super(inputFormat);
  returnMap(List cookies, dynamic getData, String postData){

  }
}

class PostData extends InputStorageMethod {
  const PostData (dynamic inputFormat) : super(inputFormat);
  returnMap(List cookies, dynamic getData, String postData){

  }
}

class CookieData extends InputStorageMethod {
  const CookieData (dynamic inputFormat) : super(inputFormat);
  returnMap(List cookies, dynamic getData, String postData){
    Map<String, String> ret;
    cookies.forEach((Cookie cookie){
      ret[cookie.name] = cookie.value;
    });
    return ret;
  }
}
// gets a class object which declares where to find data (get, post, cookie) and how to map it to a name used in a function
class DataSources extends GlobalDataRule {
  const DataSources(dynamic model) : super("DataSources", "");
}

/* Helper Objects */

// non constant helper class to get all data points for a function
class DataAggregate {
  Map<String, DataRule> aggregate;

  DataAggregate() {
    aggregate = new Map<String, DataRule>();
  }

  void addToAggregate(Map<String, DataRule> import) {
    aggregate.addAll(import);
  }

  getVar(String variable) {
    return aggregate[variable];
  }
}