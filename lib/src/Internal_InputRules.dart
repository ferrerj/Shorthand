part of Shorthand_base;

// its looking more and more like this will be scrapped for special data rules

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
