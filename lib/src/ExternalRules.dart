part of Shorthand_base;

// checks to see if this is an external rule
abstract class ExternalRule extends RuleBase {
  final String packagePath = "\\lib\\src\\templates\\";
  final List<String> requiredData; // Data points needed to use rule
  final List<String> optionalData; // if it's not in the DA then null it out
  final String
      ruleName; // name of the rule. Should be filled in by subclasses, no user input, Also used to load template files which end in a .txt format
  final String viewName; // name of view to be generated
  const ExternalRule(this.ruleName, this.viewName,
      {this.requiredData, this.optionalData});

  // makes sure the aggregate has data necessary to run
  bool checkData(DataAggregate da) {
    if (da == null) {
      return true;
    }
    bool check = true;
    requiredData.forEach((item) {
      if (da.aggregate[item] == null) {
        print("//$item is missing from $viewName");
        check = false;
      }
    });
    return check;
  }

  // Turns template into workable Flutter code
  String processTemplate(DataAggregate da) {
    String processedTemplate = new File(
            "${Directory.current.path + packagePath + ruleName}.txt")
        .readAsStringSync(); // shouldn't need to check, this is for you, you don't want the file there, you can't use it
    if (checkData(da)) {
      // all required data points are here
      da.aggregate.values.forEach((rule) {
        // go through all data rules
        if (rule is MobileDataRule) {
          // iff its a MobileDataRule, use it to swap for data in template
          MobileDataRule mdr = rule;
          mdr.mobileSwap().forEach((name, value) {
            processedTemplate =
                processedTemplate.replaceAll("{${name}}", value);
          });
        } else if (rule is GlobalDataRule) {
          GlobalDataRule gdr = rule;
          gdr.mobileSwap().forEach((name, value) {
            processedTemplate =
                processedTemplate.replaceAll("{${name}}", value);
          });
        }
      });
      // clean up unnecessary options from the code
      optionalData.forEach((option) {
        if (!da.aggregate.containsKey(option)) {
          if (option == null) return null;
          //print(currentMirrorSystem().libraries);
          ClassMirror cm = currentMirrorSystem()
              .findLibrary(new Symbol("Shorthand_base"))
              .declarations[new Symbol(option)];
          MobileDataRule opt = cm.getField(#generator).reflectee();
          opt.mobileSwap().keys.forEach((field) {
            processedTemplate = processedTemplate.replaceAll("{${field}}", "");
          });
        }
      });
    }
    print(processedTemplate.replaceAll("{ViewName}", this.viewName));
    return processedTemplate.replaceAll("{ViewName}", this.viewName);
  }
}

class BasicList extends ExternalRule {
  const BasicList(String viewName)
      : super("basicList", viewName,
            requiredData: const ["Output"], optionalData: const ["FlowTo"]);
}

class InternetList extends ExternalRule {
  const InternetList(String viewName)
      : super("InternetList", viewName,
            requiredData: const ["Input", "Output", "HostName"],
            optionalData: const ["FlowTo"]);
}

class ExternalRuleAggregate {
  Map<String, ExternalRule> aggregate;

  ExternalRuleAggregate() {
    aggregate = new Map<String, ExternalRule>();
  }

  void addToAggregate(Map<String, ExternalRule> import) {
    aggregate.addAll(import);
  }

  getVar(String variable) {
    return aggregate[variable];
  }
}
