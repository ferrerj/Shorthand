part of Shorthand_base;

// Rules to control inputs into the functions of the API
abstract class InputRule extends RuleBase {
  const InputRule ();
}
// how the data is to be recieved
enum DataInputType {GET, POST, COOKIE}
// types which should be parseable from input data
enum InputType {int, string, double, float, bool}

// Declares where to find the data, how to process and clean it
abstract class InputDataRule extends InputRule {
  final dynamic dataInputType; // yes like the enum, different can be used on same object
  final dynamic arg; // either arg position number or arg name
  final String name; // name of the input variable for function to be called
  const InputDataRule(this.dataInputType, this.arg, this.name);
  // gets the data point based on how it is stored and returns it as a string to be parsed by the InputType
  extractDataPoint(List cookies, dynamic getData, String postData);
}
// Declares how the arguments are laid out and are as expected, breaks them up as necessary
abstract class InputTypeRule extends InputRule {
  const InputTypeRule();
  processInputs(String get, String post, List cookie); // generate functions to check inputs
  countInputs(); // make sure there are enough inputs and declared inputs
}

abstract class GetData extends InputDataRule{
  GetData(String arg, String name) : super(DataInputType.GET, arg, name);
}

abstract class PostData extends InputDataRule {
  PostData(String arg, String name) : super(DataInputType.POST, arg, name);
}
// this is only a key store, shouldn't really have JSON or other formating to seperate out the different content fields
abstract class CookieData extends InputDataRule {
  CookieData(String arg, String name) : super(DataInputType.COOKIE, arg, name);
}


// these are used to reduce the amount of work in isolating data from the above classes
// these will be used as mixins with the above classes
abstract class FromJSON {
  // from data stored in a JSON object
}

abstract class FromCSV {
  // from comma seperated data
}

abstract class FromSlashData {
  // stored as /name/data
}
// really going to start with this one (for personal projects) and will do the others next
abstract class FromAndData {
  // stored as ?var1=data1&
}